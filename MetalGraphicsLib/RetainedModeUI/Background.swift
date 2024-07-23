public class Background : SingleChildElement {
  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  public var color: SIMD4<Float> = .black
  
  public init(color: SIMD4<Float>) {
    self.color = color
  }
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(position: \(position), size: \(size), color: \(color)")
    child?.debugHierarchy(offset + "  ")
  }
  
  public override func getSize() -> float2 {
    self.size
  }
  
  public override func calcSize(_ availableSize: float2) -> float2 {
    let contentSize = child?.calcSize(availableSize) ?? availableSize
    self.size = contentSize
    
    return contentSize
  }
  
  public override func calcPosition(_ position: float2) {
    self.position = position
    
    child?.calcPosition(position)
  }
  
  public override func render(_ renderer: Graphics2D) {
    // origin -> top left
    let newPosition = self.position - renderer.size * 0.5 + self.size * 0.5
    renderer.draw(square: Square(position: newPosition, size: self.size, color: self.color))
    
    self.child?.render(renderer)
  }
}
