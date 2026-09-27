import Foundation

/// Who made an edit: undo records the user's, and an input method's composing edits are
/// recorded once committed.
public enum EditOrigin: Sendable {
  case user
  case undo
  case redo
  /// An app's own edit: appended console output, a reload. Not recorded for undo.
  case program
  /// An input method's marked text.
  case input
}

public enum LineEnding: Sendable {
  case lf
  case crlf
  case cr

  var units: [UInt16] {
    switch self {
    case .lf: [0x0A]
    case .crlf: [0x0D, 0x0A]
    case .cr: [0x0D]
    }
  }
}

/// One replacement applied to a document, with the lines it touched. A change set with several
/// is reported one by one, last first, so each report's lines are those of the text as it is at
/// that moment.
public struct DocumentChange {
  /// In the text before this replacement.
  public let range: Range<Int>
  public let insertedLength: Int
  public let firstLine: Int
  /// Lines `firstLine ..< firstLine + removedLines` before became
  /// `firstLine ..< firstLine + insertedLines` after.
  public let removedLines: Int
  public let insertedLines: Int
  public let origin: EditOrigin
}

protocol TextDocumentObserver: AnyObject {
  /// One replacement was applied: lines moved, their caches are stale.
  func document(_ document: TextDocument, didChange change: DocumentChange)
  /// A whole change set was applied, after its `didChange` reports.
  func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin)
}

extension TextDocumentObserver {
  func document(_ document: TextDocument, didChange change: DocumentChange) {}
  func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin) {}
}

/// Told of a document's edits from outside the editor: saving state, a language server kept in
/// sync. Called on the document's thread, once per change set.
public protocol TextDocumentListener: AnyObject {
  /// `changes` are about to be applied: the text is still as their ranges describe it.
  func document(_ document: TextDocument, willApply changes: ChangeSet, origin: EditOrigin)
  /// `changes` were applied; `document.revision` has moved on.
  func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin)
}

extension TextDocumentListener {
  public func document(_ document: TextDocument, willApply changes: ChangeSet, origin: EditOrigin) {}
  public func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin) {}
}

/// Editable text for a `TextEditor`, sized for large documents: UTF-16 in a gap buffer, lines and
/// their heights in a `LineTree`, and ranges that move with edits (`readOnly`, `diagnostics`).
///
/// Positions are UTF-16 offsets, as in `NSString` and CoreText. Lines end in `\n` only: text
/// coming in with `\r\n` or `\r` is converted, and `lineEnding` remembers which the text had.
///
/// A document belongs to the window thread that shows it, like the elements of its tree.
public final class TextDocument {
  let buffer: GapBuffer
  let lines: LineTree
  public private(set) var revision: UInt64 = 0
  public var lineEnding: LineEnding = .lf

  /// Ranges no edit by the user may change. Text inserted at their edges stays outside.
  public let readOnly = TextMarks<Void>(removesEmptied: true)
  /// Problems to underline, which move with the text.
  public let diagnostics = TextMarks<Diagnostic>(removesEmptied: true)
  /// Where inline attachments sit: one U+FFFC each.
  public let attachments = TextMarks<TextAttachmentID>(removesEmptied: true)

  /// The height given to lines no one has measured yet. The editor showing the document sets it
  /// to its font's line height.
  var estimatedLineHeight: Float = 16

  private var nextLineID: UInt32 = 1
  private var observers: [WeakObserver] = []
  /// The last changes, to map positions from a recent revision to this one.
  private var recent: [(revision: UInt64, changes: ChangeSet)] = []
  private static let recentLimit = 64
  /// The oldest revision `recent` still maps from.
  private var oldestMappable: UInt64 = 0

  private struct WeakObserver {
    weak var observer: (any TextDocumentObserver)?
  }

  private var listeners: [WeakListener] = []

  private struct WeakListener {
    weak var listener: (any TextDocumentListener)?
  }

