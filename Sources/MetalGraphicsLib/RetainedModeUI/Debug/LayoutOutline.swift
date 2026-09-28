import simd

/// Outlines what is laid out under an element: a 0.5 pt accent frame round every text, control
/// and view that keeps a rect, as a design tool's measure mode. For a gallery or a debug overlay.
///
///     story.layoutOutline()
///
/// The frames are gathered after each layout, not per frame; drawing them is one stroke each.
final class LayoutOutlineOverlay : UIRenderableElement {
  private unowned let target: UIElement
  private var rects: [HeadlessRect] = []
  private weak var context: UIContext?

  static let color: float4 = .accent
  static let width: Float = 0.5

  init(target: UIElement) {
    self.target = target
    super.init()
  }

  override func mount(_ context: UIContext) {
    self.context = context
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
    self.context = nil
  }

  override func getSize() -> float2 { .zero }
  override func sizeThatFits(_ proposal: ProposedSize) -> float2 { .zero }
  override func calcSize(_ proposal: ProposedSize) -> float2 { .zero }

  // After the target's, as a later child of the same stack: its rects are placed by now.
  override func calcPosition(_ position: float2) {
    self.rects.removeAll(keepingCapacity: true)
    self.collect(self.target)
  }

  private func collect(_ element: UIElement) {
    if let rect = ElementGeometry.ownRect(of: element), rect.size.x > 0, rect.size.y > 0 {
      self.rects.append(rect)
    }
    element.forEachChild { self.collect($0) }
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    var color = renderer.resolve(Self.color)
    color.w *= effect.opacity
    let width = Self.width * effect.scale
    for rect in self.rects {
      let origin = effect.apply(to: rect.origin) - renderer.size * 0.5
      let size = rect.size * effect.scale
      // Four hairlines: top, bottom, leading, trailing.
      let across = float2(size.x, width), down = float2(width, size.y)
      renderer.draw(square: Square(position: origin + across * 0.5, size: across, color: color))
      renderer.draw(square: Square(position: origin + float2(0, size.y - width) + across * 0.5, size: across, color: color))
      renderer.draw(square: Square(position: origin + down * 0.5, size: down, color: color))
      renderer.draw(square: Square(position: origin + float2(size.x - width, 0) + down * 0.5, size: down, color: color))
    }
  }
}

public extension UIElement {
  /// Draws a hairline frame round everything laid out in this element. See `LayoutOutlineOverlay`.
  func layoutOutline() -> ZStack {
    let overlay = LayoutOutlineOverlay(target: self)
    return ZStack(alignment: .topLeading) {
      self
      overlay
    }
  }
}
