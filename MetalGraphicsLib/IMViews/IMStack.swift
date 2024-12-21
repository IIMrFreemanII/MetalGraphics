extension IMView {
  internal func vStack(alignment: HorizontalAlignment = .center, spacing: Float = 0, _ cb: () -> Void) -> Void {
    let view: View = .VStack(vStacks.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    vStacks.append(VStack(alignment, spacing))
    
    cb()
    
    _ = viewItemsStack.popLast()
  }
  
  internal func hStack(alignment: VerticalAlignment = .center, spacing: Float = 0, _ cb: () -> Void) -> Void {
    let view: View = .HStack(hStacks.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    hStacks.append(HStack(alignment, spacing))
    
    cb()
    
    _ = viewItemsStack.popLast()
  }
  
  @MainActor internal struct VStack {
    let alignment: HorizontalAlignment
    let spacing: Float
    
    private var contentHeight: Float = 0
    private var maxWidth: Float = 0
    private var spacerSize: Float = 0
    
    var size: SIMD2<Float> {
      .init(maxWidth, contentHeight)
    }
    
    init(_ alignment: HorizontalAlignment = .center, _ spacing: Float = 0) {
      self.alignment = alignment
      self.spacing = spacing
    }
    
    func debugTree(_ context: IMView, _ offset: String = "") -> Void {
      context.debugTree(self, context, offset)
    }
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ _self: inout Self) -> SIMD2<Float> {
      var contentHeight = Float()
      var maxWidth = Float()
      var spacersCount = Int()
      
      defer {
        _self.contentHeight = contentHeight
        _self.maxWidth = maxWidth
      }
      
      _ = context.calcSize(context, availableSize) { child, size  in
        contentHeight += size.y + spacing
        maxWidth = max(maxWidth, size.x)
        
        child.onSpacer {
          contentHeight -= spacing
          spacersCount += 1
        }
      }
      
      contentHeight -= spacing
      
      if spacersCount > 0 {
        let freeSpace = max(availableSize.y - contentHeight, 0)
        _self.spacerSize = freeSpace / Float(spacersCount)
        contentHeight = availableSize.y
      }
      
      return .init(maxWidth, contentHeight)
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>) -> SIMD2<Float> {
      var yOffset = position.y
      
      return context.calcPosition(context, { child, size in
        if child.isSpacer {
          yOffset += self.spacerSize
          return .init()
        }
        
        let availableSpace = self.maxWidth - size.x
        let xOffset = position.x + lerp(min: 0, max: availableSpace, t: self.alignment.offset)
        let result = SIMD2<Float>(xOffset, yOffset)
        yOffset += size.y + self.spacing
        
        return result
      })
    }
  }
  
  @MainActor internal struct HStack {
    let alignment: VerticalAlignment
    let spacing: Float
    
    private var contentWidth: Float = 0
    private var maxHeight: Float = 0
    private var spacerSize: Float = 0
    
    var size: SIMD2<Float> {
      .init(contentWidth, maxHeight)
    }
    
    init(_ alignment: VerticalAlignment = .center, _ spacing: Float = 0) {
      self.alignment = alignment
      self.spacing = spacing
    }
    
    func debugTree(_ context: IMView, _ offset: String = "") -> Void {
      context.debugTree(self, context, offset)
    }
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ _self: inout Self) -> SIMD2<Float> {
      var contentWidth = Float()
      var maxHeight = Float()
      var spacersCount = Int()
      
      defer {
        _self.contentWidth = contentWidth
        _self.maxHeight = maxHeight
      }
      
      _ = context.calcSize(context, availableSize) { child, size  in
        contentWidth += size.x + spacing
        maxHeight = max(maxHeight, size.y)
        
        child.onSpacer {
          contentWidth -= spacing
          spacersCount += 1
        }
      }
      
      contentWidth -= spacing
      
      if spacersCount > 0 {
        let freeSpace = max(availableSize.x - contentWidth, 0)
        _self.spacerSize = freeSpace / Float(spacersCount)
        contentWidth = availableSize.x
      }
      
      return .init(contentWidth, maxHeight)
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>) -> SIMD2<Float> {
      var xOffset = position.x
      
      return context.calcPosition(context, { child, size in
        if child.isSpacer {
          xOffset += self.spacerSize
          return .init()
        }
        
        let availableSpace = self.maxHeight - size.y
        let yOffset = position.y + lerp(min: 0, max: availableSpace, t: self.alignment.offset)
        let result = SIMD2<Float>(xOffset, yOffset)
        xOffset += size.x + self.spacing
        
        return result
      })
    }
  }
}
