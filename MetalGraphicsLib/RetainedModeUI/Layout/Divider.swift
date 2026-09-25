import simd

/// A thin line that separates content: across a `VStack`, down an `HStack`, and across
/// anywhere else. It fills its stack's cross axis and is one point thick.
public final class Divider : UIRenderableElement {
  public var color: float4
  public var thickness: Float

  /// Its length when asked for its ideal size, as SwiftUI's.
  static let idealLength: Float = 10

  public private(set) var position: float2 = .zero
  public private(set) var size: float2 = .zero

  public init(color: float4 = float4(0, 0, 0, 0.1), thickness: Float = 1) {
    self.color = color
    self.thickness = thickness
    super.init()
  }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    // Vertical only in an HStack.
    let along = self.stackAxis == 0 ? 1 : 0
    var size = float2()
    size[along] = proposal[along] ?? Self.idealLength
    size[1 - along] = self.thickness
    return size
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
    let size = self.size * effect.scale
    var color = self.color
    color.w *= effect.opacity
    // origin -> top left
    let origin = effect.apply(to: self.position) - renderer.size * 0.5 + size * 0.5
    renderer.draw(square: Square(position: origin, size: size, color: color))
  }
}
