import AppKit
import simd

/// The windows of a `DockSpace`'s detached hosts, on the main thread: opens one for each such
/// host, closes it when the host goes, and drags one around when an area asks.
///
///     DockWindows.manage(.workspace)   // once, at launch
///
/// A detached window shows while an area of the space's own — one placed by the app, such as a
/// workspace window's — is shown, and hides while none is: closing the workspace window hides
/// its panels' windows, and reopening it, or relaunching, brings them back where they were.
///
/// **Dragging a window.** An area asks for it (`DockWindowRequest.drag`/`.tearOut`) when the
/// pointer drags a float out of its window, or drags what a detached window holds. The press is
/// still the view's that took the mouse down — AppKit keeps sending it the drags, wherever the
/// pointer goes — so the main thread moves the window on each of them, with no thread in
/// between. It finds the dock area under the pointer in the window below, and has that area's
/// thread show where a drop would dock; on release, that area docks the dragged host, and its
/// window closes as the host goes. Let go anywhere else, the window stays where it is.
@MainActor public enum DockWindows {
  private final class Managed {
    let space: DockSpace
    var windows: [String: DockWindow] = [:]
    var observer: DockSpaceObserver?

    init(space: DockSpace) {
      self.space = space
    }
  }

  private struct Drag {
    let space: DockSpace
    let host: String
    let window: DockWindow
    /// Where the pointer holds the window's content, from its top left.
    let grab: float2
    /// The area under the pointer, told where it is.
    var target: (host: String, point: float2)?
  }

  private static var managed: [ObjectIdentifier: Managed] = [:]
  private static var drag: Drag?
  private static var observesWindows = false

  /// Opens and closes `space`'s detached windows from now on. Once per space; more calls do
  /// nothing.
  public static func manage(_ space: DockSpace) {
    let key = ObjectIdentifier(space)
    guard managed[key] == nil else { return }
    let entry = Managed(space: space)
    managed[key] = entry
    let observer = DockSpaceObserver { reconcile(space) }
    entry.observer = observer
    space.observers.add(observer, token: 0)
    space.setWindowHandlers(
      requests: { request in
        DispatchQueue.main.async { MainActor.assumeIsolated { handle(request, in: space) } }
      },
      areasChanged: {
        DispatchQueue.main.async { MainActor.assumeIsolated { reconcile(space) } }
      }
    )
    reconcile(space)
    observeWindows()
  }

