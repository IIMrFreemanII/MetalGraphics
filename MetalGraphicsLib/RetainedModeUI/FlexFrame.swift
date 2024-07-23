import simd

public class FlexFrame : SingleChildElement {
  public var minWidth: Float?
  public var maxWidth: Float?
  public var minHeight: Float?
  public var maxHeight: Float?
  public var alignment: Alignment
  
  private var size: float2 = .init()
  
  public init(minWidth: Float? = nil, maxWidth: Float? = nil, minHeight: Float? = nil, maxHeight: Float? = nil, _ alignment: Alignment = .center) {
    self.minWidth = minWidth
    self.maxWidth = maxWidth
    self.minHeight = minHeight
    self.maxHeight = maxHeight
    self.alignment = alignment
  }
  
  public override func getSize() -> float2 {
    self.size
  }
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(size: \(size))")
    child?.debugHierarchy(offset + "  ")
  }
  
  public override func calcSize(_ availableSize: float2) -> float2 {
    let contentSize = child?.calcSize(availableSize) ?? availableSize
    
    let minWidth = minWidth ?? contentSize.x
    let maxWidth = maxWidth ?? contentSize.x
    let minHeight = minHeight ?? contentSize.y
    let maxHeight = maxHeight ?? contentSize.y
    
    let width = clamp(availableSize.x, minWidth, maxWidth)
    let height = clamp(availableSize.y, minHeight, maxHeight)
    
    let constrainedSize = SIMD2<Float>(width, height)
    self.size = constrainedSize
    
    return constrainedSize
  }
  
  public override func calcPosition(_ position: float2) {
    if let child = child {
      let childSize = child.getSize()
      let availableSize = max(self.size - childSize, float2())
      let offset = lerp(min: float2(), max: availableSize, t: self.alignment.offset)
      
      child.calcPosition(position + offset)
    }
  }
}
