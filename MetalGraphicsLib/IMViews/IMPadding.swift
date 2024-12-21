extension IMView {
  internal func padding(_ inset: Inset = .init(all: 0), cb: () -> Void) -> Void {
    let view: View = .Padding(paddings.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    paddings.append(Padding(inset))
    
    cb()
    
    _ = viewItemsStack.popLast()
  }
  
  @MainActor internal struct Padding {
    var inset: Inset = .init()
    var size: SIMD2<Float> = .init()
    
    init(_ inset: Inset) {
      self.inset = inset
    }
    
    func debugTree(_ context: IMView, _ offset: String = "") -> Void {
      context.debugTree(self, context, offset)
    }
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ _self: inout Self) -> SIMD2<Float> {
      let temp = inset.inflate(size: context.calcSize(context, inset.deflate(size: availableSize)))
      _self.size = temp
      
      return temp
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>) -> SIMD2<Float> {
      return context.calcPosition(context, { _, _ in position + self.inset.topLeft })
    }
  }
}
