import AppKit
import simd

/// A problem to underline in an editor: `TextEditor.setDiagnostics`.
public struct TextDiagnostic: Sendable, Hashable {
  public var range: Range<Int>
  public var severity: DiagnosticSeverity
  public var message: String

  public init(_ range: Range<Int>, _ severity: DiagnosticSeverity, _ message: String = "") {
    self.range = range
    self.severity = severity
    self.message = message
  }
}

/// Whether an editor's lines wrap at its width, or run on and scroll sideways.
public enum LineWrapping: Hashable, Sendable {
  /// Code and console: one line of text is one line on screen.
  case none
  /// Prose: lines break at words to fit the width.
  case soft
}

/// How a search matches: `TextEditor.setSearchOptions`, `.searchOptions(_:)`.
public struct TextSearchOptions: Hashable, Sendable {
  /// "Name" does not match "name".
  public var caseSensitive: Bool
  /// "name" does not match inside "rename".
  public var wholeWord: Bool
  /// The query is an `NSRegularExpression` pattern, matched within each line. A replacement
  /// may use `$1` and the rest.
  public var regex: Bool

  public init(caseSensitive: Bool = false, wholeWord: Bool = false, regex: Bool = false) {
    self.caseSensitive = caseSensitive
    self.wholeWord = wholeWord
    self.regex = regex
  }
}

/// How far a selection moved from code scrolls the editor.
public enum TextReveal: Sendable {
  /// Not at all.
  case none
  /// Just enough to show it.
  case minimal
  /// Its line to the middle of the view: a jump to a line, a definition, a problem.
  case center
}

/// A handle on a `TextEditor` for the code around it, which builds the editor in a body and has
/// no reference to it: hold one, pass it to `.controller(_:)`, then select and reveal through
/// it. Does nothing while no editor has it.
public final class EditorController {
  public fileprivate(set) weak var editor: TextEditor?

  public init() {}

  /// Selects `range` (a caret when empty), and scrolls it into view by `reveal`, once the
  /// editor is laid out.
  public func select(_ range: Range<Int>, reveal: TextReveal = .minimal) {
    self.editor?.select(range, reveal: reveal)
  }

  /// A caret at `line`, `column` (zero-based, UTF-16), centred.
  public func goTo(line: Int, column: Int = 0) {
    guard let editor = self.editor else { return }
    let document = editor.document
    let line = line.clamped(to: 0 ... max(document.lineCount - 1, 0))
    let column = column.clamped(to: 0 ... document.lineRange(line).count)
    let offset = document.offset(line: line, column: column)
    editor.select(offset ..< offset, reveal: .center)
  }

  /// Gives the editor the keyboard.
  public func focus() {
    self.editor?.focus()
  }

  /// Selects the next match of the search after the selection, or the one before it, wrapping
  /// around. Returns whether there was one.
  @discardableResult
  public func findNext(forward: Bool = true) -> Bool {
    self.editor?.findNext(forward: forward) ?? false
  }

  /// Replaces the selected match, then selects the next. Returns whether it replaced one.
  @discardableResult
  public func replaceCurrent(with template: String) -> Bool {
    self.editor?.replaceCurrent(with: template) ?? false
  }

  /// Replaces every match as one step to undo. Returns how many.
  @discardableResult
  public func replaceAll(with template: String) -> Int {
    self.editor?.replaceAll(with: template) ?? 0
  }

  /// Folds the innermost range around the caret that is not folded yet. Returns whether it did.
  @discardableResult
  public func foldAtCaret() -> Bool { self.editor?.foldAtCaret() ?? false }

  /// Unfolds the fold whose first line holds the caret, or around it. Returns whether it did.
  @discardableResult
  public func unfoldAtCaret() -> Bool { self.editor?.unfoldAtCaret() ?? false }

  public func unfoldAll() { self.editor?.unfoldAll() }

  /// "3 of 12" for a find bar: the selected match's index, from 1 (0 when no match is
  /// selected), and how many there are.
  public var matchPosition: (current: Int, count: Int) {
    self.editor?.matchPosition ?? (0, 0)
  }
}

/// Multi-line, styled, editable text: the base of a code editor, a console, a markdown editor.
///
/// `TextEditor(text: $source)` edits a string, as SwiftUI's does. For a long document, give it a
/// `TextDocument` instead — `TextEditor(document: doc)` — which is edited in place: a keystroke
/// then costs the same in a document of a hundred thousand lines as in one of ten, where a string
/// is rebuilt and handed back on every edit.
///
/// What it does:
/// - the macOS text keys: arrows by character, word (⌥), line end (⌘), document end; ⇧ to
///   select; the Emacs keys (⌃A ⌃E ⌃K ⌃Y …); ⌘Z undo in coalesced steps; ⌘C ⌘X ⌘V; Tab and
///   ⇧Tab, ⌘] ⌘[ to indent, ⌘/ to comment out lines;
/// - a click places the caret, a drag selects, a double-click a word, a triple-click a line;
/// - input methods: accents, Chinese and Japanese, the emoji picker, dictation;
/// - tokens styled by a `TextStyler` and an `EditorTheme`: colours, weights, sizes, backgrounds,
///   underlines; diagnostics and search matches drawn over them;
/// - line numbers, soft wrap, read-only stretches.
///
/// Only the lines in view are shaped and drawn. See `docs/TextEditor.md`.
public final class TextEditor : SingleChildElement, TextDocumentObserver, EditorStateDelegate, TextInputClient, WakeTarget {
  public private(set) var document: TextDocument
  public private(set) var state: EditorState
  let layout: EditorLayout
  let styling: EditorStyling
  public var styler: (any TextStyler)? { self.styling.styler }

  public private(set) var lineWrapping: LineWrapping = .none
  public private(set) var showsLineNumbers = false
  public private(set) var theme: EditorTheme = .light
  public var isEditable: Bool { self.state.isEditable }

