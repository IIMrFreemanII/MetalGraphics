public class Rectangle : UIRenderableElement {
  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  public var color: SIMD4<Float> = .black
  
  public init(_ color: SIMD4<Float>, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()
    
    self.color = color
    
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
  
  public override func calcSize(_ availableSize: float2) -> float2 {
    _ = child?.calcSize(availableSize)
    self.size = availableSize
    
    return availableSize
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
    // origin -> top left
    let newPosition = effect.apply(to: self.position) - renderer.size * 0.5 + size * 0.5
    renderer.draw(square: Square(position: newPosition, size: size, color: color))
  }
}
