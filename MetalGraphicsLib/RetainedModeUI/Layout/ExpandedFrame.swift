import simd

/// Takes all the space it is offered along `axis`, and its content's size across it: SwiftUI's
/// `.frame(maxWidth: .infinity)`, `.frame(maxHeight: .infinity)` or both, spelled by axis.
public class ExpandedFrame : FlexFrame {
  public var axis: Axis {
    didSet { self.applyAxis() }
  }

  public init(_ axis: Axis, _ alignment: Alignment = .center, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.axis = axis

    super.init(alignment: alignment, content: content)

    self.applyAxis()
  }

  private func applyAxis() {
    self.maxWidth = self.axis.horizontal != 0 ? .infinity : nil
    self.maxHeight = self.axis.vertical != 0 ? .infinity : nil
  }
}
