import simd

/// What a presentation modifier shows.
public enum PresentationKind: Sendable, Equatable {
  case sheet
  case fullScreenCover
  case popover
  case alert
  case confirmationDialog
}

/// Whether something shows: a confirmation dialog's title, as SwiftUI's `Visibility`.
public enum Visibility: Sendable, Equatable {
  case automatic
  case visible
  case hidden
}

/// Where a popover points from, as SwiftUI's. Only the element's own bounds for now.
public enum PopoverAttachmentAnchor: Sendable, Equatable {
  case rect(Bounds)

  public enum Bounds: Sendable, Equatable {
    case bounds
  }
}

/// `.sheet`, `.fullScreenCover`, `.popover`, `.alert` and `.confirmationDialog`: shows its
/// content above the app while `isPresented` is true — in a layer over the window, or in a
/// window of its own (see `.presentationWindow(_:)`) — and draws nothing itself.
///
/// The content is built when it is presented and let go when it has gone, so what it holds
/// starts afresh each time, as in SwiftUI. It is built from a closure, `content`, which
/// `@Component` arms on mount like a handler: the closure may capture `self` and build
/// components.
///
/// Escape, a click outside, a dismiss action or an alert's button ask for it to go by reporting
/// `false` to `onIsPresentedChange` — the binding's write-back — and the state's update brings it
/// back through `setIsPresented`, which dismisses it. With no write-back, as for a constant
/// binding, nothing dismisses it but the value.
public class PresentationElement : SingleChildElement {
  public let kind: PresentationKind
  public internal(set) var isPresented: Bool
  /// An alert's or a dialog's title.
  public private(set) var title: String
  let titleVisibility: Visibility
  let prefersAbove: Bool

  /// The binding's write-back, armed by `@Component` for `isPresented: $state`.
  public var onIsPresentedChange: ((Bool) -> Void)?
  /// Runs once what was shown has gone.
  public var onDismiss: (() -> Void)?
  /// Builds the content: a sheet's, or an alert's actions. `@Component` arms it on mount.
  public var content: (() -> [UIElement])? {
    didSet { self.contentArmed() }
  }
  /// Builds an alert's or a dialog's message.
  public var message: (() -> [UIElement])?

  public private(set) weak var context: UIContext?
  /// The text style around it, which the content is styled with: laid out apart from the tree,
  /// it is not under the `TextStyleElement`s here. Captured at each layout.
  private var textScope = TextEnvironment()
  /// Where a popover points from: the element it modifies. Takes no input.
  private let anchor: HittableView?
  /// What it shows now; nil once that has started going away.
  private(set) var shown: PresentationRoot?
  /// An alert's title on screen.
  private weak var shownTitle: Text?

  /// Whether it shows something that has not started going away.
  var isShowing: Bool { self.shown != nil }

  init(
    kind: PresentationKind, isPresented: Bool, title: String = "", titleVisibility: Visibility = .automatic,
    prefersAbove: Bool = false, content: UIElement
  ) {
    self.kind = kind
    self.isPresented = isPresented
    self.title = title
    self.titleVisibility = titleVisibility
    self.prefersAbove = prefersAbove
    if kind == .popover {
      let anchor = HittableView(onTap: nil) { content }
      self.anchor = anchor
      super.init()
      self.applyContent([anchor])
    } else {
      self.anchor = nil
      super.init()
      self.applyContent([content])
    }
  }

  // MARK: - Doors

  public func setIsPresented(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.isPresented else { return }
    self.isPresented = value
    guard self.mounted else { return }
    if value {
      self.present()
    } else {
      self.dismissShown(animated: true)
    }
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.title else { return }
    self.title = value
    if let title = self.shownTitle, let titleContext = self.shown?.presentedContext {
      title.setText(value, titleContext, animation: animation)
    }
  }

  // MARK: - Mounting

  public override func mount(_ context: UIContext) {
    self.context = context
    context.registerPresentation(self)
    if self.isPresented {
      // Once the component around it has armed the content, and the anchor has a place.
      context.afterLayout { [weak self] in self?.presentIfWaiting() }
    }
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterPresentation(self)
    // Going with it: at once, without asking the binding, which may be going too.
    if let shown = self.shown {
      self.shown = nil
      shown.presenter = nil
      shown.dismissImmediately()
    }
    self.context = nil
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.textScope = TextScope.current
    return super.calcSize(proposal)
  }

  public override func calcPosition(_ position: float2) {
    super.calcPosition(position)
    // A popover in a window of its own follows its source.
    if self.kind == .popover, let window = self.shown as? WindowPresentation {
      window.anchorMoved(self.anchorRect)
    }
  }

