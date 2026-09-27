import Foundation
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
  private(set) var searchOptions = TextSearchOptions()
  /// The query as typed, for a regular expression and replacement templates.
  private(set) var searchQuery = ""
  /// The query compiled, with `.regex`; nil when it is not one, or does not compile.
  private(set) var searchRegex: NSRegularExpression? = nil
  /// The match found last by find next, drawn in the current match's colour.
  var currentMatch: Range<Int>? = nil
  /// The bracket beside the caret and its partner, highlighted.
  var bracketPair: (Int, Int)? = nil

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
  func setSearch(_ query: String?, options: TextSearchOptions? = nil) -> Bool {
    let options = options ?? self.searchOptions
    let query = query ?? ""
    guard query != self.searchQuery || options != self.searchOptions else { return false }
    self.searchQuery = query
    self.searchOptions = options
    self.searchIgnoresCase = !options.caseSensitive
    self.search = Array((self.searchIgnoresCase ? query.lowercased() : query).utf16)
    self.searchRegex = nil
    if options.regex && !query.isEmpty {
      var flags: NSRegularExpression.Options = [.anchorsMatchLines]
      if self.searchIgnoresCase { flags.insert(.caseInsensitive) }
      let pattern = options.wholeWord ? "\\b(?:\(query))\\b" : query
      self.searchRegex = try? NSRegularExpression(pattern: pattern, options: flags)
      // A pattern that does not compile matches nothing.
      if self.searchRegex == nil { self.search = [] }
    }
    self.currentMatch = nil
    return true
  }

  /// Whether a search is set.
  var isSearching: Bool { !self.search.isEmpty }

  /// The matches of the search, in the document, at most `limit`. A match never spans lines.
  func searchMatches(limit: Int = 10_000) -> [Range<Int>] {
    guard !self.search.isEmpty else { return [] }
    var matches: [Range<Int>] = []
    for line in 0 ..< self.document.lineCount {
      let range = self.document.lineRange(line)
      self.document.withUTF16(in: range) { units in
        self.forEachMatch(in: units) { column, length in
          matches.append(range.lowerBound + column ..< range.lowerBound + column + length)
        }
      }
      if matches.count >= limit { break }
    }
    return matches
  }

  /// Every match in one line's `units`, as its column and length.
  private func forEachMatch(in units: UnsafeBufferPointer<UInt16>, _ body: (Int, Int) -> Void) {
    if let regex = self.searchRegex {
      // Only while searching by pattern, and only for the lines shaped or searched.
      let line = String(decoding: units, as: UTF16.self)
      regex.enumerateMatches(in: line, range: NSRange(location: 0, length: units.count)) { result, _, _ in
        guard let range = result?.range, range.length > 0 else { return }
        body(range.location, range.length)
      }
      return
    }
    let needle = self.search
    let count = needle.count
    guard count > 0, units.count >= count else { return }
    let first = needle[0]
    let wholeWord = self.searchOptions.wholeWord
    var i = 0
    while i <= units.count - count {
      if self.fold(units[i]) == first {
        var j = 1
        while j < count && self.fold(units[i + j]) == needle[j] { j += 1 }
        if j == count && (!wholeWord || Self.isWordBoundary(units, i, i + count)) {
          body(i, count)
          i += count
          continue
        }
      }
      i += 1
    }
  }

  /// Whether `start ..< end` has no letter, digit or `_` right before or after it.
  private static func isWordBoundary(_ units: UnsafeBufferPointer<UInt16>, _ start: Int, _ end: Int) -> Bool {
    func isWord(_ unit: UInt16) -> Bool {
      (unit >= 0x30 && unit <= 0x39) || (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A) || unit == 0x5F
        || unit >= 0x80
    }
    return (start == 0 || !isWord(units[start - 1])) && (end == units.count || !isWord(units[end]))
  }

  /// What `match` is replaced by: `template` itself, or with `.regex` the template with `$1`
  /// and the rest filled in from the match.
  func replacement(for match: Range<Int>, template: String) -> String {
    guard let regex = self.searchRegex else { return template }
    let line = self.document.line(containing: match.lowerBound)
    let lineRange = self.document.lineRange(line)
    let text = self.document.substring(lineRange)
    let local = NSRange(location: match.lowerBound - lineRange.lowerBound, length: match.count)
    guard let result = regex.firstMatch(in: text, range: local), result.range == local else { return template }
    return regex.replacementString(for: result, in: text, offset: 0, template: template)
  }

  // MARK: - Brackets

  static let openers: [UInt16] = [0x28, 0x5B, 0x7B]  // ( [ {
  static let closers: [UInt16] = [0x29, 0x5D, 0x7D]  // ) ] }
  /// How far a partner is looked for, in units each way: a caret move never scans a whole file.
  static let bracketScanLimit = 20_000

  /// The bracket just before or at `offset` and its partner, skipping brackets in strings and
  /// comments; nil when there is none, or none within reach.
  func matchingBracket(near offset: Int) -> (Int, Int)? {
    let length = self.document.length
    for candidate in [offset - 1, offset] where candidate >= 0 && candidate < length {
      let unit = self.document.unit(at: candidate)
      guard Self.openers.contains(unit) || Self.closers.contains(unit), !self.isInStringOrComment(candidate) else {
        continue
      }
      if let partner = self.partner(of: candidate, unit) { return (candidate, partner) }
    }
    return nil
  }

  private func partner(of offset: Int, _ unit: UInt16) -> Int? {
    let forward = Self.openers.contains(unit)
    let index = forward ? Self.openers.firstIndex(of: unit)! : Self.closers.firstIndex(of: unit)!
    let same = unit
    let other = forward ? Self.closers[index] : Self.openers[index]
    var depth = 0
    var position = offset
    let limit = forward ? min(self.document.length, offset + Self.bracketScanLimit) : max(0, offset - Self.bracketScanLimit)
    var skipLine = -1
    var skipped: [Range<Int>] = []
    while forward ? position < limit : position >= limit {
      let line = self.document.line(containing: position)
      if line != skipLine {
        skipLine = line
        skipped = self.stringAndCommentRanges(ofLine: line)
      }
      let unit = self.document.unit(at: position)
      if (unit == same || unit == other) && !skipped.contains(where: { $0.contains(position) }) {
        depth += unit == same ? 1 : -1
        if depth == 0 { return position }
      }
      position += forward ? 1 : -1
    }
    return nil
  }

  private func isInStringOrComment(_ offset: Int) -> Bool {
    self.stringAndCommentRanges(ofLine: self.document.line(containing: offset)).contains { $0.contains(offset) }
  }

  /// Where the styler finds strings and comments on `line`, in the document.
  private func stringAndCommentRanges(ofLine line: Int) -> [Range<Int>] {
    guard let styler = self.styler else { return [] }
    let range = self.document.lineRange(line)
    let record = self.document.lines.record(of: line)
    let state = record.flags.contains(.styleValid) ? StyleState(record.styleState) : .initial
    var spans: [TextSpan] = []
    self.document.withUTF16(in: range) { units in
      _ = styler.styleLine(units, state: state, into: &spans)
    }
    return spans.compactMap { span in
      span.token == .string || span.token == .comment
        ? range.lowerBound + Int(span.start) ..< range.lowerBound + Int(span.end) : nil
    }
  }

  @inline(__always)
  private func fold(_ unit: UInt16) -> UInt16 {
    self.searchIgnoresCase && unit >= 0x41 && unit <= 0x5A ? unit + 0x20 : unit
  }

  // MARK: - Edits

  func document(_ document: TextDocument, didChange change: DocumentChange) {
    self.currentMatch = nil
    self.bracketPair = nil
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
      let current = self.currentMatch
      self.document.withUTF16(in: lineStart ..< lineStart + length) { units in
        self.forEachMatch(in: units) { column, count in
          let isCurrent = current == lineStart + column ..< lineStart + column + count
          runs.append(LineDecoration(start: Int32(column), end: Int32(column + count),
                                     background: isCurrent ? self.theme.currentSearchMatch : color, squiggle: nil))
        }
      }
    }
    if let (a, b) = self.bracketPair {
      for offset in [a, b] where offset >= lineStart && offset < lineStart + length {
        let column = Int32(offset - lineStart)
        runs.append(LineDecoration(start: column, end: column + 1, background: self.theme.bracketMatch, squiggle: nil))
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
