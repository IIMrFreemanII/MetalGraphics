/// Children side by side, left to right, aligned vertically by `alignment`. See `StackElement`
/// for how they share the width.
public class HStack : StackElement {
  public var alignment: VerticalAlignment = .center

  override var crossKey: AlignmentKey { self.alignment.key }

  public init(alignment: VerticalAlignment = .center, spacing: Float = 0, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init(axis: 0, spacing: spacing)

    self.alignment = alignment

    self.applyContent(content())
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(size: \(size), spacing: \(spacing), alignment: \(alignment)")

    for child in children {
      child.debugHierarchy(offset + "  ")
    }
  }
}
