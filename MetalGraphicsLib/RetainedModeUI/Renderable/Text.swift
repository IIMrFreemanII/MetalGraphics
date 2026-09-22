public class Text : UIRenderableElement {
  public var text: String
  public var style: TextStyle
  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  // Made by `calcSize` for the space layout offered, and drawn as is every frame.
  private var layout = TextLayout()

  public init(_ text: String, style: TextStyle = TextStyle()) {
    self.text = text
    self.style = style

    super.init()
  }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(text: \"\(text)\", position: \(position), size: \(size))")
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcSize(_ availableSize: float2) -> float2 {
    self.layout = layoutText(self.text, style: self.style, maxSize: availableSize)
    self.size = self.layout.size

    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  public override func render(_ renderer: Graphics2D) {
    // origin -> top left
    renderer.draw(textLayout: self.layout, at: self.position - renderer.size * 0.5, color: self.style.color)
  }
}
