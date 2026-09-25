import MetalKit
import Combine
import SwiftUI

@MainActor open class ViewRenderer: NSObject, ObservableObject {
  public var metalView: MTKView!
  public var input: Input!
  public var graphics2D: Graphics2D?
  public let uiContext: UIContext = .init()
  @Published public var windowSize = float2()
  @Published public var mousePosition = float2()
  @Published public var temp = float2(1, 2)

  public var clearColor = MTLClearColor(
    red: 0.93,
    green: 0.97,
    blue: 1.0,
    alpha: 1.0
  )

  private var lastTime: Double = CFAbsoluteTimeGetCurrent()
  public var deltaTime: Float = 0
  public var time: Float = 0
  
  public var navigationView: some View {
    List {
      SwiftUI.Text("Navigation")
        .font(.title)
    }
  }
  
  public var inspectorView: some View {
    SwiftUI.HStack(spacing: 0) {
      SwiftUI.VStack(alignment: .leading) {
        SwiftUI.Text("Inspector")
          .font(.title)
        SwiftUI.Divider()
        SwiftUI.Text("Window size: \(String(describing: self.windowSize).split(separator: ">").last!)")
        SwiftUI.Divider()
        Number2Field(label: "Position:", value: SwiftUI.Binding(get: {self.temp}, set: { self.temp = $0 }))
        SwiftUI.Divider()
        SwiftUI.Text("Mouse position: \(String(describing: self.mousePosition).split(separator: ">").last!)")
        SwiftUI.Spacer()
      }
      SwiftUI.Spacer()
    }
    .frame(minWidth: 200)
  }

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

    // `start()` is where a subclass creates its `Graphics2D`, so the sizing pass above ran
    // while `graphics2D` was still nil and skipped the render grid entirely. Without this the
    // grid keeps the 10x10 default from its `lazy` initializer — a 500x500 box around the
    // origin — while the window is much larger, so every shape outside that box maps to no
    // cell and the compute pass rasterizes nothing. The result was a blank first frame that
    // stayed blank until a window resize happened to run this code again.
    self.resizeRenderGrid(for: self.input.windowSize)

#if DEBUG
    HotReload.start(renderer: self)
#endif
  }

  open func start() {}

  /// Called after InjectionNext injects edited Swift code (Debug only). The retained tree was
  /// built by the old code, so a subclass rebuilds it here for the new code to take effect.
  open func hotReload() {}
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
    DispatchQueue.main.async {
      self.windowSize = windowSize
    }
    self.input.windowSize = windowSize

    self.uiContext.resizeHitGrid(for: windowSize)
    self.resizeRenderGrid(for: windowSize)
  }

  /// The render grid covers the window in cells of a fixed size, so a new window size means a
  /// new cell count. Split out of `mtkView(_:drawableSizeWillChange:)` because it also has to be
  /// sized once more after `start()`, when `graphics2D` first exists.
  func resizeRenderGrid(for windowSize: float2) {
    guard let graphics2D = self.graphics2D else { return }

    let newGridSize = int2(floor(windowSize / graphics2D.grid.cellSize)) &+ 1
    guard newGridSize.x > 0, newGridSize.y > 0, newGridSize != graphics2D.grid.size else {
      return
    }

    let prevCellSize = graphics2D.grid.cellSize
    let prevPosition = graphics2D.grid.position
    // Deferred rather than applied here: `endFrame` runs this immediately before mapping
    // shapes into the grid, so the replacement never lands mid-frame.
    graphics2D.resizeCb = {
      graphics2D.grid = GraphicsGrid2D(
        position: prevPosition, size: newGridSize, cellSize: prevCellSize, graphics: graphics2D
      )
    }
  }

  open func draw(in _: MTKView) {
//    self.mousePosition = input.mousePositionFromCenter
    self.updateTime()
  }
}
