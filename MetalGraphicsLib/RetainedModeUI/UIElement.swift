import simd

public class UIElement {
  public func mount() -> Void {
    
  }
  
  public func unmount() -> Void {
    
  }
  
  public func debugHierarchy(_ offset: String) -> Void {
    print(offset + "\(self)".split(separator: ".").last!)
  }
  
  public func calcSize(_ availableSize: float2) -> float2 {
    return .init()
  }
  
  public func getSize() -> float2 {
    return .init()
  }
  
  public func calcPosition(_ position: float2) -> Void {
    
  }
  
  public func render(_ renderer: Graphics2D) -> Void {
    
  }
}

public class SingleChildElement : UIElement {
  public  var child: UIElement?
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last!)
    child?.debugHierarchy(offset + "  ")
  }
  
  public override func render(_ renderer: Graphics2D) {
    self.child?.render(renderer)
  }
  
  public func setChild(_ element: UIElement) -> Void {
    self.child = element
  }
  
  public func removeChild() -> Void {
    self.child = nil
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
  
  public func appendChild(_ element: UIElement) -> Void {
    self.children.append(element)
  }
  
  public func remove(at index: Int) -> Void {
    self.children.remove(at: index)
  }
}

public class LeafElement : UIElement {
  
}




