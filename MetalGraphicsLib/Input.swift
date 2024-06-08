import GameController
import simd

public struct Drag {
  var start = float2()
  var location = float2()
  var translation = float2()
}

extension Drag: CustomStringConvertible {
  public var description: String {
    return """
Drag:
  start: (\(start.x), \(start.y))
  location: (\(location.x), \(location.y))
  translation: (\(translation.x), \(translation.y))
"""
  }
}

public struct Input {
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
  
  public static var characters: String? = nil
  public static var charactersCode: UInt32? = nil
  public static var modifierFlags: NSEvent.ModifierFlags? = nil
  
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
  public static var mouseDelta = float2()
  public static var mouseScroll = float2()
  
  public static var hScrollTimer: Timer?
  public static var vScrollTimer: Timer?
  public static let delay: Double = 1.5
  public static var hScrolling = false
  public static var vScrolling = false
  
  public static func hideHScrollDebounced() {
    Self.hScrollTimer?.invalidate()
    Self.hScrollTimer = Timer.scheduledTimer(withTimeInterval: Self.delay, repeats: false) { _ in
      Self.hScrolling = false
    }
  }
  
  public static func hideVScrollDebounced() {
    Self.vScrollTimer?.invalidate()
    Self.vScrollTimer = Timer.scheduledTimer(withTimeInterval: Self.delay, repeats: false) { _ in
      Self.vScrolling = false
    }
  }
  
  public static var magnification = Float()
  public static var rotation = Float()
  
  public static var windowSize = float2()
  public static var framebufferSize = float2()
  public static var windowPosition = float2()
  
  public static func endFrame() {
    Self.charactersCode = nil
    Self.characters = nil
    Self.modifierFlags = nil
    
    Self.dragEnded = false
    
    Self.mouseDelta = float2()
    Self.mouseScroll = float2()
    
    Self.keysDown.removeAll(keepingCapacity: true)
    Self.keysUp.removeAll(keepingCapacity: true)
    
    Self.clickCount = 0
    Self.doubleClick = false
    Self.leftMouseDown = false
    Self.leftMouseUp = false
    
    Self.rightMouseDown = false
    Self.rightMouseUp = false
    
    Self.magnification = 0
    Self.rotation = 0
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
    
//#if os(macOS)
//    NSEvent.addLocalMonitorForEvents(
//      matching: [.keyDown]) { event in
//        return NSApp.keyWindow?.firstResponder is NSTextView ? event : nil
//      }
//#endif
  }
}

public typealias VoidFunc = () -> Void

extension Input {
  public static func scrollCounter(_ cb: (float2) -> Void) -> Void {
    let mouseScroll = floor(Input.mouseScroll)
    if mouseScroll.x != 0 || mouseScroll.y != 0 {
      cb(mouseScroll)
    }
  }
  
  public static func commandPressed(_ cb: VoidFunc) -> Void {
    if Self.commandPressed {
      cb()
    }
  }
  
  public static func shiftPressed(_ cb: VoidFunc) -> Void {
    if Self.shiftPressed {
      cb()
    }
  }
  
  public static func charactersCode(_ cb: (UInt32) -> Void) -> Void {
    if let charsCode = Input.charactersCode {
      cb(charsCode)
    }
  }
  
  public static func characters(_ cb: (String) -> Void) -> Void {
    if let chars = Input.characters {
      cb(chars)
    }
  }
  
  public static func dragChange(_ cb: (Drag) -> Void) -> Void {
    if Self.drag {
      cb(Self.dragGesture)
    }
  }
  public static func dragEnd(_ cb: (Drag) -> Void) -> Void {
    if Self.dragEnded {
      cb(Self.dragGesture)
    }
  }
  public static var mouseDown: Bool {
    get {
      return Self.leftMouseDown || Self.rightMouseDown
    }
  }
  public static var mousePressed: Bool {
    get {
      return Self.leftMousePressed || Self.rightMousePressed
    }
  }
  public static var mouseUp: Bool {
    get {
      return Self.leftMouseUp || Self.rightMouseUp
    }
  }
  
  public static func magnify(cb: (Float) -> Void) -> Void {
    if magnification != 0 {
      cb(magnification)
    }
  }
  
  public static func rotate(cb: (Float) -> Void) -> Void {
    if rotation != 0 {
      cb(rotation)
    }
  }
  
  public static func leftMouseDown(cb: VoidFunc) {
    if Self.leftMouseDown
    {
      cb()
    }
  }
  public static func leftMousePressed(cb: VoidFunc) {
    if Self.leftMousePressed
    {
      cb()
    }
  }
  public static func leftMouseUp(cb: VoidFunc) {
    if Self.leftMouseUp
    {
      cb()
    }
  }
  
  public static func rightMouseDown(cb: VoidFunc) {
    if Self.rightMouseDown
    {
      cb()
    }
  }
  public static func rightMousePressed(cb: VoidFunc) {
    if Self.rightMousePressed
    {
      cb()
    }
  }
  public static func rightMouseUp(cb: VoidFunc) {
    if Self.rightMouseUp
    {
      cb()
    }
  }
  
  public static func keyPress(_ key: GCKeyCode, cb: VoidFunc) {
    if Self.keysPressed.contains(key)
    {
      cb()
    }
  }
  
  public static func keyDown(_ key: GCKeyCode, cb: VoidFunc) {
    if Self.keysDown.contains(key)
    {
      cb()
    }
  }
  
  public static func keyUp(_ key: GCKeyCode, cb: VoidFunc) {
    if Self.keysUp.contains(key)
    {
      cb()
    }
  }
}

