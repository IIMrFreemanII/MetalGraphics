// For `GCKeyCode`, the key vocabulary. No GameController input is read.
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

  /// What input methods asked for since the last frame outside key presses, for the focused
  /// text; and the text revision it was asked against.
  public internal(set) var textInputs: [TextInputAction] = []
  public internal(set) var textInputRevision: UInt64 = 0
  /// The last batch of text actions from the main thread applied: published back with the text,
  /// so the main thread can tell a snapshot from before what it sent.
  public internal(set) var textInputSequence: UInt64 = 0

  /// Every key event since the last frame, in order, for `UIContext` to route to `.onKeyPress`
  /// handlers. Unlike `characters`, which keeps only the last, nothing typed between two frames
  /// is lost.
  public var keyPresses: [KeyPress] = []

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
  public var mousePositionFromCenter = float2()
  /// Whether the pointer is over the view. While it is, content moving under a still pointer
  /// re-hovers what it is over now.
  public var isPointerInView = false
  /// Whether the view's window is the key window, the one receiving keys. Set by `RetainedLayerView`.
  public var isWindowKey = true

  public var mouseDelta = float2()
  public var mouseScroll = float2()
  /// How far the wheel or trackpad moved content this frame, in points: positive x moves it
  /// right, positive y down. Already follows the system's scroll direction setting.
  public var scrollDelta = float2()

  /// Keys whose last `.down` has had no `.up` yet, by virtual key code, with what they were
  /// pressed as, so the `.up` sent for one AppKit never sends a `keyUp` for matches its `.down`.
  private var pressesDown: [UInt16: KeyPress] = [:]

  // Every field is fed by `apply(_:)`, from the events `RetainedLayerView` turns the view's own
  // `NSEvent`s into.
  //
  // Not GameController: `GCMouse`/`GCKeyboard` read the physical devices directly. That made
  // input global — a click on the inspector, or in another app, tapped whatever sat under the
  // last pointer position — and invisible to synthetic events, so the app could not be driven
  // by anything but a hand on the hardware. `GCKeyCode` stays as the key vocabulary only.
  public init() {}

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
    self.scrollDelta = float2()

    self.keyPresses.removeAll(keepingCapacity: true)
    self.textInputs.removeAll(keepingCapacity: true)
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

/// One of the view's `NSEvent`s, as the view saw it on the main thread: what `Input.apply` needs
/// and nothing that belongs to AppKit, so the window's thread can apply it.
///
/// Positions are in the view's points, from its top left corner, y down; a position left of or
/// below the view is pinned to its edge, as a drag carries on outside the view.
public enum InputEvent: Sendable {
  public struct Key: Sendable {
    public var keyCode: UInt16
    public var characters: String?
    public var charactersIgnoringModifiers: String?
    public var modifiers: NSEvent.ModifierFlags
    public var isRepeat: Bool
    /// The pasteboard's text when this is ⌘V, read on the main thread with the event.
    public var pasteboard: String?
    /// What the input method made of the key, when the focused element takes text through one:
    /// empty when it kept the key for its composition. Nil when the key went past it.
    public var textActions: [TextInputAction]?
    /// Which batch of text actions this is, and the text's revision they were made against.
    public var textSequence: UInt64
    public var textRevision: UInt64

    public init(
      keyCode: UInt16, characters: String?, charactersIgnoringModifiers: String?,
      modifiers: NSEvent.ModifierFlags, isRepeat: Bool = false, pasteboard: String? = nil,
      textActions: [TextInputAction]? = nil, textSequence: UInt64 = 0, textRevision: UInt64 = 0
    ) {
      self.keyCode = keyCode
      self.characters = characters
      self.charactersIgnoringModifiers = charactersIgnoringModifiers
      self.modifiers = modifiers
      self.isRepeat = isRepeat
      self.pasteboard = pasteboard
      self.textActions = textActions
      self.textSequence = textSequence
      self.textRevision = textRevision
    }
  }

  public enum Button: Sendable {
    case left, right
  }

