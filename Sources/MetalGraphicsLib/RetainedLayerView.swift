import GameController
import MetalKit

/// A window's content: the `CAMetalLayer` the window's thread draws into, and the AppKit end of
/// the window — its events, size, key status, cursor and input methods — on the main thread.
///
/// Nothing here touches the window's tree. Events go to the window's thread as `InputEvent`s,
/// which carry no AppKit object; a resize or an occlusion change is posted to it; the cursor the
/// tree asks for comes back as `pointerStyle`.
public final class RetainedLayerView: NSView {
  public let handle: WindowHandle
  public let metalLayer = CAMetalLayer()
  /// What the window's frame looks like; a translucent one is set up once the view is in it.
  public let chrome: WindowChrome
  /// The system's blur of the desktop behind a translucent window.
  private weak var effectView: NSVisualEffectView?
  /// Which blur a translucent window gets, and how round its corners are: a popover's window
  /// takes `.popover`, rounded as its card.
  var effectMaterial: NSVisualEffectView.Material = .sidebar
  var effectCornerRadius: CGFloat = 0
  /// What was last sent to the window's thread.
  private var sentSize = float2(-1, -1)
  private var sentScale: Float = 0
  private var sentTitleBar = TitleBarInsets.zero

  /// `background` is what shows before the first frame is drawn: what the content is drawn on.
  public init(handle: WindowHandle, background: CGColor? = nil, chrome: WindowChrome = .standard) {
    self.handle = handle
    self.chrome = chrome
    super.init(frame: .zero)
    self.metalLayer.device = GPUDevice.main
    self.metalLayer.pixelFormat = .bgra8Unorm
    // The frames are sRGB, as the colours they are drawn from: tagged, so a wide-gamut display
    // shows them as they are, beside AppKit's.
    self.metalLayer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
    // The frame copies its canvas into the drawable with a blit.
    self.metalLayer.framebufferOnly = false
    // A resize shows at once, before the window's thread draws the new size: the last frame
    // stays pinned to the top left rather than stretching, over the colour frames clear to.
    self.metalLayer.contentsGravity = .topLeft
    if chrome == .translucent {
      // Premultiplied frames over whatever is behind: the system's blur of the desktop.
      self.metalLayer.isOpaque = false
      self.metalLayer.backgroundColor = CGColor(gray: 0, alpha: 0)
    } else {
      self.metalLayer.backgroundColor = background ?? CGColor(srgbRed: 0.93, green: 0.93, blue: 0.94, alpha: 1)
    }
    self.wantsLayer = true
    self.layerContentsPlacement = .topLeft
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override public func makeBackingLayer() -> CALayer {
    self.metalLayer
  }

  // Top left origin, as the window's tree lays out.
  override public var isFlipped: Bool {
    true
  }

  // to handle key events
  override public var acceptsFirstResponder: Bool {
    true
  }

  /// Hands `event` to the window's thread, for its next frame.
  func send(_ event: InputEvent) {
    self.handle.send(event)
  }

  // MARK: - Size

  override public func setFrameSize(_ newSize: NSSize) {
    super.setFrameSize(newSize)
    self.sendSize()
    self.sendTitleBar()
  }

  /// A press on the content never moves the window: the tree says where the title bar is
  /// empty, and `mouseDown` drags the window from there itself.
  override public var mouseDownCanMoveWindow: Bool {
    false
  }

  /// Where a translucent window's title bar lies over the content, sent when it changes.
  func sendTitleBar() {
    guard self.chrome == .translucent, let window = self.window else { return }
    var insets = TitleBarInsets.zero
    // Only where the content runs under the title bar: a detached dock window in the native
    // look has a title bar of its own above it.
    let mask = window.styleMask
    if !mask.contains(.fullScreen), mask.contains(.titled), mask.contains(.fullSizeContentView) {
      let top = window.frame.height - window.contentLayoutRect.maxY
      var leading: CGFloat = 0
      for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
        guard let button = window.standardWindowButton(kind), !button.isHidden else { continue }
        leading = max(leading, button.convert(button.bounds, to: nil).maxX)
      }
      // Without traffic lights the content draws a title bar of its own: a detached dock
      // window in the custom look.
      if leading > 0 {
        insets = TitleBarInsets(top: Float(max(top, 0)), leading: Float(leading) + 12)
      }
    }
    guard insets != self.sentTitleBar else { return }
    self.sentTitleBar = insets
    let sent = insets
    self.handle.post { $0.setTitleBar(sent) }
  }

