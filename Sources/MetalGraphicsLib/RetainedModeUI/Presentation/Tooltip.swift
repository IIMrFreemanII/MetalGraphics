import simd

/// A tooltip's sizes and type.
public enum TooltipMetrics {
  /// A one-line tip.
  public static let font = TextFont.system(size: 12)
  public static let inset = Inset(vertical: 4, horizontal: 8)
  public static var radius: Float { Theme.current.radii.md }
  /// A hover card: several lines, as the editor's hover shows a symbol's declaration and doc.
  public static let multilineInset = Inset(vertical: 6, horizontal: 8)
  public static let multilineRadius: Float = 8
  public static let maxWidth: Float = 420
  public static let shadowRadius: Float = 8
  public static let shadowY: Float = 4
}

/// A small label on tooltip glass: what a control does, or with `multiline` a hover card of up to
/// 420 points, as the editor shows over a symbol. Not interactive: put it over content with
/// `.allowsHitTesting(false)`, or let `.help(_:)` show it.
///
///     Tooltip("Build and run (⌘R)")
///     Tooltip(declaration, multiline: true)
public final class Tooltip : SingleChildElement {
  public let multiline: Bool
  private let text: Text

  public init(_ text: String, multiline: Bool = false) {
    self.multiline = multiline
    let label = Text(text).font(TooltipMetrics.font)
    self.text = label
    super.init()
    let shape = UIShape.rect(cornerRadius: multiline ? TooltipMetrics.multilineRadius : TooltipMetrics.radius)
    let content: UIElement = multiline
      ? label
        .padding(TooltipMetrics.multilineInset)
        .frame(maxWidth: TooltipMetrics.maxWidth, alignment: .leading)
      : label.lineLimit(1).padding(TooltipMetrics.inset)
    self.applyContent([
      content
        .glass(.tooltip, in: shape)
        .border(.separator, width: 0.5, in: shape)
        .shadow(color: .shadow, radius: TooltipMetrics.shadowRadius, y: TooltipMetrics.shadowY)
    ])
  }

  public var textValue: String { self.text.text }

  public func setText(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.text.text else { return }
    self.text.setText(value, context, animation: animation)
  }
}

/// A tooltip over everything, under the element it explains: centred below it, or above when
/// there is no room below, inside the window. Takes no input: what is under it is still hovered
/// and clicked.
final class TooltipLayer : OverlayLayer {
  static let gap: Float = 6
  static let margin: Float = 8
  static let animation = UIAnimation.easeOut(0.12)

  private weak var anchor: (any Hittable)?
  private let tip: UIElement
  private let transition: TransitionElement
  private var tipSize: float2 = .zero

  init(_ text: String, anchor: any Hittable) {
    self.anchor = anchor
    let tip = Tooltip(text).allowsHitTesting(false)
    self.tip = tip
    self.transition = TransitionElement(.opacity) { tip }
    super.init(isModal: false, dismissesOnOutsideScroll: true)
    self.applyContent([self.transition])
  }

  override func animateIn(_ context: UIContext) {
    self.transition.animateIn(Self.animation, context)
  }

  override func animateOut(_ context: UIContext, completion: @escaping () -> Void) {
    self.transition.animateOut(Self.animation, context, completion: completion)
  }

  override func layout(in windowSize: float2) {
    self.tipSize = self.transition.calcSize(.unspecified)
  }

  override func calcPosition(_ position: float2) {
    guard let anchor = self.anchor else { return }
    let top = anchor.hitPosition.y
    let bottom = top + anchor.hitSize.y
    let fitsBelow = bottom + Self.gap + self.tipSize.y + Self.margin <= self.windowSize.y
    let y = fitsBelow ? bottom + Self.gap : top - Self.gap - self.tipSize.y
    var x = anchor.hitPosition.x + (anchor.hitSize.x - self.tipSize.x) * 0.5
    x = min(max(x, Self.margin), max(self.windowSize.x - Self.margin - self.tipSize.x, Self.margin))
    self.transition.calcPosition(float2(x.rounded(), y.rounded()))
  }
}

/// Shows `text` in a tooltip after the pointer rests on its content for 0.6 s, and hides it when
/// the pointer leaves or the window scrolls: `.help(_:)`, as SwiftUI's. The window still goes
/// idle while the pointer rests: a wake, not an animation, times it.
public final class HelpElement : SingleChildElement, WakeTarget {
  public static let delay: Double = 0.6

  public private(set) var text: String
  private let hit: HittableView
  private var hovered = false
  private weak var layer: TooltipLayer?
  private weak var context: UIContext?

  public init(_ text: String, @UIElementBuilder content: () -> [UIElement]) {
    self.text = text
    let hit = HittableView(onTap: nil) {}
    hit.applyContent(content())
    self.hit = hit
    super.init()
    self.applyContent([hit])
    hit.onHover = { [unowned self] hovered, _ in self.hover(hovered) }
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func unmount(_ context: UIContext) {
    context.cancelWake(for: self)
    self.layer?.dismiss(animated: false)
    self.hovered = false
    self.context = nil
  }

  private func hover(_ value: Bool) {
    guard value != self.hovered, let context = self.context else { return }
    self.hovered = value
    if value {
      context.requestWake(at: context.clock() + Self.delay, for: self)
    } else {
      context.cancelWake(for: self)
      self.layer?.dismiss(animated: true)
    }
  }

  public func wake(_ context: UIContext, now: Double) {
    guard self.hovered, self.mounted, self.layer == nil, !self.text.isEmpty else { return }
    let layer = TooltipLayer(self.text, anchor: self.hit)
    self.layer = layer
    context.present(layer, parent: self.hit)
  }

  /// What the tooltip says; "" shows none.
  public func setText(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.text else { return }
    self.text = value
    // Shown with the old text: shown anew with the new one the next time.
    self.layer?.dismiss(animated: false)
  }

  /// Whether its tooltip shows now.
  public var isShowingTooltip: Bool { self.layer.map { !$0.isDismissing } ?? false }
}

public extension UIElement {
  /// Explains this element in a tooltip when the pointer rests on it. See `HelpElement`.
  func help(_ text: String) -> HelpElement {
    HelpElement(text) { self }
  }
}
