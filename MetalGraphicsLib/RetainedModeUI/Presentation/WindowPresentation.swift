import simd

/// Why a presentation's window asks it to go, as the main thread saw it.
enum PresentedWindowEvent: Sendable {
  /// Its close button.
  case userClosed
  /// A click on the window it was presented from, which AppKit, or the presentation, blocks.
  case clickedOutside
  /// A popover's window lost the keyboard to a window that is not shown over it.
  case resignedKey
  /// The window it was presented from closed.
  case parentClosed
}

/// A presentation in a window of its own: the root of that window's tree, on the thread of the
/// window it was presented from (`WindowHandle(childOf:name:)`), so its content — built by the
/// presenter's closure, capturing the presenter — and the presenter's tree touch each other
/// directly, as over the app's window.
///
/// The main thread opens, places, resizes and closes its `NSWindow` (`PresentedWindows`); what
/// the user does there comes back as a `PresentedWindowEvent`. While it shows, a modal one blocks
/// input to the presenter's tree (`UIContext.blockInput()`).
final class WindowPresentation : PresentationRoot {
  /// The scene id of its window.
  static let sceneID = "presentation"

  let kind: PresentationKind
  let style: PresentationWindowStyle
  /// Its window's handle; nil once it has closed.
  private(set) var handle: WindowHandle?
  /// The tree it was presented from.
  private weak var presenterContext: UIContext?
  private weak var ownContext: UIContext?
  /// Blocks the presenter's input while it shows: all but a popover.
  let blocksPresenter: Bool
  /// Runs once it has gone.
  var onRemoved: (() -> Void)?

  private let background: Rectangle
  private let keys: KeyPressElement
  private let card: UIElement
  private var size: float2 = .zero
  /// The size last asked of its window, when it is fitted to the content.
  private var lastIdeal: float2?
  /// Where its popover points from, as last sent.
  private var lastAnchor: ClipRect?

  init(kind: PresentationKind, content: UIElement, style: PresentationWindowStyle) {
    self.kind = kind
    self.style = style
    self.blocksPresenter = kind != .popover
    let card: UIElement
    switch kind {
    case .fullScreenCover:
      card = content.frame(maxWidth: .infinity, maxHeight: .infinity)
    default:
      card = ScrollView(.vertical) { content }
    }
    self.card = card
    self.background = Rectangle(Self.backgroundColor(kind))
    let keys = KeyPressElement(keys: [.escape, .return], phases: [.down], action: nil) { card }
    self.keys = keys
    super.init()
    self.applyContent([self.background, keys])
    keys.action = { [unowned self] press in self.handleKey(press) }
  }

  /// What the window's content is drawn on.
  static func backgroundColor(_ kind: PresentationKind) -> float4 {
    kind == .fullScreenCover ? FormMetrics.groupedBackground : FormMetrics.cardColor
  }

  override func mount(_ context: UIContext) {
    self.ownContext = context
  }

  // MARK: - Opening

  /// Opens a window for `presentation`, showing `content`, over the window `context` is in.
  /// Nil when `context` is in no window, as in a test harness: it then shows over the tree.
  static func open(
    _ presentation: PresentationElement, content: UIElement, style: PresentationWindowStyle, in context: UIContext
  ) -> WindowPresentation? {
    guard let scene = context.scene, let parent = scene.handle else {
#if DEBUG
      print("\(presentation.kind) in a window of its own: this tree is in no window; shown over it instead")
#endif
      return nil
    }
    // A menu open in the presenter would be left pointing at nothing.
    context.dismissAllPopovers()
    let root = WindowPresentation(kind: presentation.kind, content: content, style: style)
    root.presenterContext = context
    let handle = WindowHandle(childOf: parent, name: "Presentation")
    root.handle = handle

    // `start` builds the tree now, on this thread: the child has none of its own.
    nonisolated(unsafe) let unsafeRoot = root
    nonisolated(unsafe) let storage = scene.storage
    nonisolated(unsafe) let clock = context.clock
    handle.start {
      let scene = WindowScene(sceneID: WindowPresentation.sceneID, storage: storage, handle: handle)
      let renderer = RootViewRenderer(
        scene: scene, layer: nil, root: { _ in unsafeRoot },
        showPointerStyle: { style in
          MainQueue.post { MainActor.assumeIsolated { PresentedWindows.host.showPointerStyle(handle, style) } }
        }
      )
      renderer.clock = clock
      renderer.uiContext.clock = clock
      return renderer
    }

    if root.blocksPresenter {
      context.blockInput()
    }
    let ideal = root.idealSize()
    root.lastIdeal = ideal
    root.lastAnchor = presentation.anchorRect
    let request = PresentedWindowRequest(
      handle: handle, parent: parent, kind: presentation.kind, style: style, idealSize: ideal,
      anchor: root.lastAnchor, background: Self.backgroundColor(presentation.kind), title: presentation.title
    )
    MainQueue.post { MainActor.assumeIsolated { PresentedWindows.host.open(request) } }
    return root
  }

