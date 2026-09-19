import simd

@MainActor open class UIElement {
  public var mounted = false
  public var depth: Int = 0
  
  public init() {}
  
  open func mount(_ context: UIContext) -> Void {
//    print("mount: \(self)")
  }
  internal func handleMount(_ context: UIContext) -> Void {}
  
  open func unmount(_ context: UIContext) -> Void {
//    print("unmount: \(self)")
  }
  internal func handleUnmount(_ context: UIContext) -> Void {}
  
  open func debugHierarchy(_ offset: String) -> Void {
    print(offset + "\(self)".split(separator: ".").last!)
  }
  
  open func calcSize(_ availableSize: float2) -> float2 {
    return .init()
  }
  
  open func getSize() -> float2 {
    return .init()
  }
  
  open func calcDepth(_ parentDepth: Int) -> Void {
    self.depth = parentDepth
  }
  open func calcPosition(_ position: float2) -> Void {}
//  open func render(_ renderer: Graphics2D) -> Void {}
  open func handleHitTest(_ input: Input) -> Bool {
    return false
  }
}
