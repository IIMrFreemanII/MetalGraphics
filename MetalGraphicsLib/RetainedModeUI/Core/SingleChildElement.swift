import simd

open class SingleChildElement : UIElement {
  open var child: UIElement?
  private lazy var emptyChild: UIElement = EmptyElement()

  open override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last!)
    child?.debugHierarchy(offset + "  ")
  }
  
  open override func getSize() -> float2 {
    return child?.getSize() ?? .init()
  }
  
  open override func calcSize(_ availableSize: float2) -> float2 {
    return child?.calcSize(availableSize) ?? .init()
  }
  
  open override func calcPosition(_ position: float2) {
    child?.calcPosition(position)
  }
  
//  open override func render(_ renderer: Graphics2D) {
//    self.child?.render(renderer)
//  }
  
  @discardableResult
  open override func handleHitTest(_ input: Input) -> Bool {
    return self.child?.handleHitTest(input) ?? false
  }
  
  override func handleMount(_ context: UIContext) {
    if !self.mounted {
      self.mounted = true
      self.mount(context)
      self.onMount(context)
      
      if let child = self.child {
        child.calcDepth(self.depth)
        child.handleMount(context)
      }
    }
  }
  
  override func handleUnmount(_ context: UIContext) {
    if self.mounted {
      self.mounted = false
      self.onUnmount(context)
      self.unmount(context)

      self.child?.handleUnmount(context)
    }
  }
  
  override func applyContent(_ elements: [UIElement]) -> Void {
    if elements.count > 1 {
      assertionFailure("\(type(of: self)) takes a single child, got \(elements.count)")
    }
    self.child = elements.first ?? self.emptyChild
  }
  
  // Unmounts the previous child (if different) and mounts the new one.
  private func replaceChild(_ element: UIElement?, _ context: UIContext) -> Void {
    let old = self.child
    guard old !== element else { return }
    self.child = element
    
    if self.mounted {
      context.dirtyLayout = true
      old?.handleUnmount(context)
      if let element {
        element.calcDepth(self.depth)
        element.handleMount(context)
      }
    }
  }
  
  open func setChild(_ element: UIElement, _ context: UIContext) -> Void {
    self.replaceChild(element, context)
  }
  
  open func removeChild(_ context: UIContext) -> Void {
    self.replaceChild(nil, context)
  }
}
