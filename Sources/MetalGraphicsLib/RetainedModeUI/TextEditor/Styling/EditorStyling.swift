import simd

/// An editor's styling: runs its `TextStyler` over the lines as far as they are needed, keeps
/// each line's start state in the document's line records, and adds what is drawn over the
/// tokens — search matches, diagnostics.
///
/// Start states are known to be right up to `frontier`. An edit moves the frontier back to the
/// line it changed; styling then goes forward from there, and stops as soon as the state it
/// reaches is the one a line had before the edit, past the lines the edit changed: from there on
/// nothing can differ. So typing in a function restyles one line, and opening a block comment
/// the lines until it closes. Lines far past the frontier are styled provisionally, from the
/// state they had or the initial one, and put right as background work catches up.
final class EditorStyling: LineSpanSource, TextDocumentObserver {
  private(set) var document: TextDocument
  private(set) var styler: (any TextStyler)?
  var theme: EditorTheme
  weak var layout: EditorLayout?

  /// Lines before this have start states known to be right.
  private(set) var frontier = 1
  /// Lines from the frontier to here have start states from before the last edits, maybe
  /// still right.
  private var horizon = 1
  /// Lines before this may have changed since their states were computed: styling cannot stop
  /// on one of them.
  private var dirtyEnd = 0

  /// Beyond this many lines past the frontier, lines in view are styled provisionally rather
  /// than waiting for everything before them.
  static let provisionalDistance = 2000
  /// How many lines background styling does in a frame.
  static let backgroundBudget = 4000

  /// Lines the styler ran on, for tests.
  private(set) var styledCount = 0

  /// What the search matches, as UTF-16, lowercased when it ignores case.
  private var search: [UInt16] = []
  private var searchIgnoresCase = true

  private var scratch: [TextSpan] = []

  init(document: TextDocument, theme: EditorTheme) {
    self.document = document
    self.theme = theme
    document.addObserver(self)
    self.reset()
  }

  func setDocument(_ document: TextDocument) {
    self.document.removeObserver(self)
    self.document = document
    document.addObserver(self)
    self.reset()
  }

  func setStyler(_ styler: (any TextStyler)?) {
    guard styler !== self.styler else { return }
    self.styler = styler
    self.reset()
  }

  /// Every state unknown again.
  private func reset() {
    let lines = self.document.lines
    lines.forEach(in: 0 ..< lines.lineCount) { _, record, _, _ in
      record.flags.remove(.styleValid)
    }
    lines.updateRecord(of: 0) { record in
      record.styleState = StyleState.initial.raw
      record.flags.insert(.styleValid)
    }
    self.frontier = 1
    self.horizon = 1
    self.dirtyEnd = 0
  }

  /// Whether lines are left to style in the background.
  var needsBackgroundWork: Bool {
    self.styler != nil && self.frontier < self.document.lineCount
  }

  // MARK: - Search

  /// Highlights every match of `query`; nil or empty for none. Returns whether it changed.
  @discardableResult
  func setSearch(_ query: String?, ignoresCase: Bool = true) -> Bool {
    let units = Array((ignoresCase ? query?.lowercased() : query)?.utf16 ?? "".utf16)
    guard units != self.search || ignoresCase != self.searchIgnoresCase else { return false }
    self.search = units
    self.searchIgnoresCase = ignoresCase
    return true
  }

  /// The matches of the search, in the document, from `start` on, at most `limit`.
  func searchMatches(limit: Int = 10_000) -> [Range<Int>] {
    guard !self.search.isEmpty else { return [] }
    var matches: [Range<Int>] = []
    for line in 0 ..< self.document.lineCount {
      let range = self.document.lineRange(line)
      self.document.withUTF16(in: range) { units in
        self.forEachMatch(in: units) { column in
          matches.append(range.lowerBound + column ..< range.lowerBound + column + self.search.count)
        }
      }
      if matches.count >= limit { break }
    }
    return matches
  }

  private func forEachMatch(in units: UnsafeBufferPointer<UInt16>, _ body: (Int) -> Void) {
    let needle = self.search
    let count = needle.count
    guard count > 0, units.count >= count else { return }
    let first = needle[0]
    var i = 0
    while i <= units.count - count {
      if self.fold(units[i]) == first {
        var j = 1
        while j < count && self.fold(units[i + j]) == needle[j] { j += 1 }
        if j == count {
          body(i)
          i += count
          continue
        }
      }
      i += 1
    }
  }

  @inline(__always)
  private func fold(_ unit: UInt16) -> UInt16 {
    self.searchIgnoresCase && unit >= 0x41 && unit <= 0x5A ? unit + 0x20 : unit
  }

  // MARK: - Edits

