import simd

open class MultiChildElement : UIElement {
  public var children: [UIElement] = []
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last!)
    
    for child in children {
      child.debugHierarchy(offset + "  ")
    }
  }
  
//  public override func render(_ renderer: Graphics2D) {
//    for child in self.children {
//      child.render(renderer)
//    }
//  }
  
  open override func handleHitTest(_ input: Input) -> Bool {
    var hit: Bool = false
    
    for child in self.children {
      if child.handleHitTest(input) {
        hit = true
      }
    }
    
    return hit
  }
  
  override func handleMount(_ context: UIContext) {
    if !self.mounted {
      self.mounted = true
      self.mount(context)
      self.onMount(context)
      
      for child in children {
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
      
      for child in children {
        child.handleUnmount(context)
      }
    }
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
    context.dirtyLayout = true

    guard self.mounted else { return }

    let oldIdentities = Set(old.map { ObjectIdentifier($0) })
    let newIdentities = Set(elements.map { ObjectIdentifier($0) })

    for child in old where !newIdentities.contains(ObjectIdentifier(child)) {
      child.handleUnmount(context)
    }
    for child in elements where !oldIdentities.contains(ObjectIdentifier(child)) {
      child.calcDepth(self.depth)
      child.handleMount(context)
    }
  }
  
  public func appendChild(_ element: UIElement, _ context: UIContext) -> Void {
    self.insertChild(element, at: self.children.count, context)
  }
  
  public func insertChild(_ element: UIElement, at index: Int, _ context: UIContext) -> Void {
    self.children.insert(element, at: index.clamped(to: 0 ... self.children.count))
    context.dirtyLayout = true
    
    if self.mounted {
      element.calcDepth(self.depth)
      element.handleMount(context)
    }
  }
  
  public func setChildren(_ elements: [UIElement], _ context: UIContext) -> Void {
    self.replaceChildren(elements, context)
  }
  
  @discardableResult
  public func remove(at index: Int, _ context: UIContext) -> UIElement {
    let elem = self.children.remove(at: index)
    
    if self.mounted {
      context.dirtyLayout = true
      elem.handleUnmount(context)
    }
    
    return elem
  }
  
  public func removeAll(_ context: UIContext) -> Void {
    if self.mounted {
      context.dirtyLayout = true
      for child in children {
        child.handleUnmount(context)
      }
    }
    
    self.children.removeAll(keepingCapacity: true)
  }
}
