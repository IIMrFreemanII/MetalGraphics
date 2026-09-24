import simd

/// How forms and their controls look: one place, like `TableMetrics`. SwiftUI's grouped form
/// style on macOS, approximately.
@MainActor
public enum FormMetrics {
  /// Behind the whole form, and between its sections.
  public static let groupedBackground = float4(0.93, 0.93, 0.94, 1)
  /// A section's card.
  public static let cardColor = float4(1, 1, 1, 1)
  public static let cardCornerRadius: Float = 10
  public static let separatorColor = float4(0, 0, 0, 0.1)

  public static let formInset: Float = 20
  public static let sectionSpacing: Float = 20
  /// Around each row's content, inside the card.
  public static let rowInset = Inset(vertical: 9, horizontal: 14)
  /// A row's content is at least this tall, so rows of plain text and rows of controls line up.
  public static let rowMinHeight: Float = 22
  /// Between a section's header or footer and its card.
  public static let captionGap: Float = 6

  /// A proportional face, as SwiftUI's controls use, rather than the monospaced default.
  public static let face = FontManager.shared.font(named: "Helvetica Neue")
  public static let font = TextFont.custom(face, size: 14)
  public static let captionFont = TextFont.custom(face, size: 12)
  public static let labelColor = float4(0.1, 0.1, 0.1, 1)
  public static let secondaryColor = float4(0.45, 0.45, 0.47, 1)
  public static let accentColor = float4(0.0, 0.48, 1.0, 1)
  public static let destructiveColor = float4(0.92, 0.23, 0.2, 1)
  /// A control's track, a field's border, an off switch.
  public static let fillColor = float4(0.86, 0.86, 0.88, 1)
  public static let strokeColor = float4(0, 0, 0, 0.15)

  /// Between a control's label and the control.
  public static let labelSpacing: Float = 12
  public static let disabledOpacity: Float = 0.4
  /// How a control animates a change the user made on it: a knob sliding, a chevron turning.
  public static let interaction = UIAnimation.easeOut(0.18)
}

/// A form control: built from existing elements once, in `init`, and updated through its
/// setters. Dimmed and inert while disabled.
///
/// A control never changes its own value on input. It reports the new value to its change
/// handler — the write-back `@Component` arms for a binding — and the state's update brings the
/// value back through the setter, in the same event. So the state is the only source of truth,
/// and a control given a constant keeps it, as in SwiftUI.
open class FormControl : SingleChildElement {
  public private(set) var isDisabled = false
  /// Set while the mounted tree is live; what input handlers invalidate through.
  public private(set) weak var context: UIContext?

  /// True while a change the user made is being reported. The setters the report comes back
  /// through then animate with `FormMetrics.interaction` unless told otherwise, so a click slides
  /// a knob but a plain state write outside `withAnimation` still snaps it.
  private var interacting = false

  /// Wraps the whole control: what disabling dims.
  private let dimmer: EffectElement

  public init(content: UIElement) {
    self.dimmer = EffectElement { content }
    super.init()
    self.applyContent([self.dimmer])
  }

  open override func mount(_ context: UIContext) {
    self.context = context
  }

  open override func unmount(_ context: UIContext) {
    self.context = nil
  }

  /// Replaces what the control is built from, e.g. a picker changing style.
  func setContent(_ content: UIElement, animation: UIAnimation? = nil) {
    if let context = self.context {
      self.dimmer.setChild(content, context, animation: animation)
    } else {
      self.dimmer.child = content
    }
  }

  /// Reports a change the user made. Runs `report` — the change handler — with interaction
  /// animation on for whatever comes back through the setters.
  func commit(_ report: () -> Void) {
    self.interacting = true
    defer { self.interacting = false }
    report()
  }

  /// What a setter animates with: the one it was given, else the interaction's while reporting.
  func animation(_ given: UIAnimation?) -> UIAnimation? {
    given ?? (self.interacting ? FormMetrics.interaction : nil)
  }

  /// True while reporting a change the user made.
  var isInteracting: Bool { self.interacting }

  public func setDisabled(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.isDisabled else { return }
    self.isDisabled = value
    self.dimmer.setOpacity(value ? FormMetrics.disabledOpacity : 1, context, animation: animation)
    self.disabledChanged(context)
  }

  /// Built disabled, before anything is mounted: `.disabled(true)`.
  public func disabled(_ value: Bool) -> Self {
    self.isDisabled = value
    self.dimmer.opacity = value ? FormMetrics.disabledOpacity : 1
    return self
  }

  /// Called when a mounted control is enabled or disabled, e.g. to give up focus.
  func disabledChanged(_ context: UIContext) {}
}

/// Something a control draws itself — a switch, a track, a check mark — at the size layout gives
/// it. Subclasses override `sizeThatFits` and `draw`.
public class FormGraphic : UIRenderableElement {
  public internal(set) var position: float2 = .zero
  public internal(set) var size: float2 = .zero

  public override init() {
    super.init()
  }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    // origin -> top left, window centered
    let origin = effect.apply(to: self.position) - renderer.size * 0.5
    self.draw(renderer, origin: origin, size: self.size * effect.scale, scale: effect.scale, opacity: effect.opacity)
  }

  /// Draws into the rect at `origin`, window centered, y down, `size` large. `scale` is the
  /// effects' scale, for line widths; multiply `opacity` into every color's alpha.
  func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {}

  /// The one animated value a graphic has: a knob's travel, a fill's fraction, a chevron's turn.
  public internal(set) var progress: Float = 0

  /// Moves `progress` to `value` through the animator; only redraws.
  func setProgress(_ value: Float, _ context: UIContext, animation: UIAnimation?) {
    context.animator.set(self, .progress, from: self.progress, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: FormGraphic.self).progress = value.x
      context.invalidate()
    }
  }
}

func mix(_ a: float4, _ b: float4, _ t: Float) -> float4 {
  a + (b - a) * t
}

extension UIElementWrapping where Self: UIElement {
  /// What a `Picker` option selects. Sets this element's own tag and returns it.
  public func tag<V: Hashable>(_ value: V) -> Self {
    self.ownTag = AnyHashable(value)
    return self
  }
}