  case keyDown(Key)
  case keyUp(Key)
  /// A modifier key went down or up: modifiers send nothing else.
  case flagsChanged(keyCode: UInt16, flags: NSEvent.ModifierFlags)
  case magnify(Float)
  case rotate(Float)
  /// `lines` as the wheel reports them; `points`, how far content should move, positive x
  /// moving it right and y down.
  case scroll(lines: float2, points: float2)
  case pointer(float2, inView: Bool)
  case mouseDown(Button, float2, inView: Bool, clickCount: Int)
  case mouseUp(Button, float2, inView: Bool)
  /// The pointer left the view: nothing under it is hovered any more.
  case pointerExited
  /// Another window took the keyboard and the pointer.
  case resignKey
  /// The window became key, with the pointer where it is if it is over the view.
  case becomeKey(pointer: float2?)
  /// What an input method asked for outside a key press: a pick from the accent menu, the
  /// character viewer, dictation. `sequence` and `revision` as for a key's actions.
  case textInput([TextInputAction], sequence: UInt64, revision: UInt64)
}

public extension Input {
  /// Applies one event. Between two frames, every event since the last is applied in order; the
  /// frame then reads the result, and `endFrame` clears the edges.
  func apply(_ event: InputEvent) {
    switch event {
    case .keyDown(let key):
      self.modifierFlags = key.modifiers
      self.commandPressed = key.modifiers.contains(.command)
      self.shiftPressed = key.modifiers.contains(.shift)
      self.charactersCode = key.characters?.unicodeScalars.first?.value
      self.characters = key.characters
      // A held key auto-repeats `keyDown`; `keysDown` means "went down this frame", once.
      if !key.isRepeat, let code = GCKeyCode(macKeyCode: key.keyCode) {
        self.keysDown.insert(code)
        self.keysPressed.insert(code)
      }
      if key.textActions != nil {
        self.textInputSequence = max(self.textInputSequence, key.textSequence)
      }
      self.queueKeyPress(key, key.isRepeat ? .repeat : .down)

    case .textInput(let actions, let sequence, let revision):
      self.textInputs.append(contentsOf: actions)
      self.textInputRevision = revision
      self.textInputSequence = max(self.textInputSequence, sequence)

    case .keyUp(let key):
      self.queueKeyPress(key, .up)
      guard let code = GCKeyCode(macKeyCode: key.keyCode) else { return }
      self.keysPressed.remove(code)
      self.keysUp.insert(code)

    case .flagsChanged(let keyCode, let flags):
      self.flagsChanged(keyCode: keyCode, flags: flags)

    case .magnify(let magnification):
      self.magnification += magnification

    case .rotate(let rotation):
      self.rotation += rotation

    case .scroll(let lines, let points):
      self.mouseScroll += lines
      self.scrollDelta += points

    case .pointer(let position, let inView):
      self.movePointer(to: position, inView: inView)

    // Buttons come from the view's own events, so only clicks on this view count, and synthetic
    // events (UI automation) work exactly like real ones. Each one moves the pointer first: a
    // click with no move before it must still hit where it landed.
    //
    // `…Down`/`…Up` are edges, cleared by `endFrame`, so a click whose down and up both land
    // between two frames still reads as one click in the next.
    case .mouseDown(let button, let position, let inView, let clickCount):
      self.movePointer(to: position, inView: inView)
      switch button {
      case .left:
        self.leftMousePressed = true
        self.leftMouseDown = true
        self.clickCount = clickCount
        if clickCount == 2 {
          self.doubleClick = true
        }
      case .right:
        self.rightMousePressed = true
        self.rightMouseDown = true
      }

    case .mouseUp(let button, let position, let inView):
      self.movePointer(to: position, inView: inView)
      switch button {
      case .left:
        self.leftMousePressed = false
        self.leftMouseUp = true
      case .right:
        self.rightMousePressed = false
        self.rightMouseUp = true
      }

    case .pointerExited:
      self.parkPointer()

    // Their `keyUp`s and `mouseUp`s now go to the other window, so whatever is held here is
    // released now or stays pressed for good; and the tracking area only works in the key
    // window, so no `mouseExited` comes either.
    case .resignKey:
      self.isWindowKey = false
      self.releaseHeldKeys(flags: [], includingModifiers: true)
      self.commandPressed = false
      self.shiftPressed = false
      if self.leftMousePressed {
        self.leftMousePressed = false
        self.leftMouseUp = true
      }
      if self.rightMousePressed {
        self.rightMousePressed = false
        self.rightMouseUp = true
      }
      self.parkPointer()

    // A window made key under a still pointer gets no `mouseEntered`: the view reads where the
    // pointer is instead.
    case .becomeKey(let pointer):
      self.isWindowKey = true
      if let pointer {
        self.movePointer(to: pointer, inView: true)
      }
    }
  }

