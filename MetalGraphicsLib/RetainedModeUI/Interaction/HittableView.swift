public class HittableView: SingleChildElement, @MainActor Identifiable {
  public var id: UInt
  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  public var isHovered: Bool = false
  
  let onTap: ((Input) -> Void)?
  let onHover: ((Bool, Input) -> Void)?
  
  public override func mount(_ context: UIContext) {
    context.registerHittableView(self)
  }
  
  public override func unmount(_ context: UIContext) {
    // Cleared so a remount starts neutral. `ListRows` reuses a row's element across a reorder,
    // and an element unmounted mid-hover would otherwise come back believing it is still
    // hovered, and never fire `onHover(true)` again until the pointer left and re-entered.
    self.isHovered = false
    
    context.unregisterHittableView(self)
  }
  
  init(onTap: ((Input) -> Void)? = nil, onHover: ((Bool, Input) -> Void)? = nil, @UIElementBuilder content: @escaping () -> [UIElementNode]) {
    self.onTap = onTap
    self.onHover = onHover
    self.id = .random(in: .min ... .max)
    
    super.init()
    
    self.setStaticContent(content)
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
  
  @discardableResult
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
  
  public override func calcDepth(_ parentDepth: Int) {
    self.depth = parentDepth + 1
  }
}
