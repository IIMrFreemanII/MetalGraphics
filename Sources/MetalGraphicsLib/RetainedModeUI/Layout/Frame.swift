import simd

/// A fixed width, a fixed height, or both, with its child aligned inside. Made by
/// `.frame(width:height:alignment:)`.
///
/// Along an axis given a length, the child is offered that length and the frame takes it,
/// whatever size the child ends up. Along one left nil, the frame passes on what it was offered
/// and takes the child's length, as SwiftUI's does.
public class Frame : SingleChildElement {
  /// nil takes the child's width.
  public var width: Float?
  /// nil takes the child's height.
  public var height: Float?
  public var alignment: Alignment = .center

  // What the last layout pass sized it to, and offered its child.
  private var committedSize: float2 = .init()
  private var childProposalUsed = ProposedSize.unspecified

  /// Setting it fixes both lengths. Reading it gives the size the last layout pass gave the
  /// frame, which is the same unless a length is nil.
  public var size: float2 {
    get { self.committedSize }
    set {
      self.width = newValue.x
      self.height = newValue.y
      self.committedSize = newValue
    }
  }

  public init(_ size: float2, _ alignment: Alignment = .center, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()

    self.size = size
    self.alignment = alignment
    self.applyContent(content())
  }

  public init(
    width: Float? = nil, height: Float? = nil, alignment: Alignment = .center,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    super.init()

    self.width = width
    self.height = height
    self.committedSize = float2(width ?? 0, height ?? 0)
    self.alignment = alignment
    self.applyContent(content())
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(width: \(String(describing: width)), height: \(String(describing: height)), size: \(committedSize))")
    child?.debugHierarchy(offset + "  ")
  }

  public override func getSize() -> float2 {
    self.committedSize
  }

  private func childProposal(_ proposal: ProposedSize) -> ProposedSize {
    ProposedSize(width: self.width ?? proposal.width, height: self.height ?? proposal.height)
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    if let width = self.width, let height = self.height {
      return float2(width, height)
    }
    let childSize = self.child?.measure(self.childProposal(proposal)) ?? .zero
    return float2(self.width ?? childSize.x, self.height ?? childSize.y)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.childProposalUsed = self.childProposal(proposal)
    let childSize = self.child?.calcSize(self.childProposalUsed) ?? .zero
    self.committedSize = float2(self.width ?? childSize.x, self.height ?? childSize.y)

    return self.committedSize
  }

  public override func calcPosition(_ position: float2) -> Void {
    if let child = child {
      let offset = self.alignedOffset(child, self.alignment, in: self.committedSize, self.childProposalUsed, child.getSize())
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
