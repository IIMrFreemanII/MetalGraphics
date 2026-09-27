import GameController
import MetalKit

/// A window's content: the `CAMetalLayer` the window's thread draws into, and the AppKit end of
/// the window — its events, size, key status and cursor — on the main thread.
///
/// Nothing here touches the window's tree. Events go to the window's thread as `InputEvent`s,
/// which carry no AppKit object; a resize or an occlusion change is posted to it; the cursor the
/// tree asks for comes back as `pointerStyle`.
public final class RetainedLayerView: NSView {
  public let handle: WindowHandle
  public let metalLayer = CAMetalLayer()
  /// What was last sent to the window's thread.
  private var sentSize = float2(-1, -1)
  private var sentScale: Float = 0

  /// `background` is what shows before the first frame is drawn: what the content is drawn on.
  public init(handle: WindowHandle, background: CGColor? = nil) {
    self.handle = handle
    super.init(frame: .zero)
    self.metalLayer.device = GPUDevice.main
    self.metalLayer.pixelFormat = .bgra8Unorm
    // The frame copies its canvas into the drawable with a blit.
    self.metalLayer.framebufferOnly = false
    // A resize shows at once, before the window's thread draws the new size: the last frame
    // stays pinned to the top left rather than stretching, over the colour frames clear to.
    self.metalLayer.contentsGravity = .topLeft
    self.metalLayer.backgroundColor = background ?? CGColor(srgbRed: 0.93, green: 0.97, blue: 1, alpha: 1)
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
    self.send(.keyDown(Self.key(event, pasteboard: isPaste ? NSPasteboard.general.string(forType: .string) : nil)))
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

  // MARK: - Window status

  private var windowObservers: [NSObjectProtocol] = []

  override public func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    for observer in self.windowObservers {
      NotificationCenter.default.removeObserver(observer)
    }
    self.windowObservers.removeAll()
    guard let window = self.window else { return }

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

    // Occlusion is left to its notification: a window not yet on screen reads as occluded.
    if !window.isKeyWindow {
      self.send(.resignKey)
    }
    self.sendSize()
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
