import simd

/// Empty space that grows to take whatever its stack does not give anyone else, and no less than
/// `minLength`.
///
/// In a stack it grows along the stack's axis only, and has no thickness across it. Anywhere
/// else it grows along both axes.
public class Spacer : LeafElement {
  public var minLength: Float

  private var size: float2 = .zero

  public init(minLength: Float = 0) {
    self.minLength = minLength
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    var size = float2()
    for axis in 0..<2 {
      if let stackAxis = self.stackAxis, stackAxis != axis {
        continue
      }
      size[axis] = max(proposal[axis] ?? self.minLength, self.minLength)
    }
    return size
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    return self.size
  }
}
