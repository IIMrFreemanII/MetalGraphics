import MetalKit

private struct ShapeArgBuffer {
  var circles: UInt64 = 0
  var circlesCount: Int32 = 0

  var squares: UInt64 = 0
  var squaresCount: Int32 = 0

  var lines: UInt64 = 0
  var linesCount: Int32 = 0

  var glyphs: UInt64 = 0
  var glyphsCount: Int32 = 0

  var images: UInt64 = 0
  var imagesCount: Int32 = 0
  /// `MTLResourceID`s of the textures `images` index.
  var textures: UInt64 = 0

  var vectors: UInt64 = 0
  var vectorsCount: Int32 = 0

  /// The `GPUClip`s `Shape.clip` indexes.
  var clips: UInt64 = 0
  var clipsCount: Int32 = 0

  var glasses: UInt64 = 0
  var glassesCount: Int32 = 0
}

/// One frosted glass panel, laid out as `Glass` in Shaders.metal: a rounded rect filled with
/// the blurred scene behind it, which this frame's passes leave in `regionMin`...`regionMax` of
/// the glass atlas. Rects are min x, min y, max x, max y in centered points, y down.
struct GlassItem {
  var rect = float4()
  var radii = float4()
  /// Composited over the blurred backdrop, straight alpha.
  var tint = float4()
  /// Where atlas texel `regionMin` samples the scene, in centered points.
  var sceneOrigin = float2()
  /// In texels; an empty region is a glass without a backdrop.
  var regionMin = float2()
  var regionMax = float2()
  var pointsPerTexel: Float = 1
  var saturation: Float = 1
  var noise: Float = 0
  var opacity: Float = 1
  var depth: Float = 0
  private var padding: Float = 0

  init(
    rect: float4, radii: float4, tint: float4, sceneOrigin: float2, regionMin: float2, regionMax: float2,
    pointsPerTexel: Float, saturation: Float, noise: Float, opacity: Float, depth: Float
  ) {
    self.rect = rect
    self.radii = radii
    self.tint = tint
    self.sceneOrigin = sceneOrigin
    self.regionMin = regionMin
    self.regionMax = regionMax
    self.pointsPerTexel = pointsPerTexel
    self.saturation = saturation
    self.noise = noise
    self.opacity = opacity
    self.depth = depth
  }

  /// Where the glass covers anything, with a pixel for anti-aliasing.
  func bounds(pixelsPerPoint: Float) -> BoundingBox2D {
    let aa = 1 / pixelsPerPoint
    return BoundingBox2D(
      center: float2(self.rect.x + self.rect.z, self.rect.y + self.rect.w) * 0.5,
      size: float2(self.rect.z - self.rect.x, self.rect.w - self.rect.y) + 2 * aa
    )
  }
}

/// One glass's backdrop pass, or one direction of its blur, laid out as `GlassPass` in
/// Shaders.metal. Regions are in texels.
private struct GlassPass {
  /// Where the region starts in the glass atlas.
  var atlasOrigin = SIMD2<Int32>()
  var size = SIMD2<Int32>()
  /// Where texel (0, 0) samples the scene, in centered points.
  var sceneOrigin = float2()
  var pointsPerTexel: Float = 1
  /// Only what is drawn below the glass is its backdrop.
  var maxDepth: Float = 0
  /// The blur's standard deviation, in texels.
  var sigma: Float = 0
  private var padding: Int32 = 0
  /// (1, 0) for the horizontal blur, (0, 1) for the vertical one.
  var direction = float2()

  init(atlasOrigin: SIMD2<Int32>, size: SIMD2<Int32>, sceneOrigin: float2, pointsPerTexel: Float, maxDepth: Float, sigma: Float) {
    self.atlasOrigin = atlasOrigin
    self.size = size
    self.sceneOrigin = sceneOrigin
    self.pointsPerTexel = pointsPerTexel
    self.maxDepth = maxDepth
    self.sigma = sigma
  }
}

/// One entry of the clip table, laid out as `Clip` in Shaders.metal. Rects are min x, min y,
/// max x, max y in centered points, y down.
struct GPUClip: Equatable {
  /// Everything drawn under this clip is inside it: its own rect cut to every clip above.
  /// Shapes outside are rejected, and not filed in the grid at all.
  var bounds: float4
  /// This clip's own rounded rect, tested only when some radius is not zero.
  var rect: float4
  /// Corner radii, in `sdRoundedBox`'s order: see `UIShape.radii`.
  var radii: float4
  /// The next entry up whose rounded rect applies as well, 0 when none does.
  var rounded: Int32 = 0
  /// A shadow's soft clip: `rect` rounded by `radii`, blurred by this standard deviation in
  /// points, caps the coverage of what is drawn under it. 0 for a hard clip.
  var blur: Float = 0
  private var padding1: Int32 = 0
  private var padding2: Int32 = 0

  init(bounds: float4, rect: float4, radii: float4, rounded: Int32, blur: Float = 0) {
    self.bounds = bounds
    self.rect = rect
    self.radii = radii
    self.rounded = rounded
    self.blur = blur
  }
}

public struct DebugData {
  public var drawGrid: Bool = false
  public var showFilledCells: Bool = false
}

public struct SceneData {
  public var windowSize = SIMD2<Int32>()
  public var time = Float()
  public var debug = DebugData()
}

@MainActor public class Graphics2D {
  private var renderer: ViewRenderer
  private var depth = Float()
  lazy var grid: GraphicsGrid2D = .init(position: float2(), size: int2(10, 10), cellSize: Float(50), graphics: self)
  var resizeCb: (() -> Void)?
  
  public var size: float2 {
    self.renderer.windowSize
  }

  public init(renderer: ViewRenderer) {
    self.renderer = renderer
    self.device = GPUDevice.main
    self.commandQueue = self.device.makeCommandQueue()

    do {
      self.library = try self.device.makeDefaultLibrary(bundle: Bundle(for: Graphics2D.self))
      //      if let path = Bundle(for: Graphics.self).path(forResource: "default", ofType: "metallib") {
      //        library = try device.makeLibrary(URL: URL(fileURLWithPath: path))
      //      } else {
      //        fatalError("Could not find metallib file in bundle")
      //      }
    } catch {
      fatalError("Could not create Metal library: \(error)")
    }

    self.shapeArgBuffer = self.device.makeBuffer(length: MemoryLayout<ShapeArgBuffer>.stride * 1)
    self.circleBuffer = self.device.makeBuffer(length: MemoryLayout<Circle2D>.stride * 1)
    self.squareBuffer = self.device.makeBuffer(length: MemoryLayout<Square>.stride * 1)
    self.lineBuffer = self.device.makeBuffer(length: MemoryLayout<Line>.stride * 1)
    self.glyphBuffer = self.device.makeBuffer(length: MemoryLayout<Glyph>.stride * 1)
    self.imageBuffer = self.device.makeBuffer(length: MemoryLayout<ImageQuad>.stride * 1)
    self.textureTableBuffer = self.device.makeBuffer(length: MemoryLayout<MTLResourceID>.stride * 1)
    self.vectorBuffer = self.device.makeBuffer(length: MemoryLayout<VectorItem>.stride * 1)
    self.clipBuffer = self.device.makeBuffer(length: MemoryLayout<GPUClip>.stride * 1)
    self.glassBuffer = self.device.makeBuffer(length: MemoryLayout<GlassItem>.stride * 1)
    self.glassAtlas = Self.makeGlassTexture(self.device, width: 1, height: 1, label: "Glass atlas")
    self.glassScratchA = Self.makeGlassTexture(self.device, width: 1, height: 1, label: "Glass scratch A")
    self.glassScratchB = Self.makeGlassTexture(self.device, width: 1, height: 1, label: "Glass scratch B")

    do {
      try self.makePipelines(self.library)
    } catch {
      fatalError(String(describing: error))
    }
  }

