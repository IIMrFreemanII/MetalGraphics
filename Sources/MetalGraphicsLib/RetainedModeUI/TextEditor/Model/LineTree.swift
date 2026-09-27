/// What a document keeps for each line besides its length and height.
struct LineRecord {
  /// Names this line's current text: a line gets a new id whenever its text changes, so caches
  /// keyed by it (shaped layouts, styled spans) go stale by themselves, and survive lines moving
  /// up or down under them.
  var id: UInt32
  /// The styler's state at the start of the line, valid when `flags` has `styleValid`.
  var styleState: UInt64 = 0
  var flags: LineFlags = []
  /// Tokens stored with the text (console output, rich text), in line columns. They move with
  /// edits of the line and are dropped with it.
  var spans: [TextSpan] = []
}

struct LineFlags: OptionSet {
  var rawValue: UInt8
  /// `height` was measured from the shaped line, not estimated.
  static let measured = LineFlags(rawValue: 1 << 0)
  /// `styleState` was computed from the line above's end state since that line last changed.
  static let styleValid = LineFlags(rawValue: 1 << 1)
  /// Folded away: height 0, skipped when drawn and by the caret moving up and down.
  static let hidden = LineFlags(rawValue: 1 << 2)
}

/// The line index and the height index of a document in one structure: every line's length in
/// UTF-16 units (with its newline) and its height in points, in leaves of a few hundred lines,
/// with running totals per leaf. Finding a line by offset or by y, or a line's start or top, is a
/// binary search over the leaves and then a scan of one: O(leaves + leaf size), a few hundred
/// integer steps at 100k lines. An edit touches one leaf and marks the totals after it stale;
/// they are summed again at the next query.
///
/// Records travel with their lines, so what is cached per line needs no rekeying when a newline
/// shifts every line below it.
final class LineTree {
  final class Leaf {
    var lengths: [Int32] = []
    var heights: [Float] = []
    var records: [LineRecord] = []
    var length = 0
    var height: Double = 0

    var count: Int { self.lengths.count }

    func recount() {
      self.length = 0
      self.height = 0
      for length in self.lengths { self.length += Int(length) }
      for height in self.heights { self.height += Double(height) }
    }
  }

  static let maxLeaf = 512
  static let splitLeaf = 256
  static let minLeaf = 32

  private(set) var leaves: [Leaf]
  /// Per leaf, then one past the last: the first line, the offset and the top where it starts.
  private var firstLines: [Int] = [0]
  private var starts: [Int] = [0]
  private var tops: [Double] = [0]
  /// Entries of the three arrays above up to this index are current.
  private var validPrefix = 0

  init(lengths: [Int32], heights: [Float], records: [LineRecord]) {
    precondition(!lengths.isEmpty && lengths.count == heights.count && heights.count == records.count)
    self.leaves = []
    var i = 0
    while i < lengths.count {
      let end = min(i + Self.splitLeaf, lengths.count)
      let leaf = Leaf()
      leaf.lengths = Array(lengths[i ..< end])
      leaf.heights = Array(heights[i ..< end])
      leaf.records = Array(records[i ..< end])
      leaf.recount()
      self.leaves.append(leaf)
      i = end
    }
  }

  // MARK: - Totals

  var lineCount: Int {
    self.ensurePrefix()
    return self.firstLines[self.leaves.count]
  }

  var length: Int {
    self.ensurePrefix()
    return self.starts[self.leaves.count]
  }

  var height: Double {
    self.ensurePrefix()
    return self.tops[self.leaves.count]
  }

  private func invalidate(fromLeaf leaf: Int) {
    self.validPrefix = min(self.validPrefix, leaf)
  }

  private func ensurePrefix() {
    let count = self.leaves.count
    guard self.validPrefix < count || self.firstLines.count != count + 1 else { return }
    if self.firstLines.count != count + 1 {
      self.firstLines = Array(repeating: 0, count: count + 1)
      self.starts = Array(repeating: 0, count: count + 1)
      self.tops = Array(repeating: 0, count: count + 1)
      self.validPrefix = 0
    }
    var i = self.validPrefix
    while i < count {
      let leaf = self.leaves[i]
      self.firstLines[i + 1] = self.firstLines[i] + leaf.count
      self.starts[i + 1] = self.starts[i] + leaf.length
      self.tops[i + 1] = self.tops[i] + leaf.height
      i += 1
    }
    self.validPrefix = count
  }

  // MARK: - Finding lines

