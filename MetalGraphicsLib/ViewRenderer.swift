import MetalKit

open class ViewRenderer: NSObject {
  public var metalView: MTKView!
  public var input: Input!
  public var graphics2D: Graphics2D?
  public var windowSize = float2()

  public var clearColor = MTLClearColor(
    red: 0.93,
    green: 0.97,
    blue: 1.0,
    alpha: 1.0
  )

  private var lastTime: Double = CFAbsoluteTimeGetCurrent()
  public var deltaTime: Float = 0
  public var time: Float = 0

  public func updateTime() {
    let currentTime = CFAbsoluteTimeGetCurrent()
    self.deltaTime = Float(currentTime - self.lastTime)
    self.time += self.deltaTime
    self.lastTime = currentTime

//    Time.deltaTime = self.deltaTime
//    Time.time = self.time

//    Time.cursorTime += self.deltaTime
//    Time.cursorSinBlinking = sin(Time.cursorTime * 5)
  }

  override public init() {
    super.init()
  }

  public func initialize(metalView: MyMTKView) {
    self.metalView = metalView
    self.input = metalView.input
    self.metalView.device = GPUDevice.main
    self.metalView.delegate = self
    self.metalView.clearColor = self.clearColor
//    self.metalView.depthStencilPixelFormat = .depth32Float
    self.metalView.framebufferOnly = false

//    self.metalView.addTrackingArea(
//      NSTrackingArea(
//        rect: metalView.frame,
//        options: [.activeInActiveApp, .mouseMoved],
//        owner: self.metalView
//      )
//    )

    mtkView(
      metalView,
      drawableSizeWillChange: metalView.drawableSize
    )

    self.start()
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

//    let resolution = float2(Float(size.width), Float(size.height))
    let windowSize = float2(width, height)
    self.windowSize = windowSize
    self.input.windowSize = windowSize

    if let graphics2D = self.graphics2D {
      let newGridSize = int2(floor(windowSize / graphics2D.grid.cellSize)) &+ 1
      let prevCellSize = graphics2D.grid.cellSize
      let prevPosition = graphics2D.grid.position
      let notZero = newGridSize.x > 0 && newGridSize.y > 0

      if newGridSize != graphics2D.grid.size, notZero {
        //      print("trigger newGridSize: \(newGridSize)")
        graphics2D.resizeCb = {
          //        print("newGridSize: \(newGridSize)")
          graphics2D.grid = Grid2D(position: prevPosition, size: newGridSize, cellSize: prevCellSize, graphics: graphics2D)
        }
      }
    }
  }

  open func draw(in _: MTKView) {
    self.updateTime()
  }
}
