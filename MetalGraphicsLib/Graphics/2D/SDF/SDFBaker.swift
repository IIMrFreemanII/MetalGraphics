import CoreGraphics
import MetalKit

// Outlines are turned into signed distance fields once, on first use, and baked into a single
// atlas texture that `compute2D` samples. Glyphs (see SDFFont.swift) and SVG icons (see
// SVGIcon.swift) share it: both are quads whose coverage comes from a baked distance.
//
// A region's metrics and atlas uv are known on the CPU as soon as it is requested. The bake
// itself is queued and encoded into the next frame's command buffer, ahead of `compute2D`, so
// nothing waits on the GPU.

// type
// 0 - moveToPoint, starts new path
// 1 - addLineToPoint, adds line from current point to a new point. Element holds 1 point for destination
// 2 - addQuadCurveToPoint, adds a quadratice curve from current point to the specified point.
//     Element holds control point (point0) and a destination point (point1).
// 4 - closePath, path element that closes and completes a subpath. The element does not contain any points.
struct PathElement {
  var point0 = float2()
  var point1 = float2()
  var type: UInt8 = 0
}

struct SubPath {
  var start: UInt32 = 0
  var end: UInt32 = 0
}

/// How a shape's distance is signed. Laid out as `mode` of `SDFShape` in GlyphSDF.metal.
enum SDFShapeMode: UInt32 {
  /// Inside where the winding number is not zero, the way fonts fill glyphs.
  case fillNonZero = 0
  /// Inside where the winding number is odd.
  case fillEvenOdd = 1
  /// Inside within `halfWidth` of the outline. Round caps and joins, as a distance field has.
  case stroke = 2
}

/// One fill or stroke of a bake region, laid out as `SDFShape` in GlyphSDF.metal.
private struct SDFShape {
  var subPathStart: UInt32 = 0
  var subPathEnd: UInt32 = 0
  var mode: UInt32 = 0
  var halfWidth: Float = 0
}

/// A fill or stroke to bake, in em space, y up. Its subpaths index into its own elements.
struct SDFShapeGeometry {
  var mode: SDFShapeMode
  /// Half the stroke width in em. Unused by fills.
  var halfWidth: Float = 0
  var pathElements: [PathElement]
  var subPaths: [SubPath]
}

/// Where a baked region landed.
struct SDFRegion {
  /// Em space bounds of the baked region, y up. The outline plus padding.
  var boundsMin = float2()
  var boundsMax = float2()
  /// Atlas uv of the centers of the region's top left and bottom right texels.
  var uvMin = float2()
  var uvMax = float2()
}

private struct SDFBakeParams {
  var origin = SIMD2<UInt32>()
  var size = SIMD2<UInt32>()
  var emTopLeft = float2()
  var emPerTexel = Float()
  var shapeStart = UInt32()
  var shapeEnd = UInt32()
  var pathElementCount = UInt32()
  var subPathCount = UInt32()
}

/// A region waiting to be baked. Its shapes index into its own subpaths, and its subpaths into
/// its own elements; all of them are rebased when the batch is encoded.
private struct PendingBake {
  var params: SDFBakeParams
  var shapes: [SDFShape]
  var pathElements: [PathElement]
  var subPaths: [SubPath]
}

/// Builds the element list `bakeSDF` walks, one subpath at a time.
struct SDFPathBuilder {
  private(set) var pathElements: [PathElement] = []
  private(set) var subPaths: [SubPath] = []
  private(set) var currentPoint = float2()
  /// Fills close every subpath, as filling implies; strokes only close the ones that say so.
  let closesOpenSubPaths: Bool

  private var subPathStart = 0
  private var startPoint = float2()
  private var isSubPathOpen = false

  init(closesOpenSubPaths: Bool = true) {
    self.closesOpenSubPaths = closesOpenSubPaths
  }

  var isEmpty: Bool { self.subPaths.isEmpty && !self.isSubPathOpen }

  mutating func move(to point: float2) {
    self.endSubPath()
    self.subPathStart = self.pathElements.count
    self.isSubPathOpen = true
    self.currentPoint = point
    self.startPoint = point
    self.pathElements.append(PathElement(point0: point, type: 0))
  }

