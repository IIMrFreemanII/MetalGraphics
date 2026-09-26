import simd

/// A popover on screen, for dismissing it. See `UIContext.presentPopover`.
@MainActor public final class PopoverHandle {
  fileprivate weak var layer: PopoverLayer?

  /// True until it has finished animating out.
  public var isPresented: Bool { self.layer != nil }
}

extension UIContext {
  /// Shows `content` on a card next to `anchor`, above everything else and outside every clip:
  /// below the anchor, or above it when there is more room there, and inside the window.
  ///
  /// A click outside the card, Escape, a scroll outside the card, or the anchor going away
  /// dismisses it; `onDismiss` runs once it is gone. It takes key presses: focus is cleared, so
  /// handlers in `content` that belong to no focusable element get them first.
  ///
  /// The popover is laid out apart from the tree, so the text style around the anchor does not
  /// reach it: pass it as `textStyle`, with `textDefaults` under it, to style the texts inside as
  /// if they were there. It is taken as it is now, and not updated while the popover is open.
  @discardableResult
  public func presentPopover(
    _ content: UIElement, anchor: any Hittable, alignment: HorizontalAlignment = .trailing,
    textStyle: TextEnvironment? = nil, textDefaults: TextEnvironment = TextEnvironment(),
    onDismiss: (() -> Void)? = nil
  ) -> PopoverHandle {
    let handle = PopoverHandle()
    var content = content
    if textStyle != nil || textDefaults != TextEnvironment() {
      let wrapped = content
      content = TextStyleElement(overrides: textStyle ?? TextEnvironment(), defaults: textDefaults) { wrapped }
    }
    let layer = PopoverLayer(content, anchor: anchor, alignment: alignment, onDismiss: onDismiss)
    layer.handle = handle
    handle.layer = layer
    layer.context = self
    self.overlays.append(layer)
    self.focus(nil)
    layer.handleMount(self)
    self.invalidate([.layout, .treeOrder])
    layer.transition.animateIn(PopoverLayer.animation, self)
    return handle
  }

  public func dismissPopover(_ handle: PopoverHandle, animated: Bool = true) {
    handle.layer?.dismiss(animated: animated)
  }

  public func dismissAllPopovers() {
    for overlay in self.overlays {
      overlay.dismiss(animated: true)
    }
  }
}

/// The root of one popover: a see-through scrim over the whole window that dismisses on a click,
/// and the card placed by its anchor. Held by `UIContext.overlays`, never in the app's tree.
final class PopoverLayer : MultiChildElement {
  static let animation = UIAnimation.easeOut(0.12)
  static let gap: Float = 4
  static let margin: Float = 8
  static let cornerRadius: Float = 8

  weak var anchor: (any Hittable)?
  weak var context: UIContext?
  weak var handle: PopoverHandle?
  let alignment: HorizontalAlignment
  let onDismiss: (() -> Void)?
  let transition: TransitionElement

  private let scrim = HittableView(onTap: nil) {}
  private let card: UIElement
  private var dismissing = false
  private var windowSize: float2 = .zero
  private var cardSize: float2 = .zero
  private var cardOrigin: float2 = .zero
  private var below = true

  init(_ content: UIElement, anchor: any Hittable, alignment: HorizontalAlignment, onDismiss: (() -> Void)?) {
    self.anchor = anchor
    self.alignment = alignment
    self.onDismiss = onDismiss
    let radius = Self.cornerRadius
    let card = ScrollView(.vertical) { content }
      .clipShape(.rect(cornerRadius: radius))
      .background {
        PopoverFill().shadow(color: float4(0, 0, 0, 0.22), radius: 10, y: 4)
      }
      .border(float4(0, 0, 0, 0.12), width: 0.5, in: .rect(cornerRadius: radius))
    // A tap goes to the topmost view that takes taps, and a press to the topmost that takes
    // presses. This takes both under the content, so a click anywhere on the card — on a
    // slider, which only presses, or on nothing — never reaches the scrim and dismisses.
    let backstop = HittableView(onTap: { _ in }, onPress: { _, _ in }) { card }
    let transition = TransitionElement(.opacity.combined(with: .scale(0.96))) { backstop }
    self.transition = transition
    let escape = KeyPressElement(keys: [.escape], phases: [.down], action: nil) { transition }
    self.card = escape
    super.init()
    self.applyContent([self.scrim, escape])
    self.scrim.onTap = { [unowned self] _ in self.dismiss(animated: true) }
    escape.action = { [unowned self] _ in
      self.dismiss(animated: true)
      return .handled
    }
  }

