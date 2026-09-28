import simd

/// The 1 pt line between two docked panes, in the gap colour: what a `DockArea`'s splits leave
/// between panes, on its own for a spec. Fills the length it is offered. Not in SwiftUI.
public final class DockGap : UIRenderableElement {
  public let vertical: Bool
  public private(set) var position: float2 = .zero
  public private(set) var size: float2 = .zero

  /// `vertical`: a line between panes side by side.
  public init(vertical: Bool = true) {
    self.vertical = vertical
    super.init()
  }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 { self.size }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.vertical
      ? float2(DockMetrics.gap, proposal.height ?? 40)
      : float2(proposal.width ?? 40, DockMetrics.gap)
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
    var color = DockMetrics.gapColor
    color.w *= effect.opacity
    let drawn = self.size * effect.scale
    renderer.draw(square: Square(position: effect.apply(to: self.position) - renderer.size * 0.5 + drawn * 0.5, size: drawn, color: color))
  }
}
