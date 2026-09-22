import simd

open class SingleChildElement : UIElement {
  open var child: UIElement?

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
  
  override func forEachChild(_ body: (UIElement) -> Void) {
    if let child = self.child {
      body(child)
    }
  }
  
  override func applyContent(_ elements: [UIElement]) -> Void {
    if elements.count > 1 {
      assertionFailure("\(type(of: self)) takes a single child, got \(elements.count)")
    }
    self.child = elements.first ?? EmptyElement()
  }
  
  // Unmounts the previous child (if different) and mounts the new one.
  public func setChild(_ element: UIElement, _ context: UIContext) -> Void {
    let old = self.child
    guard old !== element else { return }
    self.child = element
    
    if self.mounted {
      context.invalidate(.layout)
      old?.handleUnmount(context)
      element.handleMount(context)
    }
  }
}