  /// Whether `point`, window top left origin, lands on the card.
  func cardContains(_ point: float2) -> Bool {
    ClipRect(position: self.cardOrigin, size: self.cardSize).contains(point)
  }

  func dismiss(animated: Bool) {
    guard !self.dismissing, let context = self.context else { return }
    self.dismissing = true
    // Still drawn while it fades, but no longer hit: the app underneath is live again.
    self.isLeaving = true
    context.invalidate(.treeOrder)
    guard animated else {
      self.remove(context)
      return
    }
    self.transition.animateOut(Self.animation, context) { [weak self, weak context] in
      guard let self, let context else { return }
      self.remove(context)
    }
  }

  private func remove(_ context: UIContext) {
    context.overlays.removeAll { $0 === self }
    self.isLeaving = false
    self.handleUnmount(context)
    context.invalidate([.layout, .treeOrder])
    self.handle?.layer = nil
    self.onDismiss?()
  }

  // MARK: - Layout

  override func getSize() -> float2 {
    self.windowSize
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.windowSize = proposal.replacingUnspecified(with: .zero)
    _ = self.scrim.calcSize(ProposedSize(self.windowSize))

    guard let anchor = self.anchor, anchor.mounted else {
      // The anchor went away under it: nothing left to point at.
      if let context = self.context {
        context.afterLayout { [weak self] in self?.dismiss(animated: false) }
      }
      return self.windowSize
    }
    let top = anchor.hitPosition.y
    let bottom = top + anchor.hitSize.y
    let ideal = self.card.measure(.unspecified)
    let spaceBelow = self.windowSize.y - bottom - Self.gap - Self.margin
    let spaceAbove = top - Self.gap - Self.margin
    self.below = ideal.y <= spaceBelow || spaceBelow >= spaceAbove
    let height = min(ideal.y, max(self.below ? spaceBelow : spaceAbove, 40))
    let width = min(ideal.x, self.windowSize.x - Self.margin * 2)
    self.cardSize = self.card.calcSize(ProposedSize(width: width, height: height))
    return self.windowSize
  }

  override func calcPosition(_ position: float2) {
    self.scrim.calcPosition(position)
    guard let anchor = self.anchor else { return }
    let anchorMin = anchor.hitPosition
    let anchorMax = anchorMin + anchor.hitSize
    var x: Float
    switch self.alignment {
    case .leading: x = anchorMin.x
    case .center: x = (anchorMin.x + anchorMax.x - self.cardSize.x) * 0.5
    default: x = anchorMax.x - self.cardSize.x
    }
    x = min(max(x, Self.margin), max(self.windowSize.x - Self.margin - self.cardSize.x, Self.margin))
    let y = self.below ? anchorMax.y + Self.gap : anchorMin.y - Self.gap - self.cardSize.y
    self.cardOrigin = float2(x, y)
    self.card.calcPosition(self.cardOrigin)
  }
}

/// A popover card's white rounded fill, as large as it is offered. Under its own shadow, apart
/// from the content, so the text on the card casts none.
final class PopoverFill : FormGraphic {
  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    renderer.draw(
      roundedRect: origin, size: size, radii: float4(repeating: PopoverLayer.cornerRadius * scale),
      color: float4(1, 1, 1, opacity)
    )
  }
}
