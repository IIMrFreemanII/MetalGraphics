import simd

/// One column of a `LazyVGrid`, or one row of a `LazyHGrid`: how wide it is, the space after
/// it, and how its cells are aligned in it.
public struct GridItem: Sendable {
  public enum Size: Sendable {
    /// Exactly this long.
    case fixed(Float)
    /// A share of the space left after the fixed items, within these bounds.
    case flexible(minimum: Float = 10, maximum: Float = .infinity)
    /// As many tracks as fit in its share, each at least `minimum` long.
    case adaptive(minimum: Float, maximum: Float = .infinity)
  }

  public var size: Size
  /// The space after it, before the next item; 0 when nil, as for stacks.
  public var spacing: Float?
  /// How cells are aligned in it; nil is the grid's alignment, centred across.
  public var alignment: Alignment?

  public init(_ size: Size = .flexible(), spacing: Float? = nil, alignment: Alignment? = nil) {
    self.size = size
    self.spacing = spacing
    self.alignment = alignment
  }
}

/// What `LazyVGrid` and `LazyHGrid` share: cells flowing through tracks resolved from
/// `GridItem`s — columns filled left to right, then the next row, for a `LazyVGrid`; rows filled
/// top to bottom, then the next column, for a `LazyHGrid`.
///
/// Tracks are resolved from the length offered across the flow as SwiftUI does: fixed items
/// first, then an equal share of what is left for each other item, a flexible one clamped to its
/// bounds and an adaptive one split into as many tracks of at least its minimum as fit. The grid
/// takes all that length, and aligns the tracks in it. Each cell is offered its track's length
/// and its ideal length along the flow; a line of cells is as long as its longest.
///
/// Checked against SwiftUI's own layout of the same grids. All cells are built and laid out;
/// see the lazy stacks for content that is only built when scrolled into view.
public class LazyGridElement : MultiChildElement {
  /// The axis tracks run across: 0 for columns, 1 for rows.
  let trackAxis: Int

  public var items: [GridItem]
  /// Between lines of cells.
  public var spacing: Float

  /// Where the tracks sit across the grid, and cells in them unless their item says otherwise.
  var trackAlignment: Float { 0.5 }
  /// How cells are aligned in their track and line when their item does not say.
  var defaultCellAlignment: Alignment { .center }

  public private(set) var size: float2 = .zero

  // Resolved tracks: each one's length, the space before it, its alignment, and where it starts.
  private var trackLengths: [Float] = []
  private var trackAlignments: [Alignment] = []
  private var trackStarts: [Float] = []
  private var lineLengths: [Float] = []
  private var cells: [UIElement] = []
  private var placed: [float2] = []

  init(trackAxis: Int, items: [GridItem], spacing: Float) {
    self.trackAxis = trackAxis
    self.items = items
    self.spacing = spacing
    super.init()
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.layout(proposal, commit: false)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.layout(proposal, commit: true)
    return self.size
  }

  /// Resolves `items` into tracks across `available`, or at their smallest when it is nil.
  /// Returns the length the tracks take, spacing included.
  private func resolveTracks(_ available: Float?) -> Float {
    self.trackLengths.removeAll(keepingCapacity: true)
    self.trackAlignments.removeAll(keepingCapacity: true)
    self.trackStarts.removeAll(keepingCapacity: true)

    let items = self.items
    var fixed: Float = 0
    var spacing: Float = 0
    var others = 0
    for (index, item) in items.enumerated() {
      if case .fixed(let length) = item.size { fixed += length } else { others += 1 }
      if index < items.count - 1 { spacing += item.spacing ?? 0 }
    }
    var remaining = (available ?? 0) - fixed - spacing
    var left = others

    var offset: Float = 0
    for (index, item) in items.enumerated() {
      let alignment = item.alignment ?? self.defaultCellAlignment
      let gap = item.spacing ?? 0
      func add(_ length: Float) {
        self.trackStarts.append(offset)
        self.trackLengths.append(length)
        self.trackAlignments.append(alignment)
        offset += length + gap
      }
      switch item.size {
      case .fixed(let length):
        add(length)
      case .flexible(let minimum, let maximum):
        let share = available == nil ? minimum : remaining / Float(left)
        let length = min(max(share, minimum), maximum)
        remaining -= length
        left -= 1
        add(length)
      case .adaptive(let minimum, let maximum):
        let share = available == nil ? minimum : remaining / Float(left)
        let count = max(Int(((share + gap) / (minimum + gap)).rounded(.down)), 1)
        var length = (share - gap * Float(count - 1)) / Float(count)
        length = min(max(length, minimum), maximum)
        for _ in 0..<count { add(length) }
        remaining -= length * Float(count) + gap * Float(count - 1)
        left -= 1
      }
      // No space after the last item.
      if index == items.count - 1 { offset -= gap }
    }
    return max(offset, 0)
  }

