public class Background : UIRenderableElement {
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
/// tint, with a little grain, and a light rim along its edge. The presets go from nearly clear to
/// nearly opaque, like SwiftUI's materials; `Theme.materials` has one per kind of panel.
public struct GlassMaterial: Hashable, Sendable {
  /// About the backdrop blur's standard deviation, in points, as a SwiftUI blur radius.
  public var blurRadius: Float
  /// Composited over the blurred backdrop; its alpha is how much of it covers the backdrop.
  public var tint: float4
  /// The tint at the bottom edge, for a vertical gradient from `tint`; nil for none.
  public var tintBottom: float4?
  /// 1 leaves the backdrop's colors as they are, more makes them more vivid, 0 grey.
  public var saturation: Float
  /// Grain amplitude, 0...1: a little hides banding and reads as frost.
  public var noise: Float
  /// A light inner edge, strongest along the top: light catching the glass. Clear for none.
  public var rim: float4
  /// The rim's width, in points.
  public var rimWidth: Float
  /// How much of the rim's alpha is left at the bottom edge.
  public var rimBottom: Float
  /// Under the backdrop where the window lets the desktop through, which the library cannot
  /// see: opaque for a panel whose text must read over any desktop, clear to show the desktop.
  public var fallback: float4

  public init(
    blurRadius: Float, tint: float4 = float4(1, 1, 1, 0.3), tintBottom: float4? = nil, saturation: Float = 1.8,  // design: a material is a token itself
    noise: Float = 0.015, rim: float4 = .clear, rimWidth: Float = 1, rimBottom: Float = 0.25, fallback: float4 = .clear
  ) {
    self.blurRadius = blurRadius
    self.tint = tint
    self.tintBottom = tintBottom
    self.saturation = saturation
    self.noise = noise
    self.rim = rim
    self.rimWidth = rimWidth
    self.rimBottom = rimBottom
    self.fallback = fallback
  }

  public static let ultraThin = GlassMaterial(blurRadius: 10, tint: float4(1, 1, 1, 0.1))  // design: SwiftUI's materials; the theme's are `.glass(role)`
  public static let thin = GlassMaterial(blurRadius: 16, tint: float4(1, 1, 1, 0.25))  // design: SwiftUI's materials; the theme's are `.glass(role)`
  public static let regular = GlassMaterial(blurRadius: 24, tint: float4(1, 1, 1, 0.4))  // design: SwiftUI's materials; the theme's are `.glass(role)`
  public static let thick = GlassMaterial(blurRadius: 32, tint: float4(1, 1, 1, 0.6))  // design: SwiftUI's materials; the theme's are `.glass(role)`
}

/// A frosted glass panel behind its content, fitted to it like a `Background`: what is drawn
/// below it, blurred and tinted by `material`, inside `shape`.
///
/// Glass stacks: a panel above another shows the lower one frosted, since each panel's backdrop
/// is rendered, lowest first, in a pass of its own before the frame. See
/// `Graphics2D.draw(glass:...)` for the cost, which grows with the panels' area, not the blur.
public class GlassBackground : Background {
  public var material: GlassMaterial = .regular
  /// The theme's material to draw instead of `material`, resolved when drawn.
  public var materialRole: ThemeMaterial? = nil

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
    let material = self.materialRole.map { renderer.theme[$0] } ?? self.material
    renderer.draw(
      glass: effect.apply(to: resolved.rect.min) - renderer.size * 0.5,
      size: (resolved.rect.max - resolved.rect.min) * effect.scale,
      radii: resolved.radii * effect.scale, material: material,
      sigma: max(material.blurRadius, 0) * ShadowState.sigmaPerRadius * effect.scale,
      opacity: effect.opacity
    )
  }
}