  public init(_ text: String = "") {
    var units = Array(text.utf16)
    self.lineEnding = Self.detectLineEnding(units)
    units = Self.normalizeLineEndings(units)
    self.buffer = GapBuffer(units)
    var lengths: [Int32] = []
    var length: Int32 = 0
    for unit in units {
      length += 1
      if unit == 0x0A {
        lengths.append(length)
        length = 0
      }
    }
    lengths.append(length)
    var records: [LineRecord] = []
    records.reserveCapacity(lengths.count)
    for _ in lengths {
      records.append(LineRecord(id: self.nextLineID))
      self.nextLineID &+= 1
    }
    self.lines = LineTree(lengths: lengths, heights: Array(repeating: 16, count: lengths.count), records: records)
  }

  // MARK: - Reading

  /// In UTF-16 units.
  public var length: Int { self.buffer.count }
  public var lineCount: Int { self.lines.lineCount }
  public var isEmpty: Bool { self.buffer.count == 0 }

  /// The whole text, `\n` line endings. O(length).
  public var string: String {
    self.substring(0 ..< self.length)
  }

  /// The whole text with the line endings it came with.
  public var stringWithOriginalLineEndings: String {
    guard self.lineEnding != .lf else { return self.string }
    var units: [UInt16] = []
    units.reserveCapacity(self.length + self.lineCount)
    let ending = self.lineEnding.units
    self.buffer.withUnits(in: 0 ..< self.length) { text in
      for unit in text {
        if unit == 0x0A { units.append(contentsOf: ending) } else { units.append(unit) }
      }
    }
    return String(decoding: units, as: UTF16.self)
  }

  public func substring(_ range: Range<Int>) -> String {
    let range = range.clamped(to: 0 ..< self.length)
    return self.buffer.withUnits(in: range) { String(decoding: $0, as: UTF16.self) }
  }

  /// The unit at `offset`.
  public func unit(at offset: Int) -> UInt16 {
    self.buffer[offset]
  }

  /// Runs `body` over the units in `range`, without copying them when it can.
  public func withUTF16<R>(in range: Range<Int>, _ body: (UnsafeBufferPointer<UInt16>) throws -> R) rethrows -> R {
    try self.buffer.withUnits(in: range, body)
  }

  /// The line `offset` is on.
  public func line(containing offset: Int) -> Int {
    self.lines.line(containing: offset)
  }

  public func lineStart(_ line: Int) -> Int {
    self.lines.start(of: line)
  }

  /// A line's text range, without its `\n` unless asked.
  public func lineRange(_ line: Int, includingNewline: Bool = false) -> Range<Int> {
    let start = self.lines.start(of: line)
    var length = self.lines.length(of: line)
    if !includingNewline && line < self.lineCount - 1 { length -= 1 }
    return start ..< start + length
  }

  public func lineText(_ line: Int) -> String {
    self.substring(self.lineRange(line))
  }

  /// An offset as a line and a column, both from 0, the column in UTF-16 units.
  public func position(of offset: Int) -> (line: Int, column: Int) {
    let offset = offset.clamped(to: 0 ... self.length)
    let line = self.lines.line(containing: offset)
    return (line, offset - self.lines.start(of: line))
  }

  public func offset(line: Int, column: Int) -> Int {
    let line = line.clamped(to: 0 ... self.lineCount - 1)
    let range = self.lineRange(line)
    return range.lowerBound + column.clamped(to: 0 ... range.count)
  }

  /// The tokens stored with a line's text.
  public func spans(ofLine line: Int) -> [TextSpan] {
    self.lines.record(of: line).spans
  }

  func lineID(_ line: Int) -> UInt32 {
    self.lines.record(of: line).id
  }

  // MARK: - Observers

  func addObserver(_ observer: any TextDocumentObserver) {
    self.observers.removeAll { $0.observer == nil || $0.observer === observer }
    self.observers.append(WeakObserver(observer: observer))
  }

  func removeObserver(_ observer: any TextDocumentObserver) {
    self.observers.removeAll { $0.observer == nil || $0.observer === observer }
  }

  /// Tells `listener` of every edit from now on. Held weakly.
  public func addListener(_ listener: any TextDocumentListener) {
    self.listeners.removeAll { $0.listener == nil || $0.listener === listener }
    self.listeners.append(WeakListener(listener: listener))
  }

