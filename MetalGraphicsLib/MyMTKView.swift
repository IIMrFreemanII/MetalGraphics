import MetalKit

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
  
  public override func mouseDragged(with event: NSEvent) {
    self.updateInput(with: event)
  }
  
  public override func mouseMoved(with event: NSEvent) {
    self.updateInput(with: event)
  }
  
   func updateInput(with event: NSEvent) {
    let position = self.convert(event.locationInWindow, from: nil)
    
    let newX = Float(position.x.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude))
    // flip because origin in bottom-left corner
    let newY = -Float(position.y.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude)) + Input.windowSize.y
    
    let newMousePos = float2(newX, newY)
    Input.mousePosition = newMousePos
    
    let mouseDelta = float2(newX, newY) - Input.prevMousePosition
    Input.mouseDelta = float2(mouseDelta.x, -mouseDelta.y)
    Input.prevMousePosition = newMousePos
  }
  
  public override func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)
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
