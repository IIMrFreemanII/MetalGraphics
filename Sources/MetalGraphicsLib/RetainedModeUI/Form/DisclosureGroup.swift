import simd

/// A label that shows or hides content under it: `DisclosureGroup("Advanced", isExpanded:
/// $advanced) { … }`. A click on the label flips it; the chevron turns and the content fades in
/// or out while what is below slides.
public final class DisclosureGroup : FormControl {
  public private(set) var isExpanded: Bool
  /// Where a click reports the flip. `@Component` arms it with the binding's write-back.
  public var onIsExpandedChange: ((Bool) -> Void)?

  private let label: Text
  private let chevron = DisclosureChevron()
  private let header: UIElement
  /// The content, one row under another, a separator above each.
  private let content = RowStack()
  /// The content as inserted and removed: inset from the header, fading.
  private let revealed: UIElement
  /// The header, and the content while expanded.
  private let body = VStack(alignment: .leading, spacing: 0)

  public init(
    _ label: String, isExpanded: Bool = false, onIsExpandedChange: ((Bool) -> Void)? = nil,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.isExpanded = isExpanded
    self.onIsExpandedChange = onIsExpandedChange
    let label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    self.label = label
    let chevron = self.chevron
    chevron.progress = isExpanded ? 1 : 0
    let hit = HittableView(onTap: nil) {
      HStack(spacing: FormMetrics.labelSpacing) {
        label
        Spacer()
        chevron
      }
    }
    self.header = hit
    self.content.applyContent(content())
    // The header's row inset below it, before the first separator.
    self.revealed = self.content.padding(Inset(top: FormMetrics.rowInset.bottom)).transition(.opacity)
    self.body.applyContent(isExpanded ? [hit, self.revealed] : [hit])
    super.init(content: self.body)
    hit.onTap = { [unowned self] _ in self.flip() }
  }

  /// A hand-built group over a binding. In a `@Component` body `$state` is lowered instead.
  public convenience init(
    _ label: String, isExpanded: Binding<Bool>, @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.init(label, isExpanded: isExpanded.wrappedValue, content: content)
    self.onIsExpandedChange = { [unowned self] value in
      isExpanded.wrappedValue = value
      if let context = self.context { self.setIsExpanded(isExpanded.wrappedValue, context) }
    }
  }

  /// The door `@Component` attaches the content through.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.content.replaceChildren(elements, context, animation: animation)
  }

  private func flip() {
    guard !self.isDisabled, let report = self.onIsExpandedChange else { return }
    let value = !self.isExpanded
    self.commit { report(value) }
  }

  public func setIsExpanded(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.isExpanded else { return }
    self.isExpanded = value
    let animation = self.animation(animation)
    self.chevron.setProgress(value ? 1 : 0, context, animation: animation)
    self.body.replaceChildren(value ? [self.header, self.revealed] : [self.header], context, animation: animation)
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }
}

/// A chevron pointing right, turned to point down as `progress` goes to 1.
final class DisclosureChevron : FormGraphic {
  static let size = float2(14, 14)

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    Self.size
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    var ink = FormMetrics.secondaryColor
    ink.w *= opacity
    let angle = self.progress * .pi * 0.5
    let (c, s) = (cos(angle), sin(angle))
    let center = origin + size * 0.5
    // `>` about the centre, turned clockwise (y is down).
    func point(_ x: Float, _ y: Float) -> float2 {
      center + float2(x * c - y * s, x * s + y * c) * scale
    }
    let tip = point(2, 0)
    renderer.draw(stroke: point(-2, -4.5), to: tip, width: 1.8 * scale, color: ink)
    renderer.draw(stroke: tip, to: point(-2, 4.5), width: 1.8 * scale, color: ink)
  }
}