  /// The size its window takes when fitted to the content: an alert's or a dialog's width, and
  /// a sheet's or a popover's content's own.
  func idealSize(freshPass: Bool = true) -> float2 {
    // Measured outside a layout pass: nothing remembered from the last one may stand.
    if freshPass {
      LayoutPass.generation &+= 1
    }
    switch self.kind {
    case .alert, .confirmationDialog:
      let width: Float = self.kind == .alert ? 260 : 280
      return float2(width, self.card.measure(ProposedSize(width: width, height: nil)).y)
    default:
      return self.card.measure(.unspecified)
    }
  }

  /// Whether its window follows the content's size.
  private var isFitted: Bool {
    switch self.kind {
    case .fullScreenCover: return false
    case .sheet: return !self.style.isResizable
    default: return true
    }
  }

  // MARK: - Input

  private func handleKey(_ press: KeyPress) -> KeyPress.Result {
    guard press.modifiers.intersection([.command, .option, .control, .shift]).isEmpty else { return .ignored }
    if press.key == .escape {
      self.cancel()
      return .handled
    }
    if press.key == .return, self.kind == .alert || self.kind == .confirmationDialog {
      return self.activateDefault() ? .handled : .ignored
    }
    return .ignored
  }

  /// What the user did to its window.
  func windowEvent(_ event: PresentedWindowEvent) -> Void {
    switch event {
    case .userClosed:
      self.cancel()
    case .clickedOutside:
      if self.kind == .alert || self.kind == .confirmationDialog {
        self.cancel()
      } else if self.kind != .fullScreenCover {
        self.requestDismiss()
      }
    case .resignedKey, .parentClosed:
      self.requestDismiss()
    }
  }

  /// Its popover's source moved in the presenter's window: its window follows.
  func anchorMoved(_ anchor: ClipRect?) -> Void {
    guard self.kind == .popover, !self.isDismissing, anchor != self.lastAnchor, let anchor, let handle else { return }
    self.lastAnchor = anchor
    MainQueue.post { MainActor.assumeIsolated { PresentedWindows.host.move(handle, anchor: anchor) } }
  }

  // MARK: - Closing

  override var presentedContext: UIContext? { self.ownContext }

  override func dismissItself() -> Void {
    self.close(runningOnRemoved: true)
  }

  override func dismissAnimated(_ animated: Bool) -> Void {
    self.close(runningOnRemoved: true)
  }

  override func dismissImmediately() -> Void {
    self.close(runningOnRemoved: false)
  }

  /// Closes its window: the tree under it unmounts after this frame, and `onRemoved` runs then.
  private func close(runningOnRemoved: Bool) -> Void {
    guard !self.isDismissing, let handle = self.handle else { return }
    self.isDismissing = true
    if let context = self.ownContext {
      self.dismissNested(context)
    }
    if self.blocksPresenter {
      self.presenterContext?.unblockInput()
    }
    MainQueue.post { MainActor.assumeIsolated { PresentedWindows.host.close(handle) } }
    handle.close()
    self.handle = nil
    if runningOnRemoved, let onRemoved = self.onRemoved {
      self.onRemoved = nil
      // After the tree has unmounted, posted after it.
      nonisolated(unsafe) let run = onRemoved
      handle.executor.post { run() }
    }
  }

  // MARK: - Layout

  override func getSize() -> float2 {
    self.size
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = proposal.replacingUnspecified(with: .zero)
    if self.isFitted, !self.isDismissing, let handle = self.handle {
      let ideal = self.idealSize(freshPass: false)
      if ideal != self.lastIdeal {
        self.lastIdeal = ideal
        MainQueue.post { MainActor.assumeIsolated { PresentedWindows.host.resize(handle, to: ideal) } }
      }
    }
    _ = self.background.calcSize(ProposedSize(self.size))
    _ = self.keys.calcSize(ProposedSize(self.size))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.background.calcPosition(position)
    self.keys.calcPosition(position)
  }
}
