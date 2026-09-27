/// An edit about to be made: what an editor's `filter` may change, redirect or refuse.
public struct EditorTransaction {
  public var changes: ChangeSet
  /// The selection after it; nil to map the one before through the changes.
  public var selection: EditorSelection?
  public var kind: EditKind
  public var origin: EditOrigin

  public init(changes: ChangeSet, selection: EditorSelection? = nil, kind: EditKind = .other, origin: EditOrigin = .user) {
    self.changes = changes
    self.selection = selection
    self.kind = kind
    self.origin = origin
  }
}

/// Two characters typed as one: `(` brings its `)`. See `EditorState.autoClosingPairs`.
public struct AutoClosingPair: Hashable, Sendable {
  public var open: UInt16
  public var close: UInt16

  public init(_ open: Character, _ close: Character) {
    self.open = open.utf16.first!
    self.close = close.utf16.first!
  }

  /// Brackets and double quotes, as code has them.
  public static let code = [
    AutoClosingPair("(", ")"), AutoClosingPair("[", "]"), AutoClosingPair("{", "}"), AutoClosingPair("\"", "\""),
  ]
}

/// How a language indents: what a styler adopts to indent a new line inside a block and outdent
/// the line a block closes on. `SwiftStyler` does, for `{`, `(` and `[`.
public protocol IndentationRules: AnyObject {
  /// Whether a line ending in `text` (the line up to the caret, trailing spaces dropped) opens a
  /// block, so that the next line goes one level in.
  func opensBlock(_ text: [UInt16]) -> Bool
  /// The unit that closes a block opened by `text`'s last unit, if it does: `}` for `{`.
  func closer(forOpener unit: UInt16) -> UInt16?
  /// Whether `unit`, typed first on a line, closes a block: the line then goes one level out.
  func closesBlock(_ unit: UInt16) -> Bool
}

protocol EditorStateDelegate: AnyObject {
  func editorStateDidChangeSelection(_ state: EditorState)
  /// An edit was refused: read-only text, a filter.
  func editorStateDidRefuseEdit(_ state: EditorState)
}

/// A document being edited: its selection, the input method's marked text, the undo history,
/// and the commands that move and edit, independent of how the text is drawn. What depends on
/// where lines break on screen it asks a `TextLayoutQueries`.
public final class EditorState: TextDocumentObserver {
  public let document: TextDocument
  public private(set) var selection: EditorSelection = .caret(0)
  /// The input method's composition, part of the text until it is committed.
  public private(set) var markedRange: Range<Int>? = nil
  /// Within the marked text, what the input method selects: the clause being converted.
  public private(set) var markedSelection: Range<Int>? = nil
  /// When false, the user's edits are refused; moving and selecting still work.
  public var isEditable = true
  /// Sees each edit of the user's before it is made; may rewrite it, or return false to refuse it.
  public var filter: ((inout EditorTransaction, EditorState) -> Bool)?
  /// What Tab inserts and indenting adds.
  public var indentUnit = "    "
  /// What ⌘/ puts at the start of lines; nil for none.
  public var lineComment: String? = nil
  /// Units, besides letters, digits and `_`, that belong to words.
  public var wordCharacters: Set<UInt16> = []
  /// Typed with the opening half, the closing half goes in too, after the caret; typed before
  /// its own closing half, it moves over it; Backspace between an empty pair deletes both; typed
  /// over a selection, the pair goes around it. None by default.
  public var autoClosingPairs: [AutoClosingPair] = []
  /// Indents a new line inside a block and outdents a closing line; the styler's, when it has
  /// rules. Without, a new line keeps the indentation of the one it breaks.
  public var indentation: (any IndentationRules)? = nil
  /// Counts selection changes, so an observer can tell one happened.
  public private(set) var selectionGeneration: UInt64 = 0

  let history = UndoHistory()
  var clock: () -> Double = { 0 }
  weak var delegate: (any EditorStateDelegate)?
  /// What ⌃K deleted last, for ⌃Y.
  private var killBuffer = ""
  /// Set while applying an edit of our own, whose selection is set by hand.
  private var applying = false

