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
        result.leftMousePressed = pressed

        if pressed {
          result.leftMouseDown = true
        } else {
          result.leftMouseUp = true
        }
      }
      mouse?.mouseInput?.rightButton?.pressedChangedHandler = { _, _, pressed in
        result.rightMousePressed = pressed

        if pressed {
          result.rightMouseDown = true
        } else {
          result.rightMouseUp = true
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
            result.commandPressed = true
          case .leftShift, .rightShift:
            result.shiftPressed = true
          default:
            break
          }
        } else {
          result.keysPressed.remove(keyCode)
          result.keysUp.insert(keyCode)

          switch keyCode {
          case .leftGUI, .rightGUI:
            result.commandPressed = false
          case .leftShift, .rightShift:
            result.shiftPressed = false
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

  private var characters: String?
  public static var characters: String? {
    get { Input.shared.characters }
    set { Input.shared.characters = newValue }
  }

  private var charactersCode: UInt32?
  public static var charactersCode: UInt32? {
    get { Input.shared.charactersCode }
    set { Input.shared.charactersCode = newValue }
  }

  private var modifierFlags: NSEvent.ModifierFlags?
  public static var modifierFlags: NSEvent.ModifierFlags? {
    get { Input.shared.modifierFlags }
    set { Input.shared.modifierFlags = newValue }
  }

  public var keysPressed: Set<GCKeyCode> = []
  public var keysDown: Set<GCKeyCode> = []
  public var keysUp: Set<GCKeyCode> = []

  private var dragGesture = Drag()
  public static var dragGesture: Drag {
    get { Input.shared.dragGesture }
    set { Input.shared.dragGesture = newValue }
  }

  private var drag = false
  public static var drag: Bool {
    get { Input.shared.drag }
    set { Input.shared.drag = newValue }
  }

  private var dragEnded = false
  public static var dragEnded: Bool {
    get { Input.shared.dragEnded }
    set { Input.shared.dragEnded = newValue }
  }

  private var commandPressed = false
  public static var commandPressed: Bool {
    get { Input.shared.commandPressed }
    set { Input.shared.commandPressed = newValue }
  }

  private var shiftPressed = false
  public static var shiftPressed: Bool {
    get { Input.shared.shiftPressed }
    set { Input.shared.shiftPressed = newValue }
  }

  private var doubleClick = false
  public static var doubleClick: Bool {
    get { Input.shared.doubleClick }
    set { Input.shared.doubleClick = newValue }
  }

  private var clickCount = 0
  public static var clickCount: Int {
    get { Input.shared.clickCount }
    set { Input.shared.clickCount = newValue }
  }

  private var leftMousePressed = false
  public static var leftMousePressed: Bool {
    get { Input.shared.leftMousePressed }
    set { Input.shared.leftMousePressed = newValue }
  }

  private var rightMousePressed = false
  public static var rightMousePressed: Bool {
    get { Input.shared.rightMousePressed }
    set { Input.shared.rightMousePressed = newValue }
  }

  private var leftMouseDown = false
  public static var leftMouseDown: Bool {
    get { Input.shared.leftMouseDown }
    set { Input.shared.leftMouseDown = newValue }
  }

  private var rightMouseDown = false
  public static var rightMouseDown: Bool {
    get { Input.shared.rightMouseDown }
    set { Input.shared.rightMouseDown = newValue }
  }

  private var leftMouseUp = false
  public static var leftMouseUp: Bool {
    get { Input.shared.leftMouseUp }
    set { Input.shared.leftMouseUp = newValue }
  }

  private var rightMouseUp = false
  public static var rightMouseUp: Bool {
    get { Input.shared.rightMouseUp }
    set { Input.shared.rightMouseUp = newValue }
  }

  private var prevMousePosition = float2()
  public static var prevMousePosition: float2 {
    get { Input.shared.prevMousePosition }
    set { Input.shared.prevMousePosition = newValue }
  }

  private var mousePosition = float2()
  public static var mousePosition: float2 {
    get { Input.shared.mousePosition }
    set { Input.shared.mousePosition = newValue }
  }

  public static var mousePositionFromCenter: float2 {
    Input.mousePosition - Input.windowSize * 0.5
  }

  private var mouseDelta = float2()
  public static var mouseDelta: float2 {
    get { Input.shared.mouseDelta }
    set { Input.shared.mouseDelta = newValue }
  }

  private var mouseScroll = float2()
  public static var mouseScroll: float2 {
    get { Input.shared.mouseScroll }
    set { Input.shared.mouseScroll = newValue }
  }

  private var hScrollTimer: Timer?
  public static var hScrollTimer: Timer? {
    get { Input.shared.hScrollTimer }
    set { Input.shared.hScrollTimer = newValue }
  }

  private var vScrollTimer: Timer?
  public static var vScrollTimer: Timer? {
    get { Input.shared.vScrollTimer }
    set { Input.shared.vScrollTimer = newValue }
  }

  private let delay: Double = 1.5
  public static var delay: Double {
    Input.shared.delay
  }

  private var hScrolling = false
  public static var hScrolling: Bool {
    get { Input.shared.hScrolling }
    set { Input.shared.hScrolling = newValue }
  }

  var vScrolling = false
  public static var vScrolling: Bool {
    get { Input.shared.vScrolling }
    set { Input.shared.vScrolling = newValue }
  }

  public init() {}

  public static func hideHScrollDebounced() {
    let shared = Input.shared

    shared.hScrollTimer?.invalidate()
    shared.hScrollTimer = Timer.scheduledTimer(withTimeInterval: shared.delay, repeats: false) { _ in
      shared.hScrolling = false
    }
  }

  public static func hideVScrollDebounced() {
    let shared = Input.shared

    shared.vScrollTimer?.invalidate()
    shared.vScrollTimer = Timer.scheduledTimer(withTimeInterval: shared.delay, repeats: false) { _ in
      shared.vScrolling = false
    }
  }

  private var magnification = Float()
  public static var magnification: Float {
    get { Input.shared.magnification }
    set { Input.shared.magnification = newValue }
  }

  private var rotation = Float()
  public static var rotation: Float {
    get { Input.shared.rotation }
    set { Input.shared.rotation = newValue }
  }

  private var windowSize = float2()
  public static var windowSize: float2 {
    get { Input.shared.windowSize }
    set { Input.shared.windowSize = newValue }
  }

  private var framebufferSize = float2()
  public static var framebufferSize: float2 {
    get { Input.shared.framebufferSize }
    set { Input.shared.framebufferSize = newValue }
  }

  private var windowPosition = float2()
  public static var windowPosition: float2 {
    get { Input.shared.windowPosition }
    set { Input.shared.windowPosition = newValue }
  }

  public static func endFrame() {
    let shared = Input.shared

    shared.charactersCode = nil
    shared.characters = nil
    shared.modifierFlags = nil

    shared.dragEnded = false

    shared.mouseDelta = float2()
    shared.mouseScroll = float2()

    shared.keysDown.removeAll(keepingCapacity: true)
    shared.keysUp.removeAll(keepingCapacity: true)

    shared.clickCount = 0
    shared.doubleClick = false
    shared.leftMouseDown = false
    shared.leftMouseUp = false

    shared.rightMouseDown = false
    shared.rightMouseUp = false

    shared.magnification = 0
    shared.rotation = 0
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
