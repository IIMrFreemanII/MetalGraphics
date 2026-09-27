import EditorCore
import Foundation
import MetalGraphicsLib
import ReactiveUI
import simd
import SwiftCodeModel

/// One open file, in a tab: its text in an editor, a find bar over it when searching, and a
/// status line under it.
///
/// ⌘S saves it. A tab showing unsaved edits reads "● name", and closing it asks first. ⌘F finds
/// (⌘G, ⇧⌘G next and previous, Escape in the text closes the bar), ⌘L goes to a line. Moved to
/// another window, the panel is made anew there; its unsaved text goes with it (`OpenFiles`),
/// its undo history does not.
@Component
final class FileEditorPanel : SingleChildElement {
  private static let statusFont = TextFont.system(size: 11)
  private static let statusColor = float4(0.42, 0.42, 0.45, 1)
  private static let errorColor = float4(0.8, 0.2, 0.15, 1)
  private static let barColor = float4(0.955, 0.955, 0.96, 1)

  let panel: DockPanel
  let file: FileBinding
  let controller = EditorController()
  let styler: (any TextStyler)?
  /// Brackets and quotes typed in pairs, in code.
  let pairs: [AutoClosingPair]
  /// Parses a Swift file after each pause in typing: the outline, and what folds.
  let codeModel: CodeModelSession?

  @State var dirty: Bool
  // The find bar.
  @State var finding: Bool = false
  @State var findFocused: Bool = false
  @State var query: String = ""
  @State var replacement: String = ""
  @State var caseSensitive: Bool = false
  @State var wholeWord: Bool = false
  @State var regex: Bool = false
  @State var matches: String = ""
  @State var goingToLine: Bool = false
  /// The build's problems in this file.
  @State var diagnostics: [TextDiagnostic] = []
  /// What can fold, from the last parse.
  @State var foldable: [Range<Int>] = []
  @State var confirmingClose: Bool = false
  @State var status: String = "Ln 1, Col 1"
  /// What went wrong reading or saving the file; "" when nothing did.
  @State var problem: String

