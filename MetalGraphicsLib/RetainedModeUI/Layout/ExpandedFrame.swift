import simd

public class ExpandedFrame : SingleChildElement {
  public var axis: Axis
  public var alignment: Alignment
  
  private var size: float2 = .init()
  
  public init(_ axis: @autoclosure @escaping () -> Axis, _ alignment: @autoclosure @escaping () -> Alignment = .center, @UIElementBuilder content: @escaping () -> [UIElementNode] = { [] }) {
    // These are non-optional, so they must be set before `super.init`. They used to be read
    // through `DependencyTracker.untracked` to keep the read out of an enclosing builder's
    // tracker; with dependencies resolved at compile time there is no tracker to hide from,
    // and the later `bind` calls would only have assigned the same values again.
    self.axis = axis()
    self.alignment = alignment()

    super.init()

    self.setStaticContent(content)
  }
  
  public override func getSize() -> float2 {
    self.size
  }
  
  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(size: \(size))")
    child?.debugHierarchy(offset + "  ")
  }
  
  public override func calcSize(_ availableSize: float2) -> float2 {
    let contentSize = child?.calcSize(availableSize) ?? availableSize
    var size = float2()
    
    if axis.horizontal == 1, axis.vertical == 1 {
      size = availableSize
    } else {
      size += availableSize * axis.size
      size += contentSize * axis.inverted
    }
    
    self.size = size
    
    return size
  }
  
  public override func calcPosition(_ position: float2) {
    if let child = child {
      let childSize = child.getSize()
      let availableSize = max(self.size - childSize, float2())
      let offset = lerp(min: float2(), max: availableSize, t: self.alignment.offset)
      
      child.calcPosition(position + offset)
    }
  }
}
