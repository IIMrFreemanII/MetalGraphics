import AppKit
import simd

/// What a presentation's thread asks the main thread for: a window for it. A value, with no
/// element in it; the handles are all the main thread holds of either window.
struct PresentedWindowRequest: @unchecked Sendable {
  /// The presentation's window, whose tree runs on its parent's thread.
  let handle: WindowHandle
  /// The window it is presented from.
  let parent: WindowHandle
  let kind: PresentationKind
  let style: PresentationWindowStyle
  /// The content's size, in points: what a fitted window takes.
  let idealSize: float2
  /// Where a popover points from, in the parent's content, points, top left origin.
  let anchor: ClipRect?
  /// What the content is drawn on, shown until the first frame is.
  let background: float4
  let title: String
}

/// Opens, places and closes presentations' windows, on the main thread: `AppKitPresentedWindows`
/// in the app, `HeadlessPresentedWindows` in a `HeadlessApp`.
@MainActor protocol PresentedWindowHost: AnyObject {
  func open(_ request: PresentedWindowRequest)
  /// The content's size changed; a fitted window follows it.
  func resize(_ handle: WindowHandle, to idealSize: float2)
  /// A popover's source moved.
  func move(_ handle: WindowHandle, anchor: ClipRect)
  func close(_ handle: WindowHandle)
  func showPointerStyle(_ handle: WindowHandle, _ style: PointerStyle)
  func showTextInput(_ handle: WindowHandle, _ snapshot: TextInputSnapshot)
}

@MainActor enum PresentedWindows {
  static var host: any PresentedWindowHost = AppKitPresentedWindows()

  /// Tells a presentation what happened to its window, on its thread. Dropped once it closed.
  nonisolated static func send(_ event: PresentedWindowEvent, to handle: WindowHandle) {
    handle.post { renderer in
      (renderer.root.child as? WindowPresentation)?.windowEvent(event)
    }
  }

  /// Where a popover of `size` goes for a source at `anchor`: below it, or above when there is
  /// more room there, centred on it, inside `bounds`. Screen coordinates, y up.
  static func popoverFrame(size: CGSize, anchor: CGRect, in bounds: CGRect, gap: CGFloat = 4) -> CGRect {
    let below = anchor.minY - gap - size.height
    let above = anchor.maxY + gap
    let y: CGFloat
    if below >= bounds.minY || anchor.minY - bounds.minY >= bounds.maxY - anchor.maxY {
      y = max(below, bounds.minY)
    } else {
      y = min(above, bounds.maxY - size.height)
    }
    var x = anchor.midX - size.width / 2
    x = min(max(x, bounds.minX), max(bounds.maxX - size.width, bounds.minX))
    return CGRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height)
  }

  /// A floating window of `size` centred over `parent`, a little above its middle, inside
  /// `bounds`. Screen coordinates, y up.
  static func floatingFrame(size: CGSize, over parent: CGRect, in bounds: CGRect) -> CGRect {
    var x = parent.midX - size.width / 2
    var y = parent.midY - size.height / 2 + parent.height * 0.1
    x = min(max(x, bounds.minX), max(bounds.maxX - size.width, bounds.minX))
    y = min(max(y, bounds.minY), max(bounds.maxY - size.height, bounds.minY))
    return CGRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height)
  }

  /// `size` kept inside most of the screen, and no smaller than a window can usefully be.
  static func clamp(_ size: float2, _ kind: PresentationKind, in bounds: CGRect) -> CGSize {
    let minimum: float2 = kind == .popover ? float2(40, 24) : float2(200, 80)
    let maximum = float2(Float(bounds.width), Float(bounds.height)) * 0.9
    let clamped = simd_min(simd_max(size, minimum), simd_max(maximum, minimum))
    return CGSize(width: CGFloat(clamped.x.rounded(.up)), height: CGFloat(clamped.y.rounded(.up)))
  }
}

/// A presentation's `NSWindow`: an AppKit sheet, a floating window, a popover's borderless one or
/// a cover.
final class PresentedWindow : NSWindow, NSWindowDelegate {
  let handle: WindowHandle
  /// The handle of the window it was presented from.
  let parentHandle: WindowHandle
  let kind: PresentationKind
  let style: PresentationWindowStyle
  /// The window it was presented from.
  weak var presenter: NSWindow?
  /// Where a popover points from, in the presenter's content view.
  var anchor: ClipRect?
  /// Set once the main thread closes it on the presentation's behalf.
  var isClosing = false