  init(panel: DockPanel) {
    self.panel = panel
    let path = panel.storage.value(IDE.pathKey, default: StoredText(rawValue: "")).rawValue
    let file = FileBinding(path: path, unsaved: OpenFiles.shared.takeUnsaved(panel: panel.id))
    self.file = file
    self.styler = Self.styler(for: path)
    self.pairs = self.styler is SwiftStyler ? AutoClosingPair.code : []
    self.codeModel = self.styler is SwiftStyler && file.loadError == nil ? CodeModelSession(document: file.document) : nil
    self.dirty = file.isDirty
    self.problem = file.loadError ?? ""
    super.init()
    // For Save All, while the panel lives: shown or in a tab behind another.
    OpenFiles.shared.register(file)
    file.onDirtyChange = { [unowned self] dirty in
      self.dirty = dirty
      self.showTitle()
    }
    file.onDiskChange = { [unowned self] reason in
      self.problem = reason ?? ""
    }
    self.codeModel?.onAnalysis = { [unowned self] analysis in
      self.foldable = analysis.foldingRanges
      self.publishOutline()
    }
    panel.shouldClose = { [weak self] in
      guard let self, self.file.isDirty else { return true }
      self.confirmingClose = true
      return false
    }
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 0) {
      if self.finding {
        HStack(spacing: 6) {
          TextField("Find", text: $query, prompt: "Find")
            .focused(self.findFocused)
            .onSubmit { self.controller.findNext() }
            .frame(width: 200)
          Text(self.matches)
            .font(Self.statusFont)
            .foregroundColor(Self.statusColor)
            .frame(width: 70, alignment: .leading)
          Button("◀") { self.controller.findNext(forward: false) }
          Button("▶") { self.controller.findNext() }
          Button(self.caseSensitive ? "✓ Aa" : "Aa") { self.caseSensitive.toggle() }
          Button(self.wholeWord ? "✓ Word" : "Word") { self.wholeWord.toggle() }
          Button(self.regex ? "✓ .*" : ".*") { self.regex.toggle() }
          TextField("Replace", text: $replacement, prompt: "Replace")
            .onSubmit { self.controller.replaceCurrent(with: self.replacement) }
            .frame(width: 160)
          Button("Replace") { self.controller.replaceCurrent(with: self.replacement) }
          Button("All") { self.controller.replaceAll(with: self.replacement) }
          Spacer()
          Button("Done") { self.closeFind() }
        }
        .padding(Inset(vertical: 5, horizontal: 10))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.barColor)
      }
      TextEditor(document: self.file.document)
        .styler(self.styler)
        .lineNumbers(true)
        .bracketMatching(true)
        .autoClosingPairs(self.pairs)
        .searchQuery(self.finding ? self.query : "")
        .searchOptions(TextSearchOptions(caseSensitive: self.caseSensitive, wholeWord: self.wholeWord, regex: self.regex))
        .diagnostics(self.diagnostics)
        .foldingRanges(self.foldable)
        .editable(self.file.loadError == nil)
        .controller(self.controller)
        .onSelectionChange { selection in self.showStatus(selection) }
        .onSearchChange { current, count in self.showMatches(current, count) }
        .onCommand { command in self.command(command) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      HStack(spacing: 12) {
        Text(self.status)
          .font(Self.statusFont)
          .foregroundColor(Self.statusColor)
        Text(self.problem)
          .font(Self.statusFont)
          .foregroundColor(Self.errorColor)
          .lineLimit(1)
        Spacer()
        Text(self.file.name)
          .font(Self.statusFont)
          .foregroundColor(Self.statusColor)
      }
      .padding(Inset(vertical: 4, horizontal: 10))
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Self.barColor)
    }
    .onKeyPress(phases: .down) { press in self.key(press) }
    .sheet(isPresented: $goingToLine) {
      GoToLineSheet(lineCount: self.file.document.lineCount) { line, column in
        self.controller.goTo(line: line, column: column)
        self.controller.focus()
      }
    }
    .alert("Save changes to “\(self.file.name)”?", isPresented: $confirmingClose) {
      Button("Save") { self.saveAndClose() }
      Button("Don’t Save", role: .destructive) { self.discardAndClose() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Your changes will be lost if you don’t save them.")
    }
  }

  override func onMount(_ context: UIContext) {
    WorkspaceModel.shared.activeFile = self.file.path
    self.publishOutline()
    self.showTitle()
    // The build's problems and the places asked for are the shared models': subscribed by hand,
    // as they are turned into this document's ranges, which a body cannot do.
    BuildModel.shared.__observers(named: "problems").add(self, token: Self.problemsToken)
    WorkspaceModel.shared.__observers(named: "reveal").add(self, token: Self.revealToken)
    self.showProblems()
    // Shown, so it takes the keyboard: a file just opened, a tab picked.
    context.afterLayout { [weak self] in
      self?.controller.focus()
      self?.revealIfAsked()
    }
  }

  private static let problemsToken = 0
  private static let revealToken = 1

  override func __modelDidChange(_ token: Int, _ animated: Bool) {
    switch token {
    case Self.problemsToken: self.showProblems()
    default: self.revealIfAsked()
    }
  }

  // Leaving the window — another tab picked, the panel moved or closed, the app quitting. A
  // move makes the panel anew elsewhere, from the text kept here.
  override func onUnmount(_ context: UIContext) {
    BuildModel.shared.__observers(named: "problems").remove(self)
    WorkspaceModel.shared.__observers(named: "reveal").remove(self)
    // Still in the layout: moving, or another tab picked. Not when it was closed.
    if self.file.isDirty && self.panel.space.layout.panels[self.panel.id] != nil {
      OpenFiles.shared.keepUnsaved(self.file.document.stringWithOriginalLineEndings, panel: self.panel.id)
    }
  }

  // MARK: - Actions

  private func key(_ press: KeyPress) -> KeyPress.Result {
    if press.key == .escape && self.finding {
      // From the find bar's fields, which gave up focus and passed it on.
      self.closeFind()
      return .handled
    }
    guard press.modifiers.contains(.command) else { return .ignored }
    switch press.key {
    case "s":
      if press.modifiers.contains(.option) {
        OpenFiles.shared.saveAll()
      } else {
        self.save()
      }
    case "f":
      self.openFind()
    case "g":
      if !self.finding { self.openFind() }
      self.controller.findNext(forward: !press.modifiers.contains(.shift))
    case "l":
      self.goingToLine = true
    default:
      return .ignored
    }
    return .handled
  }

  /// Escape in the text closes the find bar.
  private func command(_ command: EditorCommand) -> Bool {
    guard command == .cancel, self.finding, self.controller.editor?.state.selection.ranges.count == 1 else { return false }
    self.closeFind()
    return true
  }

  /// Shows the find bar with the keyboard in its field, looking for the selection when it is on
  /// one line.
  private func openFind() {
    if let editor = self.controller.editor {
      let selected = editor.state.selectedText
      if !selected.isEmpty && !selected.contains("\n") { self.query = selected }
    }
    self.finding = true
    self.findFocused = true
  }

  private func closeFind() {
    self.finding = false
    self.findFocused = false
    self.controller.focus()
  }

  private func showMatches(_ current: Int, _ count: Int) {
    self.matches = count == 0
      ? (self.query.isEmpty ? "" : "No matches")
      : (current > 0 ? "\(current) of \(count)" : (count == 1 ? "1 match" : "\(count) matches"))
  }

  @discardableResult
  func save() -> Bool {
    do {
      try self.file.save()
      OpenFiles.shared.forgetUnsaved(panel: self.panel.id)
      self.problem = ""
      return true
    } catch {
      self.problem = "\(error)"
      return false
    }
  }

  private func saveAndClose() {
    if self.save() { self.panel.close() }
  }

  private func discardAndClose() {
    OpenFiles.shared.forgetUnsaved(panel: self.panel.id)
    self.panel.close()
  }

  /// "● name" while unsaved, written only when it flips.
  private func showTitle() {
    let title = self.file.isDirty ? "● \(self.file.name)" : self.file.name
    if self.panel.title != title { self.panel.setTitle(title) }
  }

  private func showStatus(_ selection: EditorSelection) {
    let document = self.file.document
    let (line, column) = document.position(of: selection.primary.head)
    let selected = selection.ranges.reduce(0) { $0 + $1.range.count }
    self.status = selected > 0
      ? "Ln \(line + 1), Col \(column + 1) (\(selected) selected)"
      : "Ln \(line + 1), Col \(column + 1)"
  }

  /// The build's problems in this file, as ranges of its text: each underlines the word at its
  /// column, or the character.
  private func showProblems() {
    let document = self.file.document
    let problems = BuildModel.shared.problems.filter { $0.path == self.file.path }
    guard !problems.isEmpty || !self.diagnostics.isEmpty else { return }
    self.diagnostics = problems.map { problem in
      let offset = Self.offset(of: problem.line, problem.column, in: document)
      let line = document.line(containing: offset)
      let lineEnd = document.lineRange(line).upperBound
      var end = offset
      while end < lineEnd, Self.isWordUnit(document.unit(at: end)) { end += 1 }
      if end == offset { end = min(offset + 1, lineEnd) }
      let severity: DiagnosticSeverity = switch problem.severity {
      case .error: .error
      case .warning: .warning
      case .note, .remark: .info
      }
      return TextDiagnostic(offset ..< max(end, offset), severity, problem.message)
    }
  }

  /// Where `line` and `column`, from 1 and in UTF-8 bytes as compilers count, are in the text.
  static func offset(of line: Int, _ column: Int, in document: TextDocument) -> Int {
    let line = min(max(line - 1, 0), document.lineCount - 1)
    let text = document.lineText(line)
    let utf16 = TextPositions.utf16Column(fromUTF8: max(column - 1, 0), in: text)
    return document.lineStart(line) + min(utf16, text.utf16.count)
  }

  private static func isWordUnit(_ unit: UInt16) -> Bool {
    (unit >= 0x30 && unit <= 0x39) || (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A) || unit == 0x5F
  }

  /// The outline of this file, when it is the one in front.
  private func publishOutline() {
    guard WorkspaceModel.shared.activeFile == self.file.path else { return }
    let outline = OutlineModel.shared
    outline.path = self.file.path
    outline.symbols = self.codeModel?.analysis.symbols ?? []
  }

  /// Takes a request to show a place in this file: selects it, centred, and takes the keyboard.
  private func revealIfAsked() {
    let model = WorkspaceModel.shared
    guard let request = model.reveal, request.path == self.file.path, self.mounted else { return }
    model.reveal = nil
    let offset = request.offset.map { min($0, self.file.document.length) }
      ?? Self.offset(of: request.line, request.column, in: self.file.document)
    self.controller.select(offset ..< offset, reveal: .center)
    self.controller.focus()
  }

  static func styler(for path: String) -> (any TextStyler)? {
    switch (path as NSString).pathExtension.lowercased() {
    case "swift": SwiftStyler()
    case "md", "markdown": MarkdownStyler()
    default: nil
    }
  }
}
