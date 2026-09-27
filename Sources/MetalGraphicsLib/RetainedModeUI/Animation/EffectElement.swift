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

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = child?.calcSize(proposal) ?? .zero
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

/// A shadow as `Graphics2D` draws it: a copy of a shape in `color`, moved by `offset` and
/// blurred by a Gaussian of standard deviation `sigma`, all in points.
public struct ShadowState: Equatable, Sendable {
  /// A SwiftUI shadow radius is about the blur's standard deviation.
  public static let sigmaPerRadius: Float = 1
  /// How far past its shape a shadow reaches, in standard deviations.
  static let reach: Float = 3

  public var color: float4
  public var sigma: Float
  public var offset: float2
  /// The `Graphics2D` clip its copies are drawn under, or -1 for the one the shape is drawn
  /// under. They differ when a clip lies between the shadow and the shape: that clip shapes the
  /// shadow but must not cut it.
  var clip: Int32 = -1

  /// How far past its shape this shadow can cover anything, on each side.
  var margin: Float { self.sigma * Self.reach }
}

/// Gives everything drawn under it a soft shadow, as SwiftUI's `.shadow`. Purely visual: layout
/// and hit-testing are unchanged.
///
/// Like SwiftUI without a `compositingGroup`, every shape under it casts its own shadow, drawn
/// just beneath that shape: a text on a shadowed card shadows the card. `UIContext` resolves
/// shadows once per frame, like effects, and `Graphics2D` draws each shape's shadow from its
/// distance field, so no pass is added.
public class ShadowElement : SingleChildElement {
  /// SwiftUI's default: black at a third opacity.
  public static let defaultColor = float4(0, 0, 0, 0.33)

  public var color: float4 = ShadowElement.defaultColor
  public var radius: Float = 0
  public var x: Float = 0
  public var y: Float = 0

  public init(
    color: float4 = ShadowElement.defaultColor, radius: Float, x: Float = 0, y: Float = 0,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    super.init()

    self.color = color
    self.radius = radius
    self.x = x
    self.y = y
    self.applyContent(content())
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "Shadow(color: \(self.color), radius: \(self.radius), x: \(self.x), y: \(self.y))")
    child?.debugHierarchy(offset + "  ")
  }

  /// This shadow drawn under `effect`, the effects at or above it: scaled with what it shadows.
  func resolved(_ effect: EffectState) -> ShadowState {
    ShadowState(
      color: self.color,
      sigma: max(self.radius, 0) * ShadowState.sigmaPerRadius * effect.scale,
      offset: float2(self.x, self.y) * effect.scale
    )
  }
}

/// Blurs everything drawn under it by a Gaussian, as SwiftUI's `.blur(radius:)`. Purely visual:
/// layout and hit-testing are unchanged.
///
/// Each shape under it is blurred on its own, from its distance field, the way a shadow is:
/// no offscreen pass is added. Where shapes overlap, each blurs separately rather than their
/// composite blurring as one, which is close but not exact. Nested blurs add up as Gaussians
/// do. `UIContext` resolves them once per frame, like effects.
public class BlurElement : SingleChildElement {
  /// About the blur's standard deviation, in points, as SwiftUI's radius.
  public var radius: Float = 0

  public init(radius: Float, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()

    self.radius = radius
    self.applyContent(content())
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "Blur(radius: \(self.radius))")
    child?.debugHierarchy(offset + "  ")
  }

  /// This blur's standard deviation drawn under `effect`, the effects at or above it: scaled
  /// with what it blurs.
  func resolved(_ effect: EffectState) -> Float {
    max(self.radius, 0) * ShadowState.sigmaPerRadius * effect.scale
  }
}
