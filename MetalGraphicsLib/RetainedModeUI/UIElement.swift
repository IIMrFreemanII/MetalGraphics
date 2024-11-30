import simd

@resultBuilder
public struct UIElementBuilder {
  public static func buildBlock<T: UIElement>(_ element: T) -> T {
    return element
  }
  
  public static func buildBlock(_ elements: UIElement...) -> [UIElement] {
    return elements
  }
}

open class UIElement {
  public var mounted = false
  
  public init() {}
  
  open func mount() -> Void {
//    print("mount: \(self)")
  }
  internal func handleMount() -> Void {}
  
  open func unmount() -> Void {
//    print("unmount: \(self)")
  }
  internal func handleUnmount() -> Void {}
  
  open func debugHierarchy(_ offset: String) -> Void {
    print(offset + "\(self)".split(separator: ".").last!)
  }
  
  open func calcSize(_ availableSize: float2) -> float2 {
    return .init()
  }
  
  open func getSize() -> float2 {
    return .init()
  }
  
  open func calcPosition(_ position: float2) -> Void {}
  open func render(_ renderer: Graphics2D) -> Void {}
  
  public func padding(_ inset: Inset) -> Padding {
    Padding(inset) {
      self
    }
  }
  
  public func frame(width: Float, height: Float) -> Frame {
    Frame(.init(width, height)) {
      self
    }
  }
  
  public func background(_ color: float4) -> Background {
    Background(color) {
      self
    }
  }
  
  public func ref<T: UIElement>(_ storage: inout T?) -> T {
    storage = self as? T
    return self as! T
  }
  
  public func ref<T: UIElement>(_ cb: (T) -> Void) -> T {
    cb(self as! T)
    return self as! T
  }
}

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
  
  open override func render(_ renderer: Graphics2D) {
    self.child?.render(renderer)
  }
  
  override func handleMount() {
    if !self.mounted {
      self.mounted = true
      self.mount()
      
      self.child?.handleMount()
    }
  }
  
  override func handleUnmount() {
    if self.mounted {
      self.mounted = false
      self.unmount()
      
      self.child?.handleUnmount()
    }
  }
  
  open func setChild(_ element: UIElement) -> Void {
    self.child = element
    
    if self.mounted {
      self.child!.handleMount()
    }
  }
  
  open func removeChild() -> Void {
    if let child = child {
      self.child = nil
      
      if self.mounted {
        child.handleUnmount()
      }
    }
  }
}

public class MultiChildElement : UIElement {
  public var children: [UIElement] = []
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last!)
    
    for child in children {
      child.debugHierarchy(offset + "  ")
    }
  }
  
  public override func render(_ renderer: Graphics2D) {
    for child in self.children {
      child.render(renderer)
    }
  }
  
  override func handleMount() {
    if !self.mounted {
      self.mounted = true
      self.mount()
      
      for child in children {
        child.handleMount()
      }
    }
  }
  
  override func handleUnmount() {
    if self.mounted {
      self.mounted = false
      self.unmount()
      
      for child in children {
        child.handleUnmount()
      }
    }
  }
  
  public func appendChild(_ element: UIElement) -> Void {
    self.children.append(element)
    
    if self.mounted {
      element.handleMount()
    }
  }
  
  public func insertChild(_ element: UIElement, at index: Int) -> Void {
    self.children.insert(element, at: index)
    
    if self.mounted {
      element.handleMount()
    }
  }
  
  public func setChildren(_ elements: [UIElement]) -> Void {
    self.children = elements
    
    if self.mounted {
      for child in children {
        child.handleMount()
      }
    }
  }
  
  @discardableResult
  public func remove(at index: Int) -> UIElement {
    let elem = self.children.remove(at: index)
    
    if self.mounted {
      elem.handleUnmount()
    }
    
    return elem
  }
  
  public func removeAll() -> Void {
    if self.mounted {
      for child in children {
        child.handleUnmount()
      }
    }
    
    self.children.removeAll(keepingCapacity: true)
  }
}

public class LeafElement : UIElement {
  override func handleMount() {
    if !self.mounted {
      self.mounted = true
      self.mount()
    }
  }
  
  override func handleUnmount() {
    if self.mounted {
      self.mounted = false
      self.unmount()
    }
  }
}




