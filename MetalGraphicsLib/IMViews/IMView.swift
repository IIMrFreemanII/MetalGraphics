import MetalKit

public class IMView {
  private var viewDepth = Float()
  private func getViewDepth() -> Float {
    let value = viewDepth
    viewDepth += 1
    
    return value
  }
  
  private var viewItemsTree: ViewItem!
  private var viewItems: [ViewItem] = []
  private var viewItemsStack: [Int] = []
  
  private var backgrounds: [Background] = []
  private var spacers: [Spacer] = []
  private var vStacks: [VStack] = []
  private var paddings: [Padding] = []
  private var frames: [Frame] = []
  private var expandedFrames: [ExpandedFrame] = []
//  private var texts: [Text] = []
  
  private func beginFrame(_ viewSize: float2) {
    viewDepth = 0
    viewItemsStack.removeAll(keepingCapacity: true)
    viewItems.removeAll(keepingCapacity: true)
    
    backgrounds.removeAll(keepingCapacity: true)
    spacers.removeAll(keepingCapacity: true)
    vStacks.removeAll(keepingCapacity: true)
    paddings.removeAll(keepingCapacity: true)
    frames.removeAll(keepingCapacity: true)
    expandedFrames.removeAll(keepingCapacity: true)
    
    let view: View = .Frame(frames.count)
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    frames.append(Frame(viewSize, .center))
  }
  
  private func endFrame(_ viewSize: float2) {
    let root = self.frames.first!
    
    self.childIndex = 0
    _ = root.calcSize(self, viewSize)
    
    self.childIndex = 0
    _ = root.calcPosition(self, SIMD2<Float>(0, 0))
    
//    self.childIndex = 0
//    print("-------------------------------------")
//    root.debugTree(self)
  }
  
  public func run(_ viewSize: float2) -> Void {
    beginFrame(viewSize)
    update()
    endFrame(viewSize)
  }
  
  internal func update() -> Void {
    
  }
  
  public func draw(in context: Graphics2D) -> Void {
    let offset = context.size * 0.5
    
    for item in backgrounds {
      context.draw(square: Square(position: item.position - offset + item.size * 0.5, size: item.size, color: item.color))
    }
  }
  
  private func debugTree<T>(_ item: T, _ context: IMView, _ offset: String) -> Void {
    print(offset + "\(item)")
    
    context.forEachChild { child in
      switch child {
      case .Background(let index):
        context.backgrounds[index].debugTree(context, offset + "  ")
      case .Spacer(let index):
        context.spacers[index].debugTree(context, offset + "  ")
      case .VStack(let index):
        context.vStacks[index].debugTree(context, offset + "  ")
      case .Padding(let index):
        context.paddings[index].debugTree(context, offset + "  ")
      case .Frame(let index):
        context.frames[index].debugTree(context, offset + "  ")
      case .ExpandedFrame(let index):
        context.expandedFrames[index].debugTree(context, offset + "  ")
      }
    }
  }
  
