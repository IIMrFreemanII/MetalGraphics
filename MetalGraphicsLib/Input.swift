import GameController
import simd

public struct Drag {
  var start = float2()
  var location = float2()
  var translation = float2()
}

extension Drag: CustomStringConvertible {
  public var description: String {
    """
    Drag:
      start: (\(self.start.x), \(self.start.y))
      location: (\(self.location.x), \(self.location.y))
      translation: (\(self.translation.x), \(self.translation.y))
    """
  }
}

@preconcurrency public class Input : @unchecked Sendable {
  public let returnOrEnterKey = "\r".uint32[0]
  public let space = " ".uint32[0]
  public let deleteKey = "\u{7F}".uint32[0]
  public let newLine = "\n".uint32[0]
  public let nullTerminator = "\0".uint32[0]
  public let topArrow = UInt32(63232)
  public let downArrow = UInt32(63233)
  public let leftArrow = UInt32(63234)
  public let rightArrow = UInt32(63235)
  public let escape = UInt32(27)

  public var characters: String?
  public var charactersCode: UInt32?
  public var modifierFlags: NSEvent.ModifierFlags?

  public var keysPressed: Set<GCKeyCode> = []
  public var keysDown: Set<GCKeyCode> = []
  public var keysUp: Set<GCKeyCode> = []

  public var dragGesture = Drag()
  public var drag = false
  public var dragEnded = false

  public var commandPressed = false
  public var shiftPressed = false

  public var doubleClick = false
  public var clickCount = 0

  public var leftMousePressed = false
  public var rightMousePressed = false

  public var leftMouseDown = false
  public var rightMouseDown = false

  public var leftMouseUp = false
  public var rightMouseUp = false

  public var prevMousePosition = float2()
  public var mousePosition = float2()
  public var mousePositionFromCenter: float2 {
    self.mousePosition - self.windowSize * 0.5
  }

  public var mouseDelta = float2()
  public var mouseScroll = float2()

  public var hScrollTimer: Timer?
  public var vScrollTimer: Timer?

  public let delay: Double = 1.5

  public var hScrolling = false
  public var vScrolling = false

  public init() {
    let center = NotificationCenter.default

    center.addObserver(
      forName: .GCMouseDidConnect,
      object: nil,
      queue: nil
    ) { notification in
      let mouse = notification.object as? GCMouse
      // 1
      mouse?.mouseInput?.leftButton.pressedChangedHandler = { _, _, pressed in
        self.leftMousePressed = pressed

        if pressed {
          self.leftMouseDown = true
        } else {
          self.leftMouseUp = true
        }
      }
      mouse?.mouseInput?.rightButton?.pressedChangedHandler = { _, _, pressed in
        self.rightMousePressed = pressed

        if pressed {
          self.rightMouseDown = true
        } else {
          self.rightMouseUp = true
        }
      }
    }

    center.addObserver(
      forName: .GCKeyboardDidConnect,
      object: nil,
      queue: nil
    ) { notification in
      let keyboard = notification.object as? GCKeyboard
      keyboard?.keyboardInput?.keyChangedHandler = { _, _, keyCode, pressed in
        if pressed {
          self.keysDown.insert(keyCode)
          self.keysPressed.insert(keyCode)

          switch keyCode {
          case .leftGUI, .rightGUI:
            self.commandPressed = true
          case .leftShift, .rightShift:
            self.shiftPressed = true
          default:
            break
          }
        } else {
          self.keysPressed.remove(keyCode)
          self.keysUp.insert(keyCode)

          switch keyCode {
          case .leftGUI, .rightGUI:
            self.commandPressed = false
          case .leftShift, .rightShift:
            self.shiftPressed = false
          default:
            break
          }
        }
      }
    }

    // #if os(macOS)
    //    NSEvent.addLocalMonitorForEvents(
    //      matching: [.keyDown]) { event in
    //        return NSApp.keyWindow?.firstResponder is NSTextView ? event : nil
    //      }
    // #endif
  }

