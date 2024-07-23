public class HStack : MultiChildElement {
  public var alignment: VerticalAlignment
  public var spacing: Float
  
  private var contentWidth: Float = 0
  private var maxHeight: Float = 0
  private var spacerSize: Float = 0
  
  public var size: SIMD2<Float> {
    .init(contentWidth, maxHeight)
  }
  
  public init(alignment: VerticalAlignment = .center, spacing: Float = 0) {
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
    var contentWidth = Float()
    var maxHeight = Float()
    var spacersCount = Int()
    
    defer {
      self.contentWidth = contentWidth
      self.maxHeight = maxHeight
    }
    
    for child in self.children {
      let childSize = child.calcSize(availableSize)
      contentWidth += childSize.x + spacing
      maxHeight = max(maxHeight, childSize.y)
      
      if child is Spacer {
        contentWidth -= spacing
        spacersCount += 1
      }
    }
    
    contentWidth -= spacing
    
    if spacersCount > 0 {
      let freeSpace = max(availableSize.x - contentWidth, 0)
      self.spacerSize = freeSpace / Float(spacersCount)
      contentWidth = availableSize.x
    }
    
    return .init(contentWidth, maxHeight)
  }
  
  public override func calcPosition(_ position: float2) {
    var xOffset = position.x
    
    for child in self.children {
      if child is Spacer {
        xOffset += self.spacerSize
        continue
      }
      
      let childSize = child.getSize()
      let availableSpace = self.maxHeight - childSize.y
      let yOffset = position.y + lerp(min: 0, max: availableSpace, t: self.alignment.offset)
      let result = SIMD2<Float>(xOffset, yOffset)
      xOffset += childSize.x + self.spacing
      
      child.calcPosition(result)
    }
  }
}