  /// Where a popover points from, in its window: the element it modifies.
  var anchorRect: ClipRect? {
    guard let anchor = self.anchor else { return nil }
    return ClipRect(position: anchor.position, size: anchor.size)
  }

  // MARK: - Presenting

  /// Builds what it shows now. Nil when there is nothing to build from yet.
  func makeContent() -> [UIElement]? {
    self.content?()
  }

  /// The content can be built now: shows it, if it waited for it, once the frame's layout has
  /// run — the message and the write-back are armed after it, and the anchor has a place then.
  func contentArmed() -> Void {
    guard self.mounted, self.isPresented, self.shown == nil, let context = self.context else { return }
    context.afterLayout { [weak self] in self?.presentIfWaiting() }
  }

  /// Presents it if it should show and nothing is shown.
  func presentIfWaiting() -> Void {
    guard self.mounted, self.isPresented, self.shown == nil else { return }
    self.present()
  }

  func present() -> Void {
    guard let context = self.context, self.shown == nil, let elements = self.makeContent() else { return }
    let body = PresentationContent.make(
      self.kind, title: self.title, titleVisibility: self.titleVisibility,
      content: elements, message: self.message?() ?? []
    )
    let styled = TextStyleElement(overrides: self.textScope, defaults: Self.contentDefaults) { body.root }
    let style = self.windowStyle
    let root: PresentationRoot
    if style.placement != .inline, let window = WindowPresentation.open(self, content: styled, style: style, in: context) {
      window.onRemoved = { [weak self] in self?.onDismiss?() }
      root = window
    } else {
      let layer: OverlayLayer
      if self.kind == .popover, let anchor = self.anchor {
        layer = PopoverLayer(styled, anchor: anchor, alignment: .center, modal: true, prefersAbove: self.prefersAbove)
      } else {
        layer = ModalLayer(self.kind, content: styled)
      }
      layer.onRemoved = { [weak self] in self?.onDismiss?() }
      root = layer
    }
    root.presenter = self
    root.inheritedWindowStyle = style
    root.adopt(buttons: body.buttons)
    self.shown = root
    self.shownTitle = body.title
    if let layer = root as? OverlayLayer {
      context.present(layer, parent: self.kind == .popover ? self.anchor : nil)
    }
  }

  /// Texts in a presentation take the form's font unless something sets one.
  static let contentDefaults = TextEnvironment().font(FormMetrics.font)

  func dismissShown(animated: Bool) -> Void {
    guard let shown = self.shown else { return }
    self.shown = nil
    self.shownTitle = nil
    shown.dismissAnimated(animated)
  }

  /// The user asked for `root`, or everything shown from here, to go: reports it to the binding.
  func userDismissed(_ root: PresentationRoot?) -> Void {
    guard let shown = self.shown, root == nil || root === shown else { return }
    self.reportDismissed()
  }

  func reportDismissed() -> Void {
    self.onIsPresentedChange?(false)
  }

  // MARK: - Window style

  /// The style it is presented with: set around it, or on the element it modifies, else the
  /// presentation it is in's, else in the window.
  var windowStyle: PresentationWindowStyle {
    PresentationWindowStyle.effective(for: self)
  }
}

/// `.sheet(item:)` and `.fullScreenCover(item:)`: shown while `item` is not nil, with content
/// built for it. A new item — another `id` — dismisses what shows and presents afresh; the same
/// one again changes nothing.
public final class ItemPresentationElement<Item: Identifiable> : PresentationElement {
  public private(set) var item: Item?
  /// The binding's write-back, armed by `@Component` for `item: $state`.
  public var onItemChange: ((Item?) -> Void)?
  /// Builds the content for an item. `@Component` arms it on mount.
  public var itemContent: ((Item) -> [UIElement])? {
    didSet { self.contentArmed() }
  }
  /// The id of the item what shows was built for.
  private var shownID: Item.ID?

  init(kind: PresentationKind, item: Item?, content: UIElement) {
    self.item = item
    super.init(kind: kind, isPresented: item != nil, content: content)
  }

  public func setItem(_ value: Item?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let wasPresented = self.isPresented
    self.item = value
    self.isPresented = value != nil
    guard self.mounted else { return }
    if let value, wasPresented, self.isShowing, value.id == self.shownID { return }
    if self.isShowing {
      self.dismissShown(animated: true)
    }
    if value != nil {
      self.present()
    }
  }

  override func makeContent() -> [UIElement]? {
    guard let item = self.item, let content = self.itemContent else { return nil }
    self.shownID = item.id
    return content(item)
  }

  override func reportDismissed() -> Void {
    self.onItemChange?(nil)
  }
}
