public class Padding : SingleChildElement {
  public var inset: Inset = .init()
  public var size: SIMD2<Float> = .init()
  
  public init(_ inset: Inset, @UIElementBuilder content: () -> UIElement = { EmptyElement() }) {
    super.init()
    
    self.inset = inset
    self.child = content()
  }
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(inset: \(inset), size: \(size))")
    child?.debugHierarchy(offset + "  ")
  }
  
  public override func getSize() -> float2 {
    self.size
  }
  
  public override func calcSize(_ availableSize: float2) -> float2 {
    var contentSize = self.child?.calcSize(inset.deflate(size: availableSize)) ?? availableSize
    contentSize = inset.inflate(size: contentSize)
    self.size = contentSize
    
    return contentSize
  }
  
  public override func calcPosition(_ position: float2) {
    child?.calcPosition(position + self.inset.topLeft)
  }
}