  public func removeListener(_ listener: any TextDocumentListener) {
    self.listeners.removeAll { $0.listener == nil || $0.listener === listener }
  }

  // MARK: - Editing

  /// Replaces `range` with `text`: an app's edit, not recorded for undo in an editor.
  public func replace(_ range: Range<Int>, with text: String, origin: EditOrigin = .program) {
    self.apply(ChangeSet(TextChange(range: range, with: text)), origin: origin)
  }

  /// Replaces all the text.
  public func setText(_ text: String) {
    self.lineEnding = Self.detectLineEnding(Array(text.utf16))
    self.apply(ChangeSet(TextChange(range: 0 ..< self.length, with: text)), origin: .program)
  }

  /// Adds `text` at the end, its lines stored with `token`: a console's output. Returns where it
  /// went.
  @discardableResult
  public func append(_ text: String, token: TextToken? = nil) -> Range<Int> {
    self.insert(text, at: self.length, token: token)
  }

  /// Inserts `text` at `offset`, its lines stored with `token`. Returns where it went.
  @discardableResult
  public func insert(_ text: String, at offset: Int, token: TextToken? = nil) -> Range<Int> {
    let units = Self.normalizeLineEndings(Array(text.utf16))
    self.apply(ChangeSet(TextChange(range: offset ..< offset, text: units)), origin: .program)
    let range = offset ..< offset + units.count
    if let token, !range.isEmpty {
      self.addSpans(token, over: range)
    }
    return range
  }

  /// Inserts an inline attachment at `offset`: a U+FFFC marked with `id`, which an editor with a
  /// `TextAttachmentProvider` shows as the provider's element. An app's edit, not the user's.
  public func insertAttachment(_ id: TextAttachmentID, at offset: Int) {
    let offset = offset.clamped(to: 0 ... self.length)
    // Marked before the text is reported, so an editor shaping the line sees the mark.
    self.pendingAttachment = (offset, id)
    self.apply(ChangeSet(TextChange(range: offset ..< offset, with: "\u{FFFC}")), origin: .program)
  }

  private var pendingAttachment: (offset: Int, id: TextAttachmentID)? = nil

  /// Stores `token` over `range`, replacing what was stored there.
  public func addSpans(_ token: TextToken, over range: Range<Int>) {
    let first = self.lines.line(containing: range.lowerBound)
    let last = self.lines.line(containing: max(range.lowerBound, range.upperBound - 1))
    var start = self.lines.start(of: first)
    self.lines.forEach(in: first ..< last + 1) { _, record, _, length in
      let low = Int32(max(range.lowerBound - start, 0))
      let high = Int32(min(range.upperBound - start, Int(length)))
      if low < high {
        record.spans = Self.replacingSpans(record.spans, low ..< high, with: TextSpan(start: low, end: high, token: token))
        record.id = self.nextLineID
        self.nextLineID &+= 1
      }
      start += Int(length)
    }
    self.revision &+= 1
    self.notifyRestyled(first ..< last + 1)
  }

  /// Applies `changes` and reports them. Returns them as applied (line endings converted) and
  /// the changes that undo them.
  @discardableResult
  public func apply(_ changes: ChangeSet, origin: EditOrigin) -> (applied: ChangeSet, inverse: ChangeSet) {
    guard !changes.changes.isEmpty else { return (changes, changes) }
    var changes = changes
    if changes.changes.contains(where: { $0.text.contains(0x0D) }) {
      changes = ChangeSet(changes.changes.map { TextChange(range: $0.range, text: Self.normalizeLineEndings($0.text)) })
    }
    for listener in self.listeners {
      listener.listener?.document(self, willApply: changes, origin: origin)
    }
    var removed = Array(repeating: [UInt16](), count: changes.changes.count)
    // Last first, so the ranges before each are still as the change set gives them.
    for index in changes.changes.indices.reversed() {
      removed[index] = self.applyOne(changes.changes[index], origin: origin)
    }
    self.revision &+= 1
    self.recent.append((self.revision, changes))
    if self.recent.count > Self.recentLimit {
      self.oldestMappable = self.recent.removeFirst().revision
    }
    self.readOnly.map(through: changes)
    self.diagnostics.map(through: changes)
    self.attachments.map(through: changes)
    if let pending = self.pendingAttachment {
      self.pendingAttachment = nil
      self.attachments.add(pending.offset ..< pending.offset + 1, pending.id)
    }
    for observer in self.observers {
      observer.observer?.document(self, didApply: changes, origin: origin)
    }
    for listener in self.listeners {
      listener.listener?.document(self, didApply: changes, origin: origin)
    }
    return (changes, changes.inverted(removed: removed))
  }

