import AppKit
import Carbon.HIToolbox
import Metal
import simd

/// A rectangle in points, top left origin, y down: a window's frame on a `HeadlessApp`'s screen,
/// or an element's in its window.
public struct HeadlessRect: Equatable, Sendable, CustomStringConvertible {
  public var origin: float2
  public var size: float2

  public init(origin: float2, size: float2) {
    self.origin = origin
    self.size = size
  }

  public var center: float2 { self.origin + self.size * 0.5 }
  public var max: float2 { self.origin + self.size }

  public func contains(_ point: float2) -> Bool {
    all(point .>= self.origin) && all(point .< self.max)
  }

  public var description: String {
    "(\(self.origin.x), \(self.origin.y), \(self.size.x)×\(self.size.y))"
  }
}

/// One window of a `HeadlessApp`: a tree built by its scene's `root`, run by the app's
/// `RootViewRenderer` with no view, drawn into an offscreen texture.
///
/// Input goes in as the `InputEvent`s a `RetainedLayerView` sends, through `Input.apply`, and each
/// action steps the whole app — every window — as many frames as the real events would take:
/// a click is a press frame and a release frame. Points are the window's, from its content's top
/// left, y down. Any action on a window makes it key first, as clicking one does.
@MainActor public final class HeadlessWindow {
  public unowned let app: HeadlessApp
  /// The scene it was opened from; `"dock"` for a dock window.
  public let sceneID: String
  public internal(set) var title: String
  public let handle: WindowHandle
  let renderer: RootViewRenderer

  /// The content's size, in points.
  public private(set) var size: float2
  /// The content's top left on the app's screen.
  public var origin: float2
  public var frame: HeadlessRect { HeadlessRect(origin: self.origin, size: self.size) }

  /// Shown on the screen. A hidden window (a dock window while its workspace is closed, a
  /// minimized one) runs what is posted to it but draws nothing, as an occluded window.
  public internal(set) var isVisible = true
  public private(set) var isOpen = true
  /// Frames it ran, and those of them that drew.
  public private(set) var frames = 0
  public private(set) var renders = 0

  /// Where the pointer is over the window, or nil when it is elsewhere.
  public private(set) var pointer: float2?
  /// Whether the left button went down in this window and is still down.
  public private(set) var isPressed = false

  /// Called instead of closing when the user closes it: a dock window closes its host, a
  /// presentation's asks its binding.
  var onUserClose: (() -> Void)?

  /// Set for a presentation's window: what it shows, and the window it was presented from.
  var presentation: HeadlessPresentation?
  /// A press a presentation over this window took: its release only steps.
  private var pressTaken = false

  private var target: MTLTexture
  private let state: HeadlessWindowState

  init(
    app: HeadlessApp, sceneID: String, title: String, size: float2, origin: float2, restoring: String,
    root: @escaping @Sendable (WindowScene) -> UIElement
  ) {
    self.app = app
    self.sceneID = sceneID
    self.title = title
    self.size = size
    self.origin = origin
    self.target = Graphics2D.makeOffscreenTarget(size: size, pixelsPerPoint: app.pixelsPerPoint)
    let state = HeadlessWindowState(persisted: restoring)
    self.state = state
    let handle = WindowHandle(threadlessNamed: "Headless \(sceneID)")
    self.handle = handle

    let clock = app.clock
    let previous = ThreadState.current.executor
    ThreadState.current.executor = handle.executor
    handle.start(
      sceneID: sceneID, root: root, restoring: restoring,
      persist: { encoded in state.persisted = encoded },
      layer: nil,
      showPointerStyle: { style in state.pointerStyle = style },
      showTextInput: { snapshot in state.textInput = snapshot },
      clock: { clock.now }
    )
    ThreadState.current.executor = previous
    self.renderer = handle.currentRenderer!
    // As the view's first layout sends it.
    let scale = app.pixelsPerPoint
    handle.post { $0.resize(to: size, scale: scale) }
  }

