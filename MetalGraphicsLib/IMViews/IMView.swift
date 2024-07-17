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
  
  private var paddings: [Padding] = []
  private var texts: [Text] = []
  private var vStacks: [VStack] = []
  private var rects: [Rect] = []
  private var spacers: [Spacer] = []
  
  private func beginFrame() {
    viewDepth = 0
    viewItemsStack.removeAll(keepingCapacity: true)
    viewItems.removeAll(keepingCapacity: true)
    paddings.removeAll(keepingCapacity: true)
    rects.removeAll(keepingCapacity: true)
    spacers.removeAll(keepingCapacity: true)
    vStacks.removeAll(keepingCapacity: true)
    
    let view: View = .Padding(paddings.count)
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    paddings.append(Padding(.init(all: 10)))
  }
  
  private func endFrame() {
    var root = self.paddings.first!
    
    self.childIndex = 0
    _ = root.calcSize(self, SIMD2<Float>(500, 500), &root)
    
    self.childIndex = 0
    _ = root.calcPosition(self, SIMD2<Float>(0, 0))
    
//    self.childIndex = 0
//    root.debugTree(self)
  }
  
  public func run() -> Void {
    beginFrame()
    update()
    endFrame()
  }
  
  internal func update() -> Void {
    
  }
  
  public func draw(in context: Graphics2D) -> Void {
//    print(context.size)
    
    let offset = context.size * 0.5
    
    for rect in rects {
      context.draw(square: Square(position: rect.position - offset + rect.size * 0.5, size: rect.size, color: rect.color))
    }
  }
  
  private func debugTree<T>(_ item: T, _ context: IMView, _ offset: String) -> Void {
    print(offset + "\(item)")
    
    context.forEachChild { child in
      switch child {
      case .Padding(let index):
        context.paddings[index].debugTree(context, offset + "  ")
      case .Rect(let index):
        context.rects[index].debugTree(context, offset + "  ")
      case .VStack(let index):
        context.vStacks[index].debugTree(context, offset + "  ")
      case .Spacer(let index):
        context.spacers[index].debugTree(context, offset + "  ")
      }
    }
  }
  
  private func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ cb: (SIMD2<Float>, View) -> Void = {_,_ in }) -> SIMD2<Float> {
    var size = availableSize
    
    context.forEachChild { child in
      switch child {
      case .Rect(let index):
        size = context.rects[index].calcSize(context, availableSize)
        cb(size, child)
      case .VStack(let index):
        var temp = context.vStacks[index]
        size = temp.calcSize(context, availableSize, &temp)
        cb(size, child)
        context.vStacks[index] = temp
      case .Padding(let index):
        var temp = context.paddings[index]
        size = temp.calcSize(context, availableSize, &temp)
        context.paddings[index] = temp
        cb(size, child)
      case .Spacer(let index):
        size = context.spacers[index].calcSize(context, availableSize)
        cb(size, child)
      }
    }
    
    return size
  }
  
  private func calcPosition(_ context: IMView, _ cb: (_ child: View, _ size: SIMD2<Float>) -> SIMD2<Float>) -> SIMD2<Float> {
    var result = SIMD2<Float>()
    
    context.forEachChild { child in
      switch child {
      case .Rect(let index):
        var temp = context.rects[index]
        result = temp.calcPosition(context, cb(child, temp.size), &temp)
        context.rects[index] = temp
      case .VStack(let index):
        let temp = context.vStacks[index]
        result = temp.calcPosition(context, cb(child, temp.size))
        context.vStacks[index] = temp
      case .Padding(let index):
        let temp = context.paddings[index]
        result = context.paddings[index].calcPosition(context, cb(child, temp.size))
        context.paddings[index] = temp
      case .Spacer(let index):
        result = context.spacers[index].calcPosition(context, cb(child, .init()))
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
  
  internal func rect(_ size: SIMD2<Float>, _ color: float4 = .black, _ cb: () -> Void = { }) -> Void {
    let view: View = .Rect(rects.count)
    let parentIndex = viewItemsStack[viewItemsStack.count - 1]
    viewItemsStack.append(viewItems.count)
    viewItems.append(ViewItem(type: view))
    viewItems[parentIndex].childrenCount += 1
    rects.append(Rect(size, color, getViewDepth()))
    
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
      
      _ = context.calcSize(context, availableSize) { size, child in
        contentHeight += size.y + spacing
        maxWidth = max(maxWidth, size.x)
        
        child.onSpacer {
          spacersCount += 1
        }
      }
      
      if spacersCount > 0 {
        let freeSpace = max(availableSize.y - contentHeight, 0)
        _self.spacerSize = freeSpace / Float(spacersCount)
        
        return .init(maxWidth, availableSize.y)
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
        
        var xOffset = position.x
        switch self.alignment {
        case .leading:
          xOffset = position.x
        case .center:
          let halfOfMaxWidth = self.maxWidth * 0.5
          let halfOfChildWidth = size.x * 0.5
          xOffset += halfOfMaxWidth - halfOfChildWidth
        case .trailing:
          let difference = self.maxWidth - size.x
          xOffset += difference
        }
        
        let result = SIMD2<Float>(xOffset, yOffset)
        
        yOffset += size.y
        
        return result
      })
    }
  }
  
  internal struct Rect {
    var position: SIMD2<Float> = .init()
    var size: SIMD2<Float> = .init(100, 100)
    var color: SIMD4<Float> = .black
    var depth: Float
    
    init(_ size: SIMD2<Float>, _ color: float4, _ depth: Float) {
      self.size = size
      self.depth = depth
      self.color = color
    }
    
    func debugTree(_ context: IMView, _ offset: String = "") -> Void {
      context.debugTree(self, context, offset)
    }
    
    func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>) -> SIMD2<Float> {
      return context.calcSize(context, self.size)
    }
    
    func calcPosition(_ context: IMView, _ position: SIMD2<Float>, _ _self: inout Rect) -> SIMD2<Float> {
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
      let temp = inset.inflate(size: context.calcSize(context, availableSize))
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
    case Rect(Int)
    case Spacer(Int)
    case VStack(Int)
    case Padding(Int)
    
    var isSpacer: Bool {
      switch self {
      case .Rect(_):
        break
      case .Spacer(_):
        return true
      case .VStack(_):
        break
      case .Padding(_):
        break
      }
      
      return false
    }
    
    func onSpacer(_ cb: () -> Void) -> Void {
      switch self {
      case .Rect(_):
        break
      case .Spacer(_):
        cb()
      case .VStack(_):
        break
      case .Padding(_):
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
  
  enum HorizontalAlignment {
    case leading
    case center
    case trailing
  }
  
  enum VerticalAlignment {
    case top
    case center
    case bottom
  }
}

