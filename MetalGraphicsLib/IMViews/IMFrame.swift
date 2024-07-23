import simd

extension IMView {
  internal func frame(width: Float, height: Float, _ alignment: Alignment = .center, _ cb: () -> Void = { }) -> Void {
    let view: View = .Frame(frames.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    frames.append(Frame(.init(width, height), alignment))
    
    cb()
    
    _ = viewItemsStack.popLast()
  }
  
  internal func expandedFrame(_ axis: Axis, _ alignment: Alignment = .center, _ cb: () -> Void = { }) -> Void {
    let view: View = .ExpandedFrame(expandedFrames.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    expandedFrames.append(ExpandedFrame(axis, alignment))
    
    cb()
    
    _ = viewItemsStack.popLast()
  }
  
  internal func frame(minWidth: Float? = nil, maxWidth: Float? = nil, minHeight: Float? = nil, maxHeight: Float? = nil, _ alignment: Alignment = .center, _ cb: () -> Void = { }) -> Void {
    let view: View = .FlexFrame(flexFrames.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    flexFrames.append(FlexFrame(minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight, alignment))
    
    cb()
    
    _ = viewItemsStack.popLast()
  }
  
  internal struct Frame {
    let size: float2
    let alignment: Alignment
    
    init(_ size: float2, _ alignment: Alignment = .center) {
      self.size = size
      self.alignment = alignment
    }
    
    func debugTree(_ context: IMView, _ offset: String = "") -> Void {
      context.debugTree(self, context, offset)
    }
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>) -> SIMD2<Float> {
      return context.calcSize(context, self.size)
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>) -> SIMD2<Float> {
      return context.calcPosition(context, { _, size in
        let availableSize = max(self.size - size, float2())
        let offset = lerp(min: float2(), max: availableSize, t: self.alignment.offset)
        
        return position + offset
      })
    }
  }
  
  internal struct FlexFrame {
    let minWidth: Float?
    let maxWidth: Float?
    let minHeight: Float?
    let maxHeight: Float?
    let alignment: Alignment
    
    var size: float2 = .init()
    
    init(minWidth: Float?, maxWidth: Float?, minHeight: Float?, maxHeight: Float?, _ alignment: Alignment = .center) {
      self.minWidth = minWidth
      self.maxWidth = maxWidth
      self.minHeight = minHeight
      self.maxHeight = maxHeight
      self.alignment = alignment
    }
    
    func debugTree(_ context: IMView, _ offset: String = "") -> Void {
      context.debugTree(self, context, offset)
    }
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ _self: inout Self) -> SIMD2<Float> {
      let contentSize = context.calcSize(context, availableSize)
      
      let minWidth = minWidth ?? contentSize.x
      let maxWidth = maxWidth ?? contentSize.x
      let minHeight = minHeight ?? contentSize.y
      let maxHeight = maxHeight ?? contentSize.y
      
      let width = clamp(availableSize.x, minWidth, maxWidth)
      let height = clamp(availableSize.y, minHeight, maxHeight)
      
      let constrainedSize = SIMD2<Float>(width, height)
      _self.size = constrainedSize
      
      return constrainedSize
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>) -> SIMD2<Float> {
      return context.calcPosition(context, { _, size in
        let availableSize = max(self.size - size, float2())
        let offset = lerp(min: float2(), max: availableSize, t: self.alignment.offset)
        
        return position + offset
      })
    }
  }
  
  internal struct ExpandedFrame {
    let axis: Axis
    let alignment: Alignment
    var size: float2 = .init()
    
    init(_ axis: Axis, _ alignment: Alignment = .center) {
      self.axis = axis
      self.alignment = alignment
    }
    
    func debugTree(_ context: IMView, _ offset: String = "") -> Void {
      context.debugTree(self, context, offset)
    }
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ _self: inout Self) -> SIMD2<Float> {
      let contentSize = context.calcSize(context, availableSize)
      var size = float2()
      
      if axis.horizontal == 1, axis.vertical == 1 {
        size = availableSize
      } else {
        size += availableSize * axis.size
        size += contentSize * axis.inverted
      }
      
      _self.size = size
      
      return size
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>) -> SIMD2<Float> {
      return context.calcPosition(context, { _, size in
        let availableSize = max(self.size - size, float2())
        let offset = lerp(min: float2(), max: availableSize, t: self.alignment.offset)
        
        return position + offset
      })
    }
  }
}
