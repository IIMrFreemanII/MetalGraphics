import simd

/// Shows the first of its children that fits, as SwiftUI's `ViewThatFits`: the first whose ideal
/// size along `axes` is no larger than what it is offered, or the last when none is.
///
/// Only that child is laid out, drawn and hit; the others stay mounted, keeping their state, so
/// switching back is instant. It is offered everything the container was.
public final class ViewThatFits : MultiChildElement {
  public var axes: Axis

  /// The child shown since the last layout pass.
  private var chosen: UIElement? = nil
  private weak var context: UIContext? = nil
  private var size: float2 = .zero

  public init(in axes: Axis = .both, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.axes = axes
    super.init()
    self.applyContent(content())
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func getSize() -> float2 {
    self.size
  }

  private func choose(_ proposal: ProposedSize) -> UIElement? {
    var last: UIElement? = nil
    // Ideal along the axes that are checked, the proposal along the others.
    let ideal = ProposedSize(
      width: self.axes.horizontal != 0 ? nil : proposal.width,
      height: self.axes.vertical != 0 ? nil : proposal.height
    )
    for child in self.children where !child.isLeaving {
      last = child
      let size = child.measure(ideal)
      let fitsWidth = self.axes.horizontal == 0 || proposal.width.map { size.x <= $0 + 1e-3 } ?? true
      let fitsHeight = self.axes.vertical == 0 || proposal.height.map { size.y <= $0 + 1e-3 } ?? true
      if fitsWidth && fitsHeight { return child }
    }
    return last
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.choose(proposal)?.measure(proposal) ?? .zero
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    let chosen = self.choose(proposal)
    if chosen !== self.chosen {
      self.chosen = chosen
      // Something else is drawn and hit now; the order is rebuilt before the next draw.
      self.context?.invalidate(.treeOrder)
    }
    self.size = chosen?.calcSize(proposal) ?? .zero
    return self.size
  }

  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    self.explicitGuide(key, size) ?? self.choose(proposal)?.guideValue(key, proposal, size)
  }

  override func forEachChildInPaintOrder(_ body: (UIElement) -> Void) {
    if let chosen = self.chosen, !chosen.isLeaving {
      body(chosen)
    }
    for child in self.children where child.isLeaving {
      body(child)
    }
  }

  public override func calcPosition(_ position: float2) {
    if let chosen = self.chosen {
      self.place(chosen, at: position, in: position)
    }
    self.placeLeaving(in: position)
  }
}
