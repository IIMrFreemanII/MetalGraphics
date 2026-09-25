import simd

/// What `HStack` and `VStack` share: children in a row along one axis, aligned across it.
///
/// Space is shared as in SwiftUI. Along the stack's axis, after the spacing:
///
/// 1. Each child is measured at its smallest and its largest. The difference is how flexible it
///    is.
/// 2. Children are sized in order of `layoutPriority`, highest first. While a priority is being
///    sized, the children of lower priority keep only their smallest size in reserve.
/// 3. Within a priority, the least flexible child goes first and is offered an equal share of
///    what is left; whatever it takes, more or less, comes off what the next one is offered.
///
/// A `Spacer` comes after every other child, whatever their priority, so it takes only what
/// nobody else did: `HStack { Text(…); Spacer() }` gives the text all but the spacer's minimum
/// length, while `HStack { Text(…); Rectangle(…) }` shares the width between the two. A stack
/// asked for its ideal size along its axis asks every child for theirs.
///
/// Across its axis a stack offers every child what it was offered, and lines them up on its
/// alignment guide: `.center` or `.leading`, a text baseline, or a guide of your own, where each
/// child's is its default unless `.alignmentGuide` says otherwise. The stack is as thick as the
/// children it lines up. `spacing` goes between every two neighbours, spacers included.
///
/// Checked against SwiftUI's own layout of the same trees.
public class StackElement : MultiChildElement {
  /// 0 for a horizontal stack, 1 for a vertical one.
  let axis: Int

  public var spacing: Float = 0

  /// The guide children are lined up on across the stack.
  var crossKey: AlignmentKey { AlignmentKey(axis: 1 - self.axis, .fraction(0.5)) }

  /// The stack's size from the last layout pass.
  private var mainLength: Float = 0
  private var crossLength: Float = 0

  // Scratch for the layout of one pass, reused so layout allocates nothing once warmed up.
  // Indexed by position among the children taking part (`live`), not by index in `children`.
  private var live: [UIElement] = []
  private var isSpacer: [Bool] = []
  private var minLengths: [Float] = []
  private var maxLengths: [Float] = []
  private var priorities: [Float] = []
  private var lengths: [Float] = []
  private var order: [Int] = []
  private var sizes: [float2] = []
  private var crossOffsets: [Float] = []
  /// Where the guide children are lined up on lies across the stack, from the last `layout`.
  private var alignedLine: Float = 0
  /// Where each child goes across the stack, from the last committed layout. Kept apart from the
  /// scratch above, which measuring the stack for a guide may overwrite before it is placed.
  private var placedCross: [Float] = []

  init(axis: Int, spacing: Float) {
    self.axis = axis
    self.spacing = spacing
    super.init()
  }

  /// The stack's width and height from the last layout pass.
  public var size: float2 {
    var size = float2()
    size[self.axis] = self.mainLength
    size[1 - self.axis] = self.crossLength
    return size
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.layout(proposal, commit: false)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    let size = self.layout(proposal, commit: true)
    self.mainLength = size[self.axis]
    self.crossLength = size[1 - self.axis]
    self.placedCross.removeAll(keepingCapacity: true)
    self.placedCross.append(contentsOf: self.crossOffsets)
    return size
  }

  /// Sizes the children for `proposal` and returns the stack's size. With `commit`, each child
  /// is sized for good, once, with the length it settled on; otherwise only measured.
  private func layout(_ proposal: ProposedSize, commit: Bool) -> float2 {
    let axis = self.axis
    let cross = 1 - axis
    self.gatherLiveChildren()
    let count = self.live.count
    self.sizes.removeAll(keepingCapacity: true)
    self.crossOffsets.removeAll(keepingCapacity: true)
    guard count > 0 else { return .zero }

    let totalSpacing = self.spacing * Float(count - 1)

    self.lengths.removeAll(keepingCapacity: true)
    if let available = proposal[axis] {
      self.shareSpace(available - totalSpacing, proposal)
    } else {
      // Asked for its ideal length: every child at theirs.
      for child in self.live {
        self.lengths.append(child.measure(proposal.with(axis, nil))[axis])
      }
    }

    var main = totalSpacing
    for index in 0..<count {
      let child = self.live[index]
      let childProposal = proposal.with(axis, self.lengths[index])
      let size = commit ? child.calcSize(childProposal) : child.measure(childProposal)
      self.sizes.append(size)
      main += size[axis]
    }

    // Line the children up across: the line is as far in as the furthest guide, and the stack
    // reaches as far past it as any child does.
    let key = self.crossKey
    var line: Float = 0
    var beyond: Float = 0
    for index in 0..<count {
      let guide = self.live[index].alignmentValue(key, proposal.with(axis, self.lengths[index]), self.sizes[index])
      self.crossOffsets.append(guide)
      line = max(line, guide)
    }
    for index in 0..<count {
      beyond = max(beyond, self.sizes[index][cross] - self.crossOffsets[index])
      self.crossOffsets[index] = line - self.crossOffsets[index]
    }
    self.alignedLine = line

    var result = float2()
    result[axis] = main
    result[cross] = line + beyond
    return result
  }

