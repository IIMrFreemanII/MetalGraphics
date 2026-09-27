/// Children one above the other, top to bottom, aligned horizontally by `alignment`. See
/// `StackElement` for how they share the height.
public class VStack : StackElement {
  public var alignment: HorizontalAlignment = .center

  override var crossKey: AlignmentKey { self.alignment.key }

  public init(alignment: HorizontalAlignment = .center, spacing: Float = 0, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init(axis: 1, spacing: spacing)

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
