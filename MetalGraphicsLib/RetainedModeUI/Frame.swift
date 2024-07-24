import simd

public class Frame : SingleChildElement {
  public var size: float2 = .init()
  public var alignment: Alignment = .center
  
  public init(_ size: float2, _ alignment: Alignment = .center, @UIElementBuilder content: () -> UIElement = { EmptyElement() }) {
    super.init()
    
    self.size = size
    self.alignment = alignment
    self.child = content()
  }
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(size: \(size))")
    child?.debugHierarchy(offset + "  ")
  }
  
  public override func getSize() -> float2 {
    self.size
  }
  
  public override func calcSize(_ availableSize: float2) -> float2 {
    if let child = child {
      _ = child.calcSize(self.size)
    }
    
    return self.size
  }
  
  public override func calcPosition(_ position: float2) -> Void {
    if let child = child {
      let childSize = child.getSize()
      let availableSize = max(self.size - childSize, float2())
      let offset = lerp(min: float2(), max: availableSize, t: self.alignment.offset)
      
      child.calcPosition(position + offset)
    }
  }
}
