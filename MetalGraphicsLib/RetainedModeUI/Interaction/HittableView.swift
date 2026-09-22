public class HittableView: SingleChildElement {
  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  public var isHovered: Bool = false
  
  /// Settable, and cleared while unmounted.
  ///
  /// A handler written in a `@Component` body captures `self` strongly, so the component reaches
  /// itself through the element that stores it. `@Component` breaks that loop by arming these on
  /// mount and clearing them on unmount, which is why they are `var` rather than the `let` the
  /// initializer would suggest. An element built by hand keeps whatever it was constructed with.
  public var onTap: ((Input) -> Void)?
  public var onHover: ((Bool, Input) -> Void)?
  
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
  
  init(onTap: ((Input) -> Void)? = nil, onHover: ((Bool, Input) -> Void)? = nil, @UIElementBuilder content: () -> [UIElement]) {
    self.onTap = onTap
    self.onHover = onHover
    
    super.init()
    
    self.applyContent(content())
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
