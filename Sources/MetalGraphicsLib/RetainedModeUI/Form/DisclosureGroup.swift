import simd

/// A label that shows or hides content under it: `DisclosureGroup("Advanced", isExpanded:
/// $advanced) { … }`. A click on the label flips it; the chevron turns and the content fades in
/// or out while what is below slides.
public final class DisclosureGroup : FormControl {
  public private(set) var isExpanded: Bool
  /// Where a click reports the flip. `@Component` arms it with the binding's write-back.
  public var onIsExpandedChange: ((Bool) -> Void)?

  private let label: Text
  /// Turns to point down while expanded: the animated chevron.
  private let chevron: AnimatedIcon
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
    self.chevron = AnimatedIcon(.chevronRight, active: isExpanded).foregroundColor(FormMetrics.secondaryColor)
    let label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    self.label = label
    let chevron = self.chevron
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
    self.chevron.setActive(value, context)
    self.body.replaceChildren(value ? [self.header, self.revealed] : [self.header], context, animation: animation)
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }
}
