import MetalKit

struct ShapeArgBuffer {
  var circles: UInt64 = 0
  var circlesCount: Int32 = 0

  var squares: UInt64 = 0
  var squaresCount: Int32 = 0

  var lines: UInt64 = 0
  var linesCount: Int32 = 0
}

public struct DebugData {
  public var drawGrid: Bool = true
  public var showFilledCells: Bool = true
}

public struct SceneData {
  public var windowSize = SIMD2<Int32>()
  public var time = Float()
  public var debug = DebugData()
}

public class Graphics {
  private static var depth = Float()
  static var grid: Grid2D = .init(position: float2(), size: int2(10, 10), cellSize: Float(50))

  public static var shared: Graphics = {
    var result = Graphics()
    guard let device = MTLCreateSystemDefaultDevice()
    else {
      fatalError("Metal is not supported on this device")
    }
    result.device = device
    let commandQueue = device.makeCommandQueue()!
    result.commandQueue = commandQueue

    var library: MTLLibrary!
    do {
      if let path = Bundle(for: Graphics.self).path(forResource: "default", ofType: "metallib") {
        library = try device.makeLibrary(URL: URL(fileURLWithPath: path))
      } else {
        fatalError("Could not find metallib file in bundle")
      }
    } catch {
      fatalError("Could not create Metal library: \(error)")
    }

    result.library = library

    result.shapeArgBuffer = device.makeBuffer(length: MemoryLayout<ShapeArgBuffer>.stride * 1)
    result.circleBuffer = device.makeBuffer(length: MemoryLayout<Circle>.stride * 1)
    result.squareBuffer = device.makeBuffer(length: MemoryLayout<Square>.stride * 1)
    result.lineBuffer = device.makeBuffer(length: MemoryLayout<Line>.stride * 1)

    do {
      guard let kernel = result.library.makeFunction(name: "compute2D")
      else {
        fatalError()
      }
      result.pipelineState = try device.makeComputePipelineState(function: kernel)
    } catch {
      fatalError()
    }

    return result
  }()

  var device: MTLDevice!
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

  public var sceneData = SceneData()

  static func beginFrame() {
    self.depth = 0
    self.shared.circles.removeAll(keepingCapacity: true)
    self.shared.squares.removeAll(keepingCapacity: true)
    self.shared.lines.removeAll(keepingCapacity: true)
  }

  static func endFrame() {
    let shared = Self.shared

    Self.grid.reset()

    for (i, item) in shared.circles.enumerated() {
      Self.grid.mapShapeBoundingBoxToGrid(item.bounds, Shape(index: Int32(i), shapeType: ShapeType2D.Circle.rawValue))
    }
    for (i, item) in shared.squares.enumerated() {
      Self.grid.mapShapeBoundingBoxToGrid(item.bounds, Shape(index: Int32(i), shapeType: ShapeType2D.Square.rawValue))
    }
    for (i, item) in shared.lines.enumerated() {
      Self.grid.mapShapeBoundingBoxToGrid(item.bounds, Shape(index: Int32(i), shapeType: ShapeType2D.Line.rawValue))
    }

    Self.grid.updateBuffers()

    do {
      if shared.circleBufferCount < shared.circles.count {
        shared.circleBufferCount += shared.circles.count + 10
        shared.circleBuffer = shared.device.makeBuffer(length: MemoryLayout<Circle>.stride * shared.circleBufferCount)
        shared.circleBuffer.label = "Circle buffer"
      }

      shared.circleBuffer.contents().copyMemory(from: &shared.circles, byteCount: shared.circles.byteCount)
    }

    do {
      if shared.squareBufferCount < shared.squares.count {
        shared.squareBufferCount += shared.squares.count + 10
        shared.squareBuffer = shared.device.makeBuffer(length: MemoryLayout<Square>.stride * shared.squareBufferCount)
        shared.squareBuffer.label = "Square buffer"
      }

      shared.squareBuffer.contents().copyMemory(from: &shared.squares, byteCount: shared.squares.byteCount)
    }

    do {
      if shared.lineBufferCount < shared.lines.count {
        shared.lineBufferCount += shared.lines.count + 10
        shared.lineBuffer = shared.device.makeBuffer(length: MemoryLayout<Line>.stride * shared.lineBufferCount)
        shared.lineBuffer.label = "Line buffer"
      }

      shared.lineBuffer.contents().copyMemory(from: &shared.lines, byteCount: shared.lines.byteCount)
    }

    let shapeArgPointer = shared.shapeArgBuffer.contents().bindMemory(to: ShapeArgBuffer.self, capacity: 1)
    shapeArgPointer.pointee.circles = shared.circleBuffer.gpuAddress
    shapeArgPointer.pointee.circlesCount = Int32(shared.circles.count)
    shapeArgPointer.pointee.squares = shared.squareBuffer.gpuAddress
    shapeArgPointer.pointee.squaresCount = Int32(shared.squares.count)
    shapeArgPointer.pointee.lines = shared.lineBuffer.gpuAddress
    shapeArgPointer.pointee.linesCount = Int32(shared.lines.count)

    Input.endFrame()
  }

