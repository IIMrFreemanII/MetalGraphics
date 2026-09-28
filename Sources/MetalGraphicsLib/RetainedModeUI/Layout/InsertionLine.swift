import simd

/// Where a dragged row would land: a 2 pt accent capsule across its list, as a `ReorderElement`
/// draws while reordering. Fills the width it is offered, less `indent` at the leading edge. Not
/// in SwiftUI.
public final class InsertionLine : UIRenderableElement {
  public static let thickness: Float = 2
  public static let color: float4 = .accent

  public private(set) var indent: Float
  public private(set) var position: float2 = .zero
  public private(set) var size: float2 = .zero

  public init(indent: Float = 0) {
    self.indent = indent
    super.init()
  }

  public func setIndent(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.indent else { return }
    self.indent = value
    context.invalidate()
  }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 { self.size }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    float2(proposal.width ?? 40, Self.thickness)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    let origin = self.position + float2(self.indent, 0)
    let size = float2(max(self.size.x - self.indent, 0), self.size.y)
    Self.draw(origin: origin, size: size, renderer, effect)
  }

  /// The capsule over `origin` and `size` (window points): what `ReorderIndicator` draws too.
  static func draw(origin: float2, size: float2, color: float4 = InsertionLine.color, _ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    var color = color
    color.w *= effect.opacity
    let drawn = size * effect.scale
    renderer.draw(
      roundedRect: effect.apply(to: origin) - renderer.size * 0.5, size: drawn,
      radii: float4(repeating: Self.thickness * 0.5 * effect.scale), color: color
    )
  }
}