  /// A press on the empty title bar the tree reported: drags the window, or on a double click
  /// does what the system does there. True when it was one.
  private func pressTitleBar(_ event: NSEvent) -> Bool {
    guard self.chrome == .translucent, let window = self.window else { return false }
    let point = self.convert(event.locationInWindow, from: nil)
    let x = Float(point.x), y = Float(point.y)
    let hit = self.handle.titleBarDragRegions.contains { r in x >= r.x && x < r.x + r.z && y >= r.y && y < r.y + r.w }
    guard hit else { return false }
    if event.clickCount == 2 {
      switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
      case "Minimize": window.miniaturize(nil)
      case "None": break
      default: window.zoom(nil)
      }
    } else {
      window.performDrag(with: event)
    }
    return true
  }

  override public func viewDidChangeBackingProperties() {
    super.viewDidChangeBackingProperties()
    self.sendSize()
  }

  /// The layer takes the window's scale here; the window's thread sizes its drawable to match.
  private func sendSize() {
    let scale = Float(self.window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2)
    self.metalLayer.contentsScale = CGFloat(scale)
    let size = float2(Float(self.bounds.width), Float(self.bounds.height))
    guard size != self.sentSize || scale != self.sentScale else { return }
    self.sentSize = size
    self.sentScale = scale
    self.handle.post { $0.resize(to: size, scale: scale) }
  }

  override public func keyDown(with event: NSEvent) {
    // The window handles ⌘V off the main thread, where the pasteboard can't be read: it is read
    // here, with the key.
    let isPaste = event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "v"
    var key = Self.key(event, pasteboard: isPaste ? NSPasteboard.general.string(forType: .string) : nil)
    // Focused text takes the key through the input method, which calls back into this view, at
    // once, with what it makes of the key. Command keys are shortcuts, and go past it.
    if self.textInput.isActive, !event.modifierFlags.contains(.command), let context = self.inputContext {
      self.collected = []
      _ = context.handleEvent(event)
      let actions = self.collected ?? []
      self.collected = nil
      self.textSequence &+= 1
      key.textActions = actions
      key.textSequence = self.textSequence
      key.textRevision = self.textInput.revision
    }
    self.send(.keyDown(key))
  }

  // MARK: - Input methods

  /// The focused text as the window's thread last published it, moved on by what this view has
  /// sent since: what the input method's questions are answered from, at once.
  private(set) var textInput = TextInputSnapshot.inactive
  /// Batches of text actions sent to the window's thread, counted.
  private var textSequence: UInt64 = 0
  /// Set while the input method handles a key: what it asks for is collected, and goes with the
  /// key.
  private var collected: [TextInputAction]? = nil

  /// The window's thread published its focused text.
  func textInputChanged(_ snapshot: TextInputSnapshot) {
    // From before what this view last sent: its own copy is ahead.
    guard snapshot.appliedSequence >= self.textSequence else { return }
    let wasComposing = self.textInput.marked != nil
    let wasActive = self.textInput.isActive
    self.textInput = snapshot
    guard let context = self.inputContext ?? (wasActive ? super.inputContext : nil) else { return }
    if wasComposing && snapshot.marked == nil {
      // The composition ended over there: a click elsewhere, focus moving, an edit refused.
      context.discardMarkedText()
    }
    context.invalidateCharacterCoordinates()
  }

  override public var inputContext: NSTextInputContext? {
    self.textInput.isActive ? super.inputContext : nil
  }

  /// Collects `action` while a key is handled; sends it on its own otherwise.
  private func textAction(_ action: TextInputAction) {
    self.textInput = self.textInput.applying(action)
    if self.collected != nil {
      self.collected!.append(action)
    } else {
      self.textSequence &+= 1
      self.send(.textInput([action], sequence: self.textSequence, revision: self.textInput.revision))
    }
  }

  override public func keyUp(with event: NSEvent) {
    self.send(.keyUp(Self.key(event)))
  }

  private static func key(_ event: NSEvent, pasteboard: String? = nil) -> InputEvent.Key {
    InputEvent.Key(
      keyCode: event.keyCode, characters: event.characters,
      charactersIgnoringModifiers: event.charactersIgnoringModifiers,
      modifiers: event.modifierFlags, isRepeat: event.isARepeat, pasteboard: pasteboard
    )
  }

  // Modifiers send no key events, only this, with the flags as they are after the change.
  override public func flagsChanged(with event: NSEvent) {
    self.send(.flagsChanged(keyCode: event.keyCode, flags: event.modifierFlags))
  }

  override public func magnify(with event: NSEvent) {
    self.send(.magnify(Float(event.magnification)))
  }

  override public func rotate(with event: NSEvent) {
    self.send(.rotate(Float(event.rotation)))
  }

  override public func scrollWheel(with event: NSEvent) {
    // A wheel reports lines; a trackpad or Magic Mouse points.
    let pointsPerLine: Float = event.hasPreciseScrollingDeltas ? 1 : 12
    self.send(.scroll(
      lines: float2(Float(event.deltaX), Float(event.deltaY)),
      points: float2(Float(event.scrollingDeltaX), Float(event.scrollingDeltaY)) * pointsPerLine
    ))
  }

  override public func mouseDragged(with event: NSEvent) {
    // A dock window being dragged follows the pointer; the press's own view has nothing to do.
    if DockWindows.dragged() { return }
    self.sendPointer(event)
  }

  override public func mouseMoved(with event: NSEvent) {
    self.sendPointer(event)
  }

  override public func rightMouseDragged(with event: NSEvent) {
    self.sendPointer(event)
  }

  override public func mouseEntered(with event: NSEvent) {
    self.sendPointer(event)
  }

  // Leaving the view sends no `mouseMoved`, so the last position inside would stay current and
  // a hover under it would never end.
  override public func mouseExited(with event: NSEvent) {
    self.isPointerInView = false
    self.send(.pointerExited)
    NSCursor.arrow.set()
  }

  override public func mouseDown(with event: NSEvent) {
    if self.pressTitleBar(event) { return }
    let (position, inView) = self.pointer(at: event.locationInWindow)
    self.send(.mouseDown(.left, position, inView: inView, clickCount: event.clickCount))
  }

  override public func mouseUp(with event: NSEvent) {
    DockWindows.released()
    let (position, inView) = self.pointer(at: event.locationInWindow)
    self.send(.mouseUp(.left, position, inView: inView))
  }

  override public func rightMouseDown(with event: NSEvent) {
    let (position, inView) = self.pointer(at: event.locationInWindow)
    self.send(.mouseDown(.right, position, inView: inView, clickCount: event.clickCount))
  }

  override public func rightMouseUp(with event: NSEvent) {
    let (position, inView) = self.pointer(at: event.locationInWindow)
    self.send(.mouseUp(.right, position, inView: inView))
  }

  private func sendPointer(_ event: NSEvent) {
    let (position, inView) = self.pointer(at: event.locationInWindow)
    self.send(.pointer(position, inView: inView))
  }

  /// Whether the pointer is over the view, as the main thread last saw it: what the cursor goes
  /// by. `input` keeps its own, for the frame.
  private var isPointerInView = false

  /// `locationInWindow` in the view's points from its top left, pinned to the view's left and
  /// bottom edges, and whether it is over the view. A drag goes on outside the view, and still reports
  /// where it is.
  func pointer(at locationInWindow: NSPoint) -> (float2, Bool) {
    let position = self.convert(locationInWindow, from: nil)
    let inView = self.bounds.contains(position)
    self.isPointerInView = inView
    let x = Float(max(position.x, 0))
    let y = Float(min(position.y, self.bounds.height))
    return (float2(x, y), inView)
  }

  override public func updateTrackingAreas() {
    for item in trackingAreas {
      removeTrackingArea(item)
    }

    // The visible rect, in the view's own coordinates, kept up to date by AppKit.
    addTrackingArea(
      NSTrackingArea(
        rect: .zero,
        options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .cursorUpdate, .inVisibleRect],
        owner: self
      )
    )
  }

  // MARK: - Title bar presses

  /// Watches presses in the window, for `titleBarPress(_:)`.
  private var titleBarMonitor: Any?
  /// A press in the title bar's strip went to the tree: its drags and its release follow it.
  private var tracksTitleBarPress = false

  /// In a translucent window AppKit's title bar lies over the top of the content and takes the
  /// presses there, as a drag of the window. The tree draws its own bar in that row — tabs, a
  /// toolbar — so its presses are handed to it here, away from the traffic lights; the parts the
  /// tree says are empty still drag the window (`pressTitleBar`).
  private func claimTitleBarPresses() {
    self.titleBarMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) {
      [weak self] event in
      // Monitors run on the main thread, with the event.
      nonisolated(unsafe) let pressed = event
      let taken = MainActor.assumeIsolated { self?.takesTitleBarPress(pressed) ?? false }
      return taken ? nil : event
    }
  }

  /// Whether this view took `event`.
  private func takesTitleBarPress(_ event: NSEvent) -> Bool {
    guard event.window === self.window, self.window != nil else { return false }
    switch event.type {
    case .leftMouseDown:
      let point = self.convert(event.locationInWindow, from: nil)
      let strip = self.sentTitleBar
      guard strip.top > 0, self.bounds.contains(point), point.y < CGFloat(strip.top), point.x >= CGFloat(strip.leading) else {
        return false
      }
      self.tracksTitleBarPress = true
      self.mouseDown(with: event)
      return true
    case .leftMouseDragged where self.tracksTitleBarPress:
      self.mouseDragged(with: event)
      return true
    case .leftMouseUp where self.tracksTitleBarPress:
      self.tracksTitleBarPress = false
      self.mouseUp(with: event)
      return true
    default:
      return false
    }
  }

  // MARK: - Window status

  private var windowObservers: [NSObjectProtocol] = []

  override public func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    for observer in self.windowObservers {
      NotificationCenter.default.removeObserver(observer)
    }
    self.windowObservers.removeAll()
    if let monitor = self.titleBarMonitor {
      NSEvent.removeMonitor(monitor)
      self.titleBarMonitor = nil
    }
    guard let window = self.window else { return }
    if self.chrome == .translucent {
      self.makeTranslucent(window)
      self.claimTitleBarPresses()
    }

    let center = NotificationCenter.default
    let observe = { (name: Notification.Name, handler: @escaping @MainActor (RetainedLayerView) -> Void) in
      self.windowObservers.append(
        center.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
          MainActor.assumeIsolated {
            guard let self else { return }
            handler(self)
          }
        }
      )
    }
    observe(NSWindow.didResignKeyNotification) { $0.windowDidResignKey() }
    observe(NSWindow.didBecomeKeyNotification) { $0.windowDidBecomeKey() }
    observe(NSWindow.didChangeOcclusionStateNotification) { $0.windowOcclusionDidChange() }
    observe(NSWindow.didEnterFullScreenNotification) { $0.sendTitleBar() }
    observe(NSWindow.didExitFullScreenNotification) { $0.sendTitleBar() }

    // Occlusion is left to its notification: a window not yet on screen reads as occluded.
    if !window.isKeyWindow {
      self.send(.resignKey)
    }
    self.sendSize()
    self.sendTitleBar()
    // After SwiftUI has set the window up: it would otherwise keep the keyboard until a click.
    DispatchQueue.main.async { [weak self] in self?.claimKeyboard() }
  }

  /// Lets the desktop through `window`, blurred: a transparent title bar over a system blur that
  /// fills the window, under the content. One blur for the whole window; the tree tints it, per
  /// region, as it draws (`ThemeColor.sidebarTint`, `.barTint`), so nothing of AppKit's has to
  /// follow the tree's layout.
  private func makeTranslucent(_ window: NSWindow) {
    window.styleMask.insert(.fullSizeContentView)
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.isOpaque = false
    window.backgroundColor = .clear
    guard self.effectView == nil, let content = window.contentView, let frame = content.superview else { return }
    let effect = NSVisualEffectView(frame: frame.bounds)
    effect.material = self.effectMaterial
    if self.effectCornerRadius > 0 {
      effect.wantsLayer = true
      effect.layer?.cornerRadius = self.effectCornerRadius
      effect.layer?.masksToBounds = true
    }
    effect.blendingMode = .behindWindow
    effect.state = .followsWindowActiveState
    effect.autoresizingMask = [.width, .height]
    frame.addSubview(effect, positioned: .below, relativeTo: content)
    self.effectView = effect
  }

  /// Becomes the window's first responder when nothing else in it is: the window itself or a
  /// view around this one (SwiftUI's hosting view) has the keyboard. Without, a tree whose
  /// element took focus as it was built — a document's editor — gets no keys until the first
  /// click. A text view or control of the window's own keeps it.
  private func claimKeyboard() {
    guard let window = self.window, let responder = window.firstResponder, responder !== self else { return }
    let isAround = (responder as? NSView).map { self.isDescendant(of: $0) } ?? false
    if responder === window || isAround {
      window.makeFirstResponder(self)
    }
  }

  /// Another window took the keyboard and the pointer; `input` releases what is held. Not the
  /// cursor: it belongs to the window that is key now.
  func windowDidResignKey() {
    self.isPointerInView = false
    self.send(.resignKey)
  }

  /// A window made key under a still pointer gets no `mouseEntered`, so the pointer is read here.
  func windowDidBecomeKey() {
    guard let window = self.window else { return }
    self.claimKeyboard()
    let location = window.mouseLocationOutsideOfEventStream
    let (position, inView) = self.pointer(at: location)
    self.send(.becomeKey(pointer: inView ? position : nil))
    if inView {
      Self.cursor(for: self.pointerStyle).set()
    }
  }

  /// A hidden window (minimized, fully covered, on another Space) stops drawing. Invalidations
  /// made meanwhile — a shared model written from another window — stay pending, and its first
  /// frame back draws them.
  private func windowOcclusionDidChange() {
    guard let window = self.window else { return }
    let occluded = !window.occlusionState.contains(.visible)
    self.handle.post { $0.setOccluded(occluded) }
  }

  // MARK: - Pointer style

  /// The cursor over the view: `UIContext.pointerStyle`, sent by the window's thread when it
  /// changes, and applied only while the pointer is over the view, so another view keeps its own.
  public var pointerStyle: PointerStyle = .default {
    didSet {
      guard self.pointerStyle != oldValue else { return }
      if Self.logsCursor {
        print("[cursor] \(self.pointerStyle)")
      }
      // The cursor is the whole app's: a window in the background, still animating under a
      // pointer it last saw, must not change it over the key window.
      if self.isPointerInView, self.window?.isKeyWindow == true {
        Self.cursor(for: self.pointerStyle).set()
      }
    }
  }

  /// `MG_LOG_CURSOR=1` prints each change of cursor, for checking it from outside the app.
  private static let logsCursor = ProcessInfo.processInfo.environment["MG_LOG_CURSOR"] != nil

  // AppKit sets the arrow back when the pointer comes into the view; this is where it asks.
  override public func cursorUpdate(with event: NSEvent) {
    Self.cursor(for: self.pointerStyle).set()
  }

  static func cursor(for style: PointerStyle) -> NSCursor {
    switch style.kind {
    case .default: return .arrow
    case .link: return .pointingHand
    case .horizontalText: return .iBeam
    case .verticalText: return .iBeamCursorForVerticalLayout
    case .rectSelection: return .crosshair
    case .grabIdle: return .openHand
    case .grabActive: return .closedHand
    case .zoomIn: return .zoomIn
    case .zoomOut: return .zoomOut
    case .columnResize(let directions):
      var horizontal: NSHorizontalDirection.Set = []
      if directions.contains(.leading) { horizontal.insert(.left) }
      if directions.contains(.trailing) { horizontal.insert(.right) }
      return .columnResize(directions: horizontal)
    case .rowResize(let directions):
      var vertical: NSVerticalDirection.Set = []
      if directions.contains(.up) { vertical.insert(.up) }
      if directions.contains(.down) { vertical.insert(.down) }
      return .rowResize(directions: vertical)
    case .frameResize(let position, let directions):
      var set: NSCursor.FrameResizeDirection.Set = []
      if directions.contains(.inward) { set.insert(.inward) }
      if directions.contains(.outward) { set.insert(.outward) }
      let edge: NSCursor.FrameResizePosition = switch position {
      case .top: .top
      case .leading: .left
      case .bottom: .bottom
      case .trailing: .right
      case .topLeading: .topLeft
      case .topTrailing: .topRight
      case .bottomLeading: .bottomLeft
      case .bottomTrailing: .bottomRight
      }
      return .frameResize(position: edge, directions: set)
    }
  }
}


