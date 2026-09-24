@MainActor public class Background : UIRenderableElement {
  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  public var color: SIMD4<Float> = .black
  /// What it fills of its rect: all of it unless `.background(_:in:)` said otherwise.
  public internal(set) var shape: UIShape = .rect
  
  public init(_ color: SIMD4<Float>, in shape: UIShape = .rect, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()
    
    self.color = color
    self.shape = shape
    
    self.applyContent(content())
  }
  
  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }
  
  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(position: \(position), size: \(size), color: \(color)")
    child?.debugHierarchy(offset + "  ")
  }
  
  public override func getSize() -> float2 {
    self.size
  }
  
  // The size of what it is behind; without content it fills what it is offered, like a
  // SwiftUI `Color`.
  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    child?.measure(proposal) ?? proposal.replacingUnspecified(with: Rectangle.idealSize)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    let contentSize = child?.calcSize(proposal) ?? proposal.replacingUnspecified(with: Rectangle.idealSize)
    self.size = contentSize
    
    return contentSize
  }
  
  public override func calcPosition(_ position: float2) {
    self.position = position
    
    child?.calcPosition(position)
  }
  
  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let size = self.size * effect.scale
    var color = self.color
    color.w *= effect.opacity
    guard !self.shape.isPlainRect else {
      // origin -> top left
      let newPosition = effect.apply(to: self.position) - renderer.size * 0.5 + size * 0.5
      renderer.draw(square: Square(position: newPosition, size: size, color: color))
      return
    }
    let resolved = self.shape.resolve(in: ClipRect(position: self.position, size: self.size))
    renderer.draw(
      roundedRect: effect.apply(to: resolved.rect.min) - renderer.size * 0.5,
      size: (resolved.rect.max - resolved.rect.min) * effect.scale,
      radii: resolved.radii * effect.scale, color: color
    )
  }
}

/// What a frosted glass panel is made of: the scene behind it blurred, made more vivid, under a
/// tint, with a little grain. The presets go from nearly clear to nearly opaque, like SwiftUI's
/// materials.
public struct GlassMaterial: Equatable, Sendable {
  /// About the backdrop blur's standard deviation, in points, as a SwiftUI blur radius.
  public var blurRadius: Float
  /// Composited over the blurred backdrop; its alpha is how much of it covers the backdrop.
  public var tint: float4
  /// 1 leaves the backdrop's colors as they are, more makes them more vivid, 0 grey.
  public var saturation: Float
  /// Grain amplitude, 0...1: a little hides banding and reads as frost.
  public var noise: Float

  public init(blurRadius: Float, tint: float4 = float4(1, 1, 1, 0.3), saturation: Float = 1.8, noise: Float = 0.015) {
    self.blurRadius = blurRadius
    self.tint = tint
    self.saturation = saturation
    self.noise = noise
  }

  public static let ultraThin = GlassMaterial(blurRadius: 10, tint: float4(1, 1, 1, 0.1))
  public static let thin = GlassMaterial(blurRadius: 16, tint: float4(1, 1, 1, 0.25))
  public static let regular = GlassMaterial(blurRadius: 24, tint: float4(1, 1, 1, 0.4))
  public static let thick = GlassMaterial(blurRadius: 32, tint: float4(1, 1, 1, 0.6))
}

/// A frosted glass panel behind its content, fitted to it like a `Background`: what is drawn
/// below it, blurred and tinted by `material`, inside `shape`.
///
/// Glass stacks: a panel above another shows the lower one frosted, since each panel's backdrop
/// is rendered, lowest first, in a pass of its own before the frame. See
/// `Graphics2D.draw(glass:...)` for the cost, which grows with the panels' area, not the blur.
@MainActor public class GlassBackground : Background {
  public var material: GlassMaterial = .regular

  public init(_ material: GlassMaterial = .regular, in shape: UIShape = .rect, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init(.zero, in: shape, content: content)

    self.material = material
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "GlassBackground(position: \(position), size: \(size), material: \(material))")
    child?.debugHierarchy(offset + "  ")
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let resolved = self.shape.resolve(in: ClipRect(position: self.position, size: self.size))
    let material = self.material
    renderer.draw(
      glass: effect.apply(to: resolved.rect.min) - renderer.size * 0.5,
      size: (resolved.rect.max - resolved.rect.min) * effect.scale,
      radii: resolved.radii * effect.scale,
      sigma: max(material.blurRadius, 0) * ShadowState.sigmaPerRadius * effect.scale,
      tint: material.tint, saturation: material.saturation, noise: material.noise,
      opacity: effect.opacity
    )
  }
}
