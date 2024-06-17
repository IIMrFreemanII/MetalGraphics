import MetalKit

struct ShapeArgBuffer {
  var circles: UInt64 = 0
  var squares: UInt64 = 0
  
  var circlesCount: Int32 = 0
  var squaresCount: Int32 = 0
}

public class Graphics {
  static var shared: Graphics = {
    var result = Graphics()
    guard let device = MTLCreateSystemDefaultDevice() else {
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
    
    do {
      guard let kernel = result.library.makeFunction(name: "compute2D") else {
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
  
  static func beginFrame() {
    Self.shared.circles.removeAll(keepingCapacity: true)
    Self.shared.squares.removeAll(keepingCapacity: true)
  }
  
  static func endFrame() {
    let shared = Self.shared
    
    do {
      if shared.circleBufferCount < shared.circles.count {
        shared.circleBufferCount += 100
        shared.circleBuffer = shared.device.makeBuffer(length: MemoryLayout<Circle>.stride * shared.circleBufferCount)
        shared.circleBuffer.label = "Circle buffer"
        
        let shapeArgPointer = shared.shapeArgBuffer.contents().bindMemory(to: ShapeArgBuffer.self, capacity: 1)
        shapeArgPointer.pointee.circles = shared.circleBuffer.gpuAddress
        shapeArgPointer.pointee.circlesCount = Int32(shared.circles.count)
      }
      
      shared.circleBuffer.contents().copyMemory(from: &shared.circles, byteCount: shared.circles.byteCount)
    }
    
    do {
      if shared.squareBufferCount < shared.squares.count {
        shared.squareBufferCount += 100
        shared.squareBuffer = shared.device.makeBuffer(length: MemoryLayout<Square>.stride * shared.squareBufferCount)
        shared.squareBuffer.label = "Square buffer"
        
        let shapeArgPointer = shared.shapeArgBuffer.contents().bindMemory(to: ShapeArgBuffer.self, capacity: 1)
        shapeArgPointer.pointee.squares = shared.squareBuffer.gpuAddress
        shapeArgPointer.pointee.squaresCount = Int32(shared.squares.count)
      }
      
      shared.squareBuffer.contents().copyMemory(from: &shared.squares, byteCount: shared.squares.byteCount)
    }
    
    Input.endFrame()
  }
  
  static func drawData(at view: MTKView) {
    let shared = Self.shared
    
    guard
      let commandBuffer = shared.commandQueue.makeCommandBuffer(),
      let drawable = view.currentDrawable,
      let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
      return
    }
    
    commandEncoder.setComputePipelineState(shared.pipelineState)
    let texture = drawable.texture
    commandEncoder.setTexture(texture, index: 0)
    commandEncoder.setBytes(&Time.time, length: MemoryLayout<Float>.stride, index: 0)
    commandEncoder.setBuffer(shared.shapeArgBuffer, offset: 0, index: 1)
    
    let width = shared.pipelineState.threadExecutionWidth
    let height = shared.pipelineState.maxTotalThreadsPerThreadgroup / width
    let threadsPerThreadgroup = MTLSize(
      width: width, height: height, depth: 1)
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
  
  public static func context(in view: MTKView, _ cb: (Rect) -> Void) {
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    
    Self.beginFrame()
    cb(windowRect)
    Self.endFrame()
    
    Self.drawData(at: view)
  }
  
  public static func draw(circle: Circle) {
    Self.shared.circles.append(circle)
  }
  
  public static func draw(square: Square) {
    Self.shared.squares.append(square)
  }
}
