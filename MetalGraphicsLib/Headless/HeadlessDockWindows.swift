import simd

/// `DockWindows` for a `HeadlessApp`: the windows of a `DockSpace`'s detached hosts, opened,
/// shown, hidden, dragged and closed on the app's screen, as `DockWindows` does with `NSWindow`s.
/// Installed by `HeadlessApp.manageDocking`.
///
/// Its screen frames (`DockHost.screenFrame`) are the headless screen's: a window's content, top
/// left origin, y down.
@MainActor final class HeadlessDockWindows {
  /// The scene id of the windows it opens, as `DockWindows` names them.
  static let sceneID = "dock"

  let space: DockSpace
  private unowned let app: HeadlessApp
  private var windows: [String: HeadlessWindow] = [:]
  /// Hosts whose window has been put somewhere: a torn-out one shows once its drag places it.
  private var placed: Set<String> = []
  private var observer: DockSpaceObserver?

  /// A dock window following the pointer, from a tear-out or a drag of its title bar, until the
  /// press that started it ends.
  struct Drag {
    let docking: HeadlessDockWindows
    let host: String
    let window: HeadlessWindow
    /// Where the pointer holds the window's content, from its top left.
    let grab: float2
    /// The area under the pointer, told where it is.
    var target: (host: String, point: float2)?
  }

  init(app: HeadlessApp, space: DockSpace) {
    self.app = app
    self.space = space
    // Subscribed as the main thread, which the test's code runs as between steps: a change
    // reaches it through the app's main mailbox.
    let observer = DockSpaceObserver { [weak self] in self?.reconcile() }
    self.observer = observer
    space.observers.add(observer, token: 0)
    let post = MainQueue.post
    space.setWindowHandlers(
      requests: { [weak self] request in
        post { MainActor.assumeIsolated { self?.handle(request) } }
      },
      areasChanged: { [weak self] in
        post { MainActor.assumeIsolated { self?.reconcile() } }
      }
    )
    self.reconcile()
  }

  /// Stops managing the space, and closes its windows as quitting does: their hosts stay.
  func stop() {
    self.space.setWindowHandlers(requests: nil, areasChanged: nil)
    if let observer = self.observer {
      self.space.observers.remove(observer)
    }
    self.observer = nil
    for window in self.windows.values {
      window.close(quitting: true)
    }
    self.windows.removeAll()
    if self.app.dockDrag?.docking === self { self.app.dockDrag = nil }
  }

  /// Opens, shows, hides and closes windows to match the layout, as `DockWindows.reconcile`.
  func reconcile() {
    guard self.observer != nil else { return }
    let layout = self.space.layout
    // An area the app placed, in a window on screen.
    let visible = self.space.shownAreas().contains { area in
      guard layout.host(area.host)?.isDetached != true else { return false }
      guard let handle = area.window else { return true }
      guard let window = self.app.windows.first(where: { $0.handle === handle }) else { return false }
      return window.isOpen && window.isVisible
    }

    for host in layout.hosts where host.isDetached {
      let window = self.windows[host.id] ?? self.makeWindow(for: host.id)
      self.windows[host.id] = window
      window.title = layout.title(ofHost: host.id)
      if let frame = host.screenFrame, !self.placed.contains(host.id) {
        window.origin = float2(frame.x, frame.y)
        window.setContentSize(float2(frame.width, frame.height))
        self.placed.insert(host.id)
      }
      let dragged = self.app.dockDrag?.window === window
      if visible && self.placed.contains(host.id) && !window.isVisible && !dragged {
        window.show()
      } else if !visible && window.isVisible {
        window.hide()
      }
    }
    for (id, window) in self.windows where layout.host(id)?.isDetached != true {
      self.windows[id] = nil
      self.placed.remove(id)
      if self.app.dockDrag?.window === window { self.app.dockDrag = nil }
      window.close(quitting: true)
    }
  }

