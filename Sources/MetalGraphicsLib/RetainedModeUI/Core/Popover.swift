import simd

/// A popover on screen, for dismissing it. See `UIContext.presentPopover`.
public final class PopoverHandle {
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
  ///
  /// `material` is the card's glass: `.popover`, or `.menu` for a menu.
  @discardableResult
  public func presentPopover(
    _ content: UIElement, anchor: any Hittable, alignment: HorizontalAlignment = .trailing,
    material: ThemeMaterial = .popover,
    textStyle: TextEnvironment? = nil, textDefaults: TextEnvironment = TextEnvironment(),
    onDismiss: (() -> Void)? = nil
  ) -> PopoverHandle {
    let handle = PopoverHandle()
    var content = content
    if textStyle != nil || textDefaults != TextEnvironment() {
      let wrapped = content
      content = TextStyleElement(overrides: textStyle ?? TextEnvironment(), defaults: textDefaults) { wrapped }
    }
    let layer = PopoverLayer(content, anchor: anchor, alignment: alignment, modal: false, material: material)
    handle.layer = layer
    layer.onRemoved = { [weak handle] in
      handle?.layer = nil
      onDismiss?()
    }
    self.present(layer, parent: anchor as? UIElement)
    return handle
  }

  public func dismissPopover(_ handle: PopoverHandle, animated: Bool = true) {
    handle.layer?.dismiss(animated: animated)
  }

  /// Dismisses the popovers controls opened above the topmost modal presentation: a menu, a
  /// date picker's calendar. A sheet, and what is under it, stay.
  public func dismissAllPopovers() {
    for overlay in self.overlays.reversed() {
      if overlay.isModal && !overlay.isDismissing { break }
      if overlay.presenter == nil {
        overlay.dismiss(animated: true)
      }
    }
  }
}

/// The root of one popover: a see-through scrim over the whole window that dismisses on a click,
/// and the card placed by its anchor. Held by `UIContext.overlays`, never in the app's tree.
///
/// A control's popover is transient: the scrim takes a click, and a press under it still
/// reaches what is there. A `.popover` presentation's is modal: the scrim takes presses too.
final class PopoverLayer : OverlayLayer {
  static let animation = UIAnimation.easeOut(0.12)
  static let gap: Float = 4
  static let margin: Float = 8
  static let cornerRadius: Float = 10

  weak var anchor: (any Hittable)?
  let alignment: HorizontalAlignment
  /// Above the anchor when it fits there, rather than below: `.popover(arrowEdge: .bottom)`.
  let prefersAbove: Bool
  let transition: TransitionElement

  private let scrim: HittableView
  private let card: UIElement
  private var cardSize: float2 = .zero
  private var cardOrigin: float2 = .zero
  private var below = true

  init(
    _ content: UIElement, anchor: any Hittable, alignment: HorizontalAlignment, modal: Bool,
    prefersAbove: Bool = false, material: ThemeMaterial = .popover
  ) {
    self.anchor = anchor
    self.alignment = alignment
    self.prefersAbove = prefersAbove
    self.scrim = HittableView(onTap: nil, onPress: modal ? { _, _ in } : nil) {}
    let card = CardChrome.popover(content, material: material)
    // A tap goes to the topmost view that takes taps, and a press to the topmost that takes
    // presses. This takes both under the content, so a click anywhere on the card — on a
    // slider, which only presses, or on nothing — never reaches the scrim and dismisses.
    let backstop = HittableView(onTap: { _ in }, onPress: { _, _ in }) { card }
    let transition = TransitionElement(.opacity.combined(with: .scale(0.96))) { backstop }
    self.transition = transition
    let escape = KeyPressElement(keys: [.escape], phases: [.down], action: nil) { transition }
    self.card = escape
    super.init(isModal: modal, dismissesOnOutsideScroll: true)
    self.applyContent([self.scrim, escape])
    self.scrim.onTap = { [unowned self] _ in self.requestDismiss() }
    escape.action = { [unowned self] _ in
      self.cancel()
      return .handled
    }
  }

  override func contains(_ point: float2) -> Bool {
    ClipRect(position: self.cardOrigin, size: self.cardSize).contains(point)
  }

  override func animateIn(_ context: UIContext) {
    self.transition.animateIn(Self.animation, context)
  }

  override func animateOut(_ context: UIContext, completion: @escaping () -> Void) {
    self.transition.animateOut(Self.animation, context, completion: completion)
  }

  // MARK: - Layout

  override func layout(in windowSize: float2) {
    _ = self.scrim.calcSize(ProposedSize(windowSize))

    guard let anchor = self.anchor, anchor.mounted else {
      // The anchor went away under it: nothing left to point at.
      if let context = self.context {
        context.afterLayout { [weak self] in self?.dismiss(animated: false) }
      }
      return
    }
    let top = anchor.hitPosition.y
    let bottom = top + anchor.hitSize.y
    let ideal = self.card.measure(.unspecified)
    let spaceBelow = windowSize.y - bottom - Self.gap - Self.margin
    let spaceAbove = top - Self.gap - Self.margin
    if self.prefersAbove {
      self.below = !(ideal.y <= spaceAbove || spaceAbove >= spaceBelow)
    } else {
      self.below = ideal.y <= spaceBelow || spaceBelow >= spaceAbove
    }
    let height = min(ideal.y, max(self.below ? spaceBelow : spaceAbove, 40))
    let width = min(ideal.x, windowSize.x - Self.margin * 2)
    self.cardSize = self.card.calcSize(ProposedSize(width: width, height: height))
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

/// A card's rounded fill, as large as it is offered: a popover's, a sheet's, an alert's. Under
/// its own shadow, apart from the content, so the text on the card casts none. With a
/// `material`, the card is that glass of the theme's, over whatever is behind it.
final class CardFill : FormGraphic {
  let cornerRadius: Float
  let color: float4
  let material: ThemeMaterial?

  init(cornerRadius: Float, color: float4 = .card, material: ThemeMaterial? = nil) {
    self.cornerRadius = cornerRadius
    self.color = color
    self.material = material
    super.init()
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let radii = float4(repeating: self.cornerRadius * scale)
    if let material = self.material {
      let glass = renderer.theme[material]
      renderer.draw(
        glass: origin, size: size, radii: radii, material: glass,
        sigma: glass.blurRadius * ShadowState.sigmaPerRadius * scale, opacity: opacity
      )
      return
    }
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: self.color.withAlpha(opacity))
  }
}