  /// A presentation's window, whose tree and renderer its presenter's thread already made
  /// (`WindowPresentation.open`).
  init(
    app: HeadlessApp, adopting handle: WindowHandle, sceneID: String, title: String, size: float2, origin: float2
  ) {
    self.app = app
    self.sceneID = sceneID
    self.title = title
    self.size = size
    self.origin = origin
    self.target = Graphics2D.makeOffscreenTarget(size: size, pixelsPerPoint: app.pixelsPerPoint)
    self.state = HeadlessWindowState(persisted: "")
    self.handle = handle
    self.renderer = handle.currentRenderer!
    let scale = app.pixelsPerPoint
    handle.post { $0.resize(to: size, scale: scale) }
  }

  /// The cursor its tree asks for, as the main thread hears of it.
  func setPointerStyle(_ style: PointerStyle) {
    self.state.pointerStyle = style
  }

  func setTextInput(_ snapshot: TextInputSnapshot) {
    self.state.textInput = snapshot
  }

  /// The focused text as an input method would see it: its selection, marked text and caret.
  public var textInput: TextInputSnapshot { self.state.textInput }

  // MARK: - State

  /// The tree's root: the window-sized `Frame` its scene's root is the child of.
  public var root: Frame { self.renderer.root }
  public var context: UIContext { self.renderer.uiContext }
  public var input: Input { self.renderer.input }
  public var scene: WindowScene { self.renderer.scene }
  /// The cursor it asks for, as the view would show it.
  public var pointerStyle: PointerStyle { self.state.pointerStyle }
  /// Its scene storage as last saved: what SwiftUI would restore it from.
  public var persisted: String { self.state.persisted }
  public var isKey: Bool { self.app.keyWindow === self }

  /// Nothing animating, nothing to draw, nothing posted or sent to it.
  public var isIdle: Bool {
    guard self.isOpen else { return true }
    if self.handle.executor.hasPending { return false }
    // Hidden, its frames wait: events sent meanwhile apply in its first frame back.
    guard self.isVisible else { return true }
    return !self.handle.hasEvents && self.context.isIdle && self.renderer.graphics2D?.needsDamageFrames != true
  }

  /// Runs `body` as the window's thread: with its mailbox as the thread's executor, so a model
  /// written or subscribed to in `body` counts it as this window. Frames run this way; so should
  /// a test's code that changes the tree by hand.
  public func perform<T>(_ body: () throws -> T) rethrows -> T {
    let state = ThreadState.current
    let previous = state.executor
    state.executor = self.handle.executor
    defer { state.executor = previous }
    return try body()
  }

  /// Every element of type `T` in the tree, in pre-order, then in what shows over it — popovers,
  /// sheets, alerts — bottom first: everything the window shows.
  public func all<T: UIElement>(_ type: T.Type) -> [T] {
    var found: [T] = []
    func visit(_ element: UIElement) {
      if let match = element as? T { found.append(match) }
      element.forEachChild(visit)
    }
    visit(self.root)
    self.context.overlays.forEach(visit)
    return found
  }

  public func first<T: UIElement>(_ type: T.Type) -> T? {
    self.all(type).first
  }

  // MARK: - Frames (called by the app)

  /// What was posted to the window, then its frame, as its thread's run loop would.
  func runFrame() {
    guard self.isOpen else { return }
    self.perform {
      var turns = 0
      while self.handle.executor.runPending() {
        turns += 1
        precondition(turns < 10_000, "Work posted to \(self.sceneID) keeps posting more")
      }
      guard self.isVisible else { return }
      self.frames += 1
      let target = self.target
      let pixelsPerPoint = self.app.pixelsPerPoint
      self.renderer.runFrame { graphics, body in
        self.renders += 1
        graphics.render(into: target, pixelsPerPoint: pixelsPerPoint) { _ in body() }
      }
    }
  }

  // MARK: - Window

  /// Resizes the content to `size` points, as a user dragging its edge does, and steps.
  public func resize(to size: float2) {
    self.setContentSize(size)
    self.app.step()
  }

  /// The new size reaches the tree before its next frame, as the view's resize is posted.
  func setContentSize(_ size: float2) {
    guard size != self.size else { return }
    self.size = size
    self.target = Graphics2D.makeOffscreenTarget(size: size, pixelsPerPoint: self.app.pixelsPerPoint)
    let scale = self.app.pixelsPerPoint
    self.handle.post { $0.resize(to: size, scale: scale) }
    self.app.presentedWindows?.parentResized(self)
  }

