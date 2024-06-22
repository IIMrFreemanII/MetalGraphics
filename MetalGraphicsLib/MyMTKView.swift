import MetalKit

public class MyMTKView: MTKView {
  // to handle key events
  override public var acceptsFirstResponder: Bool {
    true
  }

  override public func keyDown(with event: NSEvent) {
    Input.modifierFlags = event.modifierFlags
    Input.charactersCode = event.characters?.unicodeScalars.first?.value
    Input.characters = event.characters
  }

  override public func magnify(with event: NSEvent) {
    Input.magnification += Float(event.magnification)
  }

  override public func rotate(with event: NSEvent) {
    Input.rotation += Float(event.rotation)
  }

  override public func scrollWheel(with event: NSEvent) {
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
    } else if phase.contains(.ended) {
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
    } else if momentumPhase.contains(.ended) {
      if scroll.x == 0 {
        Input.hideHScrollDebounced()
      }

      if scroll.y == 0 {
        Input.hideVScrollDebounced()
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

    let newX = Float(position.x.clamped(to: 0.0 ... CGFloat.greatestFiniteMagnitude))
    // flip because origin in bottom-left corner
    let newY = -Float(position.y.clamped(to: 0.0 ... CGFloat.greatestFiniteMagnitude)) + Input.windowSize.y

    let newMousePos = float2(newX, newY)
    Input.mousePosition = newMousePos

    let mouseDelta = float2(newX, newY) - Input.prevMousePosition
    Input.mouseDelta = float2(mouseDelta.x, -mouseDelta.y)
    Input.prevMousePosition = newMousePos
  }

  override public func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)
    Input.clickCount = event.clickCount

    if event.clickCount == 2 {
      Input.doubleClick = true
    }
  }

  override public func updateTrackingAreas() {
    for item in trackingAreas {
      removeTrackingArea(item)
    }

    addTrackingArea(
      NSTrackingArea(
        rect: frame,
        options: [.activeInActiveApp, .mouseMoved],
        owner: self
      )
    )
  }
}
