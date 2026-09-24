import MetalKit
import QuartzCore

// Distance fields of paths drawn by a `VectorCanvas`, which unlike glyphs and icons can change
// every frame. Each path owns a square tile of a separate atlas and re-bakes into it in place,
// so an animation allocates nothing; a tile is only swapped when the path outgrows it.
//
// Only a path's geometry is baked. Where it is drawn, how thick its stroke is and how much of
// it is trimmed are applied by `compute2D`, so most animations never bake at all.

/// A square region of the dynamic atlas.
struct SDFSlot {
  var origin: SIMD2<Int>
  var size: Int
  fileprivate var sizeClass: Int
}

/// Where a path was baked, in its own local units, y down.
struct BakedRegion {
  /// Local position of the centers of the region's top left and bottom right texels.
  var boundsMin = float2()
  var boundsMax = float2()
  /// Atlas uv of the same two texel centers.
  var uvMin = float2()
  var uvMax = float2()
  var texelsPerUnit: Float = 0
}

/// Tiles of a few fixed sizes over one rg16Float texture. Pages of the largest size are handed
/// to a size as it first needs one and cut into tiles of that size; freed tiles go back to their
/// size's free list, so a tile is reused rather than packed again.
@MainActor final class DynamicSDFAtlas {
  static let tileSizes = [64, 128, 256, 512]
  static var maxTileSize: Int { Self.tileSizes.last! }

  let texture: MTLTexture
  let size: Int
  private var free: [[SIMD2<Int>]]
  private var nextPage = 0
  private(set) var tilesInUse = 0

  init(device: MTLDevice, size: Int = 2048) {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rg16Float, width: size, height: size, mipmapped: false
    )
    descriptor.storageMode = .private
    descriptor.usage = [.shaderRead, .shaderWrite]
    guard let texture = device.makeTexture(descriptor: descriptor) else {
      fatalError("Could not create the dynamic SDF atlas")
    }
    texture.label = "Dynamic SDF atlas"
    self.texture = texture
    self.size = size
    self.free = Array(repeating: [], count: Self.tileSizes.count)
  }

  /// A tile at least `texels` wide, or nil when none is free and no page is left.
  func allocate(texels: Int) -> SDFSlot? {
    guard let sizeClass = Self.tileSizes.firstIndex(where: { $0 >= texels }) else { return nil }
    let tileSize = Self.tileSizes[sizeClass]
    if self.free[sizeClass].isEmpty {
      let pagesPerRow = self.size / Self.maxTileSize
      guard self.nextPage < pagesPerRow * pagesPerRow else { return nil }
      let page = SIMD2(self.nextPage % pagesPerRow, self.nextPage / pagesPerRow) &* Self.maxTileSize
      self.nextPage += 1
      let perSide = Self.maxTileSize / tileSize
      // reversed, so tiles are handed out from the page's top left
      for i in (0 ..< perSide * perSide).reversed() {
        self.free[sizeClass].append(page &+ SIMD2(i % perSide, i / perSide) &* tileSize)
      }
    }
    self.tilesInUse += 1
    return SDFSlot(origin: self.free[sizeClass].removeLast(), size: tileSize, sizeClass: sizeClass)
  }

  func free(_ slot: SDFSlot) {
    self.free[slot.sizeClass].append(slot.origin)
    self.tilesInUse -= 1
  }
}

/// Laid out as `VectorBakeParams` in VectorSDF.metal.
private struct VectorBakeParams {
  var origin = SIMD2<UInt32>()
  var size = SIMD2<UInt32>()
  var topLeft = float2()
  var unitsPerTexel: Float = 0
  var mode: UInt32 = 0
  var segmentStart: UInt32 = 0
  var segmentEnd: UInt32 = 0
  var totalLength: Float = 0
  var segmentCount: UInt32 = 0
}

@MainActor final class VectorBaker {
  enum Mode: UInt32 {
    case fillNonZero = 0
    case fillEvenOdd = 1
    /// Distance to the centerline, and the position along the path.
    case stroke = 2
  }

