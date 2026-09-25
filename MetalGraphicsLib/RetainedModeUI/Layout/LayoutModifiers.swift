import simd

// Single-child wrappers that change how their child is sized or placed, one per SwiftUI layout
// modifier. Each is checked against SwiftUI's own layout of the same tree.

/// Asks its child for its ideal size along the fixed axes, whatever it was offered: text stays
/// on one line, a shape takes its ideal 10 points. Made by `.fixedSize(horizontal:vertical:)`.
public final class FixedSizeElement : SingleChildElement {
  public var horizontal: Bool
  public var vertical: Bool

  private var size: float2 = .zero

  public init(horizontal: Bool = true, vertical: Bool = true, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.horizontal = horizontal
    self.vertical = vertical
    super.init()
    self.applyContent(content())
  }

  private func childProposal(_ proposal: ProposedSize) -> ProposedSize {
    ProposedSize(
      width: self.horizontal ? nil : proposal.width,
      height: self.vertical ? nil : proposal.height
    )
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.child?.measure(self.childProposal(proposal)) ?? .zero
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.child?.calcSize(self.childProposal(proposal)) ?? .zero
    return self.size
  }

  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    self.explicitGuide(key, size) ?? self.child?.guideValue(key, self.childProposal(proposal), size)
  }
}

/// Offers its child the largest size of a given shape that fits in what it was offered, or the
/// smallest that covers it, and takes whatever the child answers. Made by
/// `.aspectRatio(_:contentMode:)`, `.scaledToFit()` and `.scaledToFill()`, on anything but an
/// `Image`, which applies them to itself.
public final class AspectRatioElement : SingleChildElement {
  /// Width over height; nil is the child's own, from its ideal size.
  public var ratio: Float?
  public var contentMode: ContentMode

  private var size: float2 = .zero

  public init(_ ratio: Float? = nil, contentMode: ContentMode, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.ratio = ratio
    self.contentMode = contentMode
    super.init()
    self.applyContent(content())
  }

  private func childProposal(_ proposal: ProposedSize) -> ProposedSize {
    guard let child = self.child else { return proposal }
    // Asked for its ideal size, the child answers for itself.
    if proposal.width == nil && proposal.height == nil {
      return proposal
    }
    let ratio: Float
    if let own = self.ratio {
      ratio = own
    } else {
      let ideal = child.measure(.unspecified)
      ratio = ideal.y > 0 ? ideal.x / ideal.y : 1
    }
    guard ratio > 0, ratio.isFinite else { return proposal }

    switch (proposal.width, proposal.height) {
    case let (width?, height?):
      let widthFirst = float2(width, width / ratio)
      let heightFirst = float2(height * ratio, height)
      let fitsWidthFirst = widthFirst.y <= height
      let size: float2
      switch self.contentMode {
      case .fit: size = fitsWidthFirst ? widthFirst : heightFirst
      case .fill: size = fitsWidthFirst ? heightFirst : widthFirst
      }
      return ProposedSize(size)
    case let (width?, nil):
      return ProposedSize(float2(width, width / ratio))
    case let (nil, height?):
      return ProposedSize(float2(height * ratio, height))
    case (nil, nil):
      return proposal
    }
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.child?.measure(self.childProposal(proposal)) ?? .zero
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.child?.calcSize(self.childProposal(proposal)) ?? .zero
    return self.size
  }

  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    self.explicitGuide(key, size) ?? self.child?.guideValue(key, self.childProposal(proposal), size)
  }
}

/// Takes all the space it is offered and centres its child on `point` in it. Made by
/// `.position(x:y:)`.
public final class PositionElement : SingleChildElement {
  public var point: float2

  private var size: float2 = .zero

  public init(_ point: float2, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.point = point
    super.init()
    self.applyContent(content())
  }

  public override func getSize() -> float2 {
    self.size
  }

  // Asked for its ideal size, it is its child's.
  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    if let width = proposal.width, let height = proposal.height {
      return float2(width, height)
    }
    return proposal.replacingUnspecified(with: self.child?.measure(proposal) ?? .zero)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    let childSize = self.child?.calcSize(proposal) ?? .zero
    self.size = proposal.replacingUnspecified(with: childSize)
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    guard let child = self.child else { return }
    self.place(child, at: position + self.point - child.getSize() * 0.5, in: position)
  }

  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    if let own = self.explicitGuide(key, size) { return own }
    guard let child = self.child else { return nil }
    let childSize = child.measure(proposal)
    guard let inner = child.guideValue(key, proposal, childSize) else { return nil }
    return inner + self.point[key.axis] - childSize[key.axis] * 0.5
  }
}

/// Cuts off whatever its child draws outside `shape` fitted to its bounds, and lets nothing
/// outside its bounds be hit. Made by `.clipped()`, `.clipShape(_:)` and `.cornerRadius(_:)`.
public final class ClipElement : SingleChildElement {
  private var position: float2 = .zero
  private var size: float2 = .zero
  public internal(set) var shape: UIShape

  public init(_ shape: UIShape = .rect, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.shape = shape
    super.init()
    self.applyContent(content())
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.child?.calcSize(proposal) ?? .zero
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
    self.child?.calcPosition(position)
  }

  override var clipRect: ClipRect? {
    self.shape.resolve(in: ClipRect(position: self.position, size: self.size)).rect
  }

  override var clipCornerRadii: float4 {
    self.shape.resolve(in: ClipRect(position: self.position, size: self.size)).radii
  }
}