  /// Lays the children out for `proposal` without committing, and reports where each would go,
  /// relative to the stack, and what it would be offered. What `HStackLayout` and
  /// `VStackLayout` place their subviews by.
  func arrange(_ proposal: ProposedSize, _ report: (Int, float2, ProposedSize) -> Void) -> float2 {
    let size = self.layout(proposal, commit: false)
    var offset: Float = 0
    for index in self.live.indices {
      var origin = float2()
      origin[self.axis] = offset
      origin[1 - self.axis] = self.crossOffsets[index]
      report(index, origin, proposal.with(self.axis, self.lengths[index]))
      offset += self.sizes[index][self.axis] + self.spacing
    }
    self.live.removeAll(keepingCapacity: true)
    return size
  }

  /// Shares `available` among the children by priority and flexibility, into `lengths`.
  private func shareSpace(_ available: Float, _ proposal: ProposedSize) {
    let axis = self.axis
    let count = self.live.count

    self.minLengths.removeAll(keepingCapacity: true)
    self.maxLengths.removeAll(keepingCapacity: true)
    self.priorities.removeAll(keepingCapacity: true)
    self.order.removeAll(keepingCapacity: true)
    var samePriority = true
    for (index, child) in self.live.enumerated() {
      self.minLengths.append(child.measure(proposal.with(axis, 0))[axis])
      self.maxLengths.append(child.measure(proposal.with(axis, .infinity))[axis])
      // Spacers below every priority: they get what is left once everything else is sized.
      let priority = self.isSpacer[index] ? -Float.infinity : child.layoutPriority
      self.priorities.append(priority)
      samePriority = samePriority && priority == self.priorities[0]
      self.order.append(index)
      self.lengths.append(0)
    }

    // Highest priority first, then least flexible first; ties keep the children's order.
    self.order.sort { a, b in
      if !samePriority, self.priorities[a] != self.priorities[b] {
        return self.priorities[a] > self.priorities[b]
      }
      let flexA = self.maxLengths[a] - self.minLengths[a]
      let flexB = self.maxLengths[b] - self.minLengths[b]
      return flexA != flexB ? flexA < flexB : a < b
    }

    var remaining = available
    var groupStart = 0
    while groupStart < count {
      let priority = self.priorities[self.order[groupStart]]
      var groupEnd = groupStart + 1
      while groupEnd < count, self.priorities[self.order[groupEnd]] == priority {
        groupEnd += 1
      }

      // Lower priorities keep their smallest size until their turn.
      var reserved: Float = 0
      for position in groupEnd..<count {
        reserved += self.minLengths[self.order[position]]
      }

      var left = remaining - reserved
      for position in groupStart..<groupEnd {
        let index = self.order[position]
        let share = max(left / Float(groupEnd - position), 0)
        let length = self.live[index].measure(proposal.with(axis, share))[axis]
        self.lengths[index] = length
        left -= length
        remaining -= length
      }
      groupStart = groupEnd
    }
  }

  /// Collects the children taking part in layout — those not leaving — and tells spacers which
  /// way the stack runs.
  private func gatherLiveChildren() {
    self.live.removeAll(keepingCapacity: true)
    self.isSpacer.removeAll(keepingCapacity: true)
    for child in self.children where !child.isLeaving {
      self.live.append(child)
      child.stackAxis = self.axis
      self.isSpacer.append(child is Spacer)
    }
  }

  // Across: the line the children are lined up on, when asked for that guide, and a baseline as
  // the first or last child has it. Along: a baseline — in a VStack, the first child's first
  // baseline and the last child's last one.
  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    if let own = self.explicitGuide(key, size) { return own }
    let first: Bool
    switch key.kind {
    case .firstTextBaseline: first = true
    case .lastTextBaseline: first = false
    default:
      guard key.axis != self.axis, key == self.crossKey else { return nil }
      _ = self.layout(proposal, commit: false)
      self.live.removeAll(keepingCapacity: true)
      return self.alignedLine
    }

    _ = self.layout(proposal, commit: false)
    defer { self.live.removeAll(keepingCapacity: true) }
    guard !self.live.isEmpty else { return nil }
    let index = first ? 0 : self.live.count - 1
    let child = self.live[index]
    let childSize = self.sizes[index]
    let inner = child.alignmentValue(key, proposal.with(self.axis, self.lengths[index]), childSize)
    if key.axis == self.axis {
      var offset: Float = 0
      for previous in 0..<index {
        offset += self.sizes[previous][self.axis] + self.spacing
      }
      return offset + inner
    }
    return self.crossOffsets[index] + inner
  }

  public override func calcPosition(_ position: float2) {
    let axis = self.axis
    let cross = 1 - axis
    // `live` is what the last `calcSize` laid out: nothing changes the children in between
    // without invalidating layout.
    self.gatherLiveChildren()

    var offset = position[axis]
    for (index, child) in self.live.enumerated() {
      if index > 0 {
        offset += self.spacing
      }
      let childSize = child.getSize()
      var origin = float2()
      origin[axis] = offset
      origin[cross] = position[cross] + (index < self.placedCross.count ? self.placedCross[index] : 0)
      offset += childSize[axis]

      self.place(child, at: origin, in: position)
    }
    self.placeLeaving(in: position)
    // Not kept past the pass, so a removed child is not held on to.
    self.live.removeAll(keepingCapacity: true)
  }
}
