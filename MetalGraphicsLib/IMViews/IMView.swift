import MetalKit

public class IMView {
  internal var viewDepth = Float()
  internal func getViewDepth() -> Float {
    let value = viewDepth
    viewDepth += 1
    
    return value
  }
  
  public var renderer: ViewRenderer!
  internal var viewItemsTree: ViewItem!
  internal var viewItems: [ViewItem] = []
  internal var viewItemsStack: [Int] = []
  
  internal var backgrounds: [Background] = []
  internal var spacers: [Spacer] = []
  internal var vStacks: [VStack] = []
  internal var hStacks: [HStack] = []
  internal var paddings: [Padding] = []
  internal var frames: [Frame] = []
  internal var expandedFrames: [ExpandedFrame] = []
  internal var flexFrames: [FlexFrame] = []
  internal var mouseOvers: [MouseOver] = []
  //  private var texts: [Text] = []
  
  private func beginFrame(_ viewSize: float2) {
    viewDepth = 0
    viewItemsStack.removeAll(keepingCapacity: true)
    viewItems.removeAll(keepingCapacity: true)
    
    backgrounds.removeAll(keepingCapacity: true)
    spacers.removeAll(keepingCapacity: true)
    vStacks.removeAll(keepingCapacity: true)
    hStacks.removeAll(keepingCapacity: true)
    paddings.removeAll(keepingCapacity: true)
    frames.removeAll(keepingCapacity: true)
    expandedFrames.removeAll(keepingCapacity: true)
    flexFrames.removeAll(keepingCapacity: true)
    mouseOvers.removeAll(keepingCapacity: true)
    
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
    
    let mousePosition = renderer.input.mousePosition
    for item in mouseOvers {
      let result = pointInAABBoxTopLeftOrigin(point: mousePosition, position: item.position, size: item.size)
      item.callback(result)
    }
    
    //    self.childIndex = 0
    //    print("-------------------------------------")
    //    root.debugTree(self)
  }
  
  public func run(_ viewSize: float2) -> Void {
    //    benchmark(title: "Submit and Layout") {
    beginFrame(viewSize)
    update()
    endFrame(viewSize)
    //    }
  }
  
  internal func update() -> Void {
    
  }
  
  public func draw(in context: Graphics2D) -> Void {
    let offset = context.size * 0.5
    
    for item in backgrounds {
      context.draw(square: Square(position: item.position - offset + item.size * 0.5, size: item.size, color: item.color))
    }
  }
  
  internal func debugTree<T>(_ item: T, _ context: IMView, _ offset: String) -> Void {
    print(offset + "\(item)")
    
    context.forEachChild { child in
      switch child {
      case .Background(let index):
        context.backgrounds[index].debugTree(context, offset + "  ")
      case .Spacer(let index):
        context.spacers[index].debugTree(context, offset + "  ")
      case .VStack(let index):
        context.vStacks[index].debugTree(context, offset + "  ")
      case .HStack(let index):
        context.hStacks[index].debugTree(context, offset + "  ")
      case .Padding(let index):
        context.paddings[index].debugTree(context, offset + "  ")
      case .Frame(let index):
        context.frames[index].debugTree(context, offset + "  ")
      case .ExpandedFrame(let index):
        context.expandedFrames[index].debugTree(context, offset + "  ")
      case .FlexFrame(let index):
        context.flexFrames[index].debugTree(context, offset + "  ")
      case .MouseOver(let index):
        context.backgrounds[index].debugTree(context, offset + "  ")
      }
    }
  }
  
  internal func calcSize(_ context: IMView, _ availableSize: SIMD2<Float>, _ cb: (View, SIMD2<Float>) -> Void = {_,_ in }) -> SIMD2<Float> {
    var size = availableSize
    //    var usedSpace = float2()
    //    var axis = Axis.none
    //
    //    let viewItem = self.viewItems[self.childIndex]
    //    switch viewItem.type {
    //    case .HStack(let index):
    //      axis = .horizontal
    //      //      let temp = context.hStacks[index]
    ////      let spacing = temp.spacing
    ////      print(viewItem.childrenCount, spacing)
    //    case .VStack(let index):
    //      axis = .vertical
    //    default:
    //      break
    //    }
    
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
      case .HStack(let index):
        var temp = context.hStacks[index]
        size = temp.calcSize(context, availableSize, &temp)
        context.hStacks[index] = temp
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
      case .FlexFrame(let index):
        var temp = context.flexFrames[index]
        size = temp.calcSize(context, availableSize, &temp)
        context.flexFrames[index] = temp
        cb(child, size)
      case .MouseOver(let index):
        var temp = context.mouseOvers[index]
        size = temp.calcSize(context, availableSize, &temp)
        context.mouseOvers[index] = temp
        cb(child, size)
      }
    }
    
    return size
  }
  
  internal func calcPosition(_ context: IMView, _ cb: (_ child: View, _ size: SIMD2<Float>) -> SIMD2<Float>) -> SIMD2<Float> {
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
      case .HStack(let index):
        let temp = context.hStacks[index]
        result = temp.calcPosition(context, cb(child, temp.size))
        context.hStacks[index] = temp
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
      case .FlexFrame(let index):
        let temp = context.flexFrames[index]
        result = temp.calcPosition(context, cb(child, temp.size))
        context.flexFrames[index] = temp
      case .MouseOver(let index):
        var temp = context.mouseOvers[index]
        result = temp.calcPosition(context, cb(child, temp.size), &temp)
        context.mouseOvers[index] = temp
      }
    }
    
    return result
  }
  
  internal var childIndex: Int = 0
  internal func forEachChild(_ cb: (View) -> Void) -> Void {
    let viewItem = self.viewItems[self.childIndex]
    
    for _ in 0..<viewItem.childrenCount {
      self.childIndex += 1
      let child = self.viewItems[self.childIndex]
      cb(child.type)
    }
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
  
  internal struct ViewItem {
    var type: View
    var childrenCount: Int = 0
  }
  
  internal enum View {
    case Background(Int)
    case Spacer(Int)
    case VStack(Int)
    case HStack(Int)
    case Padding(Int)
    case Frame(Int)
    case ExpandedFrame(Int)
    case FlexFrame(Int)
    case MouseOver(Int)
    
    var isSpacer: Bool {
      switch self {
      case .Background(_):
        break
      case .Spacer(_):
        return true
      case .VStack(_):
        break
      case .HStack(_):
        break
      case .Padding(_):
        break
      case .Frame(_):
        break
      case .ExpandedFrame(_):
        break
      case .FlexFrame(_):
        break
      case .MouseOver(_):
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
      case .HStack(_):
        break
      case .Padding(_):
        break
      case .Frame(_):
        break
      case .ExpandedFrame(_):
        break
      case .FlexFrame(_):
        break
      case .MouseOver(_):
        break
      }
    }
  }
}

