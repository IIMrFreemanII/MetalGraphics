import simd

/// A label at the leading edge and a value, or any content, at the trailing one: the row shape
/// of every form control. `LabeledContent("Version", value: "1.0")`, or
/// `LabeledContent("Status") { Text("Online") }`.
public final class LabeledContent : SingleChildElement {
  private let label: Text
  /// Shown when there is no content.
  private let value: Text
  /// The value, or the content in its place.
  private let trailing: HStack

  public init(_ label: String, value: String = "", @UIElementBuilder content: () -> [UIElement] = { [] }) {
    let label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    let value = Text(value).font(FormMetrics.font).foregroundColor(FormMetrics.secondaryColor)
    let trailing = HStack(spacing: 8)
    let elements = content()
    trailing.applyContent(elements.isEmpty ? [value] : elements)
    self.label = label
    self.value = value
    self.trailing = trailing
    super.init()

    self.applyContent([
      HStack(spacing: FormMetrics.labelSpacing) {
        label
        Spacer()
        trailing
      }
    ])
  }

  /// The door `@Component` attaches content through: it takes the value's place.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.trailing.replaceChildren(elements.isEmpty ? [self.value] : elements, context, animation: animation)
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }

  public func setValue(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.value.text else { return }
    self.value.setText(value, context, animation: animation)
  }
}
