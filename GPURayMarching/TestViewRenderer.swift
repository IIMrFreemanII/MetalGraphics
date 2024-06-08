import MetalGraphicsLib
import MetalKit

struct Camera {
  var position = float3()
  var rotation = float3()
  // in radians
  var fov = Float()
}

class TestViewRenderer : ViewRenderer {
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  var library: MTLLibrary!
  var pipelineState: MTLComputePipelineState!
  
  var camera: Camera!
  
  override func start() {
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
    
    //----------------
    
    self.camera = Camera(position: float3(), rotation: float3(), fov: toRadians(60))
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let drawable = view.currentDrawable,
      let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
      return
    }
    
    commandEncoder.setComputePipelineState(pipelineState)
    let texture = drawable.texture
    commandEncoder.setTexture(texture, index: 0)
    commandEncoder.setBytes(&Time.time, length: MemoryLayout<Float>.stride, index: 0)
    commandEncoder.setBytes(&self.camera, length: MemoryLayout<Camera>.stride, index: 1)

    let width = pipelineState.threadExecutionWidth
    let height = pipelineState.maxTotalThreadsPerThreadgroup / width
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
  }
}
