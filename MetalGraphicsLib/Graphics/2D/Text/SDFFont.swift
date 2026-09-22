import CoreText
import MetalKit

// Glyph outlines are turned into signed distance fields once, on first use, and baked into a
// single atlas texture that `compute2D` samples. Ported from SwiftImgui's `Font`, with the
// per-glyph textures replaced by atlas regions and the render pass by the `bakeGlyphSDF` kernel.
//
// A glyph's metrics and atlas region are known on the CPU as soon as it is first laid out. The
// bake itself is queued and encoded into the next frame's command buffer, ahead of `compute2D`,
// so nothing waits on the GPU.

struct GlyphMetrics {
  /// Em space bounds of the baked region, y up, relative to the glyph origin. The glyph outline
  /// plus padding.
  var boundsMin = float2()
  var boundsMax = float2()
  /// Atlas uv of the centers of the region's top left and bottom right texels.
  var uvMin = float2()
  var uvMax = float2()
  /// False for glyphs that only advance the pen, such as a space.
  var hasOutline = false
}

// type
// 0 - moveToPoint, starts new path
// 1 - addLineToPoint, adds line from current point to a new point. Element holds 1 point for destination
// 2 - addQuadCurveToPoint, adds a quadratice curve from current point to the specified point.
//     Element holds control point (point0) and a destination point (point1).
// 4 - closePath, path element that closes and completes a subpath. The element does not contain any points.
private struct PathElement {
  var point0 = float2()
  var point1 = float2()
  var type: UInt8 = 0
}

private struct SubPath {
  var start: UInt32 = 0
  var end: UInt32 = 0
}

private struct GlyphBakeParams {
  var origin = SIMD2<UInt32>()
  var size = SIMD2<UInt32>()
  var emTopLeft = float2()
  var emPerTexel = Float()
  var subPathStart = UInt32()
  var subPathEnd = UInt32()
  var pathElementCount = UInt32()
}

/// A glyph waiting to be baked. Its subpaths index into its own `pathElements`, and its params
/// cover its own subpaths; both are rebased when the batch is encoded.
private struct PendingBake {
  var params: GlyphBakeParams
  var pathElements: [PathElement]
  var subPaths: [SubPath]
}

/// A glyph of a concrete font: the run font CoreText picked, which may be a fallback.
private struct GlyphKey: Hashable {
  var fontName: String
  var glyph: CGGlyph
}

/// A shelf packer over one r16Float texture holding every baked glyph.
@MainActor final class SDFAtlas {
  let texture: MTLTexture
  let size: Int

  private var cursor = SIMD2<Int>()
  private var rowHeight = 0
  // Keeps bilinear filtering of one region from ever reaching into its neighbour.
  private let spacing = 1

  init(device: MTLDevice, size: Int = 2048) {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .r16Float, width: size, height: size, mipmapped: false
    )
    descriptor.storageMode = .private
    descriptor.usage = [.shaderRead, .shaderWrite]
    guard let texture = device.makeTexture(descriptor: descriptor) else {
      fatalError("Could not create the glyph SDF atlas")
    }
    texture.label = "Glyph SDF atlas"
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

@MainActor public final class FontManager {
  public static let shared = FontManager()
  /// TrueType, so its outlines are quadratic, and present on every Mac.
  public static var defaultFontName = "Menlo"

  public lazy var defaultFont: SDFFont = self.font(named: Self.defaultFontName)

  /// Resolution of the baked distance field.
  static let texelsPerEm: Float = 64
  /// Distance field kept around the outline, so anti-aliasing has room outside the glyph.
  static let paddingTexels = 4
  /// Largest region a glyph may take in the atlas, per axis. A real glyph at 64 texels per em
  /// is well under this; anything bigger means CoreText handed back a bogus outline.
  private static let maxRegionTexels = 512

  let device: MTLDevice
  let atlas: SDFAtlas
  private let bakePipelineState: MTLComputePipelineState
  private var fonts: [String: SDFFont] = [:]
  private var glyphs: [GlyphKey: GlyphMetrics] = [:]
  private var pendingBakes: [PendingBake] = []
  private var reportedAtlasFull = false

  var atlasTexture: MTLTexture {
    self.atlas.texture
  }

  private init() {
    self.device = GPUDevice.main
    self.atlas = SDFAtlas(device: self.device)

    do {
      let library = try self.device.makeDefaultLibrary(bundle: Bundle(for: FontManager.self))
      guard let kernel = library.makeFunction(name: "bakeGlyphSDF") else {
        fatalError("bakeGlyphSDF kernel is missing from the Metal library")
      }
      self.bakePipelineState = try self.device.makeComputePipelineState(function: kernel)
    } catch {
      fatalError("Could not create the glyph bake pipeline: \(error)")
    }
  }

