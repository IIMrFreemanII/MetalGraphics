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

public enum Input {
  public static let returnOrEnterKey = "\r".uint32[0]
  public static let space = " ".uint32[0]
  public static let deleteKey = "\u{7F}".uint32[0]
  public static let newLine = "\n".uint32[0]
  public static let nullTerminator = "\0".uint32[0]
  public static let topArrow = UInt32(63232)
  public static let downArrow = UInt32(63233)
  public static let leftArrow = UInt32(63234)
  public static let rightArrow = UInt32(63235)
  public static let escape = UInt32(27)

  public static var characters: String?
  public static var charactersCode: UInt32?
  public static var modifierFlags: NSEvent.ModifierFlags?

  public static var keysPressed: Set<GCKeyCode> = []
  public static var keysDown: Set<GCKeyCode> = []
  public static var keysUp: Set<GCKeyCode> = []

  public static var dragGesture = Drag()
  public static var drag = false
  public static var dragEnded = false

  public static var commandPressed = false
  public static var shiftPressed = false

  public static var doubleClick = false
  public static var clickCount = 0
  public static var leftMousePressed = false
  public static var rightMousePressed = false
  public static var leftMouseDown = false
  public static var rightMouseDown = false
  public static var leftMouseUp = false
  public static var rightMouseUp = false

  public static var prevMousePosition = float2()
  public static var mousePosition = float2()
  public static var mousePositionFromCenter: float2 {
    mousePosition - windowSize * 0.5
  }

  public static var mouseDelta = float2()
  public static var mouseScroll = float2()

  public static var hScrollTimer: Timer?
  public static var vScrollTimer: Timer?
  public static let delay: Double = 1.5
  public static var hScrolling = false
  public static var vScrolling = false

  public static func hideHScrollDebounced() {
    self.hScrollTimer?.invalidate()
    self.hScrollTimer = Timer.scheduledTimer(withTimeInterval: self.delay, repeats: false) { _ in
      self.hScrolling = false
    }
  }

  public static func hideVScrollDebounced() {
    self.vScrollTimer?.invalidate()
    self.vScrollTimer = Timer.scheduledTimer(withTimeInterval: self.delay, repeats: false) { _ in
      self.vScrolling = false
    }
  }

  public static var magnification = Float()
  public static var rotation = Float()

  public static var windowSize = float2()
  public static var framebufferSize = float2()
  public static var windowPosition = float2()

  public static func endFrame() {
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

  public static func initialize() {
    let center = NotificationCenter.default

    center.addObserver(
      forName: .GCMouseDidConnect,
      object: nil,
      queue: nil
    ) { notification in
      let mouse = notification.object as? GCMouse
      // 1
      mouse?.mouseInput?.leftButton.pressedChangedHandler = { _, _, pressed in
        Self.leftMousePressed = pressed

        if pressed {
          Self.leftMouseDown = true
        } else {
          Self.leftMouseUp = true
        }
      }
      mouse?.mouseInput?.rightButton?.pressedChangedHandler = { _, _, pressed in
        Self.rightMousePressed = pressed

        if pressed {
          Self.rightMouseDown = true
        } else {
          Self.rightMouseUp = true
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
          Self.keysDown.insert(keyCode)
          Self.keysPressed.insert(keyCode)

          switch keyCode {
          case .leftGUI, .rightGUI:
            Self.commandPressed = true
          case .leftShift, .rightShift:
            Self.shiftPressed = true
          default:
            break
          }
        } else {
          Self.keysPressed.remove(keyCode)
          Self.keysUp.insert(keyCode)

          switch keyCode {
          case .leftGUI, .rightGUI:
            Self.commandPressed = false
          case .leftShift, .rightShift:
            Self.shiftPressed = false
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
}

public typealias VoidFunc = () -> Void

public extension Input {
  static func scrollCounter(_ cb: (float2) -> Void) {
    let mouseScroll = floor(Input.mouseScroll)
    if mouseScroll.x != 0 || mouseScroll.y != 0 {
      cb(mouseScroll)
    }
  }

  static func commandPressed(_ cb: VoidFunc) {
    if self.commandPressed {
      cb()
    }
  }

  static func shiftPressed(_ cb: VoidFunc) {
    if self.shiftPressed {
      cb()
    }
  }

  static func charactersCode(_ cb: (UInt32) -> Void) {
    if let charsCode = Input.charactersCode {
      cb(charsCode)
    }
  }

  static func characters(_ cb: (String) -> Void) {
    if let chars = Input.characters {
      cb(chars)
    }
  }

  static func dragChange(_ cb: (Drag) -> Void) {
    if self.drag {
      cb(self.dragGesture)
    }
  }

  static func dragEnd(_ cb: (Drag) -> Void) {
    if self.dragEnded {
      cb(self.dragGesture)
    }
  }

  static var mouseDown: Bool {
    leftMouseDown || rightMouseDown
  }

  static var mousePressed: Bool {
    leftMousePressed || rightMousePressed
  }

  static var mouseUp: Bool {
    leftMouseUp || rightMouseUp
  }

  static func magnify(cb: (Float) -> Void) {
    if self.magnification != 0 {
      cb(self.magnification)
    }
  }

  static func rotate(cb: (Float) -> Void) {
    if self.rotation != 0 {
      cb(self.rotation)
    }
  }

  static func leftMouseDown(cb: VoidFunc) {
    if self.leftMouseDown {
      cb()
    }
  }

  static func leftMousePressed(cb: VoidFunc) {
    if self.leftMousePressed {
      cb()
    }
  }

  static func leftMouseUp(cb: VoidFunc) {
    if self.leftMouseUp {
      cb()
    }
  }

  static func rightMouseDown(cb: VoidFunc) {
    if self.rightMouseDown {
      cb()
    }
  }

  static func rightMousePressed(cb: VoidFunc) {
    if self.rightMousePressed {
      cb()
    }
  }

  static func rightMouseUp(cb: VoidFunc) {
    if self.rightMouseUp {
      cb()
    }
  }

  static func keyPress(_ key: GCKeyCode, cb: VoidFunc) {
    if self.keysPressed.contains(key) {
      cb()
    }
  }

  static func keyDown(_ key: GCKeyCode, cb: VoidFunc) {
    if self.keysDown.contains(key) {
      cb()
    }
  }

  static func keyUp(_ key: GCKeyCode, cb: VoidFunc) {
    if self.keysUp.contains(key) {
      cb()
    }
  }
}