  init(_ request: PresentedWindowRequest, presenter: NSWindow, contentSize: CGSize) {
    self.handle = request.handle
    self.parentHandle = request.parent
    self.kind = request.kind
    self.style = request.style
    self.presenter = presenter
    self.anchor = request.anchor
    var mask: NSWindow.StyleMask
    switch (request.kind, request.style.placement) {
    case (.popover, _), (.fullScreenCover, .attached):
      mask = [.borderless]
    case (.fullScreenCover, _):
      mask = [.titled, .closable, .resizable, .fullSizeContentView]
    case (.sheet, .floating):
      mask = [.titled, .closable]
    case (_, .floating):
      // An alert or a dialog: its title is on it already, as an `NSAlert`'s.
      mask = [.titled, .fullSizeContentView]
    default:
      mask = [.titled]
    }
    if request.style.isResizable, request.kind == .sheet {
      mask.insert(.resizable)
    }
    super.init(contentRect: NSRect(origin: .zero, size: contentSize), styleMask: mask, backing: .buffered, defer: false)
    self.isReleasedWhenClosed = false
    self.tabbingMode = .disallowed
    self.delegate = self
    self.title = request.title
    if mask.contains(.fullSizeContentView), request.kind != .fullScreenCover {
      self.titlebarAppearsTransparent = true
      self.titleVisibility = .hidden
    }
    if request.kind == .popover {
      self.isOpaque = false
      self.backgroundColor = .clear
      self.hasShadow = true
    }
    if request.style.isResizable, request.kind == .sheet {
      self.contentMinSize = NSSize(width: 200, height: 120)
    }
  }

  // Borderless ones too: a popover's field takes typing, and Escape closes it.
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { self.kind != .popover }

  var isAttachedSheet: Bool {
    self.style.placement == .attached && (self.kind == .sheet || self.kind == .alert || self.kind == .confirmationDialog)
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    // The presentation decides, through its binding; it closes the window if it goes.
    guard self.isClosing else {
      PresentedWindows.send(.userClosed, to: self.handle)
      return false
    }
    return true
  }

  func windowWillClose(_ notification: Notification) {
    WindowRegistry.remove(self.handle)
    self.handle.close()
  }
}

/// `PresentedWindowHost` with real windows.
@MainActor final class AppKitPresentedWindows : PresentedWindowHost {
  private var windows: [ObjectIdentifier: PresentedWindow] = [:]
  private var monitor: Any?
  private var resignObserver: NSObjectProtocol?
  private var observers: [ObjectIdentifier: [NSObjectProtocol]] = [:]

  func open(_ request: PresentedWindowRequest) {
    guard let presenterView = WindowRegistry.view(for: request.parent), let presenter = presenterView.window else {
      // Its window closed before the main thread got here.
      PresentedWindows.send(.parentClosed, to: request.handle)
      return
    }
    let screen = (presenter.screen ?? NSScreen.main)?.visibleFrame ?? presenter.frame
    let color = request.background
    // A popover's window is the system's popover glass, rounded as its card; the tree draws
    // on it with nothing under.
    let isGlass = request.kind == .popover
    let view = RetainedLayerView(
      handle: request.handle,
      background: CGColor(srgbRed: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: CGFloat(color.w)),
      chrome: isGlass ? .translucent : .standard
    )
    if isGlass {
      view.effectMaterial = .popover
      view.effectCornerRadius = CGFloat(PopoverLayer.cornerRadius)
      request.handle.post { $0.setBackground(.clear) }
    }
    WindowRegistry.add(request.handle, view: view)

    let size: CGSize
    switch request.kind {
    case .fullScreenCover: size = presenter.contentLayoutRect.size
    default: size = PresentedWindows.clamp(request.idealSize, request.kind, in: screen)
    }
    let window = PresentedWindow(request, presenter: presenter, contentSize: size)
    window.contentView = view
    if request.kind == .popover {
      view.metalLayer.cornerRadius = CGFloat(PopoverLayer.cornerRadius)
      view.metalLayer.masksToBounds = true
    }
    self.windows[ObjectIdentifier(request.handle)] = window
    self.observe(presenter)

    switch (request.kind, request.style.placement) {
    case (.popover, _):
      self.place(window, anchor: request.anchor)
      presenter.addChildWindow(window, ordered: .above)
      window.makeKeyAndOrderFront(nil)
    case (.fullScreenCover, .attached):
      window.setFrame(presenter.convertToScreen(presenter.contentLayoutRect), display: false)
      presenter.addChildWindow(window, ordered: .above)
      window.makeKeyAndOrderFront(nil)
    case (.fullScreenCover, _):
      // A window of its own, not a child: a child cannot go full screen.
      window.collectionBehavior.insert(.fullScreenPrimary)
      window.setFrame(presenter.frame, display: false)
      window.makeKeyAndOrderFront(nil)
      window.toggleFullScreen(nil)
    case (_, .attached):
      presenter.beginSheet(window) { _ in }
    default:
      window.collectionBehavior.insert(.fullScreenAuxiliary)
      window.setFrame(
        window.frameRect(forContentRect: PresentedWindows.floatingFrame(size: size, over: presenter.frame, in: screen)),
        display: false
      )
      presenter.addChildWindow(window, ordered: .above)
      window.makeKeyAndOrderFront(nil)
    }
    window.makeFirstResponder(view)

    nonisolated(unsafe) let layer = view.metalLayer
    request.handle.post { $0.attach(layer: layer) }
    self.installMonitor()
  }