  /// The leaf holding `line`, and the line's index in it.
  func locate(_ line: Int) -> (leaf: Int, index: Int) {
    self.ensurePrefix()
    precondition(line >= 0 && line < self.firstLines[self.leaves.count], "line out of range")
    let leaf = Self.lastIndex(in: self.firstLines, count: self.leaves.count, notAbove: line)
    return (leaf, line - self.firstLines[leaf])
  }

  /// The line `offset` is in: the one it starts, or the last when it is the end of the text.
  func line(containing offset: Int) -> Int {
    self.ensurePrefix()
    let count = self.leaves.count
    if offset >= self.starts[count] { return self.firstLines[count] - 1 }
    if offset <= 0 { return 0 }
    let leafIndex = Self.lastIndex(in: self.starts, count: count, notAbove: offset)
    let leaf = self.leaves[leafIndex]
    var start = self.starts[leafIndex]
    for i in 0 ..< leaf.count {
      let end = start + Int(leaf.lengths[i])
      if offset < end { return self.firstLines[leafIndex] + i }
      start = end
    }
    return self.firstLines[leafIndex] + leaf.count - 1
  }

  /// The line at `y` points from the top, clamped to the first and last.
  func line(atY y: Double) -> Int {
    self.ensurePrefix()
    let count = self.leaves.count
    if y <= 0 { return 0 }
    if y >= self.tops[count] { return self.firstLines[count] - 1 }
    let leafIndex = Self.lastIndex(in: self.tops, count: count, notAbove: y)
    let leaf = self.leaves[leafIndex]
    var top = self.tops[leafIndex]
    for i in 0 ..< leaf.count {
      let bottom = top + Double(leaf.heights[i])
      if y < bottom { return self.firstLines[leafIndex] + i }
      top = bottom
    }
    return self.firstLines[leafIndex] + leaf.count - 1
  }

  func start(of line: Int) -> Int {
    let (leafIndex, index) = self.locate(line)
    let leaf = self.leaves[leafIndex]
    var start = self.starts[leafIndex]
    for i in 0 ..< index { start += Int(leaf.lengths[i]) }
    return start
  }

  func top(of line: Int) -> Double {
    let (leafIndex, index) = self.locate(line)
    let leaf = self.leaves[leafIndex]
    var top = self.tops[leafIndex]
    for i in 0 ..< index { top += Double(leaf.heights[i]) }
    return top
  }

  /// With its newline, if it has one.
  func length(of line: Int) -> Int {
    let (leaf, index) = self.locate(line)
    return Int(self.leaves[leaf].lengths[index])
  }

  func height(of line: Int) -> Float {
    let (leaf, index) = self.locate(line)
    return self.leaves[leaf].heights[index]
  }

  func record(of line: Int) -> LineRecord {
    let (leaf, index) = self.locate(line)
    return self.leaves[leaf].records[index]
  }

  func updateRecord<R>(of line: Int, _ body: (inout LineRecord) -> R) -> R {
    let (leaf, index) = self.locate(line)
    return body(&self.leaves[leaf].records[index])
  }

  /// Visits lines `range` in order with their record, height and length; faster than looking up
  /// each.
  func forEach(in range: Range<Int>, _ body: (_ line: Int, _ record: inout LineRecord, _ height: inout Float, _ length: Int32) -> Void) {
    guard !range.isEmpty else { return }
    var (leafIndex, index) = self.locate(range.lowerBound)
    var line = range.lowerBound
    var heightChanged = false
    var changedFrom = Int.max
    while line < range.upperBound {
      let leaf = self.leaves[leafIndex]
      while index < leaf.count && line < range.upperBound {
        let old = leaf.heights[index]
        body(line, &leaf.records[index], &leaf.heights[index], leaf.lengths[index])
        if leaf.heights[index] != old {
          leaf.height += Double(leaf.heights[index] - old)
          heightChanged = true
          changedFrom = min(changedFrom, leafIndex)
        }
        index += 1
        line += 1
      }
      leafIndex += 1
      index = 0
    }
    if heightChanged { self.invalidate(fromLeaf: changedFrom) }
  }

  // MARK: - Changing lines

  /// Sets a line's height. Returns the change, in points.
  @discardableResult
  func setHeight(_ height: Float, of line: Int) -> Float {
    let (leafIndex, index) = self.locate(line)
    let leaf = self.leaves[leafIndex]
    let delta = height - leaf.heights[index]
    guard delta != 0 else { return 0 }
    leaf.heights[index] = height
    leaf.height += Double(delta)
    self.invalidate(fromLeaf: leafIndex)
    return delta
  }