  /// Closes it, as its close button does: its tree unmounts, and a dock window's panels close.
  public func close() {
    if let onUserClose = self.onUserClose {
      onUserClose()
    } else {
      self.close(quitting: false)
    }
  }

  /// Closes it without the user asking: the app quitting, or a dock window whose host went.
  func close(quitting: Bool) {
    guard self.isOpen else { return }
    self.isOpen = false
    self.perform { self.handle.close() }
    self.app.didClose(self)
  }

  func show() {
    guard !self.isVisible else { return }
    self.isVisible = true
    self.app.bringToFront(self)
  }

  func hide() {
    guard self.isVisible else { return }
    self.isVisible = false
    self.pointer = nil
    self.app.didHide(self)
  }

  /// Sends `event` as the view would, for the next frame. Does not step.
  public func send(_ event: InputEvent) {
    self.handle.send(event)
  }

  // MARK: - Mouse

  /// Moves the pointer to `point` and steps.
  public func move(to point: float2) {
    self.activate()
    self.sendPointer(point)
    self.app.step()
  }

  /// A press and a release at `point`, a frame each, as a real click arrives. `count` is the
  /// click's number in a run of them: 2 for the second click of a double click.
  public func click(at point: float2, count: Int = 1) {
    self.mouseDown(at: point, count: count)
    self.mouseUp(at: point)
  }

  public func doubleClick(at point: float2) {
    self.click(at: point, count: 1)
    self.click(at: point, count: 2)
  }

  public func rightClick(at point: float2) {
    if self.takeClick(at: point) {
      self.pressTaken = false
      self.app.step()
      return
    }
    self.activate()
    let (position, inView) = self.pin(point)
    self.pointer = inView ? position : nil
    self.app.screenPointer = self.origin + point
    self.send(.mouseDown(.right, position, inView: inView, clickCount: 1))
    self.app.step()
    self.send(.mouseUp(.right, position, inView: inView))
    self.app.step()
  }

  /// Lays the content out under a title bar where `insets` says, as a translucent window's view
  /// reports it. `HeadlessApp` gives its translucent scenes `.standard`.
  public func setTitleBar(_ insets: TitleBarInsets) {
    self.handle.post { $0.setTitleBar(insets) }
  }

  /// Presses on the title bar's empty parts: what would have dragged the window. The tree never
  /// hears of them.
  public private(set) var titleBarPresses = 0

  /// Whether `point` is on the title bar's empty parts, as the tree last reported them.
  public func isTitleBarDragRegion(_ point: float2) -> Bool {
    self.handle.titleBarDragRegions.contains { r in
      point.x >= r.x && point.x < r.x + r.z && point.y >= r.y && point.y < r.y + r.w
    }
  }

  /// The left button going down at `point`, and staying down until `mouseUp`. With a
  /// presentation shown from this window, the presentation takes it, as a click outside it. On
  /// the title bar's empty parts it would drag the window: counted, and not sent.
  public func mouseDown(at point: float2, count: Int = 1) {
    if self.takeClick(at: point) { return }
    if self.isTitleBarDragRegion(point) {
      self.activate()
      self.titleBarPresses += 1
      self.pressTaken = true
      self.app.step()
      return
    }
    self.activate()
    let (position, inView) = self.pin(point)
    self.pointer = inView ? position : nil
    self.app.screenPointer = self.origin + point
    self.isPressed = true
    self.app.pressedWindow = self
    self.send(.mouseDown(.left, position, inView: inView, clickCount: count))
    self.app.step()
  }

  /// Moves the pointer to `point` with the button still down. `point` may be outside the
  /// window: the press's view keeps getting the drag, wherever it goes. While a dock window is
  /// dragged, the window follows the pointer instead, as `DockWindows` moves it.
  public func mouseDrag(to point: float2) {
    if !self.app.dockDragged(to: self.origin + point) {
      self.sendPointer(point)
    }
    self.app.step()
  }