  mutating func line(to point: float2) {
    self.openIfNeeded()
    // a zero length segment adds nothing to the distance field
    guard point != self.currentPoint else { return }
    self.currentPoint = point
    self.pathElements.append(PathElement(point0: point, type: 1))
  }

  mutating func quad(_ control: float2, _ end: float2) {
    self.openIfNeeded()
    self.pathElements.append(PathElement(point0: control, point1: end, type: 2))
    self.currentPoint = end
  }

  /// Approximates the cubic by `2^levels` quadratics: it is halved `levels` times, and each
  /// piece gets the quadratic through its ends whose control point is the mean of the cubic's
  /// two, which is exact at its midpoint.
  mutating func cubic(_ c1: float2, _ c2: float2, _ end: float2, levels: Int = 1) {
    self.openIfNeeded()
    let p0 = self.currentPoint
    guard levels > 0 else {
      self.quad((3 * (c1 + c2) - p0 - end) * 0.25, end)
      return
    }
    let p01 = (p0 + c1) * 0.5, p12 = (c1 + c2) * 0.5, p23 = (c2 + end) * 0.5
    let p012 = (p01 + p12) * 0.5, p123 = (p12 + p23) * 0.5
    let mid = (p012 + p123) * 0.5
    self.cubic(p01, p012, mid, levels: levels - 1)
    self.cubic(p123, p23, end, levels: levels - 1)
  }

  /// Adds a cubic, split finely enough that no quadratic strays more than `tolerance` from it.
  mutating func cubic(_ c1: float2, _ c2: float2, _ end: float2, tolerance: Float) {
    let p0 = self.currentPoint
    // The distance between a cubic and its midpoint quadratic is at most sqrt(3)/36 times this,
    // and shrinks with the cube of the number of pieces.
    let error = length(end - 3 * c2 + 3 * c1 - p0) * (Float(3).squareRoot() / 36)
    let pieces = error > tolerance ? cbrt(error / max(tolerance, 1e-9)) : 1
    let levels = Int(ceil(log2(max(pieces, 1))))
    self.cubic(c1, c2, end, levels: min(max(levels, 1), 6))
  }

  mutating func close() {
    guard self.isSubPathOpen else { return }
    self.pathElements.append(PathElement(type: 4))
    self.subPaths.append(SubPath(start: UInt32(self.subPathStart), end: UInt32(self.pathElements.count)))
    self.isSubPathOpen = false
    self.currentPoint = self.startPoint
  }

  /// Ends the last subpath and returns the path.
  mutating func finish() -> ([PathElement], [SubPath]) {
    self.endSubPath()
    return (self.pathElements, self.subPaths)
  }

  private mutating func endSubPath() {
    guard self.isSubPathOpen else { return }
    if self.closesOpenSubPaths {
      self.close()
      return
    }
    // A lone move draws nothing.
    if self.pathElements.count - self.subPathStart > 1 {
      self.subPaths.append(SubPath(start: UInt32(self.subPathStart), end: UInt32(self.pathElements.count)))
    } else {
      self.pathElements.removeLast(self.pathElements.count - self.subPathStart)
    }
    self.isSubPathOpen = false
  }

  /// Drawing after a close starts a new subpath where the closed one started, as in SVG.
  private mutating func openIfNeeded() {
    if !self.isSubPathOpen {
      self.move(to: self.currentPoint)
    }
  }
}

/// A shelf packer over one r16Float texture holding every baked region.
@MainActor final class SDFAtlas {
  let texture: MTLTexture
  let size: Int

  private var cursor = SIMD2<Int>()
  private var rowHeight = 0
  // Keeps bilinear filtering of one region from ever reaching into its neighbour.
  private let spacing = 1

  init(device: MTLDevice, size: Int = 4096) {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .r16Float, width: size, height: size, mipmapped: false
    )
    descriptor.storageMode = .private
    descriptor.usage = [.shaderRead, .shaderWrite]
    guard let texture = device.makeTexture(descriptor: descriptor) else {
      fatalError("Could not create the SDF atlas")
    }
    texture.label = "SDF atlas"
    self.texture = texture
    self.size = size
  }

  /// Returns the top left texel of a free region of `regionSize` texels, or nil when the atlas
  /// has no room left.
  func allocate(_ regionSize: SIMD2<Int>) -> SIMD2<Int>? {
    var cursor = self.cursor
    var rowHeight = self.rowHeight
    if cursor.x + regionSize.x > self.size {
      cursor = SIMD2(0, cursor.y + rowHeight + self.spacing)
      rowHeight = 0
    }
    guard regionSize.x <= self.size, cursor.y + regionSize.y <= self.size else {
      return nil
    }

    self.cursor = SIMD2(cursor.x + regionSize.x + self.spacing, cursor.y)
    self.rowHeight = max(rowHeight, regionSize.y)
    return cursor
  }
}