  func document(_ document: TextDocument, didChange change: DocumentChange) {
    guard self.styler != nil else { return }
    let first = change.firstLine
    let oldEnd = first + change.removedLines
    let delta = change.insertedLines - change.removedLines
    let newEnd = first + change.insertedLines
    // A line index from before the change, after it: one inside what was replaced goes to the
    // end of what replaced it.
    func shift(_ line: Int) -> Int {
      line >= oldEnd ? line + delta : (line > first ? newEnd : line)
    }
    if first < self.frontier {
      self.horizon = shift(max(self.horizon, self.frontier))
      // The changed line still starts where it did: its state stays right.
      self.frontier = max(first + 1, 1)
    } else {
      self.horizon = shift(self.horizon)
    }
    self.dirtyEnd = max(shift(self.dirtyEnd), newEnd)
  }

  // MARK: - Styling

  /// Brings start states up to date through line `target`, unless it is too far past the
  /// frontier to wait for: then it is styled provisionally, and background work catches up.
  func ensureStyled(through target: Int) {
    guard self.styler != nil, target >= self.frontier, target - self.frontier <= Self.provisionalDistance else { return }
    self.advance(until: target + 1, budget: .max)
  }

  /// Background work: styles up to `budget` lines past the frontier. Returns the lines whose
  /// start state changed, which are to be reshaped, or nil when none did.
  @discardableResult
  func advance(budget: Int = EditorStyling.backgroundBudget) -> ClosedRange<Int>? {
    self.advance(until: self.document.lineCount, budget: budget)
  }

  private func advance(until end: Int, budget: Int) -> ClosedRange<Int>? {
    guard let styler = self.styler else { return nil }
    let lines = self.document.lines
    let count = lines.lineCount
    var changed: ClosedRange<Int>? = nil
    var remaining = budget
    while self.frontier < min(end, count) && remaining > 0 {
      let line = self.frontier
      let previous = lines.record(of: line - 1)
      // The line before's end state: its start state, run through its text.
      let range = self.document.lineRange(line - 1)
      let state = self.document.withUTF16(in: range) { units -> StyleState in
        self.scratch.removeAll(keepingCapacity: true)
        self.styledCount += 1
        return styler.styleLine(units, state: StyleState(previous.styleState), into: &self.scratch)
      }
      remaining -= 1
      let record = lines.record(of: line)
      let agrees = record.flags.contains(.styleValid) && record.styleState == state.raw
      if agrees && line >= self.dirtyEnd && line < self.horizon {
        // Past what the edits changed, and as it was: everything after is still right.
        self.frontier = self.horizon
        break
      }
      if !agrees {
        lines.updateRecord(of: line) { record in
          record.styleState = state.raw
          record.flags.insert(.styleValid)
        }
        // Its tokens depend on its start state: reshaped when next shown.
        self.layout?.invalidate(lineID: record.id)
        changed = changed.map { min($0.lowerBound, line) ... max($0.upperBound, line) } ?? line ... line
      }
      self.frontier = line + 1
    }
    if self.frontier >= self.horizon { self.horizon = self.frontier }
    if self.frontier >= self.dirtyEnd { self.dirtyEnd = 0 }
    return changed
  }

  // MARK: - LineSpanSource

  func prepare(forLine line: Int) {
    self.ensureStyled(through: line)
  }

  func spans(forLine line: Int, units: UnsafeBufferPointer<UInt16>, into spans: inout [TextSpan]) {
    guard let styler = self.styler else { return }
    let record = self.document.lines.record(of: line)
    // Past the frontier, provisional: the state it had, or the initial one.
    let state = record.flags.contains(.styleValid) ? StyleState(record.styleState) : .initial
    self.styledCount += 1
    _ = styler.styleLine(units, state: state, into: &spans)
  }

  func blocks(forLine line: Int, units: UnsafeBufferPointer<UInt16>, into blocks: inout [BlockDecoration]) {
    guard let styler = self.styler else { return }
    let record = self.document.lines.record(of: line)
    let state = record.flags.contains(.styleValid) ? StyleState(record.styleState) : .initial
    styler.blocks(units, state: state, into: &blocks)
  }

  func decorations(forLine line: Int, lineStart: Int, length: Int, into runs: inout [LineDecoration]) {
    if !self.search.isEmpty {
      let color = self.theme.searchMatch
      let count = self.search.count
      self.document.withUTF16(in: lineStart ..< lineStart + length) { units in
        self.forEachMatch(in: units) { column in
          runs.append(LineDecoration(start: Int32(column), end: Int32(column + count), background: color, squiggle: nil))
        }
      }
    }
    let diagnostics = self.document.diagnostics
    if !diagnostics.isEmpty {
      diagnostics.forEach(overlapping: lineStart ..< lineStart + max(length, 1)) { mark in
        let start = Int32(max(mark.range.lowerBound - lineStart, 0))
        var end = Int32(min(mark.range.upperBound - lineStart, length))
        // An empty mark underlines the character it sits before.
        if end <= start { end = min(start + 1, Int32(length)) }
        guard end > start else { return }
        runs.append(LineDecoration(start: start, end: end, background: nil, squiggle: self.theme.color(for: mark.payload.severity)))
      }
    }
  }
}
