public class HittableView: SingleChildElement {
  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  public var isHovered: Bool = false
  
  let onTap: ((Input) -> Void)?
  let onHover: ((Bool, Input) -> Void)?
  
  init(onTap: ((Input) -> Void)? = nil, onHover: ((Bool, Input) -> Void)? = nil, @UIElementBuilder content: () -> UIElement) {
    self.onTap = onTap
    self.onHover = onHover
    
    super.init()
    
    self.child = content()
  }
  
  func handleEvents(_ result: Bool, _ input: Input) {
    if result && !self.isHovered {
      self.isHovered = true
      self.onHover?(self.isHovered, input)
    } else if !result && self.isHovered {
      self.isHovered = false
      self.onHover?(self.isHovered, input)
    }
    if result && input.mouseDown {
      self.onTap?(input)
    }
  }
  
  public override func handleHitTest(_ input: Input) -> Bool {
    let childResult = self.child?.handleHitTest(input) ?? false
    
    if childResult {
      self.handleEvents(true, input)
      return true
    }
    
    // test hit
    // origin -> top left
    let newPosition = self.position
    let result = pointInAABBoxTopLeftOrigin(point: input.mousePosition, position: newPosition, size: self.size)
    self.handleEvents(result, input)

    return result
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
}