@MainActor final class SDFBaker {
  static let shared = SDFBaker()

  /// Distance field kept around the outline, so anti-aliasing has room outside it.
  static let paddingTexels = 4

  let device: MTLDevice
  let atlas: SDFAtlas
  private let bakePipelineState: MTLComputePipelineState
  private var pendingBakes: [PendingBake] = []
  private var reportedAtlasFull = false

  private init() {
    self.device = GPUDevice.main
    self.atlas = SDFAtlas(device: self.device)

    do {
      let library = try self.device.makeDefaultLibrary(bundle: Bundle(for: SDFBaker.self))
      guard let kernel = library.makeFunction(name: "bakeSDF") else {
        fatalError("bakeSDF kernel is missing from the Metal library")
      }
      self.bakePipelineState = try self.device.makeComputePipelineState(function: kernel)
    } catch {
      fatalError("Could not create the SDF bake pipeline: \(error)")
    }
  }

  /// Allocates a region for the union of `shapes` and queues its bake. `bounds` is the em space
  /// extent of what is inside, y up; the region adds padding around it. Returns nil, and says
  /// why, when there is nothing to bake or no room for it.
  func bake(
    _ shapes: [SDFShapeGeometry], bounds: CGRect, texelsPerEm: Float, maxRegionTexels: Int, label: String
  ) -> SDFRegion? {
    guard
      !bounds.isNull, !bounds.isInfinite,
      bounds.minX.isFinite, bounds.minY.isFinite, bounds.width.isFinite, bounds.height.isFinite,
      bounds.width > 0, bounds.height > 0
    else {
      print("Skipping \(label): invalid outline bounds \(bounds)")
      return nil
    }
    let emPerTexel = 1 / texelsPerEm
    let padding = Float(Self.paddingTexels) * emPerTexel
    // Texel centers sit on an em grid starting at the padded top left corner, so the texel
    // count includes both ends.
    let emTopLeft = float2(Float(bounds.minX) - padding, Float(bounds.maxY) + padding)
    let regionSize = SIMD2<Int>(
      Int(ceil(Float(bounds.width) * texelsPerEm)) + 2 * Self.paddingTexels + 1,
      Int(ceil(Float(bounds.height) * texelsPerEm)) + 2 * Self.paddingTexels + 1
    )
    guard regionSize.x <= maxRegionTexels, regionSize.y <= maxRegionTexels else {
      print("Skipping \(label): \(regionSize.x)x\(regionSize.y) texels is too large to bake")
      return nil
    }
    guard let origin = self.atlas.allocate(regionSize) else {
      if !self.reportedAtlasFull {
        self.reportedAtlasFull = true
        print("SDF atlas (\(self.atlas.size)x\(self.atlas.size)) is full, new glyphs and icons are not drawn")
      }
      return nil
    }
    let regionExtent = float2(Float(regionSize.x - 1), Float(regionSize.y - 1)) * emPerTexel

    var region = SDFRegion()
    region.boundsMin = float2(emTopLeft.x, emTopLeft.y - regionExtent.y)
    region.boundsMax = float2(emTopLeft.x + regionExtent.x, emTopLeft.y)
    let atlasSize = Float(self.atlas.size)
    region.uvMin = (float2(Float(origin.x), Float(origin.y)) + 0.5) / atlasSize
    region.uvMax = (float2(Float(origin.x + regionSize.x), Float(origin.y + regionSize.y)) - 0.5) / atlasSize

    var bakeShapes: [SDFShape] = []
    var pathElements: [PathElement] = []
    var subPaths: [SubPath] = []
    for shape in shapes {
      let elementBase = UInt32(pathElements.count)
      let subPathBase = UInt32(subPaths.count)
      pathElements += shape.pathElements
      subPaths += shape.subPaths.map { SubPath(start: $0.start + elementBase, end: $0.end + elementBase) }
      bakeShapes.append(SDFShape(
        subPathStart: subPathBase, subPathEnd: UInt32(subPaths.count),
        mode: shape.mode.rawValue, halfWidth: shape.halfWidth
      ))
    }

    self.pendingBakes.append(PendingBake(
      params: SDFBakeParams(
        origin: SIMD2(UInt32(origin.x), UInt32(origin.y)),
        size: SIMD2(UInt32(regionSize.x), UInt32(regionSize.y)),
        emTopLeft: emTopLeft,
        emPerTexel: emPerTexel
      ),
      shapes: bakeShapes,
      pathElements: pathElements,
      subPaths: subPaths
    ))

    return region
  }