  /// Where an edit reports the whole text, once per frame. `@Component` arms it with the
  /// binding's write-back.
  public var onTextChange: ((String) -> Void)?
  /// Called with the selection when it changed, once per frame.
  public var onSelectionChange: ((EditorSelection) -> Void)?
  /// Called with `matchPosition` — the selected match's index from 1, or 0, and how many there
  /// are — when it may have changed: a new query or options, a find, an edit or a move while
  /// searching. At most once per frame, and only when the numbers differ; each call counts the
  /// matches, O(document).
  public var onSearchChange: ((_ current: Int, _ count: Int) -> Void)?
  private var searchReportScheduled = false
  private var lastSearchReport = (current: 0, count: 0)
  /// Sees every command first, from a key, the input method or the app; returns true to take it
  /// over. A console submits on Return this way.
  public var onCommand: ((EditorCommand) -> Bool)?
  /// Sees every edit of the user's before it is made: may rewrite it, or return false to refuse
  /// it. A console sends typing in its history to the prompt this way.
  public var editFilter: ((inout EditorTransaction, EditorState) -> Bool)? {
    get { self.state.filter }
    set { self.state.filter = newValue }
  }
  /// What can fold, sorted by start: each range from its first line through its last, which
  /// folding hides. The gutter shows a chevron by each first line. Set by `.foldingRanges`, from
  /// a language's parse; moved with edits until set again.
  public internal(set) var foldingRanges: [Range<Int>] = []
  /// What is folded, moving with edits. An edit inside one unfolds it.
  let folds = TextMarks<Void>(removesEmptied: true)
  /// Whether the view stays at the end as text is added there, when it was at the end: a log's.
  public private(set) var followsTail = false
  /// Set by an app's edit made while the view was at the end, with `followsTail`.
  private var pinToEnd = false

  static let idealSize = float2(400, 300)
  static let caretWidth: Float = 1.5

  // The tree: keys, focus, pointer, then the gutter and the scrolling text.
  let scrollView: ScrollView
  let content: EditorContentView
  let gutter: EditorGutterView
  let focusable: FocusableElement
  private let pointer: HittableView
  private let gutterPointer: HittableView
  private let body: EditorBody

  private(set) weak var context: UIContext?
  private(set) var isFocused = false
  /// Whether the caret is in its visible phase.
  var caretVisible = true
  /// The font the text is in: what `.font` around the editor sets, or the theme's.
  private var font: TextFont
  /// The text style around the editor, for the attachments it lays out when it scrolls.
  private(set) var textScope = TextEnvironment()
  /// Makes the elements of attachments in the text.
  public private(set) var attachmentProvider: (any TextAttachmentProvider)?

  /// The text last reported or set, to tell the binding's echo of an edit from a new text.
  private var lastText: String? = nil
  private var reportScheduled = false
  private var textChanged = false
  private var selectionDirty = false
  private var refreshScheduled = false
  /// Set while a command runs: the edits it makes are refreshed once, at its end.
  private var inCommand = false

  // Pointer: what a press selects by, and what it selected first.
  private enum Granularity { case character, word, line }
  private var granularity = Granularity.character
  private var pressRange = 0 ..< 0
  /// Where a drag's pointer is while it is outside the text, scrolling it.
  private var autoscrollPoint: float2? = nil

  // The caret's blink: when the last input was, and when it next turns on or off.
  public private(set) var caretBlinks = true
  private var lastInput: Double = 0
  private var nextBlink: Double? = nil
  static let blinkTimeout: Double = 60
  static let blinkPeriods: (on: Double, off: Double) = {
    let defaults = UserDefaults.standard
    let on = defaults.double(forKey: "NSTextInsertionPointBlinkPeriodOn")
    let off = defaults.double(forKey: "NSTextInsertionPointBlinkPeriodOff")
    return (on > 0 ? on / 1000 : 0.5, off > 0 ? off / 1000 : 0.5)
  }()

  // What input methods were last told, and why: rebuilt only when one of these changed.
  private var snapshot = TextInputSnapshot.inactive
  private struct SnapshotKey: Equatable {
    var revision: UInt64
    var selection: UInt64
    var offset: float2
    var origin: float2
    var editable: Bool
  }
  private var snapshotKey: SnapshotKey? = nil

  public init(document: TextDocument) {
    self.document = document
    self.state = EditorState(document: document)
    self.font = EditorTheme.light.font
    self.layout = EditorLayout(document: document, theme: .light, font: EditorTheme.light.font)
    self.styling = EditorStyling(document: document, theme: .light)
    let content = EditorContentView()
    let gutter = EditorGutterView()
    let scrollView = ScrollView([.vertical, .horizontal]) { content }
    let gutterPointer = HittableView { gutter }
    let gutterBox = ClipElement { gutterPointer }
    let body = EditorBody(gutterBox: gutterBox, gutter: gutter, scrollView: scrollView)
    let pointer = HittableView { body }
    let focusable = FocusableElement { pointer }
    let keys = KeyPressElement(phases: [.down, .repeat], action: nil) { focusable }
    self.content = content
    self.gutter = gutter
    self.scrollView = scrollView
    self.gutterPointer = gutterPointer
    self.body = body
    self.pointer = pointer
    self.focusable = focusable
    super.init()
    self.applyContent([keys])
    content.editor = self
    gutter.editor = self

    self.layout.spanSource = self.styling
    self.styling.layout = self.layout
    document.addObserver(self)
    self.state.delegate = self
    focusable.textInputClient = self
    keys.action = { [unowned self] press in self.handle(press) }
    focusable.onFocusChange = { [unowned self] focused in self.focusChanged(focused) }
    pointer.onPress = { [unowned self] down, input in
      if down {
        self.pressed(at: input.mousePosition, clicks: input.clickCount, extending: input.shiftPressed)
      } else {
        self.autoscrollPoint = nil
      }
    }
    pointer.onDrag = { [unowned self] input in self.dragged(to: input.mousePosition) }
    pointer.pointerStyle = .horizontalText
    gutterPointer.onPress = { [unowned self] down, input in
      if down {
        self.pressedGutter(at: input.mousePosition, extending: input.shiftPressed)
      } else {
        self.autoscrollPoint = nil
      }
    }
    gutterPointer.onDrag = { [unowned self] input in self.dragged(to: input.mousePosition) }
  }