  func resize(_ handle: WindowHandle, to idealSize: float2) {
    guard let window = self.windows[ObjectIdentifier(handle)] else { return }
    let screen = (window.screen ?? NSScreen.main)?.visibleFrame ?? window.frame
    let size = PresentedWindows.clamp(idealSize, window.kind, in: screen)
    if window.kind == .popover {
      window.setContentSize(size)
      self.place(window, anchor: window.anchor)
      return
    }
    // Keeps its top edge where it is, as a sheet grows downwards.
    var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: size))
    frame.origin = NSPoint(x: window.frame.midX - frame.width / 2, y: window.frame.maxY - frame.height)
    window.setFrame(frame, display: true, animate: window.isAttachedSheet)
  }

  func move(_ handle: WindowHandle, anchor: ClipRect) {
    guard let window = self.windows[ObjectIdentifier(handle)] else { return }
    window.anchor = anchor
    self.place(window, anchor: anchor)
  }

  func close(_ handle: WindowHandle) {
    guard let window = self.windows.removeValue(forKey: ObjectIdentifier(handle)) else { return }
    window.isClosing = true
    let wasKey = window.isKeyWindow
    if let parent = window.sheetParent {
      parent.endSheet(window)
    } else if let parent = window.parent {
      parent.removeChildWindow(window)
    }
    window.orderOut(nil)
    window.close()
    if wasKey, let presenter = window.presenter, presenter.isVisible {
      presenter.makeKey()
    }
    if let presenter = window.presenter, !self.windows.values.contains(where: { $0.presenter === presenter }) {
      self.unobserve(presenter)
    }
    if self.windows.isEmpty {
      self.removeMonitor()
    }
  }

  func showPointerStyle(_ handle: WindowHandle, _ style: PointerStyle) {
    WindowRegistry.view(for: handle)?.pointerStyle = style
  }

  func showTextInput(_ handle: WindowHandle, _ snapshot: TextInputSnapshot) {
    WindowRegistry.view(for: handle)?.textInputChanged(snapshot)
  }

  // MARK: - Placing

  private func place(_ window: PresentedWindow, anchor: ClipRect?) {
    guard let presenter = window.presenter, let presenterView = WindowRegistry.view(for: window.parentHandle) else {
      return
    }
    let screen = (presenter.screen ?? NSScreen.main)?.visibleFrame ?? presenter.frame
    let source: CGRect
    if let anchor {
      // The content view is flipped, as the tree lays out: top left origin.
      let rect = NSRect(
        x: CGFloat(anchor.min.x), y: CGFloat(anchor.min.y),
        width: CGFloat(anchor.max.x - anchor.min.x), height: CGFloat(anchor.max.y - anchor.min.y)
      )
      source = presenter.convertToScreen(presenterView.convert(rect, to: nil))
    } else {
      source = presenter.frame
    }
    window.setFrame(PresentedWindows.popoverFrame(size: window.frame.size, anchor: source, in: screen), display: true)
  }

  // MARK: - Watching

  /// Clicks on a window a presentation was presented from dismiss it, and are taken: AppKit
  /// blocks them to a sheet's parent anyway, and this treats every window alike. A scroll
  /// dismisses a popover and still scrolls.
  private func installMonitor() {
    guard self.monitor == nil else { return }
    self.resignObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.didResignKeyNotification, object: nil, queue: .main
    ) { [weak self] note in
      nonisolated(unsafe) let object = note.object
      MainActor.assumeIsolated {
        guard let self, let resigned = object as? PresentedWindow, resigned.kind == .popover,
              self.windows[ObjectIdentifier(resigned.handle)] === resigned
        else { return }
        // On the next turn, once the new key window is known.
        DispatchQueue.main.async {
          MainActor.assumeIsolated {
            guard !resigned.isClosing, !resigned.isKeyWindow else { return }
            if let key = NSApp.keyWindow as? PresentedWindow, self.isShown(key, over: resigned) { return }
            PresentedWindows.send(.resignedKey, to: resigned.handle)
          }
        }
      }
    }
    self.monitor = NSEvent.addLocalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel]
    ) { [weak self] event in
      nonisolated(unsafe) let event = event
      let takes = MainActor.assumeIsolated { self?.handleOutside(event) ?? false }
      return takes ? nil : event
    }
  }

  /// A click or a scroll on a window a presentation was shown from: tells the presentation shown
  /// last from it. Whether the event is taken.
  private func handleOutside(_ event: NSEvent) -> Bool {
    guard let target = event.window,
          let window = self.windows.values
            .filter({ $0.presenter === target && !$0.isClosing })
            .max(by: { $0.orderedIndex > $1.orderedIndex })
    else { return false }
    if event.type == .scrollWheel {
      if window.kind == .popover {
        PresentedWindows.send(.clickedOutside, to: window.handle)
      }
      return false
    }
    PresentedWindows.send(.clickedOutside, to: window.handle)
    return true
  }

  private func removeMonitor() {
    if let monitor = self.monitor {
      NSEvent.removeMonitor(monitor)
      self.monitor = nil
    }
    if let observer = self.resignObserver {
      NotificationCenter.default.removeObserver(observer)
      self.resignObserver = nil
    }
  }

  /// A presenter closing takes what it presented with it; a popover's goes when the keyboard
  /// moves to a window not shown over it.
  private func observe(_ presenter: NSWindow) {
    let key = ObjectIdentifier(presenter)
    guard self.observers[key] == nil else { return }
    let center = NotificationCenter.default
    var tokens: [NSObjectProtocol] = []
    tokens.append(center.addObserver(forName: NSWindow.willCloseNotification, object: presenter, queue: .main) { [weak self] _ in
      MainActor.assumeIsolated {
        guard let self else { return }
        for window in self.windows.values where window.presenter === presenter {
          PresentedWindows.send(.parentClosed, to: window.handle)
        }
      }
    })
    for name in [NSWindow.didResizeNotification, NSWindow.didMoveNotification] {
      tokens.append(center.addObserver(forName: name, object: presenter, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated {
          guard let self else { return }
          for window in self.windows.values where window.presenter === presenter {
            if window.kind == .fullScreenCover, window.style.placement == .attached {
              window.setFrame(presenter.convertToScreen(presenter.contentLayoutRect), display: true)
            } else if window.kind == .popover {
              self.place(window, anchor: window.anchor)
            }
          }
        }
      })
    }
    self.observers[key] = tokens
  }

  private func unobserve(_ presenter: NSWindow) {
    guard let tokens = self.observers.removeValue(forKey: ObjectIdentifier(presenter)) else { return }
    tokens.forEach { NotificationCenter.default.removeObserver($0) }
  }

  /// Whether `window` was presented from `base`, or from something presented from it.
  private func isShown(_ window: PresentedWindow, over base: PresentedWindow) -> Bool {
    var current: NSWindow? = window.presenter
    while let presenter = current {
      if presenter === base { return true }
      current = (presenter as? PresentedWindow)?.presenter
    }
    return false
  }
}
