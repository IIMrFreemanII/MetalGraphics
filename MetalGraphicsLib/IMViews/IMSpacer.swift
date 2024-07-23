extension IMView {
  internal func spacer() -> Void {
    let view: View = .Spacer(spacers.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    spacers.append(Spacer())
  }
  
  internal struct Spacer {
    func debugTree(_ context: IMView, _ offset: String = "") -> Void {
      context.debugTree(self, context, offset)
    }
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>) -> SIMD2<Float> {
      return .init()
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>) -> SIMD2<Float> {
      return .init()
    }
  }
}
