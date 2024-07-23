extension IMView {
  internal func background(_ color: float4 = .black, _ cb: () -> Void = { }) -> Void {
    let view: View = .Background(backgrounds.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    backgrounds.append(Background(color, getViewDepth()))
    
    cb()
    
    _ = viewItemsStack.popLast()
  }
  
  internal struct Background {
    var position: SIMD2<Float> = .init()
    var size: SIMD2<Float> = .init()
    var color: SIMD4<Float> = .black
    var depth: Float
    
    init(_ color: float4, _ depth: Float) {
      self.depth = depth
      self.color = color
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
