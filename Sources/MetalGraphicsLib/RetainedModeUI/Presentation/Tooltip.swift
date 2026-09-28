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