  public func font(named name: String) -> SDFFont {
    if let font = self.fonts[name] {
      return font
    }

    let font = SDFFont(name: name)
    self.fonts[name] = font
    return font
  }

  /// Metrics of `glyph` in `font`, queueing its bake the first time it is seen. `font` can be at
  /// any size; the outline is scaled to em.
  func glyphMetrics(font: CTFont, glyph: CGGlyph) -> GlyphMetrics {
    let key = GlyphKey(fontName: CTFontCopyPostScriptName(font) as String, glyph: glyph)
    if let metrics = self.glyphs[key] {
      return metrics
    }

    let metrics = self.makeGlyph(font: font, glyph: glyph, name: key.fontName)
    self.glyphs[key] = metrics
    return metrics
  }

  /// Encodes every glyph queued since the last frame. Called on the frame's command buffer before
  /// anything samples the atlas; the atlas is hazard tracked, so the bakes finish first.
  func encodePendingBakes(into commandBuffer: MTLCommandBuffer) {
    guard !self.pendingBakes.isEmpty else {
      return
    }

    var pathElements: [PathElement] = []
    var subPaths: [SubPath] = []
    var params: [GlyphBakeParams] = []
    for bake in self.pendingBakes {
      let elementBase = UInt32(pathElements.count)
      let subPathBase = UInt32(subPaths.count)
      pathElements += bake.pathElements
      subPaths += bake.subPaths.map { SubPath(start: $0.start + elementBase, end: $0.end + elementBase) }

      var glyphParams = bake.params
      glyphParams.subPathStart = subPathBase
      glyphParams.subPathEnd = subPathBase + UInt32(bake.subPaths.count)
      params.append(glyphParams)
    }
    self.pendingBakes.removeAll(keepingCapacity: true)

    guard
      let pathElementBuffer = self.device.makeBuffer(bytes: &pathElements, length: pathElements.byteCount),
      let subPathBuffer = self.device.makeBuffer(bytes: &subPaths, length: subPaths.byteCount),
      let encoder = commandBuffer.makeComputeCommandEncoder()
    else {
      fatalError("Could not encode the glyph bakes")
    }
    pathElementBuffer.label = "Glyph path elements"
    subPathBuffer.label = "Glyph subpaths"
    encoder.label = "Glyph SDF bake"

    encoder.setComputePipelineState(self.bakePipelineState)
    encoder.setTexture(self.atlas.texture, index: 0)
    encoder.setBuffer(pathElementBuffer, offset: 0, index: 1)
    encoder.setBuffer(subPathBuffer, offset: 0, index: 2)

    let width = self.bakePipelineState.threadExecutionWidth
    let height = self.bakePipelineState.maxTotalThreadsPerThreadgroup / width
    for var glyphParams in params {
      glyphParams.pathElementCount = UInt32(pathElements.count)
      encoder.setBytes(&glyphParams, length: MemoryLayout<GlyphBakeParams>.stride, index: 0)

      let size = SIMD2<Int>(Int(glyphParams.size.x), Int(glyphParams.size.y))
      encoder.dispatchThreadgroups(
        MTLSize(width: (size.x + width - 1) / width, height: (size.y + height - 1) / height, depth: 1),
        threadsPerThreadgroup: MTLSize(width: width, height: height, depth: 1)
      )
    }
    encoder.endEncoding()
  }