  static func drawData(at view: MTKView) {
    let shared = Self.shared

    guard
      let commandBuffer = shared.commandQueue.makeCommandBuffer(),
      let drawable = view.currentDrawable,
      let commandEncoder = commandBuffer.makeComputeCommandEncoder()
    else {
      return
    }

    commandEncoder.setComputePipelineState(shared.pipelineState)
    let texture = drawable.texture
    commandEncoder.setTexture(texture, index: 0)

    shared.sceneData.windowSize = SIMD2<Int32>(Int32(Input.windowSize.x), Int32(Input.windowSize.y))
    shared.sceneData.time = Time.time

    commandEncoder.setBytes(&shared.sceneData, length: MemoryLayout<SceneData>.stride, index: 0)
    commandEncoder.setBuffer(shared.shapeArgBuffer, offset: 0, index: 1)
    commandEncoder.setBuffer(Self.grid.gridArgBuffer, offset: 0, index: 2)

    let width = shared.pipelineState.threadExecutionWidth
    let height = shared.pipelineState.maxTotalThreadsPerThreadgroup / width
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
  }

  static func getDepth(of shape: Shape) -> Float {
    switch ShapeType2D(rawValue: shape.shapeType) {
    case .Circle:
      self.shared.circles[Int(shape.index)].depth
    case .Square:
      self.shared.squares[Int(shape.index)].depth
    case .Line:
      self.shared.lines[Int(shape.index)].depth
    default:
      fatalError("Unsupported Shape: \(shape)")
    }
  }

  public static func context(in view: MTKView, _ cb: (Rect) -> Void) {
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)

    Self.beginFrame()
    cb(windowRect)
    Self.endFrame()

    Self.drawData(at: view)
  }

  // for testing
  public static func testGrid(in view: MTKView) {
    self.grid.reset()

    let boundsSize = float2(30, 30)
    let bounds = BoundingBox2D(center: Input.mousePositionFromCenter, size: boundsSize)
    Self.grid.mapShapeBoundingBoxToGrid(bounds, Shape(index: Int32(), shapeType: Int32()))

    for cell in Self.grid.cells {
      if cell.shapes.count > 1 {
        print("has duplicates")
      }
    }

    let spacing = Float(0)

    Graphics.context(in: view) { _ in
      Graphics.draw(square: Square(position: bounds.center, size: boundsSize, color: float4(0, 0, 1, 1)))
      for y in 0 ..< Self.grid.size.y {
        for x in 0 ..< Self.grid.size.x {
          let index = from2DTo1DArray(int2(x, y), Self.grid.size)
          let isEmply = Self.grid.cells[index].shapes.isEmpty
          let size = float2(Self.grid.cellSize, Self.grid.cellSize)

          Graphics.draw(square: Square(position: float2((Float(x) - Float(Self.grid.size.x) * 0.5) * (Self.grid.cellSize + spacing), (Float(y) - Float(Self.grid.size.y) * 0.5) * (Self.grid.cellSize + spacing)) + size * 0.5, size: size, color: isEmply ? float4(1, 0, 0, 1) : float4(0, 1, 0, 1)))
        }
      }
    }
  }

  public static func draw(circle: Circle) {
    var temp = circle
    temp.depth = Self.depth
    Self.shared.circles.append(temp)
    Self.depth += 1
  }

  public static func draw(square: Square) {
    var temp = square
    temp.depth = Self.depth
    Self.shared.squares.append(temp)
    Self.depth += 1
  }

  public static func draw(line: Line) {
    var temp = line
    temp.depth = Self.depth
    Self.shared.lines.append(temp)
    Self.depth += 1
  }
}