  private func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ cb: (View, SIMD2<Float>) -> Void = {_,_ in }) -> SIMD2<Float> {
    var size = availableSize
    
    context.forEachChild { child in
      switch child {
      case .Background(let index):
        var temp = context.backgrounds[index]
        size = temp.calcSize(context, availableSize, &temp)
        context.backgrounds[index] = temp
        cb(child, size)
      case .Spacer(let index):
        size = context.spacers[index].calcSize(context, availableSize)
        cb(child, size)
      case .VStack(let index):
        var temp = context.vStacks[index]
        size = temp.calcSize(context, availableSize, &temp)
        context.vStacks[index] = temp
        cb(child, size)
      case .Padding(let index):
        var temp = context.paddings[index]
        size = temp.calcSize(context, availableSize, &temp)
        context.paddings[index] = temp
        cb(child, size)
      case .Frame(let index):
        size = context.frames[index].calcSize(context, availableSize)
        cb(child, size)
      case .ExpandedFrame(let index):
        var temp = context.expandedFrames[index]
        size = temp.calcSize(context, availableSize, &temp)
        context.expandedFrames[index] = temp
        cb(child, size)
      }
    }
    
    return size
  }
  
  private func calcPosition(_ context: IMView, _ cb: (_ child: View, _ size: SIMD2<Float>) -> SIMD2<Float>) -> SIMD2<Float> {
    var result = SIMD2<Float>()
    
    context.forEachChild { child in
      switch child {
      case .Background(let index):
        var temp = context.backgrounds[index]
        result = temp.calcPosition(context, cb(child, temp.size), &temp)
        context.backgrounds[index] = temp
      case .Spacer(let index):
        result = context.spacers[index].calcPosition(context, cb(child, .init()))
      case .VStack(let index):
        let temp = context.vStacks[index]
        result = temp.calcPosition(context, cb(child, temp.size))
        context.vStacks[index] = temp
      case .Padding(let index):
        let temp = context.paddings[index]
        result = temp.calcPosition(context, cb(child, temp.size))
        context.paddings[index] = temp
      case .Frame(let index):
        let temp = context.frames[index]
        result = temp.calcPosition(context, cb(child, temp.size))
        context.frames[index] = temp
      case .ExpandedFrame(let index):
        let temp = context.expandedFrames[index]
        result = temp.calcPosition(context, cb(child, temp.size))
        context.expandedFrames[index] = temp
      }
    }
    
    return result
  }
  
  private var childIndex: Int = 0
  private func forEachChild(_ cb: (View) -> Void) -> Void {
    let viewItem = self.viewItems[self.childIndex]
    
    for _ in 0..<viewItem.childrenCount {
      self.childIndex += 1
      let child = self.viewItems[self.childIndex]
      cb(child.type)
    }
  }
}

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
  
  internal func spacer() -> Void {
    let view: View = .Spacer(spacers.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    spacers.append(Spacer())
  }
  
  internal func vStack(_ alignment: HorizontalAlignment = .center, _ spacing: Float = 0, _ cb: () -> Void) -> Void {
    let view: View = .VStack(vStacks.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    vStacks.append(VStack(alignment, spacing))
    
    cb()
    
    _ = viewItemsStack.popLast()
  }
  
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
  
  internal func frame(_ size: SIMD2<Float>, _ alignment: Alignment = .center, _ cb: () -> Void = { }) -> Void {
    let view: View = .Frame(frames.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    frames.append(Frame(size, alignment))
    
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
}

extension IMView {
  internal struct Text {
    let value: String
    let depth: Float
    
    init(_ value: String, _ depth: Float) {
      self.value = value
      self.depth = depth
    }
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
  
  internal struct VStack {
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
          spacersCount += 1
        }
      }
      
      if spacersCount > 0 {
        let freeSpace = max(availableSize.y - contentHeight, 0)
        _self.spacerSize = freeSpace / Float(spacersCount)
        contentHeight = availableSize.y
        
        return .init(maxWidth, contentHeight)
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
        yOffset += size.y
        
        return result
      })
    }
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
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ _self: inout Background) -> SIMD2<Float> {
      let contentSize = context.calcSize(context, availableSize)
      _self.size = contentSize
      
      return contentSize
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>, _ _self: inout Background) -> SIMD2<Float> {
      _self.position = position
      
      return context.calcPosition(context, { _, _ in position })
    }
  }
  
  internal struct Padding {
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
  
  internal struct ViewItem {
    var type: View
    var childrenCount: Int = 0
  }
  
  internal enum View {
    case Background(Int)
    case Spacer(Int)
    case VStack(Int)
    case Padding(Int)
    case Frame(Int)
    case ExpandedFrame(Int)
    
    var isSpacer: Bool {
      switch self {
      case .Background(_):
        break
      case .Spacer(_):
        return true
      case .VStack(_):
        break
      case .Padding(_):
        break
      case .Frame(_):
        break
      case .ExpandedFrame(_):
        break
      }
      
      return false
    }
    
    func onSpacer(_ cb: () -> Void) -> Void {
      switch self {
      case .Background(_):
        break
      case .Spacer(_):
        cb()
      case .VStack(_):
        break
      case .Padding(_):
        break
      case .Frame(_):
        break
      case .ExpandedFrame(_):
        break
      }
    }
  }
  
  struct Inset {
    var left: Float
    var top: Float
    var right: Float
    var bottom: Float
    
    var horizontal: Float {
      left + right
    }
    
    var vertical: Float {
      top + bottom
    }
    
    var topLeft: SIMD2<Float> {
      SIMD2<Float>(left, top)
    }
    
    init(left: Float = 0, top: Float = 0, right: Float = 0, bottom: Float = 0)
    {
      self.left = left
      self.top = top
      self.right = right
      self.bottom = bottom
    }
    
    init(all: Float) {
      self.left = all
      self.top = all
      self.right = all
      self.bottom = all
    }
    
    init(vertical: Float = 0, horizontal: Float = 0) {
      self.left = horizontal
      self.top = vertical
      self.right = horizontal
      self.bottom = vertical
    }
    
    ///Returns a new size that is bigger than the given size by the amount of inset in the horizontal and vertical directions.
    func inflate(size: SIMD2<Float>) -> SIMD2<Float> {
      return size + SIMD2<Float>(horizontal, vertical)
    }
    
    /// Returns a new size that is smaller than the given size by the amount of inset in the horizontal and vertical directions.
    func deflate(size: SIMD2<Float>) -> SIMD2<Float> {
      return size - SIMD2<Float>(horizontal, vertical)
    }
  }
  
  struct Axis {
    let horizontal: Float
    let vertical: Float
    
    var size: float2 {
      float2(horizontal, vertical)
    }
    var inverted: float2 {
      float2(vertical, horizontal)
    }
    
    private init(_ horizontal: Float, _ vertical: Float) {
      self.horizontal = horizontal
      self.vertical = vertical
    }
    
    static let horizontal: Self = .init(1.0, 0.0)
    static let vertical: Self = .init(0.0, 1.0)
    static let both: Self = .init(1.0, 1.0)
  }
  
  struct Alignment {
    let xOffset: Float
    let yOffset: Float
    
    var offset: float2 {
      float2(xOffset, yOffset)
    }
    
    init(_ xOffset: Float, _ yOffset: Float) {
      self.xOffset = xOffset
      self.yOffset = yOffset
    }
    
    static let topLeading: Self = .init(0.0, 0.0)
    static let top: Self = .init(0.5, 0.0)
    static let topTrailing: Self = .init(1.0, 0.0)
    static let leading: Self = .init(0.0, 0.5)
    static let center: Self = .init(0.5, 0.5)
    static let trailing: Self = .init(1.0, 0.5)
    static let bottomLeading: Self = .init(0.0, 1.0)
    static let bottom: Self = .init(0.5, 1.0)
    static let bottomTrailing: Self = .init(1.0, 1.0)
  }
  
  struct HorizontalAlignment {
    let offset: Float
    
    init(_ offset: Float) {
      self.offset = offset
    }
    
    static let leading: Self = .init(0.0)
    static let center: Self = .init(0.5)
    static let trailing: Self = .init(1.0)
  }
  
  struct VerticalAlignment {
    let offset: Float
    
    init(_ offset: Float) {
      self.offset = offset
    }
    
    static let top: Self = .init(0)
    static let center: Self = .init(0.5)
    static let bottom: Self = .init(1)
  }
}