  /// The left button coming up at `point`.
  public func mouseUp(at point: float2) {
    if self.pressTaken {
      self.pressTaken = false
      self.app.step()
      return
    }
    self.app.dockReleased(at: self.origin + point)
    let (position, inView) = self.pin(point)
    self.pointer = inView ? position : nil
    self.isPressed = false
    if self.app.pressedWindow === self { self.app.pressedWindow = nil }
    self.send(.mouseUp(.left, position, inView: inView))
    self.app.step()
  }

  /// A press at `from`, `steps` moves in a straight line to `to`, a frame each, and a release
  /// there.
  public func drag(from: float2, to: float2, steps: Int = 4) {
    self.mouseDown(at: from)
    let steps = Swift.max(steps, 1)
    for step in 1 ... steps {
      self.mouseDrag(to: from + (to - from) * Float(step) / Float(steps))
    }
    self.mouseUp(at: to)
  }

  /// A press at `from`, then the pointer moving in a straight line to `screenPoint` on the app's
  /// screen, a frame each step, and a release there. For a drag that moves its own window — a
  /// dock window by its title bar — or leaves it: each point is the window's where it is then.
  public func drag(from: float2, toScreen screenPoint: float2, steps: Int = 8) {
    self.mouseDown(at: from)
    let start = self.origin + from
    let steps = Swift.max(steps, 1)
    for step in 1 ... steps {
      let point = start + (screenPoint - start) * Float(step) / Float(steps)
      self.mouseDrag(to: point - self.origin)
    }
    self.mouseUp(at: screenPoint - self.origin)
  }

  /// A scroll of `points` over `point`, as a trackpad sends it; positive y moves content down.
  public func scroll(by points: float2, at point: float2) {
    // A popover shown from here goes; the scroll still goes on, to a tree that may be blocked.
    if let top = self.app.presentation(over: self), top.presentation?.kind == .popover {
      PresentedWindows.send(.clickedOutside, to: top.handle)
    }
    self.move(to: point)
    self.send(.scroll(lines: points / 12, points: points))
    self.app.step()
  }

  /// A click on this window while a presentation shown from it is up: the presentation takes
  /// it, as a click outside it, and the window gets nothing. Whether it did.
  private func takeClick(at point: float2) -> Bool {
    guard let top = self.app.presentation(over: self) else { return false }
    self.app.screenPointer = self.origin + point
    self.pressTaken = true
    PresentedWindows.send(.clickedOutside, to: top.handle)
    self.app.step()
    return true
  }

  /// The pointer leaving the window, as the view's `mouseExited` reports it.
  public func pointerExit() {
    self.pointer = nil
    self.send(.pointerExited)
    self.app.step()
  }

  private func sendPointer(_ point: float2) {
    self.app.screenPointer = self.origin + point
    let (position, inView) = self.pin(point)
    self.pointer = inView ? position : nil
    self.send(.pointer(position, inView: inView))
  }

  /// As `RetainedLayerView.pointer(at:)`: whether `point` is over the content, and the point
  /// pinned to the content's left and bottom edges.
  private func pin(_ point: float2) -> (float2, Bool) {
    let inView = HeadlessRect(origin: .zero, size: self.size).contains(point)
    return (float2(Swift.max(point.x, 0), Swift.min(point.y, self.size.y)), inView)
  }

  private func activate() {
    if !self.isVisible { self.show() }
    // What a presentation over it shows keeps the keyboard, as AppKit's sheets and modal
    // windows do.
    guard self.app.presentation(over: self)?.presentation?.isModal != true else { return }
    self.app.makeKey(self)
  }

  // MARK: - Keys

  /// A key going down and up in one frame. `characters` defaults to the key's own, uppercased
  /// with shift. With command, as AppKit sends it, no key-up comes: releasing command is the
  /// last event.
  public func press(
    _ key: KeyEquivalent, characters: String? = nil, modifiers: NSEvent.ModifierFlags = []
  ) {
    // To the key window: the presentation shown over this one, when there is one.
    if let top = self.app.topPresentation(over: self) {
      top.press(key, characters: characters, modifiers: modifiers)
      return
    }
    self.activate()
    self.sendPress(key, characters: characters, modifiers: modifiers, pasteboard: nil)
    self.app.step()
  }

