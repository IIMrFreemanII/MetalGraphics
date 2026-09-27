import simd

/// Bounds on a child's width and height, with the child aligned inside. Made by
/// `.frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)`.
///
/// Laid out as SwiftUI's flexible frame, one axis at a time:
///
/// - The child is offered what the frame was offered, clamped to the bounds; the ideal length
///   when the frame was asked for its own ideal.
/// - Without bounds, the frame takes the child's length.
/// - Otherwise it takes what it was offered (its ideal length, or the child's, when asked for
///   its ideal), clamped to the bounds. A missing bound is the child's length, so
///   `maxWidth: .infinity` fills what is offered but never shrinks below the child, and
///   `minWidth: 100` never grows past the child beyond 100.
public class FlexFrame : SingleChildElement {
  public var minWidth: Float?
  public var idealWidth: Float?
  public var maxWidth: Float?
  public var minHeight: Float?
  public var idealHeight: Float?
  public var maxHeight: Float?
  public var alignment: Alignment

  private var size: float2 = .init()
  private var childProposalUsed = ProposedSize.unspecified

  public init(
    minWidth: Float? = nil, idealWidth: Float? = nil, maxWidth: Float? = nil,
    minHeight: Float? = nil, idealHeight: Float? = nil, maxHeight: Float? = nil,
    alignment: Alignment = .center, @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.minWidth = minWidth
    self.idealWidth = idealWidth
    self.maxWidth = maxWidth
    self.minHeight = minHeight
    self.idealHeight = idealHeight
    self.maxHeight = maxHeight
    self.alignment = alignment

    super.init()

    self.applyContent(content())
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(size: \(size))")
    child?.debugHierarchy(offset + "  ")
  }

  private func bounds(_ axis: Int) -> (min: Float?, ideal: Float?, max: Float?) {
    axis == 0
      ? (self.minWidth, self.idealWidth, self.maxWidth)
      : (self.minHeight, self.idealHeight, self.maxHeight)
  }

  private func childProposal(_ proposal: ProposedSize) -> ProposedSize {
    var result = ProposedSize.unspecified
    for axis in 0..<2 {
      let (lower, ideal, upper) = self.bounds(axis)
      guard var length = proposal[axis] else {
        result[axis] = ideal
        continue
      }
      if let lower { length = Swift.max(length, lower) }
      if let upper { length = Swift.min(length, upper) }
      result[axis] = length
    }
    return result
  }

  private func resolve(_ proposal: ProposedSize, childSize: float2) -> float2 {
    var result = childSize
    for axis in 0..<2 {
      let (lower, ideal, upper) = self.bounds(axis)
      guard lower != nil || upper != nil else { continue }
      let child = childSize[axis]
      let offered = proposal[axis] ?? ideal ?? child
      let low = lower ?? Swift.min(child, upper!)
      let high = Swift.max(upper ?? Swift.max(child, lower!), low)
      result[axis] = Swift.min(Swift.max(offered, low), high)
    }
    return result
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let childSize = self.child?.measure(self.childProposal(proposal)) ?? .zero
    return self.resolve(proposal, childSize: childSize)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.childProposalUsed = self.childProposal(proposal)
    let childSize = self.child?.calcSize(self.childProposalUsed) ?? .zero
    self.size = self.resolve(proposal, childSize: childSize)
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    if let child = child {
      let offset = self.alignedOffset(child, self.alignment, in: self.size, self.childProposalUsed, child.getSize())
      self.place(child, at: position + offset, in: position)
    }
  }

  // A guide the child defines, moved to where the frame puts the child.
  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    if let own = self.explicitGuide(key, size) { return own }
    guard let child = self.child else { return nil }
    let childProposal = self.childProposal(proposal)
    let childSize = child.measure(childProposal)
    guard let inner = child.guideValue(key, childProposal, childSize) else { return nil }
    return inner + self.alignedOffset(child, self.alignment, in: size, childProposal, childSize)[key.axis]
  }
}