  /// Maps `offset`, a position in the text at `revision`, into the text now, through the last
  /// changes. Nil when the document has changed too much since.
  public func mapOffset(_ offset: Int, fromRevision revision: UInt64, _ association: TextAssociation = .after) -> Int? {
    guard revision != self.revision else { return offset }
    guard revision >= self.oldestMappable, revision < self.revision else { return nil }
    guard let first = self.recent.firstIndex(where: { $0.revision > revision }) else { return offset }
    var mapped = offset
    for entry in self.recent[first...] {
      mapped = entry.changes.map(mapped, association)
    }
    return mapped.clamped(to: 0 ... self.length)
  }

  private func applyOne(_ change: TextChange, origin: EditOrigin) -> [UInt16] {
    let a = change.range.lowerBound.clamped(to: 0 ... self.length)
    let b = change.range.upperBound.clamped(to: a ... self.length)
    let startLine = self.lines.line(containing: a)
    let endLine = self.lines.line(containing: b)
    let startLineStart = self.lines.start(of: startLine)
    let endLineStart = endLine == startLine ? startLineStart : self.lines.start(of: endLine)
    let endLineLength = self.lines.length(of: endLine)
    let removedText = self.buffer.units(in: a ..< b)
    change.text.withUnsafeBufferPointer { self.buffer.replace(a ..< b, with: $0) }

    let prefix = a - startLineStart
    let newlines = change.text.reduce(0) { $0 + ($1 == 0x0A ? 1 : 0) }
    if newlines == 0 && startLine == endLine {
      // Within one line: the common case, typing.
      self.lines.adjustLength(of: startLine, by: change.text.count - (b - a))
      self.lines.updateRecord(of: startLine) { record in
        record.id = self.nextLineID
        record.spans = Self.adjustedSpans(record.spans, replacing: Int32(prefix) ..< Int32(b - startLineStart),
                                          count: Int32(change.text.count))
      }
      self.nextLineID &+= 1
      self.report(DocumentChange(range: a ..< b, insertedLength: change.text.count, firstLine: startLine,
                                 removedLines: 1, insertedLines: 1, origin: origin))
      return removedText
    }

    // Lines split or joined: the lines from the first to the last touched become new ones.
    let suffix = endLineStart + endLineLength - b
    var lengths: [Int32] = []
    lengths.reserveCapacity(newlines + 1)
    var segment = 0
    for unit in change.text {
      segment += 1
      if unit == 0x0A {
        lengths.append(Int32((lengths.isEmpty ? prefix : 0) + segment))
        segment = 0
      }
    }
    let lastSegment = segment
    lengths.append(Int32((lengths.isEmpty ? prefix : 0) + lastSegment + suffix))

    let old = self.lines.record(of: startLine)
    let endSpans = endLine == startLine ? old.spans : self.lines.record(of: endLine).spans
    var records: [LineRecord] = []
    records.reserveCapacity(lengths.count)
    for i in 0 ..< lengths.count {
      var record = LineRecord(id: self.nextLineID)
      self.nextLineID &+= 1
      if i == 0 {
        // The first line starts where it did, in the state it did.
        record.styleState = old.styleState
        record.flags = old.flags.intersection(.styleValid)
        record.spans = old.spans.compactMap { span in
          span.start < Int32(prefix) ? TextSpan(start: span.start, end: min(span.end, Int32(prefix)), token: span.token) : nil
        }
      }
      if i == lengths.count - 1 {
        // The last keeps what followed the change on the old last line.
        let cut = Int32(b - endLineStart)
        let shift = Int32((lengths.count == 1 ? prefix : 0) + lastSegment) - cut
        let moved = endSpans.compactMap { span in
          span.end > cut ? TextSpan(start: max(span.start, cut) + shift, end: span.end + shift, token: span.token) : nil
        }
        record.spans = i == 0 ? record.spans + moved : moved
      }
      records.append(record)
    }
    var heights = Array(repeating: self.estimatedLineHeight, count: lengths.count)
    heights[0] = self.lines.height(of: startLine)
    self.lines.replaceLines(startLine ..< endLine + 1, lengths: lengths, heights: heights, records: records)
    self.report(DocumentChange(range: a ..< b, insertedLength: change.text.count, firstLine: startLine,
                               removedLines: endLine - startLine + 1, insertedLines: lengths.count, origin: origin))
    return removedText
  }