  private func makeGlyph(font: CTFont, glyph: CGGlyph, name: String) -> GlyphMetrics {
    var metrics = GlyphMetrics()

    // the outline in em, whatever size the run font was made at
    let scale = 1 / CTFontGetSize(font)
    var transform = CGAffineTransform(scaleX: scale, y: scale)
    guard let path = CTFontCreatePathForGlyph(font, glyph, &transform), !path.isEmpty else {
      return metrics
    }
    let (pathElements, subPaths) = Self.flatten(path)
    guard !subPaths.isEmpty else {
      return metrics
    }

    let bounds = path.boundingBoxOfPath
    guard
      !bounds.isNull, !bounds.isInfinite,
      bounds.minX.isFinite, bounds.minY.isFinite, bounds.width.isFinite, bounds.height.isFinite,
      bounds.width > 0, bounds.height > 0
    else {
      print("Skipping glyph \(glyph) of '\(name)': invalid outline bounds \(bounds)")
      return metrics
    }
    let emPerTexel = 1 / Self.texelsPerEm
    let padding = Float(Self.paddingTexels) * emPerTexel
    // Texel centers sit on an em grid starting at the padded top left corner, so the texel
    // count includes both ends.
    let emTopLeft = float2(Float(bounds.minX) - padding, Float(bounds.maxY) + padding)
    let regionSize = SIMD2<Int>(
      Int(ceil(Float(bounds.width) * Self.texelsPerEm)) + 2 * Self.paddingTexels + 1,
      Int(ceil(Float(bounds.height) * Self.texelsPerEm)) + 2 * Self.paddingTexels + 1
    )
    guard regionSize.x <= Self.maxRegionTexels, regionSize.y <= Self.maxRegionTexels else {
      print("Skipping glyph \(glyph) of '\(name)': \(regionSize.x)x\(regionSize.y) texels is too large to bake")
      return metrics
    }
    guard let origin = self.atlas.allocate(regionSize) else {
      if !self.reportedAtlasFull {
        self.reportedAtlasFull = true
        print("Glyph SDF atlas (\(self.atlas.size)x\(self.atlas.size)) is full, new glyphs are not drawn")
      }
      return metrics
    }
    let regionExtent = float2(Float(regionSize.x - 1), Float(regionSize.y - 1)) * emPerTexel

    metrics.boundsMin = float2(emTopLeft.x, emTopLeft.y - regionExtent.y)
    metrics.boundsMax = float2(emTopLeft.x + regionExtent.x, emTopLeft.y)
    let atlasSize = Float(self.atlas.size)
    metrics.uvMin = (float2(Float(origin.x), Float(origin.y)) + 0.5) / atlasSize
    metrics.uvMax = (float2(Float(origin.x + regionSize.x), Float(origin.y + regionSize.y)) - 0.5) / atlasSize
    metrics.hasOutline = true

    self.pendingBakes.append(PendingBake(
      params: GlyphBakeParams(
        origin: SIMD2(UInt32(origin.x), UInt32(origin.y)),
        size: SIMD2(UInt32(regionSize.x), UInt32(regionSize.y)),
        emTopLeft: emTopLeft,
        emPerTexel: emPerTexel
      ),
      pathElements: pathElements,
      subPaths: subPaths
    ))

    return metrics
  }

  /// Converts a glyph outline into the element list `bakeGlyphSDF` walks. Every subpath ends
  /// with a close element, and cubic curves are approximated by two quadratics.
  private static func flatten(_ path: CGPath) -> ([PathElement], [SubPath]) {
    var pathElements = [PathElement]()
    var subPaths = [SubPath]()
    var subPathStart = 0
    var isSubPathOpen = false
    var currentPoint = float2()

    func closeSubPath() {
      guard isSubPathOpen else { return }
      pathElements.append(PathElement(type: 4))
      subPaths.append(SubPath(start: UInt32(subPathStart), end: UInt32(pathElements.count)))
      isSubPathOpen = false
    }

    func quad(_ control: float2, _ end: float2) {
      pathElements.append(PathElement(point0: control, point1: end, type: 2))
      currentPoint = end
    }

    path.applyWithBlock { pointer in
      let element = pointer.pointee
      let points = element.points
      func point(_ i: Int) -> float2 {
        float2(Float(points[i].x), Float(points[i].y))
      }

      switch element.type {
      case .moveToPoint:
        closeSubPath()
        subPathStart = pathElements.count
        isSubPathOpen = true
        currentPoint = point(0)
        pathElements.append(PathElement(point0: currentPoint, type: 0))

      case .addLineToPoint:
        // a zero length segment adds nothing to the distance field
        guard point(0) != currentPoint else { break }
        currentPoint = point(0)
        pathElements.append(PathElement(point0: currentPoint, type: 1))

      case .addQuadCurveToPoint:
        quad(point(0), point(1))

      case .addCurveToPoint:
        // Split at t = 0.5, then fit a quadratic to each half.
        let p0 = currentPoint, c1 = point(0), c2 = point(1), p3 = point(2)
        let p01 = (p0 + c1) * 0.5, p12 = (c1 + c2) * 0.5, p23 = (c2 + p3) * 0.5
        let p012 = (p01 + p12) * 0.5, p123 = (p12 + p23) * 0.5
        let mid = (p012 + p123) * 0.5
        quad((3 * (p01 + p012) - p0 - mid) * 0.25, mid)
        quad((3 * (p123 + p23) - mid - p3) * 0.25, p3)

      case .closeSubpath:
        closeSubPath()

      @unknown default:
        break
      }
    }
    closeSubPath()

    return (pathElements, subPaths)
  }
}

@MainActor public final class SDFFont {
  public let name: String
  /// Layout runs at the real point size, so CoreText applies the tracking and optical size meant
  /// for it. Glyph outlines are scaled back to em when they are baked.
  private var sizedFonts: [Float: CTFont] = [:]

  fileprivate init(name: String) {
    self.name = name
  }

  func ctFont(size: Float) -> CTFont {
    if let font = self.sizedFonts[size] {
      return font
    }

    let font = CTFontCreateWithName(self.name as CFString, CGFloat(size), nil)
    self.sizedFonts[size] = font
    return font
  }
}
