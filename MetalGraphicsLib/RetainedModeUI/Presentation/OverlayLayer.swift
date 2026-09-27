import simd

/// A root of its own over the app's tree: a popover or a modal presentation. Held by
/// `UIContext.overlays`, laid out after the tree at the window's size and collected after it, so
/// it draws and hits above everything, outside every clip. See `UIContext.present(_:parent:)`.
class OverlayLayer : PresentationRoot {
  weak var context: UIContext?
  /// Blocks input to everything under it: the tree and the overlays below. See
  /// `UIContext.modalFocusStart`.
  let isModal: Bool
  /// A scroll outside it dismisses it, and still scrolls what is under it: a menu, a picker.
  let dismissesOnOutsideScroll: Bool
  /// Runs once it is gone, after animating out.
  var onRemoved: (() -> Void)?
  /// What was focused when it was presented, focused again when it goes.
  weak var restoreFocus: FocusableElement?

  init(isModal: Bool, dismissesOnOutsideScroll: Bool) {
    self.isModal = isModal
    self.dismissesOnOutsideScroll = dismissesOnOutsideScroll
    super.init()
  }

  /// Whether `point`, window top left origin, lands on what it shows.
  func contains(_ point: float2) -> Bool { false }

  func animateIn(_ context: UIContext) -> Void {}

  /// Animates out; `completion` runs once it is out, and not at all when `animated` is false.
  func animateOut(_ context: UIContext, completion: @escaping () -> Void) -> Void {
    completion()
  }

  override func dismissItself() -> Void {
    self.dismiss(animated: true)
  }

  override var presentedContext: UIContext? { self.context }

  override func dismissAnimated(_ animated: Bool) -> Void {
    self.dismiss(animated: animated)
  }

  override func dismissImmediately() -> Void {
    self.onRemoved = nil
    self.dismiss(animated: false)
  }

  /// Goes: still drawn while it animates out, but no longer hit, and the input it blocked goes
  /// to what is under it again at once.
  func dismiss(animated: Bool) -> Void {
    guard !self.isDismissing, let context = self.context else { return }
    self.isDismissing = true
    self.isLeaving = true
    context.invalidate(.treeOrder)
    self.dismissNested(context)
    self.dismissOverlaysAbove(context)
    if let focus = self.restoreFocus, focus.mounted, context.focused.map({ $0.isInside(self) }) ?? true {
      context.focus(focus)
    }
    guard animated else {
      self.remove(context)
      return
    }
    self.animateOut(context) { [weak self, weak context] in
      guard let self, let context else { return }
      self.remove(context)
    }
  }

  /// Popovers a control inside it opened, which no presenter dismisses.
  private func dismissOverlaysAbove(_ context: UIContext) -> Void {
    for overlay in context.overlays where overlay !== self && !overlay.isDismissing && overlay.presenter == nil {
      if overlay.isInside(self) { overlay.dismiss(animated: false) }
    }
  }

  private func remove(_ context: UIContext) -> Void {
    context.overlays.removeAll { $0 === self }
    self.isLeaving = false
    self.handleUnmount(context)
    context.invalidate([.layout, .treeOrder])
    let onRemoved = self.onRemoved
    self.onRemoved = nil
    onRemoved?()
  }

  // MARK: - Layout

  /// The window's size, set by `calcSize`.
  private(set) var windowSize: float2 = .zero

  override func getSize() -> float2 {
    self.windowSize
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.windowSize = proposal.replacingUnspecified(with: .zero)
    self.layout(in: self.windowSize)
    return self.windowSize
  }

  /// Sizes what it shows in a window of `windowSize`.
  func layout(in windowSize: float2) -> Void {}
}

extension UIElement {
  /// Whether `ancestor` is this element or above it, through `parent`. O(depth).
  func isInside(_ ancestor: UIElement) -> Bool {
    var current: UIElement? = self
    while let element = current {
      if element === ancestor { return true }
      current = element.parent
    }
    return false
  }
}