  private func makeWindow(for host: String) -> HeadlessWindow {
    let space = self.space
    let window = self.app.openWindow(
      sceneID: Self.sceneID, title: space.layout.title(ofHost: host),
      size: float2(360, 260), origin: .zero, visible: false
    ) { _ in DockArea(space, host: host) }
    window.onUserClose = { [weak self, weak window] in
      guard let window else { return }
      self?.closeByUser(window, host: host)
    }
    return window
  }

  /// Its close button: the window closes, and its host's panels with it.
  private func closeByUser(_ window: HeadlessWindow, host: String) {
    self.windows[host] = nil
    self.placed.remove(host)
    window.close(quitting: false)
    if self.space.layout.host(host) != nil {
      self.space.close(host: host)
    }
  }

  private func handle(_ request: DockWindowRequest) {
    switch request {
    case .tearOut(let host, let grab, let size):
      let window = self.windows[host] ?? self.makeWindow(for: host)
      self.windows[host] = window
      // The float's tree fills the content, under the title bar the custom look draws.
      let inset: Float = self.space.layout.windowStyle == .custom ? DockMetrics.titleBarHeight : 0
      let held = grab + float2(0, inset)
      window.setContentSize(float2(size.x, size.y + inset))
      window.origin = self.app.screenPointer - held
      self.placed.insert(host)
      window.show()
      self.begin(Drag(docking: self, host: host, window: window, grab: held))

    case .drag(let host, let grab):
      guard let window = self.windows[host] else { return }
      self.begin(Drag(docking: self, host: host, window: window, grab: grab))

    case .close(let host):
      guard let window = self.windows[host] else { return }
      self.closeByUser(window, host: host)
    case .minimize(let host):
      self.windows[host]?.hide()
    case .zoom(let host):
      guard let window = self.windows[host] else { return }
      window.origin = .zero
      window.setContentSize(self.app.screenSize)
    }
  }

  private func begin(_ drag: Drag) {
    self.app.dockDrag = drag
    // The button may be up already: the request came after the release.
    if self.app.pressedWindow == nil {
      self.app.dockReleased(at: self.app.screenPointer)
    } else {
      self.app.dockDragged(to: self.app.screenPointer)
    }
  }

  /// The area of the space under `point` (screen) in the front-most window below `window`, and
  /// where the point is in it.
  func area(under point: float2, below window: HeadlessWindow) -> (host: String, point: float2)? {
    guard let hostWindow = self.app.window(at: point, except: window) else { return nil }
    for (host, handle) in self.space.shownAreas() where handle === hostWindow.handle {
      return (host, point - hostWindow.origin)
    }
    return nil
  }
}

extension HeadlessApp {
  /// The pointer moved on to `point` (screen) while a dock window is dragged: moves the window,
  /// and tells the area under the pointer, as `DockWindows.dragged`. Returns false, and does
  /// nothing, when no dock window is dragged.
  @discardableResult
  func dockDragged(to point: float2) -> Bool {
    self.screenPointer = point
    guard var drag = self.dockDrag else { return false }
    drag.window.origin = point - drag.grab
    let space = drag.docking.space
    let next = drag.docking.area(under: point, below: drag.window)
    if let previous = drag.target, previous.host != next?.host {
      space.withArea(previous.host) { $0.remoteHover(nil) }
    }
    if let next {
      let local = next.point
      space.withArea(next.host) { $0.remoteHover(local) }
    }
    drag.target = next
    self.dockDrag = drag
    return true
  }

  /// The press ended at `point` (screen): docks the dragged window's host where the area under
  /// the pointer shows, or leaves the window there, as `DockWindows.released`.
  func dockReleased(at point: float2) {
    self.screenPointer = point
    guard let drag = self.dockDrag else { return }
    self.dockDrag = nil
    let host = drag.host
    let space = drag.docking.space
    if let target = drag.target {
      let local = target.point
      space.withArea(target.host) { _ = $0.remoteDrop(local, source: host) }
    }
    let frame = drag.window.frame
    space.setScreenFrame(DockRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.x, height: frame.size.y), ofHost: host)
    if drag.window.isOpen {
      self.makeKey(drag.window)
    }
  }
}
