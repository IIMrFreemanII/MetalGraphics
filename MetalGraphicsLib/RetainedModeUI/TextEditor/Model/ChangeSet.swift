/// Which way a position at the exact place of an insertion goes: before the inserted text, or
/// after it.
public enum TextAssociation: Sendable {
  case before
  case after
}

/// One replacement: `range`, in the text before the change, becomes `text`.
public struct TextChange: Hashable, Sendable {
  public var range: Range<Int>
  public var text: [UInt16]

  public init(range: Range<Int>, text: [UInt16]) {
    self.range = range
    self.text = text
  }

  public init(range: Range<Int>, with string: String) {
    self.init(range: range, text: Array(string.utf16))
  }

  /// How much longer the text is after it.
  var delta: Int { self.text.count - self.range.count }
}

/// Replacements made at once — one per cursor, say — sorted and not overlapping, every range in
/// the text as it was before any of them.
public struct ChangeSet: Hashable, Sendable {
  public private(set) var changes: [TextChange]

  public init(_ changes: [TextChange]) {
    var sorted = changes.sorted { $0.range.lowerBound < $1.range.lowerBound }
    // Overlaps join: a later change that starts inside an earlier one takes the rest of its range.
    var i = 1
    while i < sorted.count {
      if sorted[i].range.lowerBound < sorted[i - 1].range.upperBound {
        let joined = sorted[i - 1].range.lowerBound ..< max(sorted[i - 1].range.upperBound, sorted[i].range.upperBound)
        sorted[i - 1] = TextChange(range: joined, text: sorted[i - 1].text + sorted[i].text)
        sorted.remove(at: i)
      } else {
        i += 1
      }
    }
    self.changes = sorted
  }

  public init(_ change: TextChange) {
    self.changes = [change]
  }

  public var isEmpty: Bool {
    self.changes.allSatisfy { $0.range.isEmpty && $0.text.isEmpty }
  }

  /// Where `position`, in the text before, ends up after. At an insertion it goes before or after
  /// the inserted text by `association`; inside a replaced range, to the start or the end of what
  /// replaced it the same way; at a replaced range's start, to the start of the replacement.
  public func map(_ position: Int, _ association: TextAssociation = .after) -> Int {
    var delta = 0
    for change in self.changes {
      let start = change.range.lowerBound
      if position < start { break }
      if change.range.isEmpty {
        if position == start { return position + delta + (association == .after ? change.text.count : 0) }
      } else {
        if position == start { return start + delta }
        if position < change.range.upperBound {
          return start + delta + (association == .after ? change.text.count : 0)
        }
      }
      delta += change.delta
    }
    return position + delta
  }

  /// A range's image: its ends mapped inward, so it does not grow over text inserted at its
  /// edges, and an emptied range stays empty.
  public func map(_ range: Range<Int>) -> Range<Int> {
    let lower = self.map(range.lowerBound, .after)
    guard !range.isEmpty else { return lower ..< lower }
    let upper = self.map(range.upperBound, .before)
    return min(lower, upper) ..< max(lower, upper)
  }

  /// The ranges of the inserted texts, in the text after.
  public var insertedRanges: [Range<Int>] {
    var delta = 0
    var ranges: [Range<Int>] = []
    ranges.reserveCapacity(self.changes.count)
    for change in self.changes {
      let start = change.range.lowerBound + delta
      ranges.append(start ..< start + change.text.count)
      delta += change.delta
    }
    return ranges
  }

  /// The changes that undo this one, given what each range held before it.
  func inverted(removed: [[UInt16]]) -> ChangeSet {
    var delta = 0
    var inverse: [TextChange] = []
    inverse.reserveCapacity(self.changes.count)
    for (change, old) in zip(self.changes, removed) {
      let start = change.range.lowerBound + delta
      inverse.append(TextChange(range: start ..< start + change.text.count, text: old))
      delta += change.delta
    }
    return ChangeSet(inverse)
  }

  /// The lowest and highest positions this touches, before and after.
  var touchedBounds: (low: Int, high: Int) {
    var low = Int.max
    var high = Int.min
    var delta = 0
    for change in self.changes {
      low = min(low, change.range.lowerBound)
      high = max(high, change.range.upperBound, change.range.lowerBound + delta + change.text.count)
      delta += change.delta
    }
    return (low, high)
  }

  /// The same changes with every position moved by `delta`.
  func shifted(by delta: Int) -> ChangeSet {
    var shifted = self
    for i in shifted.changes.indices {
      let range = shifted.changes[i].range
      shifted.changes[i].range = range.lowerBound + delta ..< range.upperBound + delta
    }
    return shifted
  }
}
