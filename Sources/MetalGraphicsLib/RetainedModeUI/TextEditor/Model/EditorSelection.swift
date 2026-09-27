/// Which side of a soft line break a caret at the break is drawn on: the end of the upper line
/// (`upstream`) or the start of the lower (`downstream`).
public enum TextAffinity: Hashable, Sendable {
  case upstream
  case downstream
}

/// One selected range, or a caret when `anchor == head`. The head is the end that moves.
public struct SelectionRange: Hashable, Sendable {
  public var anchor: Int
  public var head: Int
  public var affinity: TextAffinity = .downstream
  /// The x a vertical move aims for, kept across moves through shorter lines.
  public var goalX: Float? = nil

  public init(anchor: Int, head: Int, affinity: TextAffinity = .downstream, goalX: Float? = nil) {
    self.anchor = anchor
    self.head = head
    self.affinity = affinity
    self.goalX = goalX
  }

  public static func caret(_ offset: Int, affinity: TextAffinity = .downstream) -> SelectionRange {
    SelectionRange(anchor: offset, head: offset, affinity: affinity)
  }

  public var isEmpty: Bool { self.anchor == self.head }
  public var lowerBound: Int { min(self.anchor, self.head) }
  public var upperBound: Int { max(self.anchor, self.head) }
  public var range: Range<Int> { self.lowerBound ..< self.upperBound }

  func mapped(through changes: ChangeSet) -> SelectionRange {
    if self.isEmpty {
      let offset = changes.map(self.head, .after)
      return SelectionRange(anchor: offset, head: offset, affinity: self.affinity)
    }
    let range = changes.map(self.range)
    return self.anchor <= self.head
      ? SelectionRange(anchor: range.lowerBound, head: range.upperBound, affinity: self.affinity)
      : SelectionRange(anchor: range.upperBound, head: range.lowerBound, affinity: self.affinity)
  }
}

/// A document's selection: one range per cursor, sorted, never overlapping, and one of them
/// primary — the one scrolled to and shown in a status bar.
public struct EditorSelection: Hashable, Sendable {
  public private(set) var ranges: [SelectionRange]
  public private(set) var primaryIndex: Int

  public init(_ ranges: [SelectionRange], primary: Int = 0) {
    precondition(!ranges.isEmpty, "a selection has at least one range")
    let primaryRange = ranges[min(primary, ranges.count - 1)]
    self.ranges = ranges
    self.primaryIndex = 0
    self.normalize(keeping: primaryRange)
  }

  public init(_ range: SelectionRange) {
    self.ranges = [range]
    self.primaryIndex = 0
  }

  public static func caret(_ offset: Int) -> EditorSelection {
    EditorSelection(.caret(offset))
  }

  public var primary: SelectionRange { self.ranges[self.primaryIndex] }
  public var isSingleCaret: Bool { self.ranges.count == 1 && self.ranges[0].isEmpty }
  public var hasSelectedText: Bool { self.ranges.contains { !$0.isEmpty } }

  /// Sorts the ranges and joins those that overlap or touch as carets.
  private mutating func normalize(keeping primary: SelectionRange) {
    guard self.ranges.count > 1 else {
      self.primaryIndex = 0
      return
    }
    var sorted = self.ranges.sorted { $0.lowerBound < $1.lowerBound }
    var i = 1
    var primary = primary
    while i < sorted.count {
      let previous = sorted[i - 1]
      let current = sorted[i]
      let touches = current.lowerBound < previous.upperBound
        || (current.lowerBound == previous.upperBound && (current.isEmpty || previous.isEmpty))
      if touches {
        let low = previous.lowerBound
        let high = max(previous.upperBound, current.upperBound)
        let joined = previous.anchor <= previous.head
          ? SelectionRange(anchor: low, head: high) : SelectionRange(anchor: high, head: low)
        if primary == previous || primary == current { primary = joined }
        sorted[i - 1] = joined
        sorted.remove(at: i)
      } else {
        i += 1
      }
    }
    self.ranges = sorted
    self.primaryIndex = sorted.firstIndex(of: primary) ?? 0
  }

  func mapped(through changes: ChangeSet) -> EditorSelection {
    EditorSelection(self.ranges.map { $0.mapped(through: changes) }, primary: self.primaryIndex)
  }

  /// Every range clamped into a text `length` long.
  func clamped(to length: Int) -> EditorSelection {
    EditorSelection(self.ranges.map {
      SelectionRange(anchor: $0.anchor.clamped(to: 0 ... length), head: $0.head.clamped(to: 0 ... length),
                     affinity: $0.affinity, goalX: $0.goalX)
    }, primary: self.primaryIndex)
  }

  /// Each range replaced by `transform`'s result, then normalized.
  func map(_ transform: (SelectionRange) -> SelectionRange) -> EditorSelection {
    EditorSelection(self.ranges.map(transform), primary: self.primaryIndex)
  }
}