  private func movePointer(to position: float2, inView: Bool) {
    self.isPointerInView = inView
    self.mousePosition = position
    self.mousePositionFromCenter = (position - self.windowSize * 0.5) * float2(1, -1)
    let mouseDelta = position - self.prevMousePosition
    self.mouseDelta = float2(mouseDelta.x, -mouseDelta.y)
    self.prevMousePosition = position
  }

  /// Moves the pointer far outside the view, so nothing reads as hovered. Not a move to where it
  /// left: that is clamped to the view, which would pin a pointer that left across the left or
  /// top edge onto views touching that edge.
  private func parkPointer() {
    let outside = float2(repeating: -1_000_000)
    self.mouseDelta = outside - self.prevMousePosition
    self.mousePosition = outside
    self.mousePositionFromCenter = outside
    self.prevMousePosition = outside
    self.isPointerInView = false
  }

  private func queueKeyPress(_ key: InputEvent.Key, _ phase: KeyPress.Phases) {
    // `charactersIgnoringModifiers` keeps shift: shift-a is "A". A letter's key is its lowercase
    // one, so `.onKeyPress("a")` sees both; `characters` still says which was typed.
    // A dead key types nothing, but what the input method made of it still has to arrive.
    guard var character = key.charactersIgnoringModifiers?.lowercased().first ?? (key.textActions != nil ? "\0" : nil)
    else { return }
    // Shift-Tab reports a back-tab; it is the Tab key, with shift in the modifiers.
    if character == "\u{19}" {
      character = "\t"
    }
    let press = KeyPress(
      key: KeyEquivalent(character), characters: key.characters ?? "",
      modifiers: key.modifiers.intersection(.deviceIndependentFlagsMask), phase: phase,
      keyCode: GCKeyCode(macKeyCode: key.keyCode), pasteboard: key.pasteboard,
      textInput: phase == .up ? nil : key.textActions, textRevision: key.textRevision
    )
    self.keyPresses.append(press)
    if phase == .up {
      self.pressesDown.removeValue(forKey: key.keyCode)
    } else if phase == .down {
      self.pressesDown[key.keyCode] = press
    }
  }

  // With the flags as they are after the change.
  private func flagsChanged(keyCode: UInt16, flags: NSEvent.ModifierFlags) {
    let wasCommand = self.commandPressed
    self.modifierFlags = flags
    self.commandPressed = flags.contains(.command)
    self.shiftPressed = flags.contains(.shift)

    // AppKit never sends `keyUp` for a key pressed with Command held, so such a key would stay
    // in `keysPressed` forever. Releasing Command is the last event it gets: release them then.
    if wasCommand, !self.commandPressed {
      self.releaseHeldKeys(flags: flags, includingModifiers: false)
    }

    guard let key = GCKeyCode(macKeyCode: keyCode),
          let modifier = Self.modifiers[key]
    else { return }

    if Self.isDown(modifier, in: flags) {
      self.keysDown.insert(key)
      self.keysPressed.insert(key)
    } else {
      self.keysPressed.remove(key)
      self.keysUp.insert(key)
    }
  }

  /// Sends the `keyUp`s AppKit will not: every key still in `keysPressed` goes up, and every
  /// `.down` press gets its `.up`. Modifiers are kept unless `includingModifiers`, since releasing
  /// Command leaves the others held.
  private func releaseHeldKeys(flags: NSEvent.ModifierFlags, includingModifiers: Bool) {
    for key in self.keysPressed where includingModifiers || Self.modifiers[key] == nil {
      self.keysPressed.remove(key)
      self.keysUp.insert(key)
    }
    for press in self.pressesDown.values {
      self.keyPresses.append(
        KeyPress(key: press.key, characters: press.characters, modifiers: flags.intersection(.deviceIndependentFlagsMask),
                 phase: .up, keyCode: press.keyCode)
      )
    }
    self.pressesDown.removeAll(keepingCapacity: true)
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
  
  var mouseMoved: Bool {
    self.mouseDelta.x != 0 || self.mouseDelta.y != 0
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
