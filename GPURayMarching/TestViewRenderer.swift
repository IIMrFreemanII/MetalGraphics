import MetalGraphicsLib
import MetalKit

struct GridArgBuffer {
  var gridItems: UInt64
  var spheres: UInt64
  var gridItemsCount: Int32
}

enum ShapeType: Int32 {
  case Sphere = 0
}

struct GridItem {
  var index: Int32;
  var shapeType: Int32;
}

struct Sphere {
  var color: float4
  var position: float3
  var radius: Float
}

struct Camera {
  var position = float3()
  var rotation = float3()
  // in degrees
  var fov = Float()
  
  var rotationMatrix: float3x3 {
    return float3x3(rotation: toRadians(self.rotation))
  }
}

class TestViewRenderer : ViewRenderer {
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  var library: MTLLibrary!
  var pipelineState: MTLComputePipelineState!
  
  var camera: Camera!
  
  var gridItems: [GridItem] = []
  var spheres: [Sphere] = []
  
  var gridItemsBuffer: MTLBuffer!
  var spheresBuffer: MTLBuffer!
  var gridArgBuffer: MTLBuffer!
  
  func addSphere(_ sphere: Sphere) {
    let sphereIndex = spheres.count
    self.spheres.append(sphere)
    
    let gridItemIndex = self.gridItems.count
    self.gridItems.append(GridItem(index: Int32(sphereIndex), shapeType: ShapeType.Sphere.rawValue))
  }
  
  func initRenderer() {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    self.device = device
    self.commandQueue = commandQueue
    self.library = device.makeDefaultLibrary()

    metalView.device = device

    do {
      guard let kernel = library.makeFunction(name: "compute") else {
        fatalError()
      }
      pipelineState = try device.makeComputePipelineState(function: kernel)
    } catch {
      fatalError()
    }
    
    metalView.framebufferOnly = false
  }
  
  override func start() {
    self.initRenderer()
    
    //----------------
    
    self.camera = Camera(position: float3(0, 0, -3), rotation: float3(), fov: 60)
    
    self.addSphere(Sphere(color: float4(1, 0, 0, 1), position: float3(-1, 0, 0), radius: 0.5))
    self.addSphere(Sphere(color: float4(0, 1, 0, 1), position: float3(0, 0, 0), radius: 0.5))
    self.addSphere(Sphere(color: float4(0, 0, 1, 1), position: float3(1, 0, 0), radius: 0.5))
    
    self.spheresBuffer = self.device.makeBuffer(bytes: &self.spheres, length: MemoryLayout<Sphere>.stride * self.spheres.count)
    self.spheresBuffer.label = "Spheres buffer"
    self.gridItemsBuffer = self.device.makeBuffer(bytes: &self.gridItems, length: MemoryLayout<GridItem>.stride * self.gridItems.count)
    self.gridItemsBuffer.label = "Grid items buffer"
    
    self.gridArgBuffer = self.device.makeBuffer(length: MemoryLayout<GridArgBuffer>.stride)
    self.gridArgBuffer.label = "Grid arg buffer"
    let argPointer = self.gridArgBuffer.contents().bindMemory(to: GridArgBuffer.self, capacity: 1)
    argPointer.pointee.gridItems = self.gridItemsBuffer.gpuAddress
    argPointer.pointee.spheres = self.spheresBuffer.gpuAddress
    argPointer.pointee.gridItemsCount = Int32(self.gridItems.count)
  }
  
  func update() {
    let speed = Float(4)
    let rotationSpeed = Float(15)
    Input.keyPress(.keyW) {
      self.camera.position += (self.camera.rotationMatrix * float3.forward) * Time.deltaTime * speed
    }
    Input.keyPress(.keyS) {
      self.camera.position += (self.camera.rotationMatrix * float3.back) * Time.deltaTime * speed
    }
    Input.keyPress(.keyA) {
      self.camera.position += (self.camera.rotationMatrix * float3.left) * Time.deltaTime * speed
    }
    Input.keyPress(.keyD) {
      self.camera.position += (self.camera.rotationMatrix * float3.right) * Time.deltaTime * speed
    }
    Input.keyPress(.keyQ) {
      self.camera.position += (self.camera.rotationMatrix * float3.down) * Time.deltaTime * speed
    }
    Input.keyPress(.keyE) {
      self.camera.position += (self.camera.rotationMatrix * float3.up) * Time.deltaTime * speed
    }
    if Input.mousePressed {
      self.camera.rotation.x += Input.mouseDelta.y * Time.deltaTime * rotationSpeed
      self.camera.rotation.y += Input.mouseDelta.x * Time.deltaTime * rotationSpeed
    }
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    Graphics.context(in: view) { r in
      Graphics.draw(circle: Circle(position: float2(0, 0), radius: Float(50), color: float4(1, 0, 0, 1)))
//      Graphics.draw(square: Square(position: float2(100, 0), size: float2(100, 100), color: float4(0, 1, 0, 1)))
    }
//    self.update()
//    defer {
//      Input.mouseDelta = float2()
//    }
//    
//    guard
//      let commandBuffer = commandQueue.makeCommandBuffer(),
//      let drawable = view.currentDrawable,
//      let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
//      return
//    }
//    
//    commandEncoder.setComputePipelineState(pipelineState)
//    let texture = drawable.texture
//    commandEncoder.setTexture(texture, index: 0)
//    commandEncoder.setBytes(&Time.time, length: MemoryLayout<Float>.stride, index: 0)
//    commandEncoder.setBytes(&self.camera, length: MemoryLayout<Camera>.stride, index: 1)
//    commandEncoder.setBuffer(self.gridArgBuffer, offset: 0, index: 2)
//
//    let width = pipelineState.threadExecutionWidth
//    let height = pipelineState.maxTotalThreadsPerThreadgroup / width
//    let threadsPerThreadgroup = MTLSize(
//      width: width, height: height, depth: 1)
//    let gridWidth = texture.width
//    let gridHeight = texture.height
//    let threadGroupCount = MTLSize(
//      width: (gridWidth + width - 1) / width,
//      height: (gridHeight + height - 1) / height,
//      depth: 1
//    )
//    commandEncoder.dispatchThreadgroups(
//      threadGroupCount,
//      threadsPerThreadgroup: threadsPerThreadgroup
//    )
//
//    commandEncoder.endEncoding()
//    commandBuffer.present(drawable)
//    commandBuffer.commit()
//    commandBuffer.waitUntilCompleted()
  }
}
