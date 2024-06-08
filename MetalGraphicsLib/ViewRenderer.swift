import MetalKit
import GameController

public class MyMTKView: MTKView {
  
  // to handle key events
  public override var acceptsFirstResponder: Bool {
    return true
  }
  
  public override func keyDown(with event: NSEvent) {
    Input.modifierFlags = event.modifierFlags
    Input.charactersCode = event.characters?.unicodeScalars.first?.value
    Input.characters = event.characters
  }
  
  public override func magnify(with event: NSEvent) {
    Input.magnification += Float(event.magnification)
  }
  
  public override func rotate(with event: NSEvent) {
    Input.rotation += Float(event.rotation)
  }
  
  public override func scrollWheel(with event: NSEvent) {
    let scroll = float2(Float(event.deltaX), Float(event.deltaY))
    Input.mouseScroll += scroll
    
    let momentumPhase = event.momentumPhase
    let phase = event.phase
    
    if phase.contains(.changed) {
      if scroll.x != 0 {
        Input.hScrolling = true
      }
      
      if scroll.y != 0 {
        Input.vScrolling = true
      }
    }
    else if phase.contains(.ended) {
      if scroll.x == 0 {
        Input.hideHScrollDebounced()
      }
      
      if scroll.y == 0 {
        Input.hideVScrollDebounced()
      }
    }
    
    if momentumPhase.contains(.began) {
      if scroll.x != 0 {
        Input.hScrolling = true
      }
      
      if scroll.y != 0 {
        Input.vScrolling = true
      }
    }
    else if momentumPhase.contains(.ended) {
      if scroll.x == 0 {
        Input.hideHScrollDebounced()
      }
      
      if scroll.y == 0 {
        Input.hideVScrollDebounced()
      }
    }
  }
  
  public override func mouseMoved(with event: NSEvent) {
    let position = event.locationInWindow
    
    let newX = Float(position.x.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude))
    // flip because origin in bottom-left corner
    let newY = -Float(position.y.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude)) + Input.windowSize.y
    
    let newMousePos = float2(newX, newY)
    Input.mousePosition = newMousePos
    
    let mouseDelta = float2(newX, newY) - Input.prevMousePosition
    Input.mouseDelta += float2(mouseDelta.x, -mouseDelta.y)
    Input.prevMousePosition = newMousePos
  }
  
  public override func mouseDown(with event: NSEvent) {
    Input.clickCount = event.clickCount
    
    if event.clickCount == 2 {
      Input.doubleClick = true
    }
  }
  
  public override func updateTrackingAreas() {
    self.trackingAreas.forEach { item in
      self.removeTrackingArea(item)
    }

    self.addTrackingArea(
      NSTrackingArea(
        rect: self.frame,
        options: [.activeInActiveApp, .mouseMoved],
        owner: self
      )
    )
  }
}

public struct Time {
  static var time: Float = 0
  static var deltaTime: Float = 0
  
  static var cursorTime = Float()
  static var cursorSinBlinking = Float()
  static func resetCursorBlinking() {
    Self.cursorTime = 0
  }
}

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
