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

public class Input {
  public static let shared: Input = {
    let result = Input()

    let center = NotificationCenter.default

    center.addObserver(
      forName: .GCMouseDidConnect,
      object: nil,
      queue: nil
    ) { notification in
      let mouse = notification.object as? GCMouse
      // 1
      mouse?.mouseInput?.leftButton.pressedChangedHandler = { _, _, pressed in
        result._leftMousePressed = pressed

        if pressed {
          result._leftMouseDown = true
        } else {
          result._leftMouseUp = true
        }
      }
      mouse?.mouseInput?.rightButton?.pressedChangedHandler = { _, _, pressed in
        result._rightMousePressed = pressed

        if pressed {
          result._rightMouseDown = true
        } else {
          result._rightMouseUp = true
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
          result.keysDown.insert(keyCode)
          result.keysPressed.insert(keyCode)

          switch keyCode {
          case .leftGUI, .rightGUI:
            result._commandPressed = true
          case .leftShift, .rightShift:
            result._shiftPressed = true
          default:
            break
          }
        } else {
          result.keysPressed.remove(keyCode)
          result.keysUp.insert(keyCode)

          switch keyCode {
          case .leftGUI, .rightGUI:
            result._commandPressed = false
          case .leftShift, .rightShift:
            result._shiftPressed = false
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

    return result
  }()

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

  private var _characters: String?
  public static var characters: String? {
    get { Input.shared._characters }
    set { Input.shared._characters = newValue }
  }

  private var _charactersCode: UInt32?
  public static var charactersCode: UInt32? {
    get { Input.shared._charactersCode }
    set { Input.shared._charactersCode = newValue }
  }

  private var _modifierFlags: NSEvent.ModifierFlags?
  public static var modifierFlags: NSEvent.ModifierFlags? {
    get { Input.shared._modifierFlags }
    set { Input.shared._modifierFlags = newValue }
  }

  public var keysPressed: Set<GCKeyCode> = []
  public var keysDown: Set<GCKeyCode> = []
  public var keysUp: Set<GCKeyCode> = []

  private var _dragGesture = Drag()
  public static var dragGesture: Drag {
    get { Input.shared._dragGesture }
    set { Input.shared._dragGesture = newValue }
  }

  private var _drag = false
  public static var drag: Bool {
    get { Input.shared._drag }
    set { Input.shared._drag = newValue }
  }

  private var _dragEnded = false
  public static var dragEnded: Bool {
    get { Input.shared._dragEnded }
    set { Input.shared._dragEnded = newValue }
  }

  private var _commandPressed = false
  public static var commandPressed: Bool {
    get { Input.shared._commandPressed }
    set { Input.shared._commandPressed = newValue }
  }

  private var _shiftPressed = false
  public static var shiftPressed: Bool {
    get { Input.shared._shiftPressed }
    set { Input.shared._shiftPressed = newValue }
  }

  private var _doubleClick = false
  public static var doubleClick: Bool {
    get { Input.shared._doubleClick }
    set { Input.shared._doubleClick = newValue }
  }

  private var _clickCount = 0
  public static var clickCount: Int {
    get { Input.shared._clickCount }
    set { Input.shared._clickCount = newValue }
  }

  private var _leftMousePressed = false
  public static var leftMousePressed: Bool {
    get { Input.shared._leftMousePressed }
    set { Input.shared._leftMousePressed = newValue }
  }

  private var _rightMousePressed = false
  public static var rightMousePressed: Bool {
    get { Input.shared._rightMousePressed }
    set { Input.shared._rightMousePressed = newValue }
  }

  private var _leftMouseDown = false
  public static var leftMouseDown: Bool {
    get { Input.shared._leftMouseDown }
    set { Input.shared._leftMouseDown = newValue }
  }

  private var _rightMouseDown = false
  public static var rightMouseDown: Bool {
    get { Input.shared._rightMouseDown }
    set { Input.shared._rightMouseDown = newValue }
  }

  private var _leftMouseUp = false
  public static var leftMouseUp: Bool {
    get { Input.shared._leftMouseUp }
    set { Input.shared._leftMouseUp = newValue }
  }

  private var _rightMouseUp = false
  public static var rightMouseUp: Bool {
    get { Input.shared._rightMouseUp }
    set { Input.shared._rightMouseUp = newValue }
  }

  private var _prevMousePosition = float2()
  public static var prevMousePosition: float2 {
    get { Input.shared._prevMousePosition }
    set { Input.shared._prevMousePosition = newValue }
  }

  private var _mousePosition = float2()
  public static var mousePosition: float2 {
    get { Input.shared._mousePosition }
    set { Input.shared._mousePosition = newValue }
  }

  public static var mousePositionFromCenter: float2 {
    Input.mousePosition - Input.windowSize * 0.5
  }

  private var _mouseDelta = float2()
  public static var mouseDelta: float2 {
    get { Input.shared._mouseDelta }
    set { Input.shared._mouseDelta = newValue }
  }

  private var _mouseScroll = float2()
  public static var mouseScroll: float2 {
    get { Input.shared._mouseScroll }
    set { Input.shared._mouseScroll = newValue }
  }

  private var _hScrollTimer: Timer?
  public static var hScrollTimer: Timer? {
    get { Input.shared._hScrollTimer }
    set { Input.shared._hScrollTimer = newValue }
  }

  private var _vScrollTimer: Timer?
  public static var vScrollTimer: Timer? {
    get { Input.shared._vScrollTimer }
    set { Input.shared._vScrollTimer = newValue }
  }

  private let _delay: Double = 1.5
  public static var delay: Double {
    Input.shared._delay
  }

  private var _hScrolling = false
  public static var hScrolling: Bool {
    get { Input.shared._hScrolling }
    set { Input.shared._hScrolling = newValue }
  }

  private var _vScrolling = false
  public static var vScrolling: Bool {
    get { Input.shared._vScrolling }
    set { Input.shared._vScrolling = newValue }
  }

  public init() {}

  public static func hideHScrollDebounced() {
    let shared = Input.shared

    shared._hScrollTimer?.invalidate()
    shared._hScrollTimer = Timer.scheduledTimer(withTimeInterval: shared._delay, repeats: false) { _ in
      shared._hScrolling = false
    }
  }

  public static func hideVScrollDebounced() {
    let shared = Input.shared

    shared._vScrollTimer?.invalidate()
    shared._vScrollTimer = Timer.scheduledTimer(withTimeInterval: shared._delay, repeats: false) { _ in
      shared._vScrolling = false
    }
  }

  private var _magnification = Float()
  public static var magnification: Float {
    get { Input.shared._magnification }
    set { Input.shared._magnification = newValue }
  }

  private var _rotation = Float()
  public static var rotation: Float {
    get { Input.shared._rotation }
    set { Input.shared._rotation = newValue }
  }

  private var _windowSize = float2()
  public static var windowSize: float2 {
    get { Input.shared._windowSize }
    set { Input.shared._windowSize = newValue }
  }

  private var _framebufferSize = float2()
  public static var framebufferSize: float2 {
    get { Input.shared._framebufferSize }
    set { Input.shared._framebufferSize = newValue }
  }

  private var _windowPosition = float2()
  public static var windowPosition: float2 {
    get { Input.shared._windowPosition }
    set { Input.shared._windowPosition = newValue }
  }

  public static func endFrame() {
    let shared = Input.shared

    shared._charactersCode = nil
    shared._characters = nil
    shared._modifierFlags = nil

    shared._dragEnded = false

    shared._mouseDelta = float2()
    shared._mouseScroll = float2()

    shared.keysDown.removeAll(keepingCapacity: true)
    shared.keysUp.removeAll(keepingCapacity: true)

    shared._clickCount = 0
    shared._doubleClick = false
    shared._leftMouseDown = false
    shared._leftMouseUp = false

    shared._rightMouseDown = false
    shared._rightMouseUp = false

    shared._magnification = 0
    shared._rotation = 0
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
    if Input.commandPressed {
      cb()
    }
  }

  static func shiftPressed(_ cb: VoidFunc) {
    if Input.shiftPressed {
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
    if Input.drag {
      cb(Input.dragGesture)
    }
  }

  static func dragEnd(_ cb: (Drag) -> Void) {
    if Input.dragEnded {
      cb(Input.dragGesture)
    }
  }

  static var mouseDown: Bool {
    Input.leftMouseDown || Input.rightMouseDown
  }

  static var mousePressed: Bool {
    Input.leftMousePressed || Input.rightMousePressed
  }

  static var mouseUp: Bool {
    Input.leftMouseUp || Input.rightMouseUp
  }

  static func magnify(cb: (Float) -> Void) {
    if Input.magnification != 0 {
      cb(Input.magnification)
    }
  }

  static func rotate(cb: (Float) -> Void) {
    if Input.rotation != 0 {
      cb(Input.rotation)
    }
  }

  static func leftMouseDown(cb: VoidFunc) {
    if Input.leftMouseDown {
      cb()
    }
  }

  static func leftMousePressed(cb: VoidFunc) {
    if Input.leftMousePressed {
      cb()
    }
  }

  static func leftMouseUp(cb: VoidFunc) {
    if Input.leftMouseUp {
      cb()
    }
  }

  static func rightMouseDown(cb: VoidFunc) {
    if Input.rightMouseDown {
      cb()
    }
  }

  static func rightMousePressed(cb: VoidFunc) {
    if Input.rightMousePressed {
      cb()
    }
  }

  static func rightMouseUp(cb: VoidFunc) {
    if Input.rightMouseUp {
      cb()
    }
  }

  static func keyPress(_ key: GCKeyCode, cb: VoidFunc) {
    if Input.shared.keysPressed.contains(key) {
      cb()
    }
  }

  static func keyDown(_ key: GCKeyCode, cb: VoidFunc) {
    if Input.shared.keysDown.contains(key) {
      cb()
    }
  }

  static func keyUp(_ key: GCKeyCode, cb: VoidFunc) {
    if Input.shared.keysUp.contains(key) {
      cb()
    }
  }
}
