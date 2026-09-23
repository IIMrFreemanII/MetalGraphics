import GameController
import MetalKit

public class MyMTKView: MTKView {
  public var input = Input()

  // to handle key events
  override public var acceptsFirstResponder: Bool {
    true
  }

  override public func keyDown(with event: NSEvent) {
    self.input.modifierFlags = event.modifierFlags
    self.input.commandPressed = event.modifierFlags.contains(.command)
    self.input.shiftPressed = event.modifierFlags.contains(.shift)
    self.input.charactersCode = event.characters?.unicodeScalars.first?.value
    self.input.characters = event.characters

    // A held key auto-repeats `keyDown`; `keysDown` means "went down this frame", once.
    if !event.isARepeat, let key = GCKeyCode(macKeyCode: event.keyCode) {
      self.input.keysDown.insert(key)
      self.input.keysPressed.insert(key)
    }
  }

  override public func keyUp(with event: NSEvent) {
    guard let key = GCKeyCode(macKeyCode: event.keyCode) else { return }
    self.input.keysPressed.remove(key)
    self.input.keysUp.insert(key)
  }

  // Modifiers send no key events, only this, with the flags as they are after the change.
  override public func flagsChanged(with event: NSEvent) {
    let flags = event.modifierFlags
    let wasCommand = self.input.commandPressed
    self.input.modifierFlags = flags
    self.input.commandPressed = flags.contains(.command)
    self.input.shiftPressed = flags.contains(.shift)

    // AppKit never sends `keyUp` for a key pressed with Command held, so such a key would stay
    // in `keysPressed` forever. Releasing Command is the last event it gets: release them then.
    if wasCommand, !self.input.commandPressed {
      for key in self.input.keysPressed where Self.modifiers[key] == nil {
        self.input.keysPressed.remove(key)
        self.input.keysUp.insert(key)
      }
    }

    guard let key = GCKeyCode(macKeyCode: event.keyCode),
          let modifier = Self.modifiers[key]
    else { return }

    if Self.isDown(modifier, in: flags) {
      self.input.keysDown.insert(key)
      self.input.keysPressed.insert(key)
    } else {
      self.input.keysPressed.remove(key)
      self.input.keysUp.insert(key)
    }
  }

  /// Whether the modifier key `modifier` describes is down after a `flagsChanged`.
  ///
  /// The device-dependent bit tells the left key from the right, so releasing one shift while
  /// the other is held reads as a release. Events that carry no device bits for the family at
  /// all — synthetic ones, as UI automation posts — fall back to the family's flag.
  private static func isDown(_ modifier: Modifier, in flags: NSEvent.ModifierFlags) -> Bool {
    let raw = flags.rawValue
    if raw & modifier.familyDeviceMask == 0 {
      return flags.contains(modifier.family)
    }
    return raw & modifier.deviceMask != 0
  }

  private struct Modifier {
    let family: NSEvent.ModifierFlags
    /// `NX_DEVICE…KEYMASK` from IOKit's IOLLEvent.h: this physical key's bit.
    let deviceMask: UInt
    /// Both keys' bits: left and right.
    let familyDeviceMask: UInt
  }

  private static let modifiers: [GCKeyCode: Modifier] = [
    .leftControl: Modifier(family: .control, deviceMask: 0x0001, familyDeviceMask: 0x2001),
    .rightControl: Modifier(family: .control, deviceMask: 0x2000, familyDeviceMask: 0x2001),
    .leftShift: Modifier(family: .shift, deviceMask: 0x0002, familyDeviceMask: 0x0006),
    .rightShift: Modifier(family: .shift, deviceMask: 0x0004, familyDeviceMask: 0x0006),
    .leftGUI: Modifier(family: .command, deviceMask: 0x0008, familyDeviceMask: 0x0018),
    .rightGUI: Modifier(family: .command, deviceMask: 0x0010, familyDeviceMask: 0x0018),
    .leftAlt: Modifier(family: .option, deviceMask: 0x0020, familyDeviceMask: 0x0060),
    .rightAlt: Modifier(family: .option, deviceMask: 0x0040, familyDeviceMask: 0x0060),
  ]

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

  override public func rightMouseDragged(with event: NSEvent) {
    self.updateInput(with: event)
  }

  // Leaving the view sends no `mouseMoved`, so the last position inside would stay current and
  // a hover under it would never end. Not `updateInput`: it clamps to the view, which would pin
  // a pointer that left across the left or top edge onto views touching that edge.
  override public func mouseExited(with event: NSEvent) {
    let outside = float2(repeating: -1_000_000)
    self.input.mouseDelta = outside - self.input.prevMousePosition
    self.input.mousePosition = outside
    self.input.mousePositionFromCenter = outside
    self.input.prevMousePosition = outside
  }

  override public func mouseEntered(with event: NSEvent) {
    self.updateInput(with: event)
  }

  func updateInput(with event: NSEvent) {
    let position = convert(event.locationInWindow, from: nil)

    let newX = Float(position.x.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude))
    // flip because origin in bottom-left corner
    let newY = -Float(position.y.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude)) + self.input.windowSize.y

    let newMousePos = float2(newX, newY)
    var newMousePosCenter = float2(newX, newY) - self.input.windowSize * 0.5
    newMousePosCenter *= float2(1.0, -1.0)
    self.input.mousePosition = newMousePos
    self.input.mousePositionFromCenter = newMousePosCenter

    let mouseDelta = float2(newX, newY) - self.input.prevMousePosition
    self.input.mouseDelta = float2(mouseDelta.x, -mouseDelta.y)
    self.input.prevMousePosition = newMousePos
  }
  
  // Buttons come from the view's own events, so only clicks on this view count, and synthetic
  // events (UI automation) work exactly like real ones. Each one updates the position first:
  // a click with no move before it must still hit where it landed.
  //
  // `…Down`/`…Up` are edges, cleared by `Input.endFrame`, so a click whose down and up both
  // land between two frames still reads as one click in the next.
  override public func mouseDown(with event: NSEvent) {
    self.updateInput(with: event)
    self.input.leftMousePressed = true
    self.input.leftMouseDown = true
    self.input.clickCount = event.clickCount

    if event.clickCount == 2 {
      self.input.doubleClick = true
    }
  }

  override public func mouseUp(with event: NSEvent) {
    self.updateInput(with: event)
    self.input.leftMousePressed = false
    self.input.leftMouseUp = true
  }

  override public func rightMouseDown(with event: NSEvent) {
    self.updateInput(with: event)
    self.input.rightMousePressed = true
    self.input.rightMouseDown = true
  }

  override public func rightMouseUp(with event: NSEvent) {
    self.updateInput(with: event)
    self.input.rightMousePressed = false
    self.input.rightMouseUp = true
  }

  override public func updateTrackingAreas() {
    for item in trackingAreas {
      removeTrackingArea(item)
    }

    addTrackingArea(
      NSTrackingArea(
        rect: frame,
        options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited],
        owner: self
      )
    )
  }
}
