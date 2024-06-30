import MetalKit

public class MyMTKView: MTKView {
  public var input = Input()
  
  // to handle key events
  override public var acceptsFirstResponder: Bool {
    true
  }

  override public func keyDown(with event: NSEvent) {
    self.input.modifierFlags = event.modifierFlags
    self.input.charactersCode = event.characters?.unicodeScalars.first?.value
    self.input.characters = event.characters
  }

  override public func magnify(with event: NSEvent) {
    self.input.magnification += Float(event.magnification)
  }

  override public func rotate(with event: NSEvent) {
    self.input.rotation += Float(event.rotation)
  }

  override public func scrollWheel(with event: NSEvent) {
    let scroll = float2(Float(event.deltaX), Float(event.deltaY))
    self.input.mouseScroll += scroll

    let momentumPhase = event.momentumPhase
    let phase = event.phase

    if phase.contains(.changed) {
      if scroll.x != 0 {
        self.input.hScrolling = true
      }

      if scroll.y != 0 {
        self.input.vScrolling = true
      }
    } else if phase.contains(.ended) {
      if scroll.x == 0 {
        self.input.hideHScrollDebounced()
      }

      if scroll.y == 0 {
        self.input.hideVScrollDebounced()
      }
    }

    if momentumPhase.contains(.began) {
      if scroll.x != 0 {
        self.input.hScrolling = true
      }

      if scroll.y != 0 {
        self.input.vScrolling = true
      }
    } else if momentumPhase.contains(.ended) {
      if scroll.x == 0 {
        self.input.hideHScrollDebounced()
      }

      if scroll.y == 0 {
        self.input.hideVScrollDebounced()
      }
    }
  }

  override public func mouseDragged(with event: NSEvent) {
    self.updateInput(with: event)
  }

  override public func mouseMoved(with event: NSEvent) {
    self.updateInput(with: event)
  }

  func updateInput(with event: NSEvent) {
    let position = convert(event.locationInWindow, from: nil)

    let newX = Float(position.x.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude))
    // flip because origin in bottom-left corner
    let newY = -Float(position.y.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude)) + self.input.windowSize.y

    let newMousePos = float2(newX, newY)
    self.input.mousePosition = newMousePos

    let mouseDelta = float2(newX, newY) - self.input.prevMousePosition
    self.input.mouseDelta = float2(mouseDelta.x, -mouseDelta.y)
    self.input.prevMousePosition = newMousePos
  }

  override public func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)
    self.input.clickCount = event.clickCount

    if event.clickCount == 2 {
      self.input.doubleClick = true
    }
  }

  override public func updateTrackingAreas() {
    for item in trackingAreas {
      removeTrackingArea(item)
    }

    addTrackingArea(
      NSTrackingArea(
        rect: frame,
        options: [.activeInKeyWindow, .mouseMoved],
        owner: self
      )
    )
  }
}
