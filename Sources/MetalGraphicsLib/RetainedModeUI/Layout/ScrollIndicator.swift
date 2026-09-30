import simd

/// A scroll bar as a scroll view draws it, on its own: the 5 pt capsule-ended bar, `length`
/// long, in the scroll indicator colour. For a spec or a custom scroller; a `ScrollView` draws
/// its own. Not in SwiftUI.
public final class ScrollIndicator : UIRenderableElement {
  public private(set) var length: Float
  public private(set) var vertical: Bool
  public private(set) var position: float2 = .zero
  public private(set) var size: float2 = .zero

  public init(length: Float = 60, vertical: Bool = true) {
    self.length = length
    self.vertical = vertical
    super.init()
  }

  public func setLength(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.length else { return }
    self.length = value
    context.invalidate(.layout)
  }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 { self.size }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let thickness = ScrollViewIndicator.thickness
    return self.vertical ? float2(thickness, self.length) : float2(self.length, thickness)
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
    var color = ScrollViewIndicator.color
    color.w *= effect.opacity
    let drawn = self.size * effect.scale
    renderer.draw(
      roundedRect: effect.apply(to: self.position) - renderer.size * 0.5, size: drawn,
      radii: float4(repeating: ScrollViewIndicator.thickness * 0.5 * effect.scale), color: color
    )
  }
}