  private struct PipelineError: Error, CustomStringConvertible {
    let description: String
  }

  /// Builds every pipeline from `library` and swaps them in only once all of them compiled, so a
  /// failed hot reload leaves the previous set untouched.
  private func makePipelines(_ library: MTLLibrary) throws {
    // The main pass comes with and without the glass branch, which costs every pixel
    // occupancy even when no glass is drawn; only a backdrop pass cuts shapes off at a depth.
    func specialised(_ name: String, hasGlass: Bool, cutsAtDepth: Bool) throws -> MTLComputePipelineState {
      let constants = MTLFunctionConstantValues()
      var hasGlass = hasGlass
      var cutsAtDepth = cutsAtDepth
      constants.setConstantValue(&hasGlass, type: .bool, index: 0)
      constants.setConstantValue(&cutsAtDepth, type: .bool, index: 1)
      let function = try library.makeFunction(name: name, constantValues: constants)
      return try self.device.makeComputePipelineState(function: function)
    }
    let pipelineState = try specialised("compute2D", hasGlass: false, cutsAtDepth: false)
    let glassPipeline = try specialised("compute2D", hasGlass: true, cutsAtDepth: false)
    let backdropPipeline = try specialised("backdrop2D", hasGlass: true, cutsAtDepth: true)
    guard let blur = library.makeFunction(name: "glassBlur") else {
      throw PipelineError(description: "No `glassBlur` function in the Metal library")
    }
    let glassBlurPipeline = try self.device.makeComputePipelineState(function: blur)

    self.pipelineState = pipelineState
    self.glassPipeline = glassPipeline
    self.backdropPipeline = backdropPipeline
    self.glassBlurPipeline = glassBlurPipeline
  }

#if DEBUG
  /// Hot reload: rebuilds the pipelines from a freshly compiled `.metallib` (see `ShaderReloader`).
  /// Runs on the main thread between frames; command buffers still in flight keep the old
  /// pipelines alive.
  func reloadShaders(from url: URL) throws {
    let library = try self.device.makeLibrary(URL: url)
    try self.makePipelines(library)
    self.library = library
  }
#endif