  public convenience init(text: String, onTextChange: ((String) -> Void)? = nil) {
    self.init(document: TextDocument(text))
    self.lastText = text
    self.onTextChange = onTextChange
    self.state.setSelection(.caret(0))
  }

  /// A hand-built editor over a binding. In a `@Component` body `$state` is lowered instead.
  public convenience init(text: Binding<String>) {
    self.init(text: text.wrappedValue)
    self.onTextChange = { [unowned self] value in
      text.wrappedValue = value
      if let context = self.context { self.setText(text.wrappedValue, context) }
    }
  }

  public override func mount(_ context: UIContext) {
    self.context = context
    self.state.clock = { [unowned context] in context.clock() }
  }

  public override func unmount(_ context: UIContext) {
    self.isFocused = false
    self.autoscrollPoint = nil
    self.nextBlink = nil
    context.cancelWake(for: self)
  }

  // MARK: - Layout

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    Self.resolve(proposal)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    // The font from around the editor, else the theme's.
    let scope = TextScope.current
    self.textScope = scope
    self.font = scope.font != nil || scope.design != nil || scope.weight != nil ? scope.resolvedFont : self.theme.font
    let size = Self.resolve(proposal)
    _ = self.child?.calcSize(ProposedSize(size))
    return size
  }

  /// The proposal's lengths, the ideal ones where it gives none, or no finite one.
  private static func resolve(_ proposal: ProposedSize) -> float2 {
    let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? Self.idealSize.x
    let height = proposal.height.flatMap { $0.isFinite ? $0 : nil } ?? Self.idealSize.y
    return float2(width, height)
  }

  /// Brings the layout up to date with the font, theme and width. Called as the text is sized.
  func configureLayout(wrapWidth: Float?) {
    self.layout.configure(theme: self.theme, font: self.font, wrapWidth: wrapWidth)
  }

  // MARK: - Refreshing

  /// Brings what is shown up to date after edits or moves: shapes the lines now in view, keeps
  /// the view still if lines above it changed height, resizes the content if it grew or shrank,
  /// and redraws. With `revealCaret`, scrolls the caret into view.
  func refresh(revealCaret: Bool) {
    guard let context = self.context, self.mounted else { return }
    let drift = self.content.anchorDrift()
    self.content.prepareVisible()
    self.scrollView.contentSizeDidChange(context, offsetBy: float2(0, Float(drift)))
    if self.pinToEnd {
      // Added to while at the end: still at the end.
      self.pinToEnd = false
      self.scrollView.contentSizeDidChange(context, offsetBy: float2(0, .greatestFiniteMagnitude))
    }
    if revealCaret {
      self.revealCaret(context)
    }
    if self.gutter.width != self.gutter.size.x && (self.showsLineNumbers || self.gutter.showsFolding) {
      context.invalidate(.layout)
    }
    context.invalidate(.render)
    if self.styling.needsBackgroundWork {
      self.scheduleWake(context, now: context.clock())
    }
  }

  private func scheduleRefresh() {
    guard !self.refreshScheduled, let context = self.context else { return }
    self.refreshScheduled = true
    context.afterLayout { [weak self] in
      guard let self else { return }
      self.refreshScheduled = false
      self.refresh(revealCaret: false)
    }
  }

  /// Scrolls just enough to show the primary caret, with a little room around it.
  private func revealCaret(_ context: UIContext) {
    let head = self.state.selection.primary
    let caret = self.layout.caretRect(head.head, affinity: head.affinity)
    let inset = self.theme.textInset
    let origin = float2(caret.x + inset.x, Float(caret.top) + inset.y)
    self.scrollView.scrollToVisible(
      contentRect: origin, size: float2(Self.caretWidth, caret.height), margin: float2(24, 2), context
    )
  }

  // MARK: - Reporting

  func document(_ document: TextDocument, didChange change: DocumentChange) {
    self.layout.linesChanged(change)
  }

  func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin) {
    self.content.anchorOffset = changes.map(self.content.anchorOffset, .before)
    if !self.foldingRanges.isEmpty || !self.folds.isEmpty {
      self.foldsDidApply(changes)
    }
    if self.followsTail && origin == .program && self.mounted {
      let scroll = self.scrollView
      if scroll.offset.y >= scroll.scrollableSize.y - 4 { self.pinToEnd = true }
    }
    self.textChanged = true
    self.scheduleReport()
    self.scheduleSearchReport()
    if !self.inCommand {
      // An app's edit, or an input method's: brought on screen at the end of the frame.
      self.scheduleRefresh()
      self.context?.invalidate(.render)
    }
  }

  func editorStateDidChangeSelection(_ state: EditorState) {
    if !self.folds.isEmpty { self.unfoldAroundSelection() }
    self.selectionDirty = true
    self.scheduleBracketMatch()
    self.scheduleSearchReport()
    if let current = self.styling.currentMatch, current != state.selection.primary.range {
      self.showCurrentMatch(nil)
    }
    self.scheduleReport()
    if !self.inCommand {
      self.context?.invalidate(.render)
    }
  }

  func editorStateDidRefuseEdit(_ state: EditorState) {}

  /// Reports the text and the selection once, at the end of the frame the edits were made in.
  private func scheduleReport() {
    guard !self.reportScheduled, let context = self.context,
          (self.textChanged && self.onTextChange != nil) || (self.selectionDirty && self.onSelectionChange != nil)
    else { return }
    self.reportScheduled = true
    context.afterLayout { [weak self] in self?.flushReports() }
  }

  private func flushReports() {
    self.reportScheduled = false
    if self.textChanged, let report = self.onTextChange {
      self.textChanged = false
      let text = self.document.string
      self.lastText = text
      report(text)
    }
    if self.selectionDirty, let report = self.onSelectionChange {
      self.selectionDirty = false
      report(self.state.selection)
    }
  }

  // MARK: - Commands

  /// Runs `command` as if a key had asked for it: `onCommand` first, then the editor. Returns
  /// whether anything took it.
  @discardableResult
  public func perform(_ command: EditorCommand) -> Bool {
    if let onCommand = self.onCommand, onCommand(command) {
      self.refresh(revealCaret: false)
      return true
    }
    self.inCommand = true
    defer { self.inCommand = false }
    var reveal = true
    var handled = true
    switch command {
    case .copy:
      self.copySelection()
      reveal = false
    case .cut:
      guard self.state.selection.hasSelectedText, self.state.canEdit(self.state.selection.primary.range) else { break }
      self.copySelection()
      self.state.perform(.cut, layout: self.layout)
    case let .scrollToDocumentEdge(forward):
      self.scrollBy(page: forward ? .infinity : -.infinity)
      reveal = false
    case let .scrollPage(forward):
      self.scrollBy(page: forward ? 1 : -1)
      reveal = false
    case let .scrollLine(forward):
      self.scrollView.contentSizeDidChange(self.context!, offsetBy: float2(0, (forward ? 1 : -1) * self.layout.rowHeight))
      reveal = false
    case .centerSelection:
      self.centerCaret()
      reveal = false
    case .fold:
      handled = self.foldAtCaret()
      reveal = false
    case .unfold:
      handled = self.unfoldAtCaret()
      reveal = false
    default:
      handled = self.state.perform(command, layout: self.layout)
    }
    self.refresh(revealCaret: reveal && handled)
    self.restartBlink()
    return handled
  }

  private func scrollBy(page: Float) {
    guard let context = self.context else { return }
    let delta = page.isInfinite ? page : page * max(self.scrollView.size.y - self.layout.rowHeight * 2, self.layout.rowHeight)
    let target = page.isInfinite ? (page > 0 ? Float.greatestFiniteMagnitude : -Float.greatestFiniteMagnitude) : delta
    self.scrollView.contentSizeDidChange(context, offsetBy: float2(0, target))
  }

  private func centerCaret() {
    guard let context = self.context else { return }
    let head = self.state.selection.primary
    let caret = self.layout.caretRect(head.head, affinity: head.affinity)
    let y = Float(caret.top) + self.theme.textInset.y - (self.scrollView.size.y - caret.height) * 0.5
    self.scrollView.contentSizeDidChange(context, offsetBy: float2(0, y - self.scrollView.offset.y))
  }

  private func copySelection() {
    let text = self.state.selectedText
    guard !text.isEmpty else { return }
    Pasteboard.write(text)
  }

  // MARK: - From code

  /// Selects `range` (a caret when empty), clamped to the text, and scrolls it into view by
  /// `reveal` once the editor is laid out.
  public func select(_ range: Range<Int>, reveal: TextReveal = .minimal) {
    let length = self.document.length
    let low = range.lowerBound.clamped(to: 0 ... length)
    let high = range.upperBound.clamped(to: low ... length)
    self.state.setSelection(EditorSelection(SelectionRange(anchor: low, head: high)))
    self.restartBlink()
    guard reveal != .none, let context = self.context else { return }
    context.afterLayout { [weak self] in
      guard let self, self.mounted else { return }
      self.refresh(revealCaret: reveal == .minimal)
      if reveal == .center { self.centerCaret() }
    }
  }

  /// Gives the editor the keyboard.
  public func focus() {
    self.context?.focus(self.focusable)
  }

  // MARK: - Find and replace

  /// Selects the next match of the search after the selection (before it, backward), wrapping
  /// around, and scrolls it into view. Returns whether there was one.
  @discardableResult
  public func findNext(forward: Bool = true) -> Bool {
    let matches = self.styling.searchMatches()
    guard !matches.isEmpty else { return false }
    let selection = self.state.selection.primary.range
    let match: Range<Int>
    if forward {
      match = matches.first { $0.lowerBound >= selection.upperBound && $0 != selection } ?? matches[0]
    } else {
      match = matches.last { $0.upperBound <= selection.lowerBound && $0 != selection } ?? matches[matches.count - 1]
    }
    self.showCurrentMatch(match)
    self.select(match, reveal: .minimal)
    return true
  }

  /// Replaces the selection with `template` when the selection is a match, then selects the
  /// next match. Returns whether it replaced one.
  @discardableResult
  public func replaceCurrent(with template: String) -> Bool {
    let selection = self.state.selection.primary.range
    guard !selection.isEmpty, self.styling.searchMatches().contains(selection) else {
      self.findNext()
      return false
    }
    let text = self.styling.replacement(for: selection, template: template)
    self.inCommand = true
    let replaced = self.state.apply(EditorTransaction(
      changes: ChangeSet(TextChange(range: selection, with: text)),
      selection: .caret(selection.lowerBound + text.utf16.count), kind: .other
    ))
    self.inCommand = false
    self.refresh(revealCaret: false)
    if replaced { self.findNext() }
    return replaced
  }

  /// Replaces every match with `template`, as one step to undo. Returns how many it replaced.
  @discardableResult
  public func replaceAll(with template: String) -> Int {
    let matches = self.styling.searchMatches(limit: .max)
    guard !matches.isEmpty else { return 0 }
    let changes = matches.map { TextChange(range: $0, with: self.styling.replacement(for: $0, template: template)) }
    self.inCommand = true
    let replaced = self.state.apply(EditorTransaction(changes: ChangeSet(changes), kind: .other))
    self.inCommand = false
    self.refresh(revealCaret: true)
    return replaced ? matches.count : 0
  }

  /// The selected match's index, from 1, or 0 when the selection is not a match; and how many
  /// matches there are. O(document) — for a find bar, after a search or a find, not per frame.
  public var matchPosition: (current: Int, count: Int) {
    let matches = self.styling.searchMatches()
    let selection = self.state.selection.primary.range
    let index = matches.firstIndex(of: selection).map { $0 + 1 } ?? 0
    return (index, matches.count)
  }

  /// Reports the match position at the end of the frame, if anyone listens and a search is
  /// set (or was, to report it gone).
  private func scheduleSearchReport() {
    guard self.onSearchChange != nil, !self.searchReportScheduled, let context = self.context,
          self.styling.isSearching || self.lastSearchReport.count > 0
    else { return }
    self.searchReportScheduled = true
    context.afterLayout { [weak self] in
      guard let self else { return }
      self.searchReportScheduled = false
      let position = self.styling.isSearching ? self.matchPosition : (0, 0)
      guard position != self.lastSearchReport else { return }
      self.lastSearchReport = position
      self.onSearchChange?(position.0, position.1)
    }
  }

  /// Draws `match` in the current match's colour, and the one before in the others'.
  private func showCurrentMatch(_ match: Range<Int>?) {
    guard match != self.styling.currentMatch else { return }
    for old in [self.styling.currentMatch, match].compactMap({ $0 }) {
      self.layout.invalidate(lineID: self.document.lineID(self.document.line(containing: old.lowerBound)))
    }
    self.styling.currentMatch = match
  }

  // MARK: - Brackets

  /// Whether the bracket beside the caret and its partner are highlighted.
  public private(set) var matchesBrackets = false
  private var bracketsScheduled = false

  /// After the frame's edits and moves, once: finds the bracket pair at the caret, and reshapes
  /// the lines of the pair that went and the one that came.
  private func scheduleBracketMatch() {
    guard self.matchesBrackets, !self.bracketsScheduled, let context = self.context else { return }
    self.bracketsScheduled = true
    context.afterLayout { [weak self] in
      guard let self else { return }
      self.bracketsScheduled = false
      self.updateBracketMatch()
    }
  }

  private func updateBracketMatch() {
    let selection = self.state.selection
    let pair = self.matchesBrackets && selection.isSingleCaret && self.isFocused
      ? self.styling.matchingBracket(near: selection.primary.head) : nil
    let old = self.styling.bracketPair
    guard pair?.0 != old?.0 || pair?.1 != old?.1 else { return }
    self.styling.bracketPair = pair
    for offset in [old?.0, old?.1, pair?.0, pair?.1].compactMap({ $0 }) where offset < self.document.length {
      self.layout.invalidate(lineID: self.document.lineID(self.document.line(containing: offset)))
    }
    self.refresh(revealCaret: false)
  }

  // MARK: - Keys

  private func handle(_ press: KeyPress) -> KeyPress.Result {
    guard press.phase != .up else { return .ignored }
    // What the input method made of the key, when it had it.
    if let actions = press.textInput {
      if actions.count == 1, case let .command(name) = actions[0], let command = EditorCommand(selector: name),
         command == .cancel, self.state.selection.ranges.count == 1, self.onCommand == nil {
        return .ignored
      }
      self.applyTextInput(actions, revision: press.textRevision)
      return .handled
    }
    guard let command = EditorKeyBindings.command(for: press) else { return .ignored }
    // Escape with one caret is the app's to handle.
    if command == .cancel && self.state.selection.ranges.count == 1 && self.onCommand == nil { return .ignored }
    return self.perform(command) ? .handled : (command == .cancel ? .ignored : .handled)
  }

  // MARK: - Pointer

  /// Where `point`, in the window, falls in the text: its offset and affinity.
  private func offset(at point: float2) -> (Int, TextAffinity) {
    let origin = self.content.textOrigin
    return self.layout.offset(atX: point.x - origin.x, y: Double(point.y - origin.y))
  }

  private func pressed(at point: float2, clicks: Int, extending: Bool) {
    if !self.folds.isEmpty, self.pressedFoldMarker(at: point) { return }
    let (offset, affinity) = self.offset(at: point)
    self.granularity = clicks >= 3 ? .line : clicks == 2 ? .word : .character
    let range = self.unitRange(at: offset)
    if extending {
      let anchor = self.state.selection.primary.anchor
      self.pressRange = anchor ..< anchor
      self.extendSelection(to: offset, affinity: affinity)
    } else {
      self.pressRange = range
      if self.granularity == .character {
        self.state.setSelection(EditorSelection(.caret(offset, affinity: affinity)))
      } else {
        self.state.setSelection(EditorSelection(SelectionRange(anchor: range.lowerBound, head: range.upperBound)))
      }
    }
    self.restartBlink()
    self.context?.invalidate(.render)
  }

  private func pressedGutter(at point: float2, extending: Bool) {
    self.context?.focus(self.focusable)
    self.granularity = .line
    let origin = self.content.textOrigin
    let line = self.layout.line(atY: Double(point.y - origin.y))
    if self.gutter.isInFoldColumn(point.x) {
      self.toggleFold(atLine: line)
      self.pressRange = self.state.selection.primary.range
      return
    }
    let range = self.document.lineRange(line, includingNewline: true)
    if extending {
      let anchor = self.state.selection.primary.anchor
      self.pressRange = anchor ..< anchor
      self.extendSelection(to: range.lowerBound, affinity: .downstream)
    } else {
      self.pressRange = range
      self.state.setSelection(EditorSelection(SelectionRange(anchor: range.lowerBound, head: range.upperBound)))
    }
    self.context?.invalidate(.render)
  }

  private func dragged(to point: float2) {
    let (offset, affinity) = self.offset(at: point)
    self.extendSelection(to: offset, affinity: affinity)
    // Held outside the text, the drag scrolls it, a step a frame, until it comes back or ends.
    let view = ClipRect(position: self.scrollView.position, size: self.scrollView.size)
    if let context = self.context {
      let outside = !view.contains(point)
      self.autoscrollPoint = outside ? point : nil
      if outside { self.scheduleWake(context, now: context.clock()) }
    }
    self.context?.invalidate(.render)
  }

  /// A frame of a drag held outside the text: scrolls toward the pointer, as far as it is past
  /// the edge, and extends the selection to what comes into view.
  private func autoscroll(to point: float2, _ context: UIContext) {
    let view = ClipRect(position: self.scrollView.position, size: self.scrollView.size)
    var delta = float2.zero
    for axis in 0 ..< 2 {
      if point[axis] < view.min[axis] { delta[axis] = point[axis] - view.min[axis] }
      if point[axis] > view.max[axis] { delta[axis] = point[axis] - view.max[axis] }
    }
    delta = simd_clamp(delta * 0.5, float2(repeating: -60), float2(repeating: 60))
    self.scrollView.contentSizeDidChange(context, offsetBy: delta)
    let (offset, affinity) = self.offset(at: point)
    self.extendSelection(to: offset, affinity: affinity)
    context.invalidate(.render)
  }

  /// The word or line around `offset`, by the press's granularity; the offset alone by character.
  private func unitRange(at offset: Int) -> Range<Int> {
    switch self.granularity {
    case .character:
      return offset ..< offset
    case .word:
      return TextBoundaries.word(at: offset, in: self.document, wordCharacters: self.state.wordCharacters)
    case .line:
      return self.document.lineRange(self.document.line(containing: offset), includingNewline: true)
    }
  }

  /// Selects from what the press selected to `offset`, whole words or lines by its granularity.
  private func extendSelection(to offset: Int, affinity: TextAffinity) {
    let unit = self.unitRange(at: offset)
    let origin = self.pressRange
    let selection: SelectionRange
    if offset < origin.lowerBound {
      selection = SelectionRange(anchor: origin.upperBound, head: unit.lowerBound)
    } else if offset >= origin.upperBound && self.granularity != .character {
      selection = SelectionRange(anchor: origin.lowerBound, head: unit.upperBound)
    } else if self.granularity == .character {
      selection = SelectionRange(anchor: origin.lowerBound, head: offset, affinity: affinity)
    } else {
      selection = SelectionRange(anchor: origin.lowerBound, head: origin.upperBound)
    }
    self.state.setSelection(EditorSelection(selection))
  }

  // MARK: - Focus and caret

  private func focusChanged(_ focused: Bool) {
    self.isFocused = focused
    self.scheduleBracketMatch()
    if !focused {
      self.state.unmarkText()
    }
    self.restartBlink()
    self.context?.invalidate(.render)
  }

  /// Shows the caret, solid, from now: after any key or click. It starts blinking half a
  /// second later, and stops, solid, a minute after the last input, so a window left alone goes
  /// idle.
  func restartBlink() {
    self.caretVisible = true
    guard let context = self.context else { return }
    let now = context.clock()
    self.lastInput = now
    let hasCaret = self.state.selection.ranges.contains { $0.isEmpty }
    self.nextBlink = self.isFocused && self.caretBlinks && hasCaret ? now + Self.blinkPeriods.on : nil
    self.scheduleWake(context, now: now)
  }

  private func scheduleWake(_ context: UIContext, now: Double) {
    var next = self.nextBlink
    if self.autoscrollPoint != nil {
      next = min(next ?? .infinity, now + 1.0 / 60)
    }
    if self.styling.needsBackgroundWork {
      // The next frame: styling the rest of the document, a slice a frame.
      next = min(next ?? .infinity, now)
    }
    if let next {
      context.requestWake(at: next, for: self)
    } else {
      context.cancelWake(for: self)
    }
  }

  public func wake(_ context: UIContext, now: Double) {
    if let point = self.autoscrollPoint {
      self.autoscroll(to: point, context)
    }
    if self.styling.needsBackgroundWork, let changed = self.styling.advance(),
       let first = self.content.visible.first?.line, let last = self.content.visible.last?.line,
       changed.overlaps(first ... last) {
      // Lines in view were styled provisionally, and wrongly.
      self.refresh(revealCaret: false)
    }
    if let next = self.nextBlink, now >= next {
      if now - self.lastInput >= Self.blinkTimeout || !context.isWindowKey || !self.isFocused {
        // Solid until the next input: nothing more to wake for.
        self.caretVisible = true
        self.nextBlink = nil
      } else {
        self.caretVisible.toggle()
        self.nextBlink = now + (self.caretVisible ? Self.blinkPeriods.on : Self.blinkPeriods.off)
      }
      context.invalidate(.render)
    }
    self.scheduleWake(context, now: now)
  }

  // MARK: - Input methods

  func textInputSnapshot() -> TextInputSnapshot {
    let state = self.state
    let key = SnapshotKey(
      revision: self.document.revision, selection: state.selectionGeneration, offset: self.scrollView.offset,
      origin: self.content.position, editable: state.isEditable
    )
    if key == self.snapshotKey { return self.snapshot }
    self.snapshotKey = key
    var snapshot = TextInputSnapshot()
    snapshot.isActive = state.isEditable
    let primary = state.selection.primary
    let selected = state.markedSelection ?? primary.range
    snapshot.selection = NSRange(location: selected.lowerBound, length: selected.count)
    snapshot.marked = state.markedRange.map { NSRange(location: $0.lowerBound, length: $0.count) }
    let length = self.document.length
    let low = max(0, selected.lowerBound - TextInputSnapshot.contextLength)
    let high = min(length, selected.upperBound + TextInputSnapshot.contextLength)
    snapshot.text = self.document.substring(low ..< high)
    snapshot.textStart = low
    snapshot.length = length
    snapshot.revision = self.document.revision
    let caret = self.layout.caretRect(state.markedRange?.lowerBound ?? primary.head, affinity: primary.affinity)
    let origin = self.content.textOrigin
    snapshot.caretRect = CGRect(
      x: Double(origin.x + caret.x), y: Double(origin.y) + caret.top,
      width: Double(Self.caretWidth), height: Double(caret.height)
    )
    self.snapshot = snapshot
    return snapshot
  }

  func applyTextInput(_ actions: [TextInputAction], revision: UInt64) {
    let document = self.document
    func mapped(_ range: NSRange?) -> Range<Int>? {
      guard let range, range.location != NSNotFound else { return nil }
      guard let low = document.mapOffset(range.location, fromRevision: revision, .after),
            let high = document.mapOffset(range.location + range.length, fromRevision: revision, .before)
      else { return nil }
      return min(low, high) ..< max(low, high)
    }
    for action in actions {
      switch action {
      case let .insert(text, replacement):
        let range = mapped(replacement)
        if self.state.markedRange == nil && range == nil {
          // Plain typing: a command, so the app sees it first.
          self.perform(.insertText(text))
        } else {
          self.state.commitText(text, replacement: range)
        }
      case let .setMarked(text, selected, replacement):
        let range = selected.location == NSNotFound ? 0 ..< 0 : selected.location ..< selected.location + selected.length
        self.state.setMarkedText(text, selected: range, replacement: mapped(replacement))
      case .unmark:
        self.state.unmarkText()
      case let .command(name):
        if let command = EditorCommand(selector: name) {
          self.perform(command)
        }
      }
    }
    self.refresh(revealCaret: true)
    self.restartBlink()
  }

  // MARK: - Setters

  /// A new text from state. The echo of an edit this editor reported is ignored; any other text
  /// replaces what differs, as one edit the undo history moves around.
  public func setText(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    if let last = self.lastText, last == value { return }
    self.lastText = value
    let old = Array(self.document.string.utf16)
    let new = Array(value.utf16)
    guard old != new else { return }
    // One replacement: what lies between the common start and the common end.
    var prefix = 0
    while prefix < old.count && prefix < new.count && old[prefix] == new[prefix] { prefix += 1 }
    var suffix = 0
    while suffix < old.count - prefix && suffix < new.count - prefix && old[old.count - 1 - suffix] == new[new.count - 1 - suffix] {
      suffix += 1
    }
    let change = TextChange(range: prefix ..< old.count - suffix, text: Array(new[prefix ..< new.count - suffix]))
    self.textChanged = false
    self.document.apply(ChangeSet(change), origin: .program)
    self.textChanged = false
  }

  /// Shows and edits another document.
  public func setDocument(_ value: TextDocument, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value !== self.document else { return }
    self.document.removeObserver(self)
    self.document = value
    let editable = self.state.isEditable
    let filter = self.state.filter
    let pairs = self.state.autoClosingPairs
    self.state.delegate = nil
    self.state = EditorState(document: value)
    self.state.isEditable = editable
    self.state.filter = filter
    self.state.delegate = self
    self.state.clock = { [unowned context] in context.clock() }
    value.addObserver(self)
    self.layout.setDocument(value)
    self.styling.setDocument(value)
    self.state.lineComment = self.styling.styler?.lineComment
    self.state.wordCharacters = self.styling.styler?.wordCharacters ?? []
    self.state.indentation = self.styling.styler as? any IndentationRules
    self.state.autoClosingPairs = pairs
    self.lastText = nil
    context.invalidate(.layout)
  }

  public func setLineWrapping(_ value: LineWrapping, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.lineWrapping else { return }
    self.lineWrapping = value
    self.scrollView.axes = value == .soft ? .vertical : [.vertical, .horizontal]
    context.invalidate(.layout)
  }

  public func setShowsLineNumbers(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.showsLineNumbers else { return }
    self.showsLineNumbers = value
    context.invalidate(.layout)
  }

  public func setTheme(_ value: EditorTheme, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.theme else { return }
    self.theme = value
    self.styling.theme = value
    context.invalidate(.layout)
  }

  /// Styles the text with `value`, a language's highlighter; nil for plain text.
  public func setStyler(_ value: (any TextStyler)?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value !== self.styling.styler else { return }
    self.applyStyler(value)
    self.refresh(revealCaret: false)
  }

  private func applyStyler(_ value: (any TextStyler)?) {
    self.styling.setStyler(value)
    self.state.indentation = value as? any IndentationRules
    self.state.lineComment = value?.lineComment
    self.state.wordCharacters = value?.wordCharacters ?? []
    self.layout.invalidateAll()
  }

  /// Shows attachments with `value`'s elements; nil shows none.
  public func setAttachmentProvider(_ value: (any TextAttachmentProvider)?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value !== self.attachmentProvider else { return }
    self.attachmentProvider = value
    self.layout.attachmentProvider = value
    self.content.attachments.reset()
    self.layout.invalidateAll()
    self.refresh(revealCaret: false)
  }

  /// Inserts an inline attachment at the selection, replacing it: a U+FFFC marked with `id`,
  /// shown with the provider's element for it. Returns whether it went in.
  @discardableResult
  public func insertAttachment(_ id: TextAttachmentID) -> Bool {
    let range = self.state.selection.primary.range
    self.inCommand = true
    let inserted = self.state.apply(EditorTransaction(
      changes: ChangeSet(TextChange(range: range, with: "\u{FFFC}")), selection: .caret(range.lowerBound + 1), kind: .other
    ))
    self.inCommand = false
    if inserted {
      self.document.attachments.add(range.lowerBound ..< range.lowerBound + 1, id)
      self.layout.invalidate(lineID: self.document.lineID(self.document.line(containing: range.lowerBound)))
    }
    self.refresh(revealCaret: true)
    return inserted
  }

  /// Highlights every match of `value`, by the search options; nil or empty for none.
  public func setSearchQuery(_ value: String?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard self.styling.setSearch(value) else { return }
    self.layout.invalidateAll()
    self.refresh(revealCaret: false)
    self.scheduleSearchReport()
  }

  /// How the search matches: case, whole words, a regular expression.
  public func setSearchOptions(_ value: TextSearchOptions, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard self.styling.setSearch(self.styling.searchQuery, options: value) else { return }
    self.layout.invalidateAll()
    self.refresh(revealCaret: false)
    self.scheduleSearchReport()
  }

  public func setMatchesBrackets(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.matchesBrackets else { return }
    self.matchesBrackets = value
    if value { self.scheduleBracketMatch() } else { self.updateBracketMatch() }
  }

  /// The ranges of the current search's matches.
  public var searchMatches: [Range<Int>] { self.styling.searchMatches() }

  /// Underlines `value`'s ranges with squiggles, by severity, replacing the ones before. They
  /// move with the text as it is edited.
  public func setDiagnostics(_ value: [TextDiagnostic], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let marks = self.document.diagnostics
    marks.removeAll()
    for diagnostic in value {
      let range = diagnostic.range.clamped(to: 0 ..< self.document.length)
      marks.add(range, Diagnostic(diagnostic.severity, diagnostic.message))
    }
    self.layout.invalidateAll()
    self.refresh(revealCaret: false)
  }

  public func setIsEditable(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.state.isEditable else { return }
    self.state.isEditable = value
    context.invalidate(.render)
  }

  // MARK: - Modifiers

  /// Wraps lines at the editor's width, or not. Sets this editor's own and returns it.
  public func lineWrapping(_ value: LineWrapping) -> Self {
    self.lineWrapping = value
    self.scrollView.axes = value == .soft ? .vertical : [.vertical, .horizontal]
    return self
  }

  /// Shows line numbers beside the text.
  public func lineNumbers(_ value: Bool = true) -> Self {
    self.showsLineNumbers = value
    return self
  }

  public func editorTheme(_ value: EditorTheme) -> Self {
    self.theme = value
    self.styling.theme = value
    return self
  }

  /// Styles the text with a language's highlighter.
  public func styler(_ value: (any TextStyler)?) -> Self {
    self.applyStyler(value)
    return self
  }

  /// Shows attachments with `value`'s elements.
  public func attachmentProvider(_ value: (any TextAttachmentProvider)?) -> Self {
    self.attachmentProvider = value
    self.layout.attachmentProvider = value
    return self
  }

  /// Highlights every match of `value`, ignoring case unless the options say otherwise.
  public func searchQuery(_ value: String?) -> Self {
    self.styling.setSearch(value)
    return self
  }

  public func searchOptions(_ value: TextSearchOptions) -> Self {
    self.styling.setSearch(self.styling.searchQuery, options: value)
    return self
  }

  /// Highlights the bracket beside the caret and its partner, skipping those in strings and
  /// comments.
  public func bracketMatching(_ value: Bool = true) -> Self {
    self.matchesBrackets = value
    return self
  }

  /// Types the closing half of a pair with the opening one, types over it, and deletes both
  /// halves of an empty pair together. Swift's brackets and quotes by default; `[]` for none.
  public func autoClosingPairs(_ value: [AutoClosingPair] = AutoClosingPair.code) -> Self {
    self.state.autoClosingPairs = value
    return self
  }

  public func setAutoClosingPairs(_ value: [AutoClosingPair], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.state.autoClosingPairs = value
  }

  /// Underlines problems in the text with squiggles.
  public func diagnostics(_ value: [TextDiagnostic]) -> Self {
    for diagnostic in value {
      self.document.diagnostics.add(diagnostic.range.clamped(to: 0 ..< self.document.length),
                                    Diagnostic(diagnostic.severity, diagnostic.message))
    }
    return self
  }

  /// Whether the user may change the text; moving and selecting still work.
  public func editable(_ value: Bool) -> Self {
    self.state.isEditable = value
    return self
  }

  public func onCommand(_ action: @escaping (EditorCommand) -> Bool) -> Self {
    self.onCommand = action
    return self
  }

  public func onSearchChange(_ action: @escaping (_ current: Int, _ count: Int) -> Void) -> Self {
    self.onSearchChange = action
    return self
  }

  public func onSelectionChange(_ action: @escaping (EditorSelection) -> Void) -> Self {
    self.onSelectionChange = action
    return self
  }

  /// Offers `value` to fold, from a language's parse: sorted by start. See `foldingRanges`.
  public func foldingRanges(_ value: [Range<Int>]) -> Self {
    self.foldingRanges = value
    return self
  }

  public func setFoldingRanges(_ value: [Range<Int>], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.foldingRanges else { return }
    let wasEmpty = self.foldingRanges.isEmpty
    self.foldingRanges = value
    // The chevrons' column comes or goes with the first ranges and the last.
    if wasEmpty != value.isEmpty { context.invalidate(.layout) }
    context.invalidate(.render)
  }

  /// Lets `controller` select and reveal in this editor from code.
  public func controller(_ value: EditorController?) -> Self {
    value?.editor = self
    return self
  }

  public func setController(_ value: EditorController?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard let value, value.editor !== self else { return }
    value.editor = self
  }

  /// Keeps the view at the end as text is added there, when it was at the end.
  public func followsTail(_ value: Bool = true) -> Self {
    self.followsTail = value
    return self
  }

  public func setFollowsTail(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.followsTail = value
  }

  /// Sees the user's edits before they are made. See `editFilter`.
  public func editFilter(_ filter: @escaping (inout EditorTransaction, EditorState) -> Bool) -> Self {
    self.editFilter = filter
    return self
  }

  /// Whether the caret blinks. It blinks by default, for a minute after the last input.
  public func caretBlink(_ value: Bool) -> Self {
    self.caretBlinks = value
    return self
  }

  public func setCaretBlinks(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.caretBlinks else { return }
    self.caretBlinks = value
    self.restartBlink()
  }
}
