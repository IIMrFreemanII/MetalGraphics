public class VStack : MultiChildElement {
  public var alignment: HorizontalAlignment
  public var spacing: Float
  
  private var contentHeight: Float = 0
  private var maxWidth: Float = 0
  private var spacerSize: Float = 0
  
  public var size: SIMD2<Float> {
    .init(maxWidth, contentHeight)
  }
  
  public init(alignment: HorizontalAlignment = .center, spacing: Float = 0) {
    self.alignment = alignment
    self.spacing = spacing
  }
  
  public override func getSize() -> float2 {
    self.size
  }
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(size: \(size), spacing: \(spacing), alignment: \(alignment)")
    
    for child in children {
      child.debugHierarchy(offset + "  ")
    }
  }
  
  public override func calcSize(_ availableSize: float2) -> float2 {
    var contentHeight = Float()
    var maxWidth = Float()
    var spacersCount = Int()
    
    defer {
      self.maxWidth = maxWidth
      self.contentHeight = contentHeight
    }
    
    for child in self.children {
      let childSize = child.calcSize(availableSize)
      contentHeight += childSize.y + spacing
      maxWidth = max(maxWidth, childSize.x)
      
      if child is Spacer {
        contentHeight -= spacing
        spacersCount += 1
      }
    }
    
    contentHeight -= spacing
    
    if spacersCount > 0 {
      let freeSpace = max(availableSize.y - contentHeight, 0)
      self.spacerSize = freeSpace / Float(spacersCount)
      contentHeight = availableSize.y
    }
    
    return .init(maxWidth, contentHeight)
  }
  
  public override func calcPosition(_ position: float2) {
    var yOffset = position.y
    
    for child in self.children {
      if child is Spacer {
        yOffset += self.spacerSize
        continue
      }
      
      let childSize = child.getSize()
      let availableSpace = self.maxWidth - childSize.x
      let xOffset = position.x + lerp(min: 0, max: availableSpace, t: self.alignment.offset)
      let result = SIMD2<Float>(xOffset, yOffset)
      yOffset += childSize.y + self.spacing
      
      child.calcPosition(result)
    }
  }
}
