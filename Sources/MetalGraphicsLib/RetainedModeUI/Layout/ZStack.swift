import simd

/// Children on top of each other, later ones in front, lined up on `alignment`'s guides.
///
/// Every child is offered what the stack was offered. Along each axis the children's guides
/// meet on one line, and the stack reaches as far as any child does on either side of it: with
/// plain fractions, that is as large as its largest child. `.zIndex(_:)` on a child changes
/// which is in front without changing the order of the children.
public class ZStack : MultiChildElement {
  public var alignment: Alignment

  public private(set) var size: float2 = .zero

  // Scratch for one layout, and where each child goes from the last committed one.
  private var sizes: [float2] = []
  private var offsets: [float2] = []
  private var lines: float2 = .zero
  private var placed: [float2] = []

  public init(alignment: Alignment = .center, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.alignment = alignment
    super.init()

    self.applyContent(content())
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "ZStack(size: \(self.size), alignment: \(self.alignment))")
    for child in self.children {
      child.debugHierarchy(offset + "  ")
    }
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.layout(proposal, commit: false)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.layout(proposal, commit: true)
    self.placed.removeAll(keepingCapacity: true)
    self.placed.append(contentsOf: self.offsets)
    return self.size
  }

  private func layout(_ proposal: ProposedSize, commit: Bool) -> float2 {
    self.sizes.removeAll(keepingCapacity: true)
    self.offsets.removeAll(keepingCapacity: true)
    for child in self.children where !child.isLeaving {
      self.sizes.append(commit ? child.calcSize(proposal) : child.measure(proposal))
    }

    var lines = float2.zero
    var beyond = float2.zero
    var index = 0
    for child in self.children where !child.isLeaving {
      var guides = float2()
      for axis in 0..<2 {
        guides[axis] = child.alignmentValue(self.alignment.key(axis), proposal, self.sizes[index])
      }
      self.offsets.append(guides)
      lines = simd_max(lines, guides)
      index += 1
    }
    for index in self.offsets.indices {
      beyond = simd_max(beyond, self.sizes[index] - self.offsets[index])
      self.offsets[index] = lines - self.offsets[index]
    }
    self.lines = lines
    return lines + beyond
  }

  /// Lays the children out for `proposal` without committing, and reports where each would go,
  /// relative to the stack. What `ZStackLayout` places its subviews by.
  func arrange(_ proposal: ProposedSize, _ report: (Int, float2, ProposedSize) -> Void) -> float2 {
    let size = self.layout(proposal, commit: false)
    for index in self.offsets.indices {
      report(index, self.offsets[index], proposal)
    }
    return size
  }

  // The line the children are lined up on, when asked for one of its alignment's guides.
  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    if let own = self.explicitGuide(key, size) { return own }
    guard key == self.alignment.key(key.axis) else { return nil }
    _ = self.layout(proposal, commit: false)
    return self.lines[key.axis]
  }

  public override func calcPosition(_ position: float2) {
    var index = 0
    for child in self.children where !child.isLeaving {
      let offset = index < self.placed.count ? self.placed[index] : .zero
      self.place(child, at: position + offset, in: position)
      index += 1
    }
    self.placeLeaving(in: position)
  }
}