  public func hideHScrollDebounced() {
    self.hScrollTimer?.invalidate()
    self.hScrollTimer = Timer.scheduledTimer(withTimeInterval: self.delay, repeats: false) { _ in
      self.hScrolling = false
    }
  }

  public func hideVScrollDebounced() {
    self.vScrollTimer?.invalidate()
    self.vScrollTimer = Timer.scheduledTimer(withTimeInterval: self.delay, repeats: false) { _ in
      self.vScrolling = false
    }
  }

  public var magnification = Float()
  public var rotation = Float()

  public var windowSize = float2()

  public func endFrame() {
    self.charactersCode = nil
    self.characters = nil
    self.modifierFlags = nil

    self.dragEnded = false

    self.mouseDelta = float2()
    self.mouseScroll = float2()

    self.keysDown.removeAll(keepingCapacity: true)
    self.keysUp.removeAll(keepingCapacity: true)

    self.clickCount = 0
    self.doubleClick = false
    self.leftMouseDown = false
    self.leftMouseUp = false

    self.rightMouseDown = false
    self.rightMouseUp = false

    self.magnification = 0
    self.rotation = 0
  }
}

public typealias VoidFunc = () -> Void

public extension Input {
  func scrollCounter(_ cb: (float2) -> Void) {
    let mouseScroll = floor(self.mouseScroll)
    if mouseScroll.x != 0 || mouseScroll.y != 0 {
      cb(mouseScroll)
    }
  }

  func commandPressed(_ cb: VoidFunc) {
    if self.commandPressed {
      cb()
    }
  }

  func shiftPressed(_ cb: VoidFunc) {
    if self.shiftPressed {
      cb()
    }
  }

  func charactersCode(_ cb: (UInt32) -> Void) {
    if let charsCode = self.charactersCode {
      cb(charsCode)
    }
  }

  func characters(_ cb: (String) -> Void) {
    if let chars = self.characters {
      cb(chars)
    }
  }

  func dragChange(_ cb: (Drag) -> Void) {
    if self.drag {
      cb(self.dragGesture)
    }
  }

  func dragEnd(_ cb: (Drag) -> Void) {
    if self.dragEnded {
      cb(self.dragGesture)
    }
  }

  var mouseDown: Bool {
    self.leftMouseDown || self.rightMouseDown
  }

  var mousePressed: Bool {
    self.leftMousePressed || self.rightMousePressed
  }

  var mouseUp: Bool {
    self.leftMouseUp || self.rightMouseUp
  }

  func magnify(cb: (Float) -> Void) {
    if self.magnification != 0 {
      cb(self.magnification)
    }
  }

  func rotate(cb: (Float) -> Void) {
    if self.rotation != 0 {
      cb(self.rotation)
    }
  }

  func leftMouseDown(cb: VoidFunc) {
    if self.leftMouseDown {
      cb()
    }
  }

  func leftMousePressed(cb: VoidFunc) {
    if self.leftMousePressed {
      cb()
    }
  }

  func leftMouseUp(cb: VoidFunc) {
    if self.leftMouseUp {
      cb()
    }
  }

  func rightMouseDown(cb: VoidFunc) {
    if self.rightMouseDown {
      cb()
    }
  }

  func rightMousePressed(cb: VoidFunc) {
    if self.rightMousePressed {
      cb()
    }
  }

  func rightMouseUp(cb: VoidFunc) {
    if self.rightMouseUp {
      cb()
    }
  }

  func keyPress(_ key: GCKeyCode, cb: VoidFunc) {
    if self.keysPressed.contains(key) {
      cb()
    }
  }

  func keyDown(_ key: GCKeyCode, cb: VoidFunc) {
    if self.keysDown.contains(key) {
      cb()
    }
  }

  func keyUp(_ key: GCKeyCode, cb: VoidFunc) {
    if self.keysUp.contains(key) {
      cb()
    }
  }
}