  /// Types `text` a character at a time, a frame each. "\n" is Return.
  public func type(_ text: String) {
    for character in text {
      let isUpper = character.isUppercase
      let key = KeyEquivalent(character == "\n" ? "\r" : Character(character.lowercased()))
      self.press(key, characters: String(character == "\n" ? "\r" : character), modifiers: isUpper ? .shift : [])
    }
  }

  /// An input method's composition so far, as a Japanese or Chinese one sends it while keys
  /// are typed: `text` marked, the input method's selection `selected` in it (its end when nil).
  public func compose(_ text: String, selected: NSRange? = nil) {
    let selected = selected ?? NSRange(location: text.utf16.count, length: 0)
    self.sendText(.setMarked(text, selected: selected, replacement: nil))
  }

  /// An input method committing `text`: in place of what is composed, or at the selection.
  public func commit(_ text: String) {
    self.sendText(.insert(text, replacement: nil))
  }

  private var textSequence: UInt64 = 0

  private func sendText(_ action: TextInputAction) {
    if let top = self.app.topPresentation(over: self) {
      top.sendText(action)
      return
    }
    self.activate()
    self.textSequence &+= 1
    self.send(.textInput([action], sequence: self.textSequence, revision: self.state.textInput.revision))
    self.app.step()
  }

  /// ⌘V with `text` on the pasteboard, as the view reads it with the key.
  public func paste(_ text: String) {
    if let top = self.app.topPresentation(over: self) {
      top.paste(text)
      return
    }
    self.activate()
    self.sendPress("v", characters: "v", modifiers: .command, pasteboard: text)
    self.app.step()
  }

  private func sendPress(_ key: KeyEquivalent, characters: String?, modifiers: NSEvent.ModifierFlags, pasteboard: String?) {
    let shifted = modifiers.contains(.shift)
    let own = shifted ? String(key.character).uppercased() : String(key.character)
    let event = InputEvent.Key(
      keyCode: Self.keyCode(for: key), characters: characters ?? own, charactersIgnoringModifiers: own,
      modifiers: modifiers, pasteboard: pasteboard
    )
    var held: NSEvent.ModifierFlags = []
    for (flag, code) in Self.modifierKeys where modifiers.contains(flag) {
      held.insert(flag)
      self.send(.flagsChanged(keyCode: code, flags: held))
    }
    self.send(.keyDown(event))
    if !modifiers.contains(.command) {
      self.send(.keyUp(event))
    }
    for (flag, code) in Self.modifierKeys.reversed() where modifiers.contains(flag) {
      held.remove(flag)
      self.send(.flagsChanged(keyCode: code, flags: held))
    }
  }

  private static let modifierKeys: [(NSEvent.ModifierFlags, UInt16)] = [
    (.command, UInt16(kVK_Command)), (.shift, UInt16(kVK_Shift)),
    (.option, UInt16(kVK_Option)), (.control, UInt16(kVK_Control)),
  ]

  /// The virtual key code of the key that types `key` on a US keyboard; one no key has for any
  /// other character.
  static func keyCode(for key: KeyEquivalent) -> UInt16 {
    Self.keyCodes[key.character] ?? UInt16.max
  }