  /// Encodes every region queued since the last frame. Called on the frame's command buffer
  /// before anything samples the atlas; the atlas is hazard tracked, so the bakes finish first.
  func encodePendingBakes(into commandBuffer: MTLCommandBuffer) {
    guard !self.pendingBakes.isEmpty else {
      return
    }

    var pathElements: [PathElement] = []
    var subPaths: [SubPath] = []
    var shapes: [SDFShape] = []
    var params: [SDFBakeParams] = []
    for bake in self.pendingBakes {
      let elementBase = UInt32(pathElements.count)
      let subPathBase = UInt32(subPaths.count)
      let shapeBase = UInt32(shapes.count)
      pathElements += bake.pathElements
      subPaths += bake.subPaths.map { SubPath(start: $0.start + elementBase, end: $0.end + elementBase) }
      shapes += bake.shapes.map {
        var shape = $0
        shape.subPathStart += subPathBase
        shape.subPathEnd += subPathBase
        return shape
      }

      var bakeParams = bake.params
      bakeParams.shapeStart = shapeBase
      bakeParams.shapeEnd = shapeBase + UInt32(bake.shapes.count)
      params.append(bakeParams)
    }
    self.pendingBakes.removeAll(keepingCapacity: true)

    // A region with nothing in it still bakes, as all outside; Metal rejects empty buffers.
    if pathElements.isEmpty { pathElements.append(PathElement()) }
    if subPaths.isEmpty { subPaths.append(SubPath()) }
    if shapes.isEmpty { shapes.append(SDFShape()) }

    guard
      let pathElementBuffer = self.device.makeBuffer(bytes: &pathElements, length: pathElements.byteCount),
      let subPathBuffer = self.device.makeBuffer(bytes: &subPaths, length: subPaths.byteCount),
      let shapeBuffer = self.device.makeBuffer(bytes: &shapes, length: shapes.byteCount),
      let encoder = commandBuffer.makeComputeCommandEncoder()
    else {
      fatalError("Could not encode the SDF bakes")
    }
    pathElementBuffer.label = "SDF path elements"
    subPathBuffer.label = "SDF subpaths"
    shapeBuffer.label = "SDF shapes"
    encoder.label = "SDF bake"

    encoder.setComputePipelineState(self.bakePipelineState)
    encoder.setTexture(self.atlas.texture, index: 0)
    encoder.setBuffer(pathElementBuffer, offset: 0, index: 1)
    encoder.setBuffer(subPathBuffer, offset: 0, index: 2)
    encoder.setBuffer(shapeBuffer, offset: 0, index: 3)

    let width = self.bakePipelineState.threadExecutionWidth
    let height = self.bakePipelineState.maxTotalThreadsPerThreadgroup / width
    for var bakeParams in params {
      bakeParams.pathElementCount = UInt32(pathElements.count)
      bakeParams.subPathCount = UInt32(subPaths.count)
      encoder.setBytes(&bakeParams, length: MemoryLayout<SDFBakeParams>.stride, index: 0)

      let size = SIMD2<Int>(Int(bakeParams.size.x), Int(bakeParams.size.y))
      encoder.dispatchThreadgroups(
        MTLSize(width: (size.x + width - 1) / width, height: (size.y + height - 1) / height, depth: 1),
        threadsPerThreadgroup: MTLSize(width: width, height: height, depth: 1)
      )
    }
    encoder.endEncoding()
  }
}