  private func layout(_ proposal: ProposedSize, commit: Bool) -> float2 {
    let across = self.trackAxis
    let along = 1 - across
    let block = self.resolveTracks(proposal[across])
    let trackCount = self.trackLengths.count

    self.cells.removeAll(keepingCapacity: true)
    for child in self.children where !child.isLeaving {
      self.cells.append(child)
    }
    self.lineLengths.removeAll(keepingCapacity: true)
    guard trackCount > 0, !self.cells.isEmpty else {
      if commit { self.placed.removeAll(keepingCapacity: true) }
      var size = float2()
      size[across] = proposal[across] ?? block
      return size
    }

    // Every cell at its track's length and its ideal length along the flow.
    for (index, cell) in self.cells.enumerated() {
      let track = index % trackCount
      let line = index / trackCount
      let cellProposal = ProposedSize.unspecified.with(across, self.trackLengths[track])
      let length = (commit ? cell.calcSize(cellProposal) : cell.measure(cellProposal))[along]
      if line == self.lineLengths.count {
        self.lineLengths.append(length)
      } else {
        self.lineLengths[line] = max(self.lineLengths[line], length)
      }
    }

    var size = float2()
    size[across] = proposal[across] ?? block
    size[along] = self.lineLengths.reduce(0, +) + self.spacing * Float(self.lineLengths.count - 1)

    if commit {
      // The tracks as a block, aligned across the grid; each cell aligned in its box.
      let blockOffset = (size[across] - block) * self.trackAlignment
      self.placed.removeAll(keepingCapacity: true)
      var lineStart: Float = 0
      for (index, cell) in self.cells.enumerated() {
        let track = index % trackCount
        let line = index / trackCount
        if track == 0 && line > 0 {
          lineStart += self.lineLengths[line - 1] + self.spacing
        }
        var box = float2()
        box[across] = self.trackLengths[track]
        box[along] = self.lineLengths[line]
        var origin = float2()
        origin[across] = blockOffset + self.trackStarts[track]
        origin[along] = lineStart
        let cellProposal = ProposedSize.unspecified.with(across, self.trackLengths[track])
        let offset = self.alignedOffset(cell, self.trackAlignments[track], in: box, cellProposal, cell.getSize())
        self.placed.append(origin + offset)
      }
    }
    return size
  }

  public override func calcPosition(_ position: float2) {
    var index = 0
    for child in self.children where !child.isLeaving {
      let offset = index < self.placed.count ? self.placed[index] : .zero
      self.place(child, at: position + offset, in: position)
      index += 1
    }
    self.placeLeaving(in: position)
    self.cells.removeAll(keepingCapacity: true)
  }
}

/// Cells in columns resolved from `columns`, filled left to right, one row after another. See
/// `LazyGridElement`.
public final class LazyVGrid : LazyGridElement {
  /// Where the columns sit across the grid, and where cells sit in them unless their item says.
  public var alignment: HorizontalAlignment

  override var trackAlignment: Float { self.alignment.offset }
  override var defaultCellAlignment: Alignment { Alignment(horizontal: self.alignment, vertical: .center) }

  public init(
    columns: [GridItem], alignment: HorizontalAlignment = .center, spacing: Float = 0,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.alignment = alignment
    super.init(trackAxis: 0, items: columns, spacing: spacing)
    self.applyContent(content())
  }
}

/// Cells in rows resolved from `rows`, filled top to bottom, one column after another. See
/// `LazyGridElement`.
public final class LazyHGrid : LazyGridElement {
  /// Where the rows sit across the grid, and where cells sit in them unless their item says.
  public var alignment: VerticalAlignment

  override var trackAlignment: Float { self.alignment.offset }
  override var defaultCellAlignment: Alignment { Alignment(horizontal: .center, vertical: self.alignment) }

  public init(
    rows: [GridItem], alignment: VerticalAlignment = .center, spacing: Float = 0,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.alignment = alignment
    super.init(trackAxis: 1, items: rows, spacing: spacing)
    self.applyContent(content())
  }
}
