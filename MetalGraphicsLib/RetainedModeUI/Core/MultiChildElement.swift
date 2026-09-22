import simd

open class MultiChildElement : UIElement {
  public var children: [UIElement] = []
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last!)
    
    for child in children {
      child.debugHierarchy(offset + "  ")
    }
  }
  
  override func forEachChild(_ body: (UIElement) -> Void) {
    self.children.forEach(body)
  }
  
  override func applyContent(_ elements: [UIElement]) -> Void {
    self.children = elements
  }
  
  // Unmounts children that are gone and mounts new ones, keeping shared instances as is.
  //
  // Membership is tested through identity sets rather than the obvious `contains(where:)`,
  // which is quadratic. A list of n rows pays this on every shuffle and every branch swap.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext) -> Void {
    let old = self.children
    self.children = elements
    context.invalidate(.layout)

    guard self.mounted else { return }

    let oldIdentities = Set(old.map { ObjectIdentifier($0) })
    let newIdentities = Set(elements.map { ObjectIdentifier($0) })

    for child in old where !newIdentities.contains(ObjectIdentifier(child)) {
      child.handleUnmount(context)
    }
    for child in elements where !oldIdentities.contains(ObjectIdentifier(child)) {
      child.handleMount(context)
    }
  }
  
  func insertChild(_ element: UIElement, at index: Int, _ context: UIContext) -> Void {
    self.children.insert(element, at: index.clamped(to: 0 ... self.children.count))
    context.invalidate(.layout)
    
    if self.mounted {
      element.handleMount(context)
    }
  }
  
  func remove(at index: Int, _ context: UIContext) -> Void {
    let elem = self.children.remove(at: index)
    
    if self.mounted {
      context.invalidate(.layout)
      elem.handleUnmount(context)
    }
  }
}