  static let shared = VectorBaker()

  /// Distance kept around what is baked, so anti-aliasing has room outside it.
  static let paddingTexels = 2

  /// Set `VECTOR_STATS=1` in the environment to print, once a second, what vector bakes and the
  /// 2D frame cost.
  static let logsStats = ProcessInfo.processInfo.environment["VECTOR_STATS"] != nil

  let device: MTLDevice
  let atlas: DynamicSDFAtlas
  private let pipelineState: MTLComputePipelineState
  private var pendingParams: [VectorBakeParams] = []
  private var pendingSegments: [VectorSegment] = []
  private var segmentBuffer: MTLBuffer?
  private var reportedAtlasFull = false

  // MARK: Stats

  private var statsStart = CACurrentMediaTime()
  private var statsFrames = 0
  private var statsBakes = 0
  private var statsTexels = 0
  private var statsGPUTime: Double = 0

  private init() {
    self.device = GPUDevice.main
    self.atlas = DynamicSDFAtlas(device: self.device)
    do {
      let library = try self.device.makeDefaultLibrary(bundle: Bundle(for: VectorBaker.self))
      guard let kernel = library.makeFunction(name: "bakeVectorSDF") else {
        fatalError("bakeVectorSDF kernel is missing from the Metal library")
      }
      self.pipelineState = try self.device.makeComputePipelineState(function: kernel)
    } catch {
      fatalError("Could not create the vector bake pipeline: \(error)")
    }
  }

  /// Queues a bake of `segments`, local units y down, into `slot` — reusing it when the region
  /// fits, replacing it otherwise. `boundsMin`...`boundsMax` must hold everything that should
  /// get a distance: the outline, and for a stroke its half width around it. The resolution
  /// drops when the region would not fit the largest tile.
  func bake(
    _ segments: [VectorSegment], mode: Mode, totalLength: Float,
    boundsMin: float2, boundsMax: float2, texelsPerUnit requested: Float,
    slot: inout SDFSlot?
  ) -> BakedRegion? {
    let extent = boundsMax - boundsMin
    guard !segments.isEmpty, extent.x.isFinite, extent.y.isFinite, extent.x >= 0, extent.y >= 0,
          requested.isFinite, requested > 0
    else { return nil }

    let border = 2 * Self.paddingTexels + 1
    let fit = Float(DynamicSDFAtlas.maxTileSize - border) / max(extent.x, extent.y, 1e-6)
    let texelsPerUnit = min(requested, fit)
    let unitsPerTexel = 1 / texelsPerUnit
    let regionSize = SIMD2(
      Int(ceil(extent.x * texelsPerUnit)) + border,
      Int(ceil(extent.y * texelsPerUnit)) + border
    )
    let side = max(regionSize.x, regionSize.y)

    if let current = slot, current.size < side || current.size >= side * 4 {
      // outgrown, or so small now that a tile a quarter the size would do
      self.atlas.free(current)
      slot = nil
    }
    if slot == nil {
      slot = self.atlas.allocate(texels: side)
    }
    guard let tile = slot else {
      if !self.reportedAtlasFull {
        self.reportedAtlasFull = true
        print("Dynamic SDF atlas (\(self.atlas.size)x\(self.atlas.size)) is full, new vector paths are not drawn")
      }
      return nil
    }

    let padding = Float(Self.paddingTexels) * unitsPerTexel
    let topLeft = boundsMin - padding
    var region = BakedRegion()
    region.boundsMin = topLeft
    region.boundsMax = topLeft + float2(Float(regionSize.x - 1), Float(regionSize.y - 1)) * unitsPerTexel
    let atlasSize = Float(self.atlas.size)
    region.uvMin = (float2(Float(tile.origin.x), Float(tile.origin.y)) + 0.5) / atlasSize
    region.uvMax = (float2(Float(tile.origin.x + regionSize.x), Float(tile.origin.y + regionSize.y)) - 0.5) / atlasSize
    region.texelsPerUnit = texelsPerUnit

    let start = UInt32(self.pendingSegments.count)
    self.pendingSegments.append(contentsOf: segments)
    self.pendingParams.append(VectorBakeParams(
      origin: SIMD2(UInt32(tile.origin.x), UInt32(tile.origin.y)),
      size: SIMD2(UInt32(regionSize.x), UInt32(regionSize.y)),
      topLeft: topLeft,
      unitsPerTexel: unitsPerTexel,
      mode: mode.rawValue,
      segmentStart: start,
      segmentEnd: start + UInt32(segments.count),
      totalLength: totalLength
    ))
    if Self.logsStats {
      self.statsTexels += regionSize.x * regionSize.y
    }
    return region
  }

