import simd

/// A line drawn along the inside of its content's outline, over the content. Made by
/// `.border(_:width:in:)`.
///
/// Like SwiftUI's `border`, it changes no size and is stroked inside the bounds, so a wider
/// border covers more of the content instead of growing past it. `shape` rounds it:
/// `.border(.gray, width: 1, in: .rect(cornerRadius: 12))`.
public final class BorderElement : SingleChildElement {
  /// Visited after the content, which is what draws it on top.
  let layer = BorderLayer()

  public var color: float4 {
    get { self.layer.color }
    set { self.layer.color = newValue }
  }

  public var lineWidth: Float {
    get { self.layer.lineWidth }
    set { self.layer.lineWidth = newValue }
  }

  public var shape: UIShape {
    get { self.layer.shape }
    set { self.layer.shape = newValue }
  }

  public init(
    _ color: float4, width: Float = 1, in shape: UIShape = .rect,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    super.init()
    self.layer.color = color
    self.layer.lineWidth = width
    self.layer.shape = shape
    self.applyContent(content())
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    super.forEachChild(body)
    body(self.layer)
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "Border(color: \(self.color), width: \(self.lineWidth), shape: \(self.shape))")
    self.child?.debugHierarchy(offset + "  ")
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    let size = self.child?.calcSize(proposal) ?? .zero
    self.layer.size = size
    return size
  }

  public override func calcPosition(_ position: float2) {
    self.child?.calcPosition(position)
    self.layer.position = position
  }
}

/// The stroke of a `BorderElement`, sized and placed by it.
final class BorderLayer : UIRenderableElement {
  var position: float2 = .zero
  var size: float2 = .zero
  var color: float4 = .black
  var lineWidth: Float = 1
  var shape: UIShape = .rect

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 {
    self.size
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    var color = self.color
    color.w *= effect.opacity
    guard color.w > 0, self.lineWidth > 0 else { return }
    let resolved = self.shape.resolve(in: ClipRect(position: self.position, size: self.size))
    renderer.draw(
      roundedRect: effect.apply(to: resolved.rect.min) - renderer.size * 0.5,
      size: (resolved.rect.max - resolved.rect.min) * effect.scale,
      radii: resolved.radii * effect.scale, color: color,
      strokeWidth: self.lineWidth * effect.scale
    )
  }
}