  public init(document: TextDocument) {
    self.document = document
    document.addObserver(self)
  }

  // MARK: - Selection

  public func setSelection(_ selection: EditorSelection) {
    let clamped = selection.clamped(to: self.document.length)
    let snapped = clamped.map { range in
      SelectionRange(anchor: TextBoundaries.snap(range.anchor, in: self.document),
                     head: TextBoundaries.snap(range.head, in: self.document), affinity: range.affinity, goalX: range.goalX)
    }
    guard snapped != self.selection else { return }
    self.history.breakCoalescing()
    self.selection = snapped
    self.selectionChanged()
  }

  private func selectionChanged() {
    self.selectionGeneration &+= 1
    self.delegate?.editorStateDidChangeSelection(self)
  }

  /// The selected text, ranges joined by newlines.
  public var selectedText: String {
    self.selection.ranges.filter { !$0.isEmpty }.map { self.document.substring($0.range) }.joined(separator: "\n")
  }

  // MARK: - Applying edits

  /// Whether the user may change `range`: not read-only, and the editor editable.
  public func canEdit(_ range: Range<Int>) -> Bool {
    guard self.isEditable else { return false }
    if range.isEmpty {
      return !self.document.readOnly.containsInside(range.lowerBound)
    }
    return !self.document.readOnly.overlaps(range)
  }

  /// Applies an edit of the user's or an input method's: through the filter, refused if it
  /// touches read-only text, then recorded for undo. Returns whether it was made.
  @discardableResult
  public func apply(_ transaction: EditorTransaction) -> Bool {
    var transaction = transaction
    if let filter = self.filter, transaction.origin != .undo && transaction.origin != .redo {
      guard filter(&transaction, self) else {
        self.delegate?.editorStateDidRefuseEdit(self)
        return false
      }
    }
    guard !transaction.changes.changes.isEmpty else {
      if let selection = transaction.selection { self.setSelection(selection) }
      return true
    }
    for change in transaction.changes.changes where !self.canEdit(change.range) {
      self.delegate?.editorStateDidRefuseEdit(self)
      return false
    }
    let before = self.selection
    self.applying = true
    let (applied, inverse) = self.document.apply(transaction.changes, origin: transaction.origin)
    self.applying = false
    let after = (transaction.selection ?? before.mapped(through: applied)).clamped(to: self.document.length)
    if let marked = self.markedRange {
      self.markedRange = applied.map(marked)
    }
    if transaction.origin == .user || transaction.origin == .input {
      self.history.record(applied, inverse: inverse, before: before, after: after, kind: transaction.kind, time: self.clock())
    }
    self.selection = after
    self.selectionChanged()
    return true
  }

