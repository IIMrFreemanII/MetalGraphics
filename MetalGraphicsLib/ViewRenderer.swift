import MetalKit

open class ViewRenderer: NSObject {
  public var metalView: MTKView!
  
  public var clearColor = MTLClearColor(
    red: 0.93,
    green: 0.97,
    blue: 1.0,
    alpha: 1.0
  )
  
  public var lastTime: Double = CFAbsoluteTimeGetCurrent()
  public var deltaTime: Float = 0
  public var time: Float = 0
  
  public func updateTime() {
    let currentTime = CFAbsoluteTimeGetCurrent()
    deltaTime = Float(currentTime - lastTime)
    time += deltaTime
    lastTime = currentTime
    
    Time.deltaTime = deltaTime
    Time.time = time
    
    Time.cursorTime += deltaTime
    Time.cursorSinBlinking = sin(Time.cursorTime * 5)
  }
  
  public override init() {
    super.init()
  }
  
  public func initialize(metalView: MTKView) {
    self.metalView = metalView
    self.metalView.device = MTLCreateSystemDefaultDevice()
    self.metalView.delegate = self
    self.metalView.clearColor = clearColor
    self.metalView.depthStencilPixelFormat = .depth32Float
    self.metalView.framebufferOnly = false
    
    self.metalView.addTrackingArea(
      NSTrackingArea(
        rect: metalView.frame,
        options: [.activeInActiveApp, .mouseMoved],
        owner: self.metalView
      )
    )
    
    mtkView(
      metalView,
      drawableSizeWillChange: metalView.drawableSize
    )
    
    start()
  }
  
  open func start() {}
}


extension ViewRenderer: MTKViewDelegate {
  open func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
//    let contentScale = Float(view.layer!.contentsScale)
    
    let width = Float(view.frame.width)
    let height = Float(view.frame.height)
    
    let resolution = float2(Float(size.width), Float(size.height))
    Input.windowSize = float2(width, height)
    Input.framebufferSize = resolution
  }
  
  open func draw(in view: MTKView) {
    updateTime()
  }
}
