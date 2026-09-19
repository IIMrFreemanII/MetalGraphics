import simd
import Combine

open class SingleChildElement : UIElement {
  open var child: UIElement?
  open var bindings: [AnyCancellable] = []

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
      
      if let child = self.child {
        child.calcDepth(self.depth)
        child.handleMount(context)
      }
    }
  }
  
  override func handleUnmount(_ context: UIContext) {
    if self.mounted {
      self.mounted = false
      self.unmount(context)
      self.bindings.forEach { $0.cancel() }
      self.bindings.removeAll()

      self.child?.handleUnmount(context)
    }
  }
  
  open func setChild(_ element: UIElement, _ context: UIContext) -> Void {
    self.child = element
    
    if self.mounted {
      context.dirtyLayout = true
      self.child!.handleMount(context)
    }
  }
  
  open func removeChild(_ context: UIContext) -> Void {
    if let child = child {
      self.child = nil
      
      if self.mounted {
        context.dirtyLayout = true
        child.handleUnmount(context)
      }
    }
  }
}
