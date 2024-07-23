extension IMView {
  internal func mouseOver(_ callback: @escaping (Bool) -> Void, _ cb: () -> Void = { }) -> Void {
    let view: View = .MouseOver(mouseOvers.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    mouseOvers.append(MouseOver(callback))
    
    cb()
    
    _ = viewItemsStack.popLast()
  }
  
  internal struct MouseOver {
    var position: SIMD2<Float> = .init()
    var size: SIMD2<Float> = .init()
    var callback: (Bool) -> Void
    
    init(_ callback: @escaping (Bool) -> Void) {
      self.callback = callback
    }
    
    func debugTree(_ context: IMView, _ offset: String = "") -> Void {
      context.debugTree(self, context, offset)
    }
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ _self: inout Self) -> SIMD2<Float> {
      let contentSize = context.calcSize(context, availableSize)
      _self.size = contentSize
      
      return contentSize
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>, _ _self: inout Self) -> SIMD2<Float> {
      _self.position = position
      
      return context.calcPosition(context, { _, _ in position })
    }
  }
}