  func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin) {
    guard !self.applying else { return }
    // An app's edit: the selection and the history move with the text.
    self.selection = self.selection.mapped(through: changes).clamped(to: document.length)
    if let marked = self.markedRange { self.markedRange = changes.map(marked) }
    if origin == .program { self.history.rebase(through: changes) }
    self.selectionChanged()
  }

  /// Replaces each range with its text, and puts a caret `caret` units into each replacement
  /// (at its end when nil).
  @discardableResult
  private func replace(_ edits: [(range: Range<Int>, text: [UInt16], caret: Int?)], kind: EditKind) -> Bool {
    guard !edits.isEmpty else { return false }
    let changes = ChangeSet(edits.map { TextChange(range: $0.range, text: $0.text) })
    let carets = edits.map { edit -> SelectionRange in
      let start = changes.map(edit.range.lowerBound, .before)
      return .caret(start + (edit.caret ?? edit.text.count))
    }
    return self.apply(EditorTransaction(changes: changes, selection: EditorSelection(carets, primary: self.selection.primaryIndex), kind: kind))
  }

  // MARK: - Commands

  /// Runs `command`. Returns false for one this state does not do by itself: copying, scrolling,
  /// and cancel with one cursor — the editor's view does those.
  @discardableResult
  public func perform(_ command: EditorCommand, layout: (any TextLayoutQueries)?) -> Bool {
    switch command {
    case let .move(motion, forward, extend):
      self.history.breakCoalescing()
      let moved = self.selection.map { self.move($0, motion, forward: forward, extend: extend, layout: layout) }
      if moved != self.selection {
        self.selection = moved
        self.selectionChanged()
      }
    case let .delete(motion, forward):
      self.delete(motion, forward: forward, layout: layout)
    case .deleteSelection:
      let edits = self.selection.ranges.filter { !$0.isEmpty }.map { (range: $0.range, text: [UInt16](), caret: Int?.none) }
      self.replace(edits, kind: .other)
    case let .insertText(text):
      if !self.typePair(text) && !self.typeCloser(text) {
        self.insert(text, kind: self.selection.hasSelectedText ? .other : .typing)
      }
    case let .paste(text):
      self.paste(text)
    case .insertNewline:
      self.insertNewline(indenting: true)
    case .insertLineBreak:
      self.insertNewline(indenting: false)
    case .insertTab:
      if self.selectionSpansLines { self.indent(true) } else { self.insertTab() }
    case .insertBacktab, .outdent:
      self.indent(false)
    case .indent:
      self.indent(true)
    case .toggleComment:
      self.toggleComment()
    case .selectAll:
      self.setSelection(EditorSelection(SelectionRange(anchor: 0, head: self.document.length)))
    case .selectWord:
      self.setSelection(self.selection.map { range in
        let word = TextBoundaries.word(at: range.head, in: self.document, wordCharacters: self.wordCharacters)
        return SelectionRange(anchor: word.lowerBound, head: word.upperBound)
      })
    case .selectLine:
      self.setSelection(self.selection.map { range in
        let first = self.document.line(containing: range.lowerBound)
        let last = self.document.line(containing: range.upperBound)
        return SelectionRange(anchor: self.document.lineStart(first),
                              head: self.document.lineRange(last, includingNewline: true).upperBound)
      })
    case .transpose:
      self.transpose()
    case .yank:
      if !self.killBuffer.isEmpty { self.insert(self.killBuffer, kind: .other) }
    case .undo:
      self.undo()
    case .redo:
      self.redo()
    case .cut:
      self.perform(.deleteSelection, layout: layout)
    case .cancel:
      guard self.selection.ranges.count > 1 else { return false }
      self.setSelection(EditorSelection(self.selection.primary))
    case .copy, .scrollToDocumentEdge, .scrollPage, .scrollLine, .centerSelection, .fold, .unfold:
      return false
    }
    return true
  }

  private var selectionSpansLines: Bool {
    self.selection.ranges.contains { range in
      !range.isEmpty && self.document.line(containing: range.lowerBound) != self.document.line(containing: range.upperBound)
    }
  }

  // MARK: Moving

  private func move(_ range: SelectionRange, _ motion: TextMotion, forward: Bool, extend: Bool,
                    layout: (any TextLayoutQueries)?) -> SelectionRange {
    // Without extending, a selection collapses to its end in the direction of the move, and a
    // character move goes no further.
    if !extend && !range.isEmpty && motion == .character {
      return .caret(forward ? range.upperBound : range.lowerBound)
    }
    let from = extend || range.isEmpty ? range.head : (forward ? range.upperBound : range.lowerBound)
    let fromRange = SelectionRange(anchor: from, head: from, affinity: range.affinity, goalX: range.goalX)
    let target = self.target(of: motion, forward: forward, from: fromRange, layout: layout)
    return SelectionRange(anchor: extend ? range.anchor : target.head, head: target.head,
                          affinity: target.affinity, goalX: target.goalX)
  }

  /// Where `motion` takes the caret at `range.head`, with the affinity and goal it ends with.
  private func target(of motion: TextMotion, forward: Bool, from range: SelectionRange,
                      layout: (any TextLayoutQueries)?) -> SelectionRange {
    let head = range.head
    let document = self.document
    switch motion {
    case .character:
      return .caret(forward ? TextBoundaries.next(after: head, in: document) : TextBoundaries.previous(before: head, in: document))
    case .word:
      return .caret(forward
        ? TextBoundaries.wordEnd(after: head, in: document, wordCharacters: self.wordCharacters)
        : TextBoundaries.wordStart(before: head, in: document, wordCharacters: self.wordCharacters))
    case .subword:
      return .caret(forward ? TextBoundaries.subwordEnd(after: head, in: document) : TextBoundaries.subwordStart(before: head, in: document))
    case .visualLine, .page:
      let lines = motion == .page ? max(1, layout?.linesPerPage ?? 20) : 1
      if let layout {
        let moved = layout.verticalMove(from: head, affinity: range.affinity, goalX: range.goalX, lines: forward ? lines : -lines)
        return SelectionRange(anchor: moved.offset, head: moved.offset, affinity: moved.affinity, goalX: moved.goalX)
      }
      // No layout: by hard lines, keeping the column.
      let (line, column) = document.position(of: head)
      let target = line + (forward ? lines : -lines)
      if target < 0 { return .caret(0) }
      if target >= document.lineCount { return .caret(document.length) }
      return .caret(TextBoundaries.snap(document.offset(line: target, column: column), in: document))
    case .lineBoundary:
      if let layout {
        let boundary = layout.visualLineBoundary(of: head, affinity: range.affinity, forward: forward)
        return .caret(boundary.offset, affinity: boundary.affinity)
      }
      return .caret(forward ? TextBoundaries.lineEnd(head, in: document) : TextBoundaries.lineStart(head, in: document))
    case .paragraphBoundary:
      return .caret(forward ? TextBoundaries.lineEnd(head, in: document) : TextBoundaries.lineStart(head, in: document))
    case .paragraph:
      return .caret(TextBoundaries.paragraphBoundary(from: head, forward: forward, in: document))
    case .document:
      return .caret(forward ? document.length : 0)
    }
  }

  // MARK: Editing

  private func insert(_ text: String, kind: EditKind) {
    let units = TextDocument.normalizeLineEndings(Array(text.utf16))
    self.replace(self.selection.ranges.map { (range: $0.range, text: units, caret: nil) }, kind: kind)
  }

  /// Pastes `text`: into every cursor, or one line per cursor when it has as many lines as there
  /// are cursors.
  private func paste(_ text: String) {
    let units = TextDocument.normalizeLineEndings(Array(text.utf16))
    let ranges = self.selection.ranges
    if ranges.count > 1 {
      let pieces = units.split(separator: 0x0A, omittingEmptySubsequences: false)
      if pieces.count == ranges.count {
        self.replace(zip(ranges, pieces).map { (range: $0.range, text: Array($1), caret: nil) }, kind: .other)
        return
      }
    }
    self.replace(ranges.map { (range: $0.range, text: units, caret: nil) }, kind: .other)
  }

  // MARK: Pairs and blocks

  /// The one unit `text` is, if it is one.
  private func singleUnit(_ text: String) -> UInt16? {
    let units = text.utf16
    return units.count == 1 ? units.first : nil
  }

  /// Types a pair's half: over the closing half after each caret, around each selection, or both
  /// halves with the caret between. Returns false to type `text` as it is.
  private func typePair(_ text: String) -> Bool {
    guard !self.autoClosingPairs.isEmpty, let unit = self.singleUnit(text), self.markedRange == nil else { return false }
    let ranges = self.selection.ranges
    let length = self.document.length
    // Over the closing half already there.
    if let pair = self.autoClosingPairs.first(where: { $0.close == unit }),
       ranges.allSatisfy({ $0.isEmpty && $0.head < length && self.document.unit(at: $0.head) == pair.close }) {
      self.history.breakCoalescing()
      self.setSelection(self.selection.map { .caret($0.head + 1) })
      return true
    }
    guard let pair = self.autoClosingPairs.first(where: { $0.open == unit }) else { return false }
    if ranges.allSatisfy({ !$0.isEmpty }) {
      // Around the selection, which stays selected inside.
      let changes = ChangeSet(ranges.flatMap { range in
        [TextChange(range: range.lowerBound ..< range.lowerBound, text: [pair.open]),
         TextChange(range: range.upperBound ..< range.upperBound, text: [pair.close])]
      })
      let selection = self.selection.map { range in
        SelectionRange(anchor: changes.map(range.lowerBound, .after), head: changes.map(range.upperBound, .before))
      }
      return self.apply(EditorTransaction(changes: changes, selection: selection, kind: .other))
    }
    // Both halves only where the closing one cannot be part of a word being typed: before a
    // space, a closer or the end; and a quote not right after a word.
    let closes = ranges.allSatisfy { range in
      guard range.isEmpty else { return false }
      if range.head < length {
        let next = self.document.unit(at: range.head)
        guard next == 0x20 || next == 0x09 || next == 0x0A || self.autoClosingPairs.contains(where: { $0.close == next })
        else { return false }
      }
      if pair.open == pair.close && range.head > 0 {
        let previous = self.document.unit(at: range.head - 1)
        if TextBoundaries.characterClass(previous, wordCharacters: self.wordCharacters) == .word || previous == pair.open {
          return false
        }
      }
      return true
    }
    guard closes else { return false }
    return self.replace(ranges.map { (range: $0.range, text: [pair.open, pair.close], caret: 1) }, kind: .typing)
  }

  /// Types a block's closer first on a line one level out, as the block it closes. Returns false
  /// to type it as it is.
  private func typeCloser(_ text: String) -> Bool {
    guard let rules = self.indentation, let unit = self.singleUnit(text), rules.closesBlock(unit),
          self.selection.isSingleCaret, self.markedRange == nil
    else { return false }
    let caret = self.selection.primary.head
    let lineStart = TextBoundaries.lineStart(caret, in: self.document)
    guard caret > lineStart else { return false }
    let leading = self.document.withUTF16(in: lineStart ..< caret) { Array($0) }
    guard leading.allSatisfy({ $0 == 0x20 || $0 == 0x09 }) else { return false }
    let outdented = Array(leading.dropLast(min(leading.last == 0x09 ? 1 : self.indentWidth, leading.count)))
    return self.replace([(range: lineStart ..< caret, text: outdented + [unit], caret: nil)], kind: .typing)
  }

  /// Backspace between the halves of an empty pair deletes both.
  private func deletePair() -> Bool {
    guard !self.autoClosingPairs.isEmpty, self.selection.ranges.allSatisfy(\.isEmpty) else { return false }
    let length = self.document.length
    let edits = self.selection.ranges.compactMap { range -> (range: Range<Int>, text: [UInt16], caret: Int?)? in
      let head = range.head
      guard head > 0, head < length else { return nil }
      let before = self.document.unit(at: head - 1)
      let after = self.document.unit(at: head)
      guard self.autoClosingPairs.contains(where: { $0.open == before && $0.close == after }) else { return nil }
      return (head - 1 ..< head + 1, [], nil)
    }
    guard edits.count == self.selection.ranges.count else { return false }
    return self.replace(edits, kind: .deleting)
  }

  private func delete(_ motion: TextMotion, forward: Bool, layout: (any TextLayoutQueries)?) {
    if motion == .character && !forward && self.deletePair() { return }
    var killed: [String] = []
    let edits = self.selection.ranges.compactMap { range -> (range: Range<Int>, text: [UInt16], caret: Int?)? in
      if !range.isEmpty { return (range.range, [], nil) }
      var target = self.target(of: motion, forward: forward, from: range, layout: layout).head
      // ⌃K at the end of a line joins the next.
      if motion == .paragraphBoundary && forward && target == range.head && target < self.document.length {
        target += 1
      }
      guard target != range.head else { return nil }
      let deleted = min(target, range.head) ..< max(target, range.head)
      if motion == .paragraphBoundary || motion == .lineBoundary { killed.append(self.document.substring(deleted)) }
      return (deleted, [], nil)
    }
    if !killed.isEmpty { self.killBuffer = killed.joined(separator: "\n") }
    let kind: EditKind = motion == .character && !forward && !self.selection.hasSelectedText ? .deleting : .other
    self.replace(edits, kind: kind)
  }

  private func insertNewline(indenting: Bool) {
    let edits = self.selection.ranges.map { range -> (range: Range<Int>, text: [UInt16], caret: Int?) in
      var text: [UInt16] = [0x0A]
      guard indenting else { return (range.range, text, nil) }
      // The new line starts as indented as the line it breaks, up to the caret.
      let lineStart = TextBoundaries.lineStart(range.lowerBound, in: self.document)
      var indent: [UInt16] = []
      var i = lineStart
      while i < range.lowerBound {
        let unit = self.document.unit(at: i)
        guard unit == 0x20 || unit == 0x09 else { break }
        indent.append(unit)
        i += 1
      }
      text += indent
      guard let rules = self.indentation else { return (range.range, text, nil) }
      var before = self.document.withUTF16(in: lineStart ..< range.lowerBound) { Array($0) }
      while let last = before.last, last == 0x20 || last == 0x09 { before.removeLast() }
      guard rules.opensBlock(before) else { return (range.range, text, nil) }
      // Inside a block: one level in. Between `{` and its `}`, the `}` goes to a line of its own.
      text += Array(self.indentUnit.utf16)
      let caret = text.count
      var after = range.upperBound
      let lineEnd = TextBoundaries.lineEnd(range.upperBound, in: self.document)
      while after < lineEnd, self.document.unit(at: after) == 0x20 { after += 1 }
      if let opener = before.last, let closer = rules.closer(forOpener: opener), after < lineEnd,
         self.document.unit(at: after) == closer {
        text += [0x0A] + indent
        return (range.lowerBound ..< after, text, caret)
      }
      return (range.range, text, nil)
    }
    self.replace(edits, kind: .other)
  }

  private var indentWidth: Int { max(1, self.indentUnit.utf16.count) }
  private var indentsWithSpaces: Bool { !self.indentUnit.contains("\t") }

  private func insertTab() {
    let edits = self.selection.ranges.map { range -> (range: Range<Int>, text: [UInt16], caret: Int?) in
      guard self.indentsWithSpaces else { return (range.range, [0x09], nil) }
      // Spaces to the next tab stop.
      let column = range.lowerBound - TextBoundaries.lineStart(range.lowerBound, in: self.document)
      let count = self.indentWidth - column % self.indentWidth
      return (range.range, Array(repeating: 0x20, count: count), nil)
    }
    self.replace(edits, kind: .typing)
  }

  /// The lines the selection touches: a range ending at the very start of a line leaves that
  /// line out.
  private var selectedLines: [Int] {
    var lines: [Int] = []
    for range in self.selection.ranges {
      let first = self.document.line(containing: range.lowerBound)
      var last = self.document.line(containing: range.upperBound)
      if last > first && self.document.lineStart(last) == range.upperBound { last -= 1 }
      for line in first ... last where lines.last.map({ line > $0 }) ?? true {
        lines.append(line)
      }
    }
    return lines
  }

  private func indent(_ inward: Bool) {
    let unit = Array(self.indentUnit.utf16)
    var changes: [TextChange] = []
    for line in self.selectedLines {
      let range = self.document.lineRange(line)
      if inward {
        guard !range.isEmpty else { continue }
        changes.append(TextChange(range: range.lowerBound ..< range.lowerBound, text: unit))
      } else {
        var end = range.lowerBound
        if end < range.upperBound && self.document.unit(at: end) == 0x09 {
          end += 1
        } else {
          while end < range.upperBound && end - range.lowerBound < self.indentWidth && self.document.unit(at: end) == 0x20 { end += 1 }
        }
        if end > range.lowerBound { changes.append(TextChange(range: range.lowerBound ..< end, text: [])) }
      }
    }
    guard !changes.isEmpty else { return }
    let set = ChangeSet(changes)
    // A selection keeps covering whole lines: its start stays at the start of its line.
    let selection = self.selection.map { range in
      guard !range.isEmpty else { return range.mapped(through: set) }
      let low = set.map(range.lowerBound, .before)
      let high = set.map(range.upperBound, .after)
      return range.anchor <= range.head ? SelectionRange(anchor: low, head: high) : SelectionRange(anchor: high, head: low)
    }
    self.apply(EditorTransaction(changes: set, selection: selection, kind: .other))
  }

  private func toggleComment() {
    guard let token = self.lineComment, !token.isEmpty else { return }
    let tokenUnits = Array(token.utf16)
    let lines = self.selectedLines
    // Lines with text, and the least indentation among them.
    var textLines: [(line: Int, start: Int, range: Range<Int>)] = []
    var minIndent = Int.max
    for line in lines {
      let range = self.document.lineRange(line)
      let first = TextBoundaries.firstNonSpace(onLineOf: range.lowerBound, in: self.document)
      guard first < range.upperBound else { continue }
      textLines.append((line, first, range))
      minIndent = min(minIndent, first - range.lowerBound)
    }
    guard !textLines.isEmpty else { return }
    let allCommented = textLines.allSatisfy { entry in
      entry.range.upperBound - entry.start >= tokenUnits.count
        && self.document.withUTF16(in: entry.start ..< entry.start + tokenUnits.count) { Array($0) == tokenUnits }
    }
    var changes: [TextChange] = []
    for entry in textLines {
      if allCommented {
        var end = entry.start + tokenUnits.count
        if end < entry.range.upperBound && self.document.unit(at: end) == 0x20 { end += 1 }
        changes.append(TextChange(range: entry.start ..< end, text: []))
      } else {
        let at = entry.range.lowerBound + minIndent
        changes.append(TextChange(range: at ..< at, text: tokenUnits + [0x20]))
      }
    }
    self.apply(EditorTransaction(changes: ChangeSet(changes), kind: .other))
  }

  /// ⌃T: swaps the characters around the caret, or the two before it at a line's end.
  private func transpose() {
    guard self.selection.isSingleCaret else { return }
    var caret = self.selection.primary.head
    let lineEnd = TextBoundaries.lineEnd(caret, in: self.document)
    let lineStart = TextBoundaries.lineStart(caret, in: self.document)
    if caret == lineEnd { caret = TextBoundaries.previous(before: caret, in: self.document) }
    let before = TextBoundaries.previous(before: caret, in: self.document)
    let after = TextBoundaries.next(after: caret, in: self.document)
    guard before >= lineStart, caret > before, after > caret, after <= lineEnd else { return }
    let first = self.document.withUTF16(in: before ..< caret) { Array($0) }
    let second = self.document.withUTF16(in: caret ..< after) { Array($0) }
    self.apply(EditorTransaction(changes: ChangeSet(TextChange(range: before ..< after, text: second + first)),
                                 selection: .caret(after), kind: .other))
  }

  // MARK: Undo

  public var canUndo: Bool { self.history.canUndo }
  public var canRedo: Bool { self.history.canRedo }

  public func undo() {
    self.unmarkText()
    guard let step = self.history.popUndo() else { return }
    // Text made read-only since — a console's history — is never changed back.
    guard self.stepAvoidsReadOnly(step.inverse) else {
      self.history.removeAll()
      self.delegate?.editorStateDidRefuseEdit(self)
      return
    }
    self.applying = true
    for set in step.inverse.reversed() {
      self.document.apply(set, origin: .undo)
    }
    self.applying = false
    self.markedRange = nil
    self.selection = step.selectionBefore.clamped(to: self.document.length)
    self.selectionChanged()
  }

  public func redo() {
    self.unmarkText()
    guard let step = self.history.popRedo() else { return }
    guard self.stepAvoidsReadOnly(step.forward) else {
      self.history.removeAll()
      self.delegate?.editorStateDidRefuseEdit(self)
      return
    }
    self.applying = true
    for set in step.forward {
      self.document.apply(set, origin: .redo)
    }
    self.applying = false
    self.markedRange = nil
    self.selection = step.selectionAfter.clamped(to: self.document.length)
    self.selectionChanged()
  }

  /// Whether applying `sets` in order touches no read-only text: each set is checked against
  /// the read-only ranges as the sets before it moved them.
  private func stepAvoidsReadOnly(_ sets: [ChangeSet]) -> Bool {
    var protected = self.document.readOnly.marks.map(\.range).filter { !$0.isEmpty }
    guard !protected.isEmpty else { return true }
    for set in sets {
      for change in set.changes {
        for range in protected {
          let blocked = change.range.isEmpty
            ? range.lowerBound < change.range.lowerBound && change.range.lowerBound < range.upperBound
            : range.overlaps(change.range)
          if blocked { return false }
        }
      }
      protected = protected.map { set.map($0) }
    }
    return true
  }

  /// Runs `body`'s edits as one step to undo.
  public func groupingUndo(_ body: () -> Void) {
    self.history.beginGroup()
    body()
    self.history.endGroup()
  }

  // MARK: - Input method

  /// Replaces the marked text (or `replacement`, or the selection) with `text`, marked, the
  /// input method's selection `selected` within it. Empty text ends the composition.
  ///
  /// Composing is not recorded for undo: the text it replaces is deleted as a step of its own,
  /// and the committed text is inserted as another, so the history never sees the marked text.
  @discardableResult
  public func setMarkedText(_ text: String, selected: Range<Int>, replacement: Range<Int>? = nil) -> Bool {
    let units = Array(text.utf16)
    let start: Int
    if let marked = self.markedRange {
      let target = replacement ?? marked
      guard self.canEdit(target) else {
        self.delegate?.editorStateDidRefuseEdit(self)
        return false
      }
      self.applyUnrecorded(ChangeSet(TextChange(range: target, text: units)))
      start = target.lowerBound
    } else {
      guard !units.isEmpty else { return true }
      var target = replacement ?? self.selection.primary.range
      guard self.canEdit(target) else {
        self.delegate?.editorStateDidRefuseEdit(self)
        return false
      }
      if !target.isEmpty {
        let deletion = EditorTransaction(changes: ChangeSet(TextChange(range: target, text: [])),
                                         selection: .caret(target.lowerBound), kind: .other, origin: .input)
        guard self.apply(deletion) else { return false }
        target = target.lowerBound ..< target.lowerBound
      }
      self.applyUnrecorded(ChangeSet(TextChange(range: target, text: units)))
      start = target.lowerBound
    }
    if units.isEmpty {
      self.markedRange = nil
      self.markedSelection = nil
      self.selection = .caret(start)
    } else {
      let low = start + selected.lowerBound.clamped(to: 0 ... units.count)
      let high = start + selected.upperBound.clamped(to: 0 ... units.count)
      self.markedRange = start ..< start + units.count
      self.markedSelection = low ..< high
      // The caret sits where the input method's selection ends.
      self.selection = .caret(high)
    }
    self.selectionChanged()
    return true
  }

  /// Inserts `text` in place of the marked text (or `replacement`, or the selection), ending
  /// any composition: what an input method commits, or a plain typed key through it.
  @discardableResult
  public func commitText(_ text: String, replacement: Range<Int>? = nil) -> Bool {
    let units = TextDocument.normalizeLineEndings(Array(text.utf16))
    guard let marked = self.markedRange else {
      let targets = replacement.map { [$0] } ?? self.selection.ranges.map(\.range)
      let kind: EditKind = targets.allSatisfy(\.isEmpty) ? .typing : .other
      return self.replace(targets.map { (range: $0, text: units, caret: nil) }, kind: kind)
    }
    // The marked text goes unrecorded, leaving the text as the history knows it; the committed
    // text goes in as a step.
    let removal = ChangeSet(TextChange(range: marked, text: []))
    self.applyUnrecorded(removal)
    self.markedRange = nil
    self.markedSelection = nil
    self.selection = .caret(marked.lowerBound)
    let target = replacement.map { removal.map($0) } ?? marked.lowerBound ..< marked.lowerBound
    let applied = self.apply(EditorTransaction(changes: ChangeSet(TextChange(range: target, text: units)),
                                               selection: .caret(target.lowerBound + units.count),
                                               kind: .typing, origin: .input))
    if !applied { self.selectionChanged() }
    return applied
  }

  /// Ends the composition, keeping the marked text as typed.
  public func unmarkText() {
    guard let marked = self.markedRange else { return }
    self.commitText(self.document.substring(marked))
  }

  private func applyUnrecorded(_ changes: ChangeSet) {
    self.applying = true
    self.document.apply(changes, origin: .input)
    self.applying = false
  }
}
