import simd

/// A visual effect accumulated down the tree: fade, then scale and move in layout coordinates.
///
/// `apply(to:)` maps a point laid out without effects to where it is drawn. Composing is
/// multiplying opacities and chaining the two affine maps, so a nested effect is as cheap as
/// one.
public struct EffectState: Equatable, Sendable {
  public var opacity: Float
  public var scale: Float
  public var translate: float2

  public static let identity = EffectState(opacity: 1, scale: 1, translate: .zero)

  public func apply(to point: float2) -> float2 {
    point * self.scale + self.translate
  }

  /// `inner` first, then `self`.
  func composed(with inner: EffectState) -> EffectState {
    EffectState(
      opacity: self.opacity * inner.opacity,
      scale: self.scale * inner.scale,
      translate: inner.translate * self.scale + self.translate
    )
  }
}

/// Fades, moves and scales everything under it. Purely visual: layout and hit-testing see the
/// content where it was laid out.
///
/// Renderables do not walk up to find their effects. `UIContext` records every effect in tree
/// order while it collects the paint order, resolves them once per frame, parents first, and
/// hands each renderable its resolved state.
public class EffectElement : SingleChildElement {
  public var opacity: Float = 1
  public var offset: float2 = .zero
  public var scale: Float = 1

  /// Where layout put this element. The centre is the scale's anchor.
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  public init(opacity: Float = 1, offset: float2 = .zero, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()

    self.opacity = opacity
    self.offset = offset
    self.applyContent(content())
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(opacity: \(opacity), offset: \(self.offset), scale: \(scale))")
    child?.debugHierarchy(offset + "  ")
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcSize(_ availableSize: float2) -> float2 {
    self.size = child?.calcSize(availableSize) ?? .zero
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
    child?.calcPosition(position)
  }

  /// This element's own effect, anchored at its laid-out centre, then its slide.
  override var localEffect: EffectState {
    let anchor = self.position + self.size * 0.5
    return EffectState(
      opacity: min(max(self.opacity, 0), 1),
      scale: self.scale,
      translate: anchor * (1 - self.scale) + self.offset + self.slideOffset
    )
  }

  override var hasEffect: Bool { true }
}
