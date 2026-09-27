/// Ranges of a document that move with its edits: read-only stretches, diagnostics, attachment
/// anchors. Kept sorted by start; an edit maps every mark after it, O(marks).
public final class TextMarks<Payload> {
  public struct Mark {
    public let id: Int
    public internal(set) var range: Range<Int>
    public var payload: Payload
    /// Text inserted exactly at the start, or at the end, becomes part of the mark.
    public let growsAtStart: Bool
    public let growsAtEnd: Bool
  }

  public private(set) var marks: [Mark] = []
  /// A mark whose text is all deleted goes with it.
  let removesEmptied: Bool
  private var nextID = 1
  private var longest = 0

  init(removesEmptied: Bool) {
    self.removesEmptied = removesEmptied
  }

  public var isEmpty: Bool { self.marks.isEmpty }

  @discardableResult
  public func add(_ range: Range<Int>, _ payload: Payload, growsAtStart: Bool = false, growsAtEnd: Bool = false) -> Int {
    let id = self.nextID
    self.nextID += 1
    let mark = Mark(id: id, range: range, payload: payload, growsAtStart: growsAtStart, growsAtEnd: growsAtEnd)
    let index = self.insertionIndex(range.lowerBound)
    self.marks.insert(mark, at: index)
    self.longest = max(self.longest, range.count)
    return id
  }

  public func remove(_ id: Int) {
    self.marks.removeAll { $0.id == id }
  }

  public func removeAll() {
    self.marks.removeAll()
    self.longest = 0
  }

  /// Moves a mark: a console's read-only history growing over output it appended.
  public func setRange(_ range: Range<Int>, of id: Int) {
    guard let index = self.marks.firstIndex(where: { $0.id == id }) else { return }
    var mark = self.marks.remove(at: index)
    mark.range = range
    self.marks.insert(mark, at: self.insertionIndex(range.lowerBound))
    self.longest = max(self.longest, range.count)
  }

  public func mark(_ id: Int) -> Mark? {
    self.marks.first { $0.id == id }
  }

  /// Calls `body` with each mark that overlaps `range`, or that is empty and inside it, in order.
  public func forEach(overlapping range: Range<Int>, _ body: (Mark) -> Void) {
    guard !self.marks.isEmpty else { return }
    // Marks start in order; one starting before `range` reaches into it only if it is long enough.
    var i = self.insertionIndex(range.lowerBound - self.longest)
    while i < self.marks.count {
      let mark = self.marks[i]
      if mark.range.lowerBound > range.upperBound { break }
      let overlaps: Bool
      if range.isEmpty {
        overlaps = mark.range.contains(range.lowerBound) || mark.range.lowerBound == range.lowerBound
      } else if mark.range.isEmpty {
        overlaps = range.contains(mark.range.lowerBound)
      } else {
        overlaps = mark.range.overlaps(range)
      }
      if overlaps { body(mark) }
      i += 1
    }
  }

  /// Whether `position` is strictly inside a mark: an insertion there would split it.
  public func containsInside(_ position: Int) -> Bool {
    var found = false
    self.forEach(overlapping: position ..< position) { mark in
      if mark.range.lowerBound < position && position < mark.range.upperBound { found = true }
    }
    return found
  }

  /// Whether any mark overlaps `range`, a non-empty range.
  public func overlaps(_ range: Range<Int>) -> Bool {
    var found = false
    self.forEach(overlapping: range) { mark in
      if !mark.range.isEmpty && mark.range.overlaps(range) { found = true }
    }
    return found
  }

  func map(through changes: ChangeSet) {
    guard !self.marks.isEmpty else { return }
    let first = changes.changes.first?.range.lowerBound ?? 0
    var removed = false
    self.longest = 0
    for i in self.marks.indices {
      let mark = self.marks[i]
      if mark.range.upperBound >= first {
        let wasEmpty = mark.range.isEmpty
        let lower = changes.map(mark.range.lowerBound, mark.growsAtStart ? .before : .after)
        let upper = wasEmpty ? lower : changes.map(mark.range.upperBound, mark.growsAtEnd ? .after : .before)
        self.marks[i].range = lower ..< max(lower, upper)
        if self.removesEmptied && !wasEmpty && lower >= upper { removed = true }
      }
      self.longest = max(self.longest, self.marks[i].range.count)
    }
    if removed {
      self.marks.removeAll { $0.range.isEmpty }
    }
  }

  /// The first index whose mark starts at or after `position`.
  private func insertionIndex(_ position: Int) -> Int {
    var low = 0
    var high = self.marks.count
    while low < high {
      let middle = (low + high) / 2
      if self.marks[middle].range.lowerBound < position { low = middle + 1 } else { high = middle }
    }
    return low
  }
}

/// How serious a diagnostic is: its squiggle's colour.
public enum DiagnosticSeverity: Int, Sendable {
  case hint
  case info
  case warning
  case error
}

public struct Diagnostic: Sendable {
  public var severity: DiagnosticSeverity
  public var message: String

  public init(_ severity: DiagnosticSeverity, _ message: String = "") {
    self.severity = severity
    self.message = message
  }
}