  /// A texture glass backdrops are rendered, blurred and kept in: half floats, so a soft
  /// gradient through the blur does not band.
  private static func makeGlassTexture(_ device: MTLDevice, width: Int, height: Int, label: String) -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba16Float, width: max(width, 1), height: max(height, 1), mipmapped: false
    )
    descriptor.usage = [.shaderRead, .shaderWrite]
    descriptor.storageMode = .private
    guard let texture = device.makeTexture(descriptor: descriptor) else {
      fatalError("Could not create \(label)")
    }
    texture.label = label
    return texture
  }

  public var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  var library: MTLLibrary!
  var pipelineState: MTLComputePipelineState!
  /// `pipelineState` with the glass branch, for a frame that draws glass.
  private var glassPipeline: MTLComputePipelineState!
  private var backdropPipeline: MTLComputePipelineState!
  private var glassBlurPipeline: MTLComputePipelineState!

  private var shapeArgBuffer: MTLBuffer!

  private var circles: [Circle2D] = []
  private var circleBuffer: MTLBuffer!
  private var circleBufferCount: Int = 0

  private var squares: [Square] = []
  private var squareBuffer: MTLBuffer!
  private var squareBufferCount: Int = 0

  private var lines: [Line] = []
  private var lineBuffer: MTLBuffer!
  private var lineBufferCount: Int = 0

  private var glyphs: [Glyph] = []
  private var glyphBuffer: MTLBuffer!
  private var glyphBufferCount: Int = 0

  private var images: [ImageQuad] = []
  private var imageBuffer: MTLBuffer!
  private var imageBufferCount: Int = 0
  /// The textures this frame's images sample, each once, in the order `textureIndex` counts.
  private var imageTextures: [MTLTexture] = []
  private var imageTextureIndices: [ObjectIdentifier: Int32] = [:]
  private var textureTableBuffer: MTLBuffer!
  private var textureTableCount: Int = 0

  private var vectors: [VectorItem] = []
  private var vectorBuffer: MTLBuffer!
  private var vectorBufferCount: Int = 0

  /// This frame's clips. Entry 0 clips nothing.
  private var clips: [GPUClip] = [Graphics2D.noClip]
  private var clipBuffer: MTLBuffer!
  private var clipBufferCount: Int = 0
  /// Which clip applies from which depth on, in depth order. Draws take increasing depths, so
  /// a shape's clip is the last run that starts at or before its depth — recorded once per
  /// change instead of once per shape.
  private var clipRuns: [(depth: Float, clip: Int32)] = [(0, 0)]
  private static let noClip: GPUClip = {
    let everything = float4(-.greatestFiniteMagnitude, -.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude)
    return GPUClip(bounds: everything, rect: everything, radii: .zero, rounded: 0)
  }()

  /// The shadows every draw casts until they are reset, outermost first. Each is drawn just
  /// beneath the shape that casts it. See `ShadowElement`.
  private var shadows: [ShadowState] = []

  /// The blur every draw gets until it is set again, as a standard deviation in points; 0 for
  /// none. Each shape is blurred on its own, analytically, from its distance field, like a
  /// shadow: no pass is added. See `BlurElement`.
  private var blur: Float = 0

  /// This frame's frosted glass panels, in depth order, and the backdrop pass each needs; a
  /// glass without a backdrop has no pass.
  private var glasses: [GlassItem] = []
  private var glassBuffer: MTLBuffer!
  private var glassBufferCount: Int = 0
  private var glassPasses: [GlassPass] = []
  /// Every glass's blurred backdrop, each in a region of its own, so a glass above another
  /// samples the lower one's while its own is rendered. Regions are packed in rows, which
  /// start over every frame; the atlas grows, never shrinks.
  private var glassAtlas: MTLTexture!
  private var glassAtlasCursor = SIMD2<Int>(0, 0)
  private var glassAtlasRowHeight = 0
  /// Where a backdrop is rendered, then blurred along x, before its blur along y lands in the
  /// atlas; as large as the largest region so far.
  private var glassScratchA: MTLTexture!
  private var glassScratchB: MTLTexture!
  /// Texels either side of a glass's own rect the backdrop is rendered over, in standard
  /// deviations of its blur: where the Gaussian has all but vanished.
  private static let glassReach: Float = 3
  /// The coarsest backdrop resolution, as drawable pixels per texel.
  private static let maxGlassDownsample = 8
  /// Largest texture edge Metal allows on every Mac.
  private static let maxTextureSize = 16384

  public var sceneData = SceneData()
  /// Drawable pixels per point, the ratio `compute2D` maps pixels to points with.
  private(set) var pixelsPerPoint: Float = 1
  // Reported once, so a persistent GPU error doesn't flood the console every frame.
  private var reportedFrameError = false

  func beginFrame() {
    self.depth = 0
    self.circles.removeAll(keepingCapacity: true)
    self.squares.removeAll(keepingCapacity: true)
    self.lines.removeAll(keepingCapacity: true)
    self.glyphs.removeAll(keepingCapacity: true)
    self.images.removeAll(keepingCapacity: true)
    self.imageTextures.removeAll(keepingCapacity: true)
    self.imageTextureIndices.removeAll(keepingCapacity: true)
    self.vectors.removeAll(keepingCapacity: true)
    self.clips.removeAll(keepingCapacity: true)
    self.clips.append(Self.noClip)
    self.clipRuns.removeAll(keepingCapacity: true)
    self.clipRuns.append((0, 0))
    self.shadows.removeAll(keepingCapacity: true)
    self.blur = 0
    self.glasses.removeAll(keepingCapacity: true)
    self.glassPasses.removeAll(keepingCapacity: true)
    self.glassAtlasCursor = .zero
    self.glassAtlasRowHeight = 0
  }

  /// Blurs every draw from now on by a Gaussian of standard deviation `sigma`, in points, or
  /// none for 0. Circles and lines, which have no anti-aliased edge to widen, stay sharp.
  func setBlur(_ sigma: Float) {
    // Under a quarter pixel a blur is invisible next to the anti-aliasing band, and would only
    // trade that band for a harder edge; draw sharp instead.
    self.blur = sigma * self.pixelsPerPoint < 0.25 ? 0 : sigma
  }

  /// Every draw from now on casts `shadow` too, beneath itself and any shadow added before.
  func addShadow(_ shadow: ShadowState) {
    self.shadows.append(shadow)
  }

  /// Draws from now on cast no shadow.
  func resetShadows() {
    self.shadows.removeAll(keepingCapacity: true)
  }

  /// Switches to `shadow`'s clip for its copies, and returns the clip to switch back to.
  private func beginShadow(_ shadow: ShadowState) -> Int32 {
    let current = self.clipRuns[self.clipRuns.count - 1].clip
    if shadow.clip >= 0 {
      self.pushClipRun(shadow.clip)
    }
    return current
  }

  private func endShadow(_ shadow: ShadowState, _ clip: Int32) {
    if shadow.clip >= 0 {
      self.pushClipRun(clip)
    }
  }

  /// Draws a shadow of `item` for each shadow set, each above the last, all below what is drawn
  /// next. `alpha` is the opacity of what casts it.
  private func drawShadows(of item: VectorItem, alpha: Float) {
    for shadow in self.shadows {
      var copy = item
      // local = M (p - offset) + t
      copy.row0.z -= simd_dot(float2(item.row0.x, item.row0.y), shadow.offset)
      copy.row1.z -= simd_dot(float2(item.row1.x, item.row1.y), shadow.offset)
      // `item.clip` already reaches as far as the shape's own blur does.
      let sigma = Self.combined(shadow.sigma, item.blur)
      let margin = sigma * ShadowState.reach
      copy.clip = item.clip
        + float4(shadow.offset.x, shadow.offset.y, shadow.offset.x, shadow.offset.y)
        + float4(-margin, -margin, margin, margin)
      copy.color = shadow.color
      copy.color.w *= alpha
      guard copy.color.w > 0 else { continue }
      copy.blur = sigma
      let clip = self.beginShadow(shadow)
      self.append(vector: copy)
      self.endShadow(shadow, clip)
    }
  }

  /// The blur of two Gaussian blurs in a row: their variances add.
  private static func combined(_ a: Float, _ b: Float) -> Float {
    b <= 0 ? a : (a * a + b * b).squareRoot()
  }

  /// A rounded box centred at `center`, window centered, y down, in points, filled in `color`;
  /// what a shadow of a rect is drawn from.
  private func roundedBox(center: float2, half: float2, radii: float4, rotation: Float = 0, color: float4) -> VectorItem {
    let c = cos(rotation)
    let s = sin(rotation)
    // the rotation `compute2D` gives a square, about its center
    let row0 = float2(c, -s)
    let row1 = float2(s, c)
    let extent = float2(abs(c) * half.x + abs(s) * half.y, abs(s) * half.x + abs(c) * half.y) + 1 / self.pixelsPerPoint
    var item = VectorItem()
    item.row0 = float4(row0.x, row0.y, -simd_dot(row0, center), 1)
    item.row1 = float4(row1.x, row1.y, -simd_dot(row1, center), 0)
    item.params0 = float4(0, 0, half.x, half.y)
    item.params1 = simd_clamp(radii, .zero, float4(repeating: min(half.x, half.y)))
    item.color = color
    item.clip = float4(center.x - extent.x, center.y - extent.y, center.x + extent.x, center.y + extent.y)
    item.kind = VectorItem.Kind.roundedBox.rawValue
    item.flags = VectorItem.closedFlag
    return item
  }

  /// Keeps everything drawn from now on inside `min`...`max`, window top left origin, y down,
  /// in points, until the clip is set again or reset.
  public func setClip(min: float2, max: float2) {
    let rect = self.centered(ClipRect(min: min, max: max))
    let current = self.clipRuns[self.clipRuns.count - 1].clip
    guard self.clips[Int(current)].bounds != rect || self.clips[Int(current)].radii != .zero else { return }
    self.pushClipRun(self.addClip(bounds: ClipRect(min: min, max: max), rect: ClipRect(min: min, max: max), radii: .zero, rounded: 0))
  }

  /// Adds a clip to this frame's table and returns its index for `setClip(_:)`. Rects are window
  /// top left origin, y down, in points. What is drawn under it stays inside `bounds`, and inside
  /// `rect` rounded by `radii` — anti-aliased — and inside the rounded rect of entry `rounded`
  /// and the ones it chains to. With `blur`, `rect` is a shadow's soft clip instead: see
  /// `GPUClip.blur`.
  func addClip(bounds: ClipRect, rect: ClipRect, radii: float4, rounded: Int32, blur: Float = 0) -> Int32 {
    let index = Int32(self.clips.count)
    self.clips.append(GPUClip(
      bounds: self.centered(bounds), rect: self.centered(rect), radii: simd_max(radii, .zero), rounded: rounded,
      blur: max(blur, 0)
    ))
    return index
  }

  /// Keeps everything drawn from now on inside the clip `addClip` returned `index` for.
  func setClip(_ index: Int32) {
    self.pushClipRun(index)
  }

  private func centered(_ rect: ClipRect) -> float4 {
    let half = self.size * 0.5
    return float4(rect.min.x - half.x, rect.min.y - half.y, rect.max.x - half.x, rect.max.y - half.y)
  }

  /// Draws from now on unclipped.
  public func resetClip() {
    self.pushClipRun(0)
  }

  private func pushClipRun(_ clip: Int32) {
    let last = self.clipRuns.count - 1
    if self.clipRuns[last].clip == clip { return }
    if self.clipRuns[last].depth == self.depth {
      // Nothing was drawn under the previous clip.
      self.clipRuns[last].clip = clip
    } else {
      self.clipRuns.append((self.depth, clip))
    }
  }

  /// Files a shape under the grid cells its bounds cover, cut to its clip. A shape clipped away
  /// entirely is not filed at all, which is what keeps long scrolled content cheap to draw.
  private func mapToGrid(
    _ bounds: BoundingBox2D, index: Int, type: ShapeType2D, depth: Float, run: inout Int
  ) {
    while run + 1 < self.clipRuns.count, self.clipRuns[run + 1].depth <= depth {
      run += 1
    }
    let clipIndex = self.clipRuns[run].clip
    let shape = Shape(index: Int32(index), shapeType: type.rawValue, clip: clipIndex, depth: depth)
    guard clipIndex != 0 else {
      self.grid.mapShapeBoundingBoxToGrid(bounds, shape)
      return
    }
    // Bounds are symmetric about their center, so which way y points does not matter here.
    let clip = self.clips[Int(clipIndex)].bounds
    let half = abs(bounds.size) * 0.5
    let lo = simd_max(bounds.center - half, float2(clip.x, clip.y))
    let hi = simd_min(bounds.center + half, float2(clip.z, clip.w))
    guard lo.x < hi.x, lo.y < hi.y else { return }
    self.grid.mapShapeBoundingBoxToGrid(BoundingBox2D(center: (lo + hi) * 0.5, size: hi - lo), shape)
  }

  func endFrame() {
    if let cb = self.resizeCb {
      cb()
      self.resizeCb = nil
    } else {
      self.grid.reset()
    }
    
    var run = 0
    for (i, item) in self.circles.enumerated() {
      self.mapToGrid(item.bounds, index: i, type: .Circle, depth: item.depth, run: &run)
    }
    run = 0
    for (i, item) in self.squares.enumerated() {
      self.mapToGrid(item.bounds, index: i, type: .Square, depth: item.depth, run: &run)
    }
    run = 0
    for (i, item) in self.lines.enumerated() {
      self.mapToGrid(item.bounds, index: i, type: .Line, depth: item.depth, run: &run)
    }
    run = 0
    for (i, item) in self.glyphs.enumerated() {
      self.mapToGrid(item.bounds, index: i, type: .Glyph, depth: item.depth, run: &run)
    }
    run = 0
    for (i, item) in self.images.enumerated() {
      self.mapToGrid(item.bounds, index: i, type: .Image, depth: item.depth, run: &run)
    }
    run = 0
    for (i, item) in self.vectors.enumerated() {
      self.mapToGrid(item.bounds, index: i, type: .Vector, depth: item.depth, run: &run)
    }
    run = 0
    for (i, item) in self.glasses.enumerated() {
      self.mapToGrid(item.bounds(pixelsPerPoint: self.pixelsPerPoint), index: i, type: .Glass, depth: item.depth, run: &run)
    }

    self.grid.updateBuffers()

    do {
      if self.circleBufferCount < self.circles.count {
        self.circleBufferCount += self.circles.count + 10
        self.circleBuffer = self.device.makeBuffer(length: MemoryLayout<Circle2D>.stride * self.circleBufferCount)
        self.circleBuffer.label = "Circle buffer"
      }

      self.circleBuffer.contents().copyMemory(from: &self.circles, byteCount: self.circles.byteCount)
    }

    do {
      if self.squareBufferCount < self.squares.count {
        self.squareBufferCount += self.squares.count + 10
        self.squareBuffer = self.device.makeBuffer(length: MemoryLayout<Square>.stride * self.squareBufferCount)
        self.squareBuffer.label = "Square buffer"
      }

      self.squareBuffer.contents().copyMemory(from: &self.squares, byteCount: self.squares.byteCount)
    }

    do {
      if self.lineBufferCount < self.lines.count {
        self.lineBufferCount += self.lines.count + 10
        self.lineBuffer = self.device.makeBuffer(length: MemoryLayout<Line>.stride * self.lineBufferCount)
        self.lineBuffer.label = "Line buffer"
      }

      self.lineBuffer.contents().copyMemory(from: &self.lines, byteCount: self.lines.byteCount)
    }

    do {
      if self.glyphBufferCount < self.glyphs.count {
        self.glyphBufferCount += self.glyphs.count + 10
        self.glyphBuffer = self.device.makeBuffer(length: MemoryLayout<Glyph>.stride * self.glyphBufferCount)
        self.glyphBuffer.label = "Glyph buffer"
      }

      self.glyphBuffer.contents().copyMemory(from: &self.glyphs, byteCount: self.glyphs.byteCount)
    }

    do {
      if self.imageBufferCount < self.images.count {
        self.imageBufferCount += self.images.count + 10
        self.imageBuffer = self.device.makeBuffer(length: MemoryLayout<ImageQuad>.stride * self.imageBufferCount)
        self.imageBuffer.label = "Image buffer"
      }

      self.imageBuffer.contents().copyMemory(from: &self.images, byteCount: self.images.byteCount)
    }

    do {
      if self.vectorBufferCount < self.vectors.count {
        self.vectorBufferCount += self.vectors.count + 10
        self.vectorBuffer = self.device.makeBuffer(length: MemoryLayout<VectorItem>.stride * self.vectorBufferCount)
        self.vectorBuffer.label = "Vector buffer"
      }

      self.vectorBuffer.contents().copyMemory(from: &self.vectors, byteCount: self.vectors.byteCount)
    }

    do {
      if self.clipBufferCount < self.clips.count {
        self.clipBufferCount += self.clips.count + 10
        self.clipBuffer = self.device.makeBuffer(length: MemoryLayout<GPUClip>.stride * self.clipBufferCount)
        self.clipBuffer.label = "Clip buffer"
      }

      self.clipBuffer.contents().copyMemory(from: &self.clips, byteCount: self.clips.byteCount)
    }

    do {
      if self.glassBufferCount < self.glasses.count {
        self.glassBufferCount += self.glasses.count + 10
        self.glassBuffer = self.device.makeBuffer(length: MemoryLayout<GlassItem>.stride * self.glassBufferCount)
        self.glassBuffer.label = "Glass buffer"
      }

      self.glassBuffer.contents().copyMemory(from: &self.glasses, byteCount: self.glasses.byteCount)
      self.growGlassTextures()
    }

    do {
      if self.textureTableCount < self.imageTextures.count {
        self.textureTableCount += self.imageTextures.count + 10
        self.textureTableBuffer = self.device.makeBuffer(length: MemoryLayout<MTLResourceID>.stride * self.textureTableCount)
        self.textureTableBuffer.label = "Texture table"
      }

      let table = self.textureTableBuffer.contents().bindMemory(to: MTLResourceID.self, capacity: self.imageTextures.count)
      for (i, texture) in self.imageTextures.enumerated() {
        table[i] = texture.gpuResourceID
      }
    }

    let shapeArgPointer = self.shapeArgBuffer.contents().bindMemory(to: ShapeArgBuffer.self, capacity: 1)
    shapeArgPointer.pointee.circles = self.circleBuffer.gpuAddress
    shapeArgPointer.pointee.circlesCount = Int32(self.circles.count)
    shapeArgPointer.pointee.squares = self.squareBuffer.gpuAddress
    shapeArgPointer.pointee.squaresCount = Int32(self.squares.count)
    shapeArgPointer.pointee.lines = self.lineBuffer.gpuAddress
    shapeArgPointer.pointee.linesCount = Int32(self.lines.count)
    shapeArgPointer.pointee.glyphs = self.glyphBuffer.gpuAddress
    shapeArgPointer.pointee.glyphsCount = Int32(self.glyphs.count)
    shapeArgPointer.pointee.images = self.imageBuffer.gpuAddress
    shapeArgPointer.pointee.imagesCount = Int32(self.images.count)
    shapeArgPointer.pointee.textures = self.textureTableBuffer.gpuAddress
    shapeArgPointer.pointee.vectors = self.vectorBuffer.gpuAddress
    shapeArgPointer.pointee.vectorsCount = Int32(self.vectors.count)
    shapeArgPointer.pointee.clips = self.clipBuffer.gpuAddress
    shapeArgPointer.pointee.clipsCount = Int32(self.clips.count)
    shapeArgPointer.pointee.glasses = self.glassBuffer.gpuAddress
    shapeArgPointer.pointee.glassesCount = Int32(self.glasses.count)

    self.renderer.input.endFrame()
  }

  func drawData(at view: MTKView) {
    guard
      let commandBuffer = self.commandQueue.makeCommandBuffer(),
      let drawable = view.currentDrawable
    else {
      return
    }
    guard self.encodeFrame(into: drawable.texture, commandBuffer) else { return }
    commandBuffer.present(drawable)
    self.finishFrame(commandBuffer)
  }

  /// Encodes this frame's bakes and `compute2D` into `texture`, which needs `.shaderWrite`
  /// usage. False when no encoder could be made; the bakes are committed on their own then.
  func encodeFrame(into texture: MTLTexture, _ commandBuffer: MTLCommandBuffer) -> Bool {
    // Glyphs and icons first laid out this frame are baked, and images first drawn uploaded,
    // before `compute2D` samples them.
    SDFBaker.shared.encodePendingBakes(into: commandBuffer)
    VectorBaker.shared.encodePendingBakes(into: commandBuffer)
    ImageManager.shared.encodePendingUploads(into: commandBuffer)
    guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
      // the bakes are already dequeued, so they still have to run
      commandBuffer.commit()
      return false
    }

    commandEncoder.useResources([self.grid.cellBuffer, self.grid.shapeBuffer, self.circleBuffer, self.squareBuffer, self.lineBuffer, self.glyphBuffer, self.imageBuffer, self.textureTableBuffer, self.vectorBuffer, self.clipBuffer, self.glassBuffer], usage: .read)
    if !self.imageTextures.isEmpty {
      commandEncoder.useResources(self.imageTextures, usage: .read)
    }

    commandEncoder.setTexture(SDFBaker.shared.atlas.texture, index: 1)
    commandEncoder.setTexture(VectorBaker.shared.atlas.texture, index: 2)
    commandEncoder.setTexture(self.glassAtlas, index: 3)

    self.sceneData.windowSize = SIMD2<Int32>(Int32(self.renderer.windowSize.x), Int32(self.renderer.windowSize.y))
    self.sceneData.time = self.renderer.time

    commandEncoder.setBytes(&self.sceneData, length: MemoryLayout<SceneData>.stride, index: 0)
    commandEncoder.setBuffer(self.shapeArgBuffer, offset: 0, index: 1)
    commandEncoder.setBuffer(self.grid.gridArgBuffer, offset: 0, index: 2)

    // Lowest glass first, so each one above finds the backdrops below it finished. The encoder
    // dispatches serially, so every pass sees the textures the one before it wrote.
    for pass in self.glassPasses {
      self.encodeGlass(pass, commandEncoder)
    }

    let pipeline: MTLComputePipelineState = self.glasses.isEmpty ? self.pipelineState : self.glassPipeline
    commandEncoder.setComputePipelineState(pipeline)
    commandEncoder.setTexture(texture, index: 0)
    commandEncoder.setTexture(self.glassAtlas, index: 3)
    self.dispatch(pipeline, width: texture.width, height: texture.height, commandEncoder)

    commandEncoder.endEncoding()
    return true
  }

  /// Commits a frame `encodeFrame` filled and waits for the GPU to finish it.
  func finishFrame(_ commandBuffer: MTLCommandBuffer) {
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    VectorBaker.shared.frameCompleted(gpuTime: commandBuffer.gpuEndTime - commandBuffer.gpuStartTime)

    if commandBuffer.status == .error, !self.reportedFrameError {
      self.reportedFrameError = true
      print("2D frame failed on the GPU: \(commandBuffer.error.map(String.init(describing:)) ?? "unknown error")")
    }
  }

  /// Runs `pipeline` once per texel of a `width` by `height` region.
  private func dispatch(_ pipeline: MTLComputePipelineState, width: Int, height: Int, _ encoder: MTLComputeCommandEncoder) {
    let groupWidth = pipeline.threadExecutionWidth
    let groupHeight = pipeline.maxTotalThreadsPerThreadgroup / groupWidth
    encoder.dispatchThreadgroups(
      MTLSize(width: (width + groupWidth - 1) / groupWidth, height: (height + groupHeight - 1) / groupHeight, depth: 1),
      threadsPerThreadgroup: MTLSize(width: groupWidth, height: groupHeight, depth: 1)
    )
  }

  /// One glass's backdrop: the scene below it rendered over its region into scratch A, blurred
  /// along x into scratch B, then along y into its region of the atlas. The atlas is only read
  /// while the backdrop renders, and only written by the last blur.
  private func encodeGlass(_ pass: GlassPass, _ encoder: MTLComputeCommandEncoder) {
    var pass = pass
    let width = Int(pass.size.x)
    let height = Int(pass.size.y)

    encoder.setComputePipelineState(self.backdropPipeline)
    encoder.setTexture(self.glassScratchA, index: 0)
    encoder.setTexture(self.glassAtlas, index: 3)
    encoder.setBytes(&pass, length: MemoryLayout<GlassPass>.stride, index: 3)
    self.dispatch(self.backdropPipeline, width: width, height: height, encoder)

    encoder.setComputePipelineState(self.glassBlurPipeline)
    var origin = SIMD2<Int32>.zero
    pass.direction = float2(1, 0)
    encoder.setTexture(self.glassScratchA, index: 0)
    encoder.setTexture(self.glassScratchB, index: 1)
    encoder.setBytes(&pass, length: MemoryLayout<GlassPass>.stride, index: 0)
    encoder.setBytes(&origin, length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
    self.dispatch(self.glassBlurPipeline, width: width, height: height, encoder)

    origin = pass.atlasOrigin
    pass.direction = float2(0, 1)
    encoder.setTexture(self.glassScratchB, index: 0)
    encoder.setTexture(self.glassAtlas, index: 1)
    encoder.setBytes(&pass, length: MemoryLayout<GlassPass>.stride, index: 0)
    encoder.setBytes(&origin, length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
    self.dispatch(self.glassBlurPipeline, width: width, height: height, encoder)

    // `backdrop2D` and `compute2D` read the atlas at index 3; the blur wrote it at index 1.
    encoder.setTexture(SDFBaker.shared.atlas.texture, index: 1)
    encoder.setBuffer(self.shapeArgBuffer, offset: 0, index: 1)
    encoder.setBuffer(self.grid.gridArgBuffer, offset: 0, index: 2)
    encoder.setBytes(&self.sceneData, length: MemoryLayout<SceneData>.stride, index: 0)
  }

  /// Makes the atlas tall enough for this frame's regions and the scratch textures as large as
  /// its largest, growing with slack so a panel that grows a little does not reallocate each
  /// frame. Regions ask for at most the drawable's width.
  private func growGlassTextures() {
    guard !self.glassPasses.isEmpty else { return }
    let atlasWidth = self.glassAtlasWidth
    let atlasHeight = self.glassAtlasCursor.y + self.glassAtlasRowHeight
    if self.glassAtlas.width != atlasWidth || self.glassAtlas.height < atlasHeight {
      let height = min(max(atlasHeight + atlasHeight / 4, self.glassAtlas.width == atlasWidth ? self.glassAtlas.height : 0), Self.maxTextureSize)
      self.glassAtlas = Self.makeGlassTexture(self.device, width: atlasWidth, height: height, label: "Glass atlas")
    }
    var largest = SIMD2<Int>(1, 1)
    for pass in self.glassPasses {
      largest = simd_max(largest, SIMD2<Int>(Int(pass.size.x), Int(pass.size.y)))
    }
    if self.glassScratchA.width < largest.x || self.glassScratchA.height < largest.y {
      let width = min(max(largest.x + largest.x / 4, self.glassScratchA.width), Self.maxTextureSize)
      let height = min(max(largest.y + largest.y / 4, self.glassScratchA.height), Self.maxTextureSize)
      self.glassScratchA = Self.makeGlassTexture(self.device, width: width, height: height, label: "Glass scratch A")
      self.glassScratchB = Self.makeGlassTexture(self.device, width: width, height: height, label: "Glass scratch B")
    }
  }

  /// As wide as the drawable, plus a texel for a region's rounding.
  private var glassAtlasWidth: Int {
    min(Int((self.size.x * self.pixelsPerPoint).rounded(.up)) + 2, Self.maxTextureSize)
  }

  /// Draws a frosted glass panel over the rect with its top left corner at `position`, window
  /// centered, y down, in points, rounded by `radii`: the scene drawn so far below it, blurred
  /// by a Gaussian of standard deviation `sigma` in points, made `saturation` times as vivid,
  /// under `tint`, with `noise` of grain. `opacity` fades the whole panel.
  ///
  /// The backdrop is rendered and blurred in passes of its own before the frame, over the
  /// panel's visible rect and as far past it as the blur reaches, at a resolution the blur can
  /// spare: about one texel per third of a standard deviation, so the blur's cost does not grow
  /// with its radius. The panel's own edge is never blurred, even under a `BlurElement`.
  func draw(
    glass position: float2, size: float2, radii: float4, sigma: Float, tint: float4,
    saturation: Float, noise: Float, opacity: Float
  ) {
    guard size.x > 0, size.y > 0, opacity > 0 else { return }
    let half = size * 0.5
    let radii = simd_clamp(radii, .zero, float4(repeating: min(half.x, half.y)))
    if !self.shadows.isEmpty {
      self.drawShadows(of: self.roundedBox(center: position + half, half: half, radii: radii, color: .one), alpha: opacity)
    }

    let rect = float4(position.x, position.y, position.x + size.x, position.y + size.y)
    let windowHalf = self.size * 0.5
    let clip = self.clips[Int(self.clipRuns[self.clipRuns.count - 1].clip)].bounds
    let visibleMin = simd_max(simd_max(position, float2(clip.x, clip.y)), -windowHalf)
    let visibleMax = simd_min(simd_min(position + size, float2(clip.z, clip.w)), windowHalf)
    guard visibleMin.x < visibleMax.x, visibleMin.y < visibleMax.y else { return }

    let sigma = max(sigma, 0)
    let sigmaPixels = sigma * self.pixelsPerPoint
    var downsample = 1
    while downsample < Self.maxGlassDownsample, sigmaPixels / Float(downsample * 2) >= 3 {
      downsample *= 2
    }
    let pointsPerTexel = Float(downsample) / self.pixelsPerPoint
    let reach = sigma * Self.glassReach
    // On a lattice fixed to the window, so the texels of a moving panel sample the same points
    // and its backdrop does not shimmer.
    let regionMin = simd_max(visibleMin - reach, -windowHalf)
    let regionMax = simd_min(visibleMax + reach, windowHalf)
    let sceneOrigin = ((regionMin + windowHalf) / pointsPerTexel).rounded(.down) * pointsPerTexel - windowHalf
    let texels = SIMD2<Int>(((regionMax - sceneOrigin) / pointsPerTexel).rounded(.up)) &+ 1

    var item = GlassItem(
      rect: rect, radii: radii, tint: tint, sceneOrigin: sceneOrigin, regionMin: .zero, regionMax: .zero,
      pointsPerTexel: pointsPerTexel, saturation: saturation, noise: noise, opacity: min(opacity, 1), depth: self.depth
    )
    // Without room in the atlas the glass is still drawn, as its tint alone.
    if let origin = self.allocateGlassRegion(texels) {
      item.regionMin = float2(Float(origin.x), Float(origin.y))
      item.regionMax = item.regionMin + float2(Float(texels.x), Float(texels.y))
      self.glassPasses.append(GlassPass(
        atlasOrigin: SIMD2<Int32>(Int32(origin.x), Int32(origin.y)), size: SIMD2<Int32>(Int32(texels.x), Int32(texels.y)),
        sceneOrigin: sceneOrigin, pointsPerTexel: pointsPerTexel, maxDepth: self.depth, sigma: sigmaPixels / Float(downsample)
      ))
    }
    self.glasses.append(item)
    self.depth += 1
  }

  /// A `size` region of the glass atlas for this frame, packed in rows, or nil when it would
  /// make the atlas taller than a texture can be.
  private func allocateGlassRegion(_ size: SIMD2<Int>) -> SIMD2<Int>? {
    let width = self.glassAtlasWidth
    guard size.x <= width else { return nil }
    if self.glassAtlasCursor.x + size.x > width {
      self.glassAtlasCursor = SIMD2(0, self.glassAtlasCursor.y + self.glassAtlasRowHeight)
      self.glassAtlasRowHeight = 0
    }
    guard self.glassAtlasCursor.y + size.y <= Self.maxTextureSize else { return nil }
    let origin = self.glassAtlasCursor
    self.glassAtlasCursor.x += size.x
    self.glassAtlasRowHeight = max(self.glassAtlasRowHeight, size.y)
    return origin
  }

  public func context(in view: MTKView, _ cb: (Rect) -> Void) {
    let windowRect = Rect(position: float2(), size: self.renderer.windowSize)
    if self.renderer.windowSize.x > 0, view.drawableSize.width > 0 {
      self.pixelsPerPoint = Float(view.drawableSize.width) / self.renderer.windowSize.x
    }

    self.beginFrame()
    cb(windowRect)
    self.endFrame()

    self.drawData(at: view)
  }

  /// `context(in:_:)` without a view: draws one frame into `texture` and waits for it, without
  /// presenting. For rendering headlessly, as tests do; `texture` needs `.shaderWrite` usage
  /// and `renderer.windowSize * pixelsPerPoint` pixels. See `makeOffscreenTarget`.
  public func render(into texture: MTLTexture, pixelsPerPoint: Float, _ cb: (Rect) -> Void) {
    let windowRect = Rect(position: float2(), size: self.renderer.windowSize)
    self.pixelsPerPoint = pixelsPerPoint

    self.beginFrame()
    cb(windowRect)
    self.endFrame()

    guard let commandBuffer = self.commandQueue.makeCommandBuffer() else { return }
    guard self.encodeFrame(into: texture, commandBuffer) else { return }
    self.finishFrame(commandBuffer)
  }

  /// Circles and lines are hard-edged debug primitives: they cast no shadow and take no blur.
  public func draw(circle: Circle2D) {
    var temp = circle
    temp.depth = self.depth
    self.circles.append(temp)
    self.depth += 1
  }

  public func draw(square: Square) {
    // A square's edge is hard; blurred, it is drawn as the rounded box that has one to widen.
    if self.blur > 0 {
      guard square.size.x > 0, square.size.y > 0, square.color.w > 0 else { return }
      self.draw(vector: self.roundedBox(
        center: square.position, half: square.size * 0.5, radii: .zero, rotation: square.rotation, color: square.color
      ))
      return
    }
    if !self.shadows.isEmpty, square.size.x > 0, square.size.y > 0 {
      let box = self.roundedBox(
        center: square.position, half: square.size * 0.5, radii: .zero, rotation: square.rotation, color: square.color
      )
      self.drawShadows(of: box, alpha: square.color.w)
    }
    var temp = square
    temp.depth = self.depth
    self.squares.append(temp)
    self.depth += 1
  }

  public func draw(line: Line) {
    var temp = line
    temp.depth = self.depth
    self.lines.append(temp)
    self.depth += 1
  }

  /// Moves a top left corner onto the pixel grid, half a pixel off the samples `compute2D` takes,
  /// so something drawn 1:1 has every sample land on a texel center. `compute2D` samples pixel
  /// `gid` at `(gid - drawableSize / 2) / pixelsPerPoint`.
  private func snapToPixelEdge(_ point: float2) -> float2 {
    let halfWindow = self.size * 0.5
    return (((point + halfWindow) * self.pixelsPerPoint).rounded(.down) + 0.5) / self.pixelsPerPoint - halfWindow
  }

  /// Draws the `uvMin`...`uvMax` part of `image` over the rect with its top left corner at
  /// `position`. A template image is drawn in `tint`, its alpha a mask; an original one in its
  /// own colors, with `tint`'s alpha as its opacity.
  public func draw(
    image: BitmapTexture, at position: float2, size: float2,
    uvMin: float2 = float2(0, 0), uvMax: float2 = float2(1, 1),
    tint: float4, template: Bool = false, nearest: Bool = false
  ) {
    guard size.x > 0, size.y > 0, tint.w > 0 else { return }

    var index = self.imageTextureIndices[ObjectIdentifier(image.texture)]
    if index == nil {
      index = Int32(self.imageTextures.count)
      self.imageTextures.append(image.texture)
      self.imageTextureIndices[ObjectIdentifier(image.texture)] = index
    }

    // Sampling the mip level with about one texel per pixel is what keeps a shrunk image from
    // shimmering; a compute kernel has no derivatives to pick it itself.
    let pixels = float2(Float(image.pixelSize.x), Float(image.pixelSize.y))
    let texelsPerPixel = abs(uvMax - uvMin) * pixels / (size * self.pixelsPerPoint)
    var lod = max(0, log2(max(texelsPerPixel.x, texelsPerPixel.y)))

    var flags: UInt32 = 0
    if template { flags |= ImageQuad.templateFlag }
    if nearest { flags |= ImageQuad.nearestFlag }

    if !self.shadows.isEmpty {
      self.drawImageShadows(
        textureIndex: index!, at: position, size: size, uvMin: uvMin, uvMax: uvMax,
        texelsPerPixel: texelsPerPixel, alpha: tint.w
      )
    }

    if self.blur > 0 {
      guard uvMin == .zero, uvMax == float2(1, 1) else {
        // A cropped image's blur would reach into what was cropped off, so it blurs inside its
        // rect only, with a hard edge: the mip level alone.
        lod = max(lod, log2(2 * self.blur * self.pixelsPerPoint * max(texelsPerPixel.x, texelsPerPixel.y)))
        flags &= ~ImageQuad.nearestFlag
        self.images.append(ImageQuad(
          position: self.snapToPixelEdge(position), size: size,
          uvMin: uvMin, uvMax: uvMax, tint: tint, depth: self.depth,
          textureIndex: index!, flags: flags, lod: lod.isFinite ? lod : 0
        ))
        self.depth += 1
        return
      }
      self.images.append(self.blurredImage(
        textureIndex: index!, at: position, size: size, texelsPerPixel: texelsPerPixel,
        sigma: self.blur, tint: tint, flags: flags
      ))
      self.depth += 1
      return
    }

    self.images.append(ImageQuad(
      position: self.snapToPixelEdge(position), size: size,
      uvMin: uvMin, uvMax: uvMax, tint: tint, depth: self.depth,
      textureIndex: index!, flags: flags, lod: lod.isFinite ? lod : 0
    ))
    self.depth += 1
  }

  /// A whole image's shadow is its alpha, blurred by sampling a mip level whose texels are about
  /// as wide as the blur, over a quad grown by the shadow's reach. A cropped image's would show
  /// what was cropped off, so it casts its visible rect's instead.
  private func drawImageShadows(
    textureIndex: Int32, at position: float2, size: float2, uvMin: float2, uvMax: float2,
    texelsPerPixel: float2, alpha: Float
  ) {
    guard uvMin == .zero, uvMax == float2(1, 1) else {
      let half = size * 0.5
      var box = self.roundedBox(center: position + half, half: half, radii: .zero, color: .one)
      box.blur = self.blur
      self.drawShadows(of: box, alpha: alpha)
      return
    }
    for shadow in self.shadows {
      var tint = shadow.color
      tint.w *= alpha
      guard tint.w > 0 else { continue }
      let clip = self.beginShadow(shadow)
      self.images.append(self.blurredImage(
        textureIndex: textureIndex, at: position + shadow.offset, size: size, texelsPerPixel: texelsPerPixel,
        sigma: Self.combined(shadow.sigma, self.blur), tint: tint, flags: ImageQuad.templateFlag
      ))
      self.depth += 1
      self.endShadow(shadow, clip)
    }
  }

  /// A whole image blurred by `sigma` points: a mip level whose texels are about 2σ wide,
  /// sampled with nothing past the edges over a quad grown by the blur's reach. `flags` keeps
  /// it a template, or not.
  private func blurredImage(
    textureIndex: Int32, at position: float2, size: float2, texelsPerPixel: float2,
    sigma: Float, tint: float4, flags: UInt32
  ) -> ImageQuad {
    let uvPerPoint = float2(1, 1) / size
    let texelsPerPixel = max(texelsPerPixel.x, texelsPerPixel.y)
    let margin = sigma * ShadowState.reach
    // never sharper than the image itself
    let lod = max(0, log2(max(texelsPerPixel, 2 * sigma * self.pixelsPerPoint * texelsPerPixel)))
    return ImageQuad(
      position: position - margin, size: size + 2 * margin,
      uvMin: -margin * uvPerPoint, uvMax: float2(1, 1) + margin * uvPerPoint,
      tint: tint, depth: self.depth, textureIndex: textureIndex,
      flags: (flags & ~ImageQuad.nearestFlag) | ImageQuad.shadowFlag, lod: lod.isFinite ? lod : 0
    )
  }

  /// Draws `icon` with its view box stretched over the rect with its top left corner at
  /// `position`, keeping only what falls inside `clipMin`...`clipMax`. Each layer is drawn in
  /// `color(layer)`, above the ones before it.
  func draw(
    icon: SVGIcon, at position: float2, size: float2, clipMin: float2, clipMax: float2,
    color: (SVGIcon.Layer) -> float4
  ) {
    guard size.x > 0, size.y > 0 else { return }
    // points per em, on each axis
    let scale = size / icon.viewBoxSize
    // Distances are scaled by one number; the smaller axis keeps edges from blurring.
    let distanceScale = min(scale.x, scale.y)
    let origin = self.snapToPixelEdge(position)
    let clipMin = clipMin + (origin - position)
    let clipMax = clipMax + (origin - position)

    // The icon casts one shadow per shadow set, all its layers' at one depth, beneath all of them.
    for shadow in self.shadows {
      let clip = self.beginShadow(shadow)
      for layer in icon.layers {
        var shadowColor = shadow.color
        shadowColor.w *= color(layer).w
        guard shadowColor.w > 0 else { continue }
        self.appendIconLayer(
          layer, origin: origin + shadow.offset, scale: scale,
          clipMin: clipMin + shadow.offset, clipMax: clipMax + shadow.offset,
          color: shadowColor, distanceScale: distanceScale, blur: Self.combined(shadow.sigma, self.blur)
        )
      }
      self.depth += 1
      self.endShadow(shadow, clip)
    }

    for layer in icon.layers {
      let layerColor = color(layer)
      guard layerColor.w > 0 else { continue }
      self.appendIconLayer(
        layer, origin: origin, scale: scale, clipMin: clipMin, clipMax: clipMax,
        color: layerColor, distanceScale: distanceScale, blur: self.blur
      )
      self.depth += 1
    }
  }

  private func appendIconLayer(
    _ layer: SVGIcon.Layer, origin: float2, scale: float2, clipMin: float2, clipMax: float2,
    color: float4, distanceScale: Float, blur: Float
  ) {
    // em space is y up, from the view box's top left corner
    let quadMin = origin + float2(layer.boundsMin.x, -layer.boundsMax.y) * scale
    let quadSize = (layer.boundsMax - layer.boundsMin) * scale
    let visibleMin = simd_max(quadMin, clipMin)
    let visibleMax = simd_min(quadMin + quadSize, clipMax)
    guard visibleMin.x < visibleMax.x, visibleMin.y < visibleMax.y, quadSize.x > 0, quadSize.y > 0 else { return }
    let t0 = (visibleMin - quadMin) / quadSize
    let t1 = (visibleMax - quadMin) / quadSize

    self.glyphs.append(Glyph(
      position: visibleMin,
      size: visibleMax - visibleMin,
      uvMin: simd_mix(layer.uvMin, layer.uvMax, t0),
      uvMax: simd_mix(layer.uvMin, layer.uvMax, t1),
      color: color,
      depth: self.depth,
      fontSize: distanceScale,
      blur: blur
    ))
  }

  /// Draws one shape of a `VectorCanvas` above everything drawn so far, above its shadows.
  func draw(vector: VectorItem) {
    let vector = self.blurred(vector)
    if !self.shadows.isEmpty {
      self.drawShadows(of: vector, alpha: vector.color.w)
    }
    self.append(vector: vector)
  }

  /// `item` under the current blur: reaching as far past its outline as the blur does.
  private func blurred(_ item: VectorItem) -> VectorItem {
    guard self.blur > 0 else { return item }
    var item = item
    let margin = self.blur * ShadowState.reach
    item.blur = self.blur
    item.clip += float4(-margin, -margin, margin, margin)
    return item
  }

  private func append(vector: VectorItem) {
    var item = vector
    item.depth = self.depth
    self.vectors.append(item)
    self.depth += 1
  }

  /// Fills the rect with its top left corner at `position`, window centered, y down, in points,
  /// with corners rounded by `radii` (see `UIShape.radii`) — or, given `strokeWidth`, strokes it
  /// that wide inside its outline, as SwiftUI's `strokeBorder`. Anti-aliased, and drawn as a
  /// `VectorItem` of the analytic rounded-box kind, so it needs no shader of its own.
  public func draw(roundedRect position: float2, size: float2, radii: float4, color: float4, strokeWidth: Float? = nil) {
    guard size.x > 0, size.y > 0, color.w > 0 else { return }
    var half = size * 0.5
    let center = position + half
    var radii = simd_clamp(radii, .zero, float4(repeating: min(half.x, half.y)))
    var halfWidth: Float = 0
    if let strokeWidth {
      // The outline runs down the middle of the stroke, so it moves in by half its width.
      halfWidth = min(max(strokeWidth, 0), min(size.x, size.y)) * 0.5
      guard halfWidth > 0 else { return }
      half -= halfWidth
      radii = simd_max(radii - halfWidth, .zero)
    }
    // a pixel beyond the edge for anti-aliasing
    let margin = half + halfWidth + 1 / self.pixelsPerPoint

    var item = VectorItem()
    item.row0 = float4(1, 0, 0, 1)
    item.row1 = float4(0, 1, 0, 0)
    item.params0 = float4(center.x, center.y, half.x, half.y)
    item.params1 = radii
    item.color = color
    item.clip = float4(center.x - margin.x, center.y - margin.y, center.x + margin.x, center.y + margin.y)
    item.stroke = float4(halfWidth, 0, 1, 0)
    item.kind = VectorItem.Kind.roundedBox.rawValue
    item.flags = VectorItem.closedFlag | (strokeWidth == nil ? 0 : VectorItem.strokeFlag)
    self.draw(vector: item)
  }

  /// Draws a straight stroke from `start` to `end`, window centered, y down, in points, `width`
  /// wide with round caps. Anti-aliased: one rounded box turned along the segment, so a chevron
  /// or a check mark costs two of them.
  public func draw(stroke start: float2, to end: float2, width: Float, color: float4) {
    guard width > 0, color.w > 0 else { return }
    let delta = end - start
    let half = float2(simd_length(delta) + width, width) * 0.5
    self.draw(vector: self.roundedBox(
      center: (start + end) * 0.5, half: half, radii: float4(repeating: width * 0.5),
      rotation: -atan2(delta.y, delta.x), color: color
    ))
  }

  /// Draws `text` with its top left corner at `position`, and returns the size it occupies.
  /// All of its glyphs share one depth, so the text as a whole sits above earlier draws.
  @discardableResult
  public func draw(text: String, at position: float2, style: TextStyle = TextStyle(), maxSize: float2? = nil) -> float2 {
    let layout = layoutText(text, style: style, maxSize: maxSize)
    self.draw(textLayout: layout, at: position, color: style.color)

    return layout.size
  }

  /// Draws a layout made by `layoutText` with its top left corner at `position`, magnified by
  /// `scale` about that corner.
  public func draw(textLayout layout: TextLayout, at position: float2, color: float4, scale: Float = 1) {
    // A text casts one shadow per shadow set, all its glyphs' at one depth, beneath all of them.
    for shadow in self.shadows {
      var shadowColor = shadow.color
      shadowColor.w *= color.w
      guard shadowColor.w > 0 else { continue }
      let clip = self.beginShadow(shadow)
      self.appendGlyphs(layout, at: position + shadow.offset, color: shadowColor, scale: scale, blur: Self.combined(shadow.sigma, self.blur))
      self.depth += 1
      self.endShadow(shadow, clip)
    }
    self.appendGlyphs(layout, at: position, color: color, scale: scale, blur: self.blur)
    self.depth += 1
  }

  private func appendGlyphs(_ layout: TextLayout, at position: float2, color: float4, scale: Float, blur: Float) {
    let fontSize = layout.fontSize * scale
    // Baselines land between two rows of pixel samples, so a flat glyph edge covers whole rows
    // instead of blurring across two. `compute2D` samples pixel `gid` at
    // `(gid - drawableSize / 2) / pixelsPerPoint`.
    let halfWindow = self.size.y * 0.5
    let snapToPixelEdge = { (y: Float) -> Float in
      (((y + halfWindow) * self.pixelsPerPoint).rounded(.down) + 0.5) / self.pixelsPerPoint - halfWindow
    }

    for line in layout.lines {
      let baseline = snapToPixelEdge(position.y + line.baseline * scale)
      for glyph in line.glyphs {
        let metrics = glyph.metrics
        let topLeft = float2(
          position.x + glyph.origin.x * scale + metrics.boundsMin.x * fontSize,
          baseline - glyph.origin.y * scale - metrics.boundsMax.y * fontSize
        )
        self.glyphs.append(Glyph(
          position: topLeft,
          size: (metrics.boundsMax - metrics.boundsMin) * fontSize,
          uvMin: metrics.uvMin,
          uvMax: metrics.uvMax,
          color: color,
          depth: self.depth,
          fontSize: fontSize,
          blur: blur
        ))
      }
    }
  }
}