  func free(_ slot: SDFSlot) {
    self.atlas.free(slot)
  }

  /// Encodes the bakes queued this frame, before `compute2D` samples the atlas. The segment
  /// buffer is reused from frame to frame: `Graphics2D` waits for each frame to complete.
  func encodePendingBakes(into commandBuffer: MTLCommandBuffer) {
    guard !self.pendingParams.isEmpty else { return }
    defer {
      if Self.logsStats { self.statsBakes += self.pendingParams.count }
      self.pendingParams.removeAll(keepingCapacity: true)
      self.pendingSegments.removeAll(keepingCapacity: true)
    }

    let byteCount = self.pendingSegments.byteCount
    if (self.segmentBuffer?.length ?? 0) < byteCount {
      self.segmentBuffer = self.device.makeBuffer(length: max(byteCount * 2, 4096), options: .storageModeShared)
      self.segmentBuffer?.label = "Vector segments"
    }
    guard let segmentBuffer = self.segmentBuffer, let encoder = commandBuffer.makeComputeCommandEncoder() else {
      return
    }
    self.pendingSegments.withUnsafeBytes { bytes in
      segmentBuffer.contents().copyMemory(from: bytes.baseAddress!, byteCount: bytes.count)
    }
    encoder.label = "Vector SDF bake"
    encoder.setComputePipelineState(self.pipelineState)
    encoder.setTexture(self.atlas.texture, index: 0)
    encoder.setBuffer(segmentBuffer, offset: 0, index: 1)

    let width = 8
    let height = min(8, self.pipelineState.maxTotalThreadsPerThreadgroup / width)
    let segmentCount = UInt32(self.pendingSegments.count)
    for var params in self.pendingParams {
      params.segmentCount = segmentCount
      encoder.setBytes(&params, length: MemoryLayout<VectorBakeParams>.stride, index: 0)
      encoder.dispatchThreadgroups(
        MTLSize(width: (Int(params.size.x) + width - 1) / width, height: (Int(params.size.y) + height - 1) / height, depth: 1),
        threadsPerThreadgroup: MTLSize(width: width, height: height, depth: 1)
      )
    }
    encoder.endEncoding()
  }

  /// Called by `Graphics2D` once a frame has completed, with its GPU time.
  func frameCompleted(gpuTime: Double) {
    guard Self.logsStats else { return }
    self.statsFrames += 1
    self.statsGPUTime += gpuTime
    let now = CACurrentMediaTime()
    guard now - self.statsStart >= 1 else { return }
    let frames = Double(max(self.statsFrames, 1))
    print(String(
      format: "vector: %d frames, %.2f bakes/frame, %.0f texels/frame, %d tiles, 2D GPU %.3f ms/frame",
      self.statsFrames, Double(self.statsBakes) / frames, Double(self.statsTexels) / frames,
      self.atlas.tilesInUse, self.statsGPUTime / frames * 1000
    ))
    self.statsStart = now
    self.statsFrames = 0
    self.statsBakes = 0
    self.statsTexels = 0
    self.statsGPUTime = 0
  }
}