// MARK: - NSTextInputClient

/// Input methods ask synchronously, on the main thread, about text that lives on the window's
/// thread. They are answered from `textInput`, the last snapshot that thread published, moved on
/// by what this view sent since; what they ask for is sent there as `TextInputAction`s.
extension RetainedLayerView: @preconcurrency NSTextInputClient {
  public func insertText(_ string: Any, replacementRange: NSRange) {
    let text = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
    self.textAction(.insert(text, replacement: replacementRange.location == NSNotFound ? nil : replacementRange))
  }

  public func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
    let text = (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
    self.textAction(.setMarked(
      text, selected: selectedRange, replacement: replacementRange.location == NSNotFound ? nil : replacementRange
    ))
  }

  public func unmarkText() {
    self.textAction(.unmark)
  }

  override public func doCommand(by selector: Selector) {
    self.textAction(.command(NSStringFromSelector(selector)))
  }

  public func selectedRange() -> NSRange {
    self.textInput.selection
  }

  public func markedRange() -> NSRange {
    self.textInput.marked ?? NSRange(location: NSNotFound, length: 0)
  }

  public func hasMarkedText() -> Bool {
    self.textInput.marked != nil
  }

  public func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
    guard let (text, covered) = self.textInput.substring(range) else { return nil }
    actualRange?.pointee = covered
    return NSAttributedString(string: text)
  }

  public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
    []
  }

  public func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
    actualRange?.pointee = range
    guard let window = self.window else { return .zero }
    return window.convertToScreen(self.convert(self.textInput.caretRect, to: nil))
  }

  public func characterIndex(for point: NSPoint) -> Int {
    NSNotFound
  }
}