  private static let keyCodes: [Character: UInt16] = {
    var codes: [Character: Int] = [
      "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D, "e": kVK_ANSI_E,
      "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H, "i": kVK_ANSI_I, "j": kVK_ANSI_J,
      "k": kVK_ANSI_K, "l": kVK_ANSI_L, "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O,
      "p": kVK_ANSI_P, "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
      "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X, "y": kVK_ANSI_Y,
      "z": kVK_ANSI_Z,
      "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3, "4": kVK_ANSI_4, "5": kVK_ANSI_5,
      "6": kVK_ANSI_6, "7": kVK_ANSI_7, "8": kVK_ANSI_8, "9": kVK_ANSI_9, "0": kVK_ANSI_0,
      "-": kVK_ANSI_Minus, "=": kVK_ANSI_Equal, "[": kVK_ANSI_LeftBracket, "]": kVK_ANSI_RightBracket,
      ";": kVK_ANSI_Semicolon, "'": kVK_ANSI_Quote, ",": kVK_ANSI_Comma, ".": kVK_ANSI_Period,
      "/": kVK_ANSI_Slash, "\\": kVK_ANSI_Backslash, "`": kVK_ANSI_Grave,
      " ": kVK_Space, "\r": kVK_Return, "\t": kVK_Tab, "\u{7F}": kVK_Delete, "\u{1B}": kVK_Escape,
    ]
    codes[KeyEquivalent.upArrow.character] = kVK_UpArrow
    codes[KeyEquivalent.downArrow.character] = kVK_DownArrow
    codes[KeyEquivalent.leftArrow.character] = kVK_LeftArrow
    codes[KeyEquivalent.rightArrow.character] = kVK_RightArrow
    codes[KeyEquivalent.home.character] = kVK_Home
    codes[KeyEquivalent.end.character] = kVK_End
    codes[KeyEquivalent.pageUp.character] = kVK_PageUp
    codes[KeyEquivalent.pageDown.character] = kVK_PageDown
    codes[KeyEquivalent.deleteForward.character] = kVK_ForwardDelete
    return codes.mapValues { UInt16($0) }
  }()

  // MARK: - Pixels

  /// The last frame drawn. Steps first if something is waiting to be drawn.
  public func snapshot() -> CGImage {
    let pixels = self.readPixels()
    return Self.image(width: pixels.width, height: pixels.height, bgra: pixels.bgra)
  }

  /// The part of the last frame inside `rect` (points), clamped to the window: a golden of one
  /// element, free of whatever else the window shows.
  public func snapshot(of rect: HeadlessRect) -> CGImage {
    let image = self.snapshot()
    let scale = CGFloat(self.app.pixelsPerPoint)
    let crop = CGRect(
      x: CGFloat(rect.origin.x) * scale, y: CGFloat(rect.origin.y) * scale,
      width: CGFloat(rect.size.x) * scale, height: CGFloat(rect.size.y) * scale
    ).integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return image.cropping(to: crop) ?? image
  }

  /// The part of the last frame around `element`'s rects (its own and its descendants'), grown
  /// by `margin` on each side for a padding or a shadow; the whole frame when it has none.
  public func snapshot(of element: UIElement, margin: Float = 0) -> CGImage {
    if self.context.needsRender { self.app.step(0) }
    guard let frame = HeadlessQuery.bounds(of: element) else { return self.snapshot() }
    return self.snapshot(of: HeadlessRect(origin: frame.origin - margin, size: frame.size + margin * 2))
  }

  /// The colour at `point` (points) in the last frame drawn, RGBA 0...255.
  public func pixel(at point: float2) -> SIMD4<UInt8> {
    let pixels = self.readPixels()
    let scale = self.app.pixelsPerPoint
    let x = Swift.min(pixels.width - 1, Int(point.x * scale))
    let y = Swift.min(pixels.height - 1, Int(point.y * scale))
    let i = (y * pixels.width + x) * 4
    return SIMD4(pixels.bgra[i + 2], pixels.bgra[i + 1], pixels.bgra[i], pixels.bgra[i + 3])
  }

  private func readPixels() -> (width: Int, height: Int, bgra: [UInt8]) {
    if self.context.needsRender { self.app.step(0) }
    guard let graphics = self.renderer.graphics2D else {
      preconditionFailure("\(self.sceneID) is closed: it has nothing to read")
    }
    return graphics.readPixels(self.target)
  }

  /// A BGRA byte buffer as an opaque image; `compute2D` leaves alpha to the layer.
  public static func image(width: Int, height: Int, bgra: [UInt8]) -> CGImage {
    let data = CFDataCreate(nil, bgra, bgra.count)!
    return CGImage(
      width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue),
      provider: CGDataProvider(data: data)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent
    )!
  }
}

/// What a headless window's tree reports to the main thread: written from the window's
/// callbacks, which here run on the same thread.
final class HeadlessWindowState: @unchecked Sendable {
  var persisted: String
  var pointerStyle = PointerStyle.default
  var textInput = TextInputSnapshot.inactive

  init(persisted: String) {
    self.persisted = persisted
  }
}
