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
    self.circleBuffer = self.device.makeBuffer(length: MemoryLayout<Circle>.stride * 1)
    self.squareBuffer = self.device.makeBuffer(length: MemoryLayout<Square>.stride * 1)
    self.lineBuffer = self.device.makeBuffer(length: MemoryLayout<Line>.stride * 1)
    self.glyphBuffer = self.device.makeBuffer(length: MemoryLayout<Glyph>.stride * 1)

    do {
      guard let kernel = self.library.makeFunction(name: "compute2D")
      else {
        fatalError()
      }
      self.pipelineState = try self.device.makeComputePipelineState(function: kernel)
    } catch {
      fatalError(String(describing: error))
    }
  }

  public var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  var library: MTLLibrary!
  var pipelineState: MTLComputePipelineState!

  private var shapeArgBuffer: MTLBuffer!

  private var circles: [Circle] = []
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
  }

  func endFrame() {
    if let cb = self.resizeCb {
      cb()
      self.resizeCb = nil
    } else {
      self.grid.reset()
    }
    
    for (i, item) in self.circles.enumerated() {
      self.grid.mapShapeBoundingBoxToGrid(item.bounds, Shape(index: Int32(i), shapeType: ShapeType2D.Circle.rawValue))
    }
    for (i, item) in self.squares.enumerated() {
      self.grid.mapShapeBoundingBoxToGrid(item.bounds, Shape(index: Int32(i), shapeType: ShapeType2D.Square.rawValue))
    }
    for (i, item) in self.lines.enumerated() {
      self.grid.mapShapeBoundingBoxToGrid(item.bounds, Shape(index: Int32(i), shapeType: ShapeType2D.Line.rawValue))
    }
    for (i, item) in self.glyphs.enumerated() {
      self.grid.mapShapeBoundingBoxToGrid(item.bounds, Shape(index: Int32(i), shapeType: ShapeType2D.Glyph.rawValue))
    }

    self.grid.updateBuffers()

    do {
      if self.circleBufferCount < self.circles.count {
        self.circleBufferCount += self.circles.count + 10
        self.circleBuffer = self.device.makeBuffer(length: MemoryLayout<Circle>.stride * self.circleBufferCount)
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

    let shapeArgPointer = self.shapeArgBuffer.contents().bindMemory(to: ShapeArgBuffer.self, capacity: 1)
    shapeArgPointer.pointee.circles = self.circleBuffer.gpuAddress
    shapeArgPointer.pointee.circlesCount = Int32(self.circles.count)
    shapeArgPointer.pointee.squares = self.squareBuffer.gpuAddress
    shapeArgPointer.pointee.squaresCount = Int32(self.squares.count)
    shapeArgPointer.pointee.lines = self.lineBuffer.gpuAddress
    shapeArgPointer.pointee.linesCount = Int32(self.lines.count)
    shapeArgPointer.pointee.glyphs = self.glyphBuffer.gpuAddress
    shapeArgPointer.pointee.glyphsCount = Int32(self.glyphs.count)

    self.renderer.input.endFrame()
  }

  func drawData(at view: MTKView) {
    guard
      let commandBuffer = self.commandQueue.makeCommandBuffer(),
      let drawable = view.currentDrawable
    else {
      return
    }
    // Glyphs first laid out this frame are baked before `compute2D` samples the atlas.
    FontManager.shared.encodePendingBakes(into: commandBuffer)
    guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
      // the bakes are already dequeued, so they still have to run
      commandBuffer.commit()
      return
    }

    commandEncoder.useResources([self.grid.cellBuffer, self.grid.shapeBuffer, self.circleBuffer, self.squareBuffer, self.lineBuffer, self.glyphBuffer], usage: .read)

    commandEncoder.setComputePipelineState(self.pipelineState)
    let texture = drawable.texture
    commandEncoder.setTexture(texture, index: 0)
    commandEncoder.setTexture(FontManager.shared.atlasTexture, index: 1)

    self.sceneData.windowSize = SIMD2<Int32>(Int32(self.renderer.windowSize.x), Int32(self.renderer.windowSize.y))
    self.sceneData.time = self.renderer.time

    commandEncoder.setBytes(&self.sceneData, length: MemoryLayout<SceneData>.stride, index: 0)
    commandEncoder.setBuffer(self.shapeArgBuffer, offset: 0, index: 1)
    commandEncoder.setBuffer(self.grid.gridArgBuffer, offset: 0, index: 2)

    let width = self.pipelineState.threadExecutionWidth
    let height = self.pipelineState.maxTotalThreadsPerThreadgroup / width
    let threadsPerThreadgroup = MTLSize(
      width: width, height: height, depth: 1
    )
    let gridWidth = texture.width
    let gridHeight = texture.height
    let threadGroupCount = MTLSize(
      width: (gridWidth + width - 1) / width,
      height: (gridHeight + height - 1) / height,
      depth: 1
    )
    commandEncoder.dispatchThreadgroups(
      threadGroupCount,
      threadsPerThreadgroup: threadsPerThreadgroup
    )

    commandEncoder.endEncoding()
    commandBuffer.present(drawable)

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    if commandBuffer.status == .error, !self.reportedFrameError {
      self.reportedFrameError = true
      print("2D frame failed on the GPU: \(commandBuffer.error.map(String.init(describing:)) ?? "unknown error")")
    }
  }

  func getDepth(of shape: Shape) -> Float {
    switch ShapeType2D(rawValue: shape.shapeType) {
    case .Circle:
      self.circles[Int(shape.index)].depth
    case .Square:
      self.squares[Int(shape.index)].depth
    case .Line:
      self.lines[Int(shape.index)].depth
    case .Glyph:
      self.glyphs[Int(shape.index)].depth
    default:
      fatalError("Unsupported Shape: \(shape)")
    }
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

  public func draw(circle: Circle) {
    var temp = circle
    temp.depth = self.depth
    self.circles.append(temp)
    self.depth += 1
  }

  public func draw(square: Square) {
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
          fontSize: fontSize
        ))
      }
    }
    self.depth += 1
  }
}