  /// A window the app placed an area in may close without its tree going: SwiftUI keeps a
  /// single `Window`'s content, and only orders it out. What shows is what counts, so its
  /// panels' windows follow it as it closes, reopens, minimises and comes back.
  private static func observeWindows() {
    guard !observesWindows else { return }
    observesWindows = true
    let center = NotificationCenter.default
    center.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: .main) { note in
      let closing = note.object as? NSWindow
      MainActor.assumeIsolated { reconcileAll(closing: closing) }
    }
    for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
                 NSWindow.didDeminiaturizeNotification] {
      center.addObserver(forName: name, object: nil, queue: .main) { _ in
        MainActor.assumeIsolated { reconcileAll(closing: nil) }
      }
    }
  }

  private static func reconcileAll(closing: NSWindow?) {
    // A panel window of its own closing is handled by its delegate.
    guard !(closing is DockWindow) else { return }
    for entry in managed.values {
      reconcile(entry.space, closing: closing)
    }
  }

  /// Opens, shows, hides, restyles and closes windows to match the layout.
  static func reconcile(_ space: DockSpace, closing: NSWindow? = nil) {
    guard let entry = managed[ObjectIdentifier(space)] else { return }
    let layout = space.layout
    let shown = space.shownAreas()
    // An area the app placed, in a window on screen.
    let visible = shown.contains { area in
      guard layout.host(area.host)?.isDetached != true else { return false }
      guard let handle = area.window else { return true }
      guard let window = WindowRegistry.view(for: handle)?.window else { return false }
      return window !== closing && window.isVisible && !window.isMiniaturized
    }

    for host in layout.hosts where host.isDetached {
      let window = entry.windows[host.id] ?? makeWindow(for: host.id, in: space, style: layout.windowStyle)
      entry.windows[host.id] = window
      window.apply(layout.windowStyle)
      window.title = layout.title(ofHost: host.id)
      if let frame = host.screenFrame, !window.isPlaced {
        window.setFrame(NSRect(frame), display: false)
        window.isPlaced = true
      }
      let dragged = drag?.window === window
      if visible && window.isPlaced && !window.isVisible && !dragged {
        window.orderFront(nil)
      } else if !visible && window.isVisible {
        window.orderOut(nil)
      }
    }
    for (id, window) in entry.windows where layout.host(id)?.isDetached != true {
      entry.windows[id] = nil
      if drag?.window === window { drag = nil }
      window.close()
    }
  }

  private static func makeWindow(for host: String, in space: DockSpace, style: DockWindowStyle) -> DockWindow {
    let (view, handle) = RetainedWindowContent.make(sceneID: "dock") { _ in DockArea(space, host: host) }
    let window = DockWindow(space: space, host: host, handle: handle)
    window.contentView = view
    window.apply(style)
    return window
  }

  private static func handle(_ request: DockWindowRequest, in space: DockSpace) {
    guard let entry = managed[ObjectIdentifier(space)] else { return }
    switch request {
    case .tearOut(let host, let grab, let size):
      let window = entry.windows[host] ?? makeWindow(for: host, in: space, style: space.layout.windowStyle)
      entry.windows[host] = window
      // The float's tree fills the content, under the title bar the custom look draws.
      let inset: Float = space.layout.windowStyle == .custom ? DockMetrics.titleBarHeight : 0
      let content = float2(size.x, size.y + inset)
      let held = grab + float2(0, inset)
      window.setFrame(window.frameRect(forContentRect: contentRect(held, size: content)), display: false)
      window.isPlaced = true
      window.orderFront(nil)
      begin(Drag(space: space, host: host, window: window, grab: held))

    case .drag(let host, let grab):
      guard let window = entry.windows[host] else { return }
      begin(Drag(space: space, host: host, window: window, grab: grab))

    case .close(let host):
      entry.windows[host]?.closeByUser()
    case .minimize(let host):
      entry.windows[host]?.miniaturize(nil)
    case .zoom(let host):
      entry.windows[host]?.zoom(nil)
    }
  }

  /// A content rect whose top left is `grab` up and left of the pointer, screen coordinates.
  private static func contentRect(_ grab: float2, size: float2) -> NSRect {
    let mouse = NSEvent.mouseLocation
    let top = mouse.y + CGFloat(grab.y)
    return NSRect(x: mouse.x - CGFloat(grab.x), y: top - CGFloat(size.y), width: CGFloat(size.x), height: CGFloat(size.y))
  }

  private static func begin(_ newDrag: Drag) {
    drag = newDrag
    // The button may be up already: the request crossed threads after the release.
    if NSEvent.pressedMouseButtons & 1 == 0 {
      released()
    } else {
      dragged()
    }
  }

  // MARK: - Called by the view that has the press

  /// The pointer dragged on while a window is dragged: moves it, and tells the area under the
  /// pointer. Returns false when no window is dragged.
  @discardableResult
  static func dragged() -> Bool {
    guard var current = drag else { return false }
    let window = current.window
    let size = window.contentRect(forFrameRect: window.frame).size
    let rect = contentRect(current.grab, size: float2(Float(size.width), Float(size.height)))
    window.setFrameOrigin(window.frameRect(forContentRect: rect).origin)

    let next = area(under: NSEvent.mouseLocation, below: window, in: current.space)
    if let previous = current.target, previous.host != next?.host {
      current.space.withArea(previous.host) { $0.remoteHover(nil) }
    }
    if let next {
      let point = next.point
      current.space.withArea(next.host) { $0.remoteHover(point) }
    }
    current.target = next
    drag = current
    return true
  }

  /// The press ended: docks the window's host where the area under the pointer shows, or
  /// leaves the window where it is.
  @discardableResult
  static func released() -> Bool {
    guard let current = drag else { return false }
    drag = nil
    let host = current.host
    if let target = current.target {
      let point = target.point
      current.space.withArea(target.host) { $0.remoteDrop(point, source: host) }
    }
    current.space.setScreenFrame(DockRect(current.window.frame), ofHost: host)
    current.window.makeKeyAndOrderFront(nil)
    return true
  }

  static func isDragging(_ window: NSWindow) -> Bool {
    drag?.window === window
  }

  /// The dock area of `space` in the window under `point`, below `window`, and where the point
  /// is in its view. Only this app's windows count, front to back: `windowNumber(at:)` also
  /// finds other apps' windows, invisible overlays among them, which would hide ours.
  private static func area(under point: NSPoint, below window: NSWindow, in space: DockSpace) -> (host: String, point: float2)? {
    guard let hostWindow = NSApp.orderedWindows.first(where: { candidate in
      candidate !== window && candidate.isVisible && !candidate.isMiniaturized && candidate.frame.contains(point)
    }) else { return nil }
    for (host, handle) in space.shownAreas() {
      guard let handle, let view = WindowRegistry.view(for: handle), view.window === hostWindow else { continue }
      let local = view.convert(hostWindow.convertPoint(fromScreen: point), from: nil)
      guard view.bounds.contains(local) else { return nil }
      return (host, float2(Float(local.x), Float(local.y)))
    }
    return nil
  }
}