  /// Changes a line's length without splitting or joining lines: an edit within one line.
  func adjustLength(of line: Int, by delta: Int) {
    let (leafIndex, index) = self.locate(line)
    let leaf = self.leaves[leafIndex]
    leaf.lengths[index] += Int32(delta)
    leaf.length += delta
    self.invalidate(fromLeaf: leafIndex)
  }

  /// Replaces lines `range` with new ones. The tree always keeps at least one line.
  func replaceLines(_ range: Range<Int>, lengths: [Int32], heights: [Float], records: [LineRecord]) {
    precondition(lengths.count == heights.count && heights.count == records.count)
    precondition(self.lineCount - range.count + lengths.count > 0, "a document has at least one line")
    // One leaf holds the whole range, the common case: splice in place.
    var (leafIndex, index) = self.locate(min(range.lowerBound, self.lineCount - 1))
    if range.lowerBound == self.lineCount {
      index = self.leaves[leafIndex].count
    }
    let first = self.leaves[leafIndex]
    if index + range.count <= first.count {
      first.lengths.replaceSubrange(index ..< index + range.count, with: lengths)
      first.heights.replaceSubrange(index ..< index + range.count, with: heights)
      first.records.replaceSubrange(index ..< index + range.count, with: records)
      first.recount()
      self.rebalance(leafIndex)
      return
    }
    // Across leaves: remove the rest of the range leaf by leaf, then insert into the first.
    var remaining = range.count - (first.count - index)
    first.lengths.removeSubrange(index...)
    first.heights.removeSubrange(index...)
    first.records.removeSubrange(index...)
    var next = leafIndex + 1
    while remaining > 0 {
      let leaf = self.leaves[next]
      let removed = min(remaining, leaf.count)
      leaf.lengths.removeFirst(removed)
      leaf.heights.removeFirst(removed)
      leaf.records.removeFirst(removed)
      leaf.recount()
      remaining -= removed
      if leaf.count == 0 {
        self.leaves.remove(at: next)
      } else {
        next += 1
      }
    }
    first.lengths.append(contentsOf: lengths)
    first.heights.append(contentsOf: heights)
    first.records.append(contentsOf: records)
    first.recount()
    self.invalidate(fromLeaf: leafIndex)
    self.firstLines.removeAll()
    self.rebalance(leafIndex)
  }

  /// Splits a leaf grown too large, and drops or merges one grown too small.
  private func rebalance(_ leafIndex: Int) {
    let leaf = self.leaves[leafIndex]
    if leaf.count > Self.maxLeaf {
      var pieces: [Leaf] = []
      var i = 0
      while i < leaf.count {
        let end = min(i + Self.splitLeaf, leaf.count)
        let piece = Leaf()
        piece.lengths = Array(leaf.lengths[i ..< end])
        piece.heights = Array(leaf.heights[i ..< end])
        piece.records = Array(leaf.records[i ..< end])
        piece.recount()
        pieces.append(piece)
        i = end
      }
      self.leaves.replaceSubrange(leafIndex ... leafIndex, with: pieces)
      self.firstLines.removeAll()
    } else if leaf.count == 0 && self.leaves.count > 1 {
      self.leaves.remove(at: leafIndex)
      self.firstLines.removeAll()
    } else if leaf.count < Self.minLeaf && self.leaves.count > 1 {
      let neighbour = leafIndex + 1 < self.leaves.count ? leafIndex + 1 : leafIndex - 1
      let (low, high) = (min(leafIndex, neighbour), max(leafIndex, neighbour))
      let a = self.leaves[low]
      let b = self.leaves[high]
      if a.count + b.count <= Self.maxLeaf {
        a.lengths.append(contentsOf: b.lengths)
        a.heights.append(contentsOf: b.heights)
        a.records.append(contentsOf: b.records)
        a.recount()
        self.leaves.remove(at: high)
        self.firstLines.removeAll()
      }
    }
    self.invalidate(fromLeaf: max(0, leafIndex - 1))
  }

  /// The last index `i` below `count` with `values[i] <= target`, for sorted `values`.
  private static func lastIndex<T: Comparable>(in values: [T], count: Int, notAbove target: T) -> Int {
    var low = 0
    var high = count - 1
    while low < high {
      let middle = (low + high + 1) / 2
      if values[middle] <= target { low = middle } else { high = middle - 1 }
    }
    return low
  }
}
