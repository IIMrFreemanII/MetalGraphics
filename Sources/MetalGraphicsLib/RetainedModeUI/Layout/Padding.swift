public class Padding : SingleChildElement {
  public var inset: Inset = .init()
  public var size: SIMD2<Float> = .init()
  
  public init(_ inset: Inset, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()
    
    self.inset = inset
    self.applyContent(content())
  }
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(inset: \(inset), size: \(size))")
    child?.debugHierarchy(offset + "  ")
  }
  
  public override func getSize() -> float2 {
    self.size
  }
  
  // Offers its child the space less the inset, and takes the child's size plus the inset.
  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.inset.inflate(size: self.child?.measure(self.inset.deflate(proposal)) ?? .zero)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.inset.inflate(size: self.child?.calcSize(self.inset.deflate(proposal)) ?? .zero)

    return self.size
  }
  
  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    if let own = self.explicitGuide(key, size) { return own }
    let childSize = size - float2(self.inset.horizontal, self.inset.vertical)
    guard let inner = self.child?.guideValue(key, self.inset.deflate(proposal), childSize) else { return nil }
    return inner + self.inset.topLeft[key.axis]
  }

  public override func calcPosition(_ position: float2) {
    child?.calcPosition(position + self.inset.topLeft)
  }
}