/// A detached host's window. Closing it closes the host's panels.
final class DockWindow : NSWindow, NSWindowDelegate {
  let space: DockSpace
  let host: String
  let handle: WindowHandle
  /// Whether it has been put somewhere: a torn-out window is shown once the drag places it.
  var isPlaced = false
  /// Set when the user closes it: only then do its panels go. Quitting closes it too, and the
  /// layout keeps it for the next launch.
  private var isClosedByUser = false
  private var style: DockWindowStyle?

  init(space: DockSpace, host: String, handle: WindowHandle) {
    self.space = space
    self.host = host
    self.handle = handle
    super.init(
      contentRect: NSRect(x: 0, y: 0, width: 360, height: 260),
      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
    )
    self.isReleasedWhenClosed = false
    self.tabbingMode = .disallowed
    self.contentMinSize = NSSize(width: 200, height: 140)
    self.delegate = self
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  /// The native look, or the custom one: no system title bar, the area drawing its own. The
  /// window keeps its frame and its native edges, shadow and corners either way.
  func apply(_ style: DockWindowStyle) {
    guard style != self.style else { return }
    self.style = style
    let frame = self.frame
    switch style {
    case .native:
      self.styleMask = [.titled, .closable, .miniaturizable, .resizable]
      self.titlebarAppearsTransparent = false
      self.titleVisibility = .visible
      self.isMovable = true
    case .custom:
      self.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
      self.titlebarAppearsTransparent = true
      self.titleVisibility = .hidden
      // The area's title bar drags the window, and docks it.
      self.isMovable = false
    }
    for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
      self.standardWindowButton(button)?.isHidden = style == .custom
    }
    self.setFrame(frame, display: true)
  }

  /// The custom look's close button.
  func closeByUser() {
    self.isClosedByUser = true
    self.close()
  }

  // Asked only when the user closes it — its close button, ⌘W — never as the app quits.
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    self.isClosedByUser = true
    return true
  }

  func windowWillClose(_ notification: Notification) {
    WindowRegistry.remove(self.handle)
    self.handle.close()
    if self.isClosedByUser, self.space.layout.host(self.host) != nil {
      self.space.close(host: self.host)
    }
  }

  func windowDidMove(_ notification: Notification) {
    self.saveFrame()
  }

  func windowDidEndLiveResize(_ notification: Notification) {
    self.saveFrame()
  }

  private func saveFrame() {
    guard self.isPlaced, !DockWindows.isDragging(self), self.space.layout.host(self.host) != nil else { return }
    self.space.setScreenFrame(DockRect(self.frame), ofHost: self.host)
  }
}

/// Stands in the space's observer list for the main thread, which has no element of its own.
final class DockSpaceObserver : UIElement {
  private let changed: @MainActor () -> Void

  init(_ changed: @escaping @MainActor () -> Void) {
    self.changed = changed
    super.init()
  }

  override func __modelDidChange(_ token: Int, _ animated: Bool) {
    let changed = self.changed
    MainActor.assumeIsolated { changed() }
  }
}

extension DockRect {
  init(_ rect: NSRect) {
    self.init(x: Float(rect.origin.x), y: Float(rect.origin.y), width: Float(rect.width), height: Float(rect.height))
  }
}

extension NSRect {
  init(_ rect: DockRect) {
    self.init(x: CGFloat(rect.x), y: CGFloat(rect.y), width: CGFloat(rect.width), height: CGFloat(rect.height))
  }
}