  private func report(_ change: DocumentChange) {
    for observer in self.observers {
      observer.observer?.document(self, didChange: change)
    }
  }

  /// Reports lines whose stored spans changed, as an edit of no text.
  private func notifyRestyled(_ lines: Range<Int>) {
    let start = self.lines.start(of: lines.lowerBound)
    self.report(DocumentChange(range: start ..< start, insertedLength: 0, firstLine: lines.lowerBound,
                               removedLines: lines.count, insertedLines: lines.count, origin: .program))
  }

  // MARK: - Spans

  /// Spans after columns `range` of their line became `count` new units: those after it move,
  /// those around it grow or shrink, those inside it go.
  static func adjustedSpans(_ spans: [TextSpan], replacing range: Range<Int32>, count: Int32) -> [TextSpan] {
    guard !spans.isEmpty else { return spans }
    let delta = count - Int32(range.count)
    var result: [TextSpan] = []
    result.reserveCapacity(spans.count)
    for span in spans {
      if span.end <= range.lowerBound {
        result.append(span)
        continue
      }
      // A span starting where text is inserted moves past it rather than taking it in.
      let keepsStart = span.start < range.lowerBound || (span.start == range.lowerBound && !range.isEmpty)
      let start = keepsStart ? span.start
        : span.start >= range.upperBound ? span.start + delta : range.lowerBound + count
      let end = span.end >= range.upperBound ? span.end + delta : range.lowerBound
      if start < end { result.append(TextSpan(start: start, end: end, token: span.token)) }
    }
    return result
  }

  /// `spans` with `range` cleared and `span` put there, in order.
  static func replacingSpans(_ spans: [TextSpan], _ range: Range<Int32>, with span: TextSpan) -> [TextSpan] {
    var result: [TextSpan] = []
    result.reserveCapacity(spans.count + 2)
    var placed = false
    for existing in spans {
      if existing.end <= range.lowerBound {
        result.append(existing)
        continue
      }
      if !placed {
        if existing.start < range.lowerBound {
          result.append(TextSpan(start: existing.start, end: range.lowerBound, token: existing.token))
        }
        result.append(span)
        placed = true
      }
      if existing.end > range.upperBound {
        result.append(TextSpan(start: max(existing.start, range.upperBound), end: existing.end, token: existing.token))
      }
    }
    if !placed { result.append(span) }
    return result
  }

  // MARK: - Line endings

  static func detectLineEnding(_ units: [UInt16]) -> LineEnding {
    guard let index = units.firstIndex(where: { $0 == 0x0A || $0 == 0x0D }) else { return .lf }
    if units[index] == 0x0A { return .lf }
    return index + 1 < units.count && units[index + 1] == 0x0A ? .crlf : .cr
  }

  static func normalizeLineEndings(_ units: [UInt16]) -> [UInt16] {
    guard units.contains(0x0D) else { return units }
    var result: [UInt16] = []
    result.reserveCapacity(units.count)
    var i = 0
    while i < units.count {
      if units[i] == 0x0D {
        result.append(0x0A)
        if i + 1 < units.count && units[i + 1] == 0x0A { i += 1 }
      } else {
        result.append(units[i])
      }
      i += 1
    }
    return result
  }
}

/// Names an inline attachment: what a `TextAttachmentProvider` makes an element for.
public struct TextAttachmentID: Hashable, Sendable {
  public var rawValue: Int
  public init(_ rawValue: Int) { self.rawValue = rawValue }
}
