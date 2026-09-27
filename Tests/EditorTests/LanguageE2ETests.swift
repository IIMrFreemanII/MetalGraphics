@testable import Editor
import EditorCore
@testable import MetalGraphicsLib
import simd
import XCTest

// The language server's part: the file kept in sync edit by edit, completions, hovers,
// definitions and live diagnostics.
final class LanguageE2ETests: EditorAppTestCase {
  private func open(_ relative: String) throws -> TextEditor {
    self.openPackage()
    try self.openInNavigator(relative)
    return try XCTUnwrap(self.shownEditor())
  }

  private func caretAtEnd(_ editor: TextEditor) {
    let end = editor.document.length
    editor.select(end ..< end, reveal: .none)
  }

  // MARK: - Sync

  func testTheServerSeesEveryEdit() throws {
    let editor = try self.open("Sources/App/main.swift")
    let path = self.path("Sources/App/main.swift")
    XCTAssertEqual(self.language.opened, [path])
    XCTAssertEqual(self.language.texts[path], editor.document.string)

    self.caretAtEnd(editor)
    self.window.type("\nlet x = [1, 2]")
    self.window.press(.delete)
    self.window.press(.delete, modifiers: .option)
    editor.select(0 ..< 3, reveal: .none)
    self.window.paste("var é😀\nline")
    XCTAssertEqual(self.language.texts[path], editor.document.string)
    XCTAssertGreaterThan(self.language.versions[path] ?? 0, 10)
    XCTAssertEqual(self.language.replacements, 0)
  }

  func testManyCursorsAtOnceStayInSync() throws {
    let editor = try self.open("Sources/App/Greeter.swift")
    let path = self.path("Sources/App/Greeter.swift")
    // A caret at the start of every line, then typing and deleting at all of them.
    let starts = (0 ..< editor.document.lineCount).map { editor.document.lineStart($0) }
    editor.state.setSelection(EditorSelection(starts.map { SelectionRange.caret($0) }))
    self.window.type("//")
    self.window.press(.delete)
    self.window.type("é ")
    XCTAssertEqual(self.language.texts[path], editor.document.string)
    XCTAssertTrue(editor.document.string.hasPrefix("/é struct"))

    // More changes at once than are worth sending one by one: the whole text.
    editor.document.apply(ChangeSet((0 ..< 60).map { TextChange(range: $0 ..< $0, with: "x") }), origin: .user)
    XCTAssertEqual(self.language.replacements, 1)
    XCTAssertEqual(self.language.texts[path], editor.document.string)
  }

  func testRandomEditsStayInSync() throws {
    let editor = try self.open("Sources/App/Greeter.swift")
    let path = self.path("Sources/App/Greeter.swift")
    var random = SystemRandomNumberGenerator()
    let pieces = ["", "a", "é", "😀", "\n", "ab\ncd", "\n\n", "{ }"]
    for step in 0 ..< 300 {
      let document = editor.document
      // A few disjoint changes, as several carets make, anywhere in the text.
      let count = Int.random(in: 1 ... 4, using: &random)
      var cuts = (0 ..< count * 2).map { _ in Int.random(in: 0 ... document.length, using: &random) }.sorted()
      // Never split a surrogate pair.
      cuts = cuts.map { TextBoundaries.snap($0, in: document) }
      var changes: [TextChange] = []
      for i in stride(from: 0, to: cuts.count, by: 2) where changes.last.map({ $0.range.upperBound <= cuts[i] }) ?? true {
        changes.append(TextChange(range: cuts[i] ..< cuts[i + 1], with: pieces.randomElement(using: &random)!))
      }
      document.apply(ChangeSet(changes), origin: .user)
      guard self.language.texts[path] == document.string else {
        return XCTFail("out of sync after edit \(step): \(changes)")
      }
    }
  }

  func testSavingAndClosingAreTold() throws {
    let editor = try self.open("Sources/App/main.swift")
    let path = self.path("Sources/App/main.swift")
    self.caretAtEnd(editor)
    self.window.type("\n")
    self.window.press("s", modifiers: .command)
    XCTAssertEqual(self.language.saved, [path])
    IDE.space.close(panel: try XCTUnwrap(self.filePanels.first?.id))
    self.app.step()
    XCTAssertEqual(self.language.closed, [path])
  }

  func testOtherFilesAreNotSent() throws {
    _ = try self.open("README.md")
    XCTAssertEqual(self.language.opened, [])
  }

  // MARK: - Completion

  private let items = [
    LSPCompletionItem(label: "print(_:)", kind: .function, detail: "Void", sortText: "1", insertText: "print(${1:items})", index: 0),
    LSPCompletionItem(label: "precondition(_:)", kind: .function, detail: "Void", sortText: "2", insertText: "precondition(${1:c})", index: 1),
    LSPCompletionItem(label: "private", kind: .keyword, sortText: "3", index: 2),
  ]

  /// The completion list's rows, top to bottom.
  private var rows: [String] {
    self.window.all(CompletionRowView.self).filter(\.mounted).map(\.row.label)
  }

  func testASecondLetterOpensTheListAndReturnAcceptsIt() throws {
    let editor = try self.open("Sources/App/main.swift")
    self.language.completions = self.items
    self.caretAtEnd(editor)
    self.window.type("\np")
    self.app.step()
    XCTAssertFalse(self.window.shows("print(_:)"), "not after one letter")
    self.window.type("r")
    self.app.step()
    XCTAssertTrue(self.window.shows("print(_:)"))
    XCTAssertTrue(self.window.shows("private"))
    XCTAssertEqual(self.language.completionPositions.last, LSPPosition(line: 2, character: 2))

    XCTAssertEqual(self.rows, ["print(_:)", "precondition(_:)", "private"])
    // Narrowed as typing goes on: what starts with "pri" first, then what matches it loosely.
    self.window.type("i")
    self.app.step()
    XCTAssertEqual(self.rows, ["print(_:)", "private", "precondition(_:)"])
    self.window.type("v")
    self.app.step()
    XCTAssertEqual(self.rows, ["private"])
    self.window.press(.delete)
    self.app.step()
    XCTAssertEqual(self.language.completionPositions.count, 1, "asked once")

    self.window.press(.return)
    self.app.step()
    XCTAssertTrue(editor.document.string.hasSuffix("\nprint(items)"))
    XCTAssertFalse(self.window.shows("private"))
    // One step to undo takes it back to what was typed.
    editor.perform(.undo)
    XCTAssertTrue(editor.document.string.hasSuffix("\npri"))
  }

  func testArrowsPickAndEscapeCloses() throws {
    let editor = try self.open("Sources/App/main.swift")
    self.language.completions = self.items
    self.caretAtEnd(editor)
    self.window.type("\npr")
    self.app.step()
    self.window.press(.downArrow)
    self.window.press(.tab)
    self.app.step()
    XCTAssertTrue(editor.document.string.hasSuffix("\nprecondition(c)"), editor.document.string)

    self.window.type("\npr")
    self.app.step()
    XCTAssertTrue(self.window.shows("print(_:)"))
    self.window.press(.escape)
    self.app.step()
    XCTAssertFalse(self.window.shows("print(_:)"))
    XCTAssertTrue(editor.document.string.hasSuffix("\npr"))
  }

  func testADotAsksAtOnceAndLeavingTheWordCloses() throws {
    let editor = try self.open("Sources/App/main.swift")
    self.language.completions = [LSPCompletionItem(label: "count", kind: .property, detail: "Int", index: 0)]
    self.caretAtEnd(editor)
    self.window.type("\ngreeting.")
    self.app.step()
    XCTAssertTrue(self.window.shows("count"))
    XCTAssertEqual(self.language.completionPositions.last, LSPPosition(line: 2, character: 9))
    self.window.type(" ")
    self.app.step()
    XCTAssertFalse(self.window.shows("count"))
  }

  func testADotAsksAgainWhileAnEarlierAnswerIsOnItsWay() throws {
    let editor = try self.open("Sources/App/main.swift")
    self.language.completions = [LSPCompletionItem(label: "count", kind: .property, detail: "Int", index: 0)]
    self.language.holdsCompletions = true
    self.caretAtEnd(editor)
    self.window.type("\ngreeting.")
    // Asked at "gr", and again after the dot.
    XCTAssertEqual(self.language.completionPositions, [LSPPosition(line: 2, character: 2), LSPPosition(line: 2, character: 9)])
    self.language.answerCompletions()
    self.app.step()
    XCTAssertEqual(self.rows, ["count"], "only the dot's answer shows")
  }

  func testAClickedRowIsAccepted() throws {
    let editor = try self.open("Sources/App/main.swift")
    self.language.completions = self.items
    self.caretAtEnd(editor)
    self.window.type("\npr")
    self.app.step()
    try self.window.tap("private")
    self.app.step()
    XCTAssertTrue(editor.document.string.hasSuffix("\nprivate"))
  }

  // MARK: - Hover and definitions

  /// Rests the pointer over `offset` long enough for a hover.
  private func rest(over offset: Int, in editor: TextEditor) throws {
    let rect = try XCTUnwrap(editor.caretRect(for: offset))
    self.window.move(to: editor.origin + rect.origin + float2(3, rect.height * 0.5))
    self.app.advance(0.7)
  }

  func testAHoverShowsWhatTheServerSays() throws {
    let editor = try self.open("Sources/App/main.swift")
    self.language.hoverText = "let greeting: String"
    try self.rest(over: 6, in: editor)
    XCTAssertTrue(self.window.shows("let greeting: String"))
    self.window.move(to: float2(5, 5))
    self.app.step()
    XCTAssertFalse(self.window.shows("let greeting: String"))
  }

  func testAProblemUnderThePointerSaysWhatItIs() throws {
    let editor = try self.open("Sources/App/main.swift")
    let path = self.path("Sources/App/main.swift")
    self.language.hoverText = "not this"
    let range = LSPRange(start: LSPPosition(line: 1, character: 6), end: LSPPosition(line: 1, character: 14))
    self.language.publish(path, [LSPDiagnostic(range: range, severity: .warning, message: "unused result")])
    self.app.step()
    XCTAssertEqual(editor.document.diagnostics.marks.map { editor.document.substring($0.range) }, ["greeting"])
    try self.rest(over: editor.document.lineStart(1) + 8, in: editor)
    XCTAssertTrue(self.window.shows("unused result"))

    // Published again without it: gone.
    self.language.publish(path, [])
    self.app.step()
    XCTAssertEqual(editor.document.diagnostics.marks.count, 0)
  }

  func testControlCommandJGoesToTheDefinitionInAnotherFile() throws {
    let editor = try self.open("Sources/App/main.swift")
    let greeter = self.path("Sources/App/Greeter.swift")
    self.language.definitions = [LSPLocation(uri: LSPURI.uri(greeter),
                                             range: LSPRange(start: LSPPosition(line: 0, character: 7), end: LSPPosition(line: 0, character: 14)))]
    editor.select(17 ..< 17, reveal: .none)  // on "Greeter"
    self.window.press("j", modifiers: [.control, .command])
    XCTAssertNotNil(self.app.settle())
    XCTAssertEqual(self.language.definitionPositions.last, LSPPosition(line: 0, character: 17))
    let shown = try XCTUnwrap(self.shownEditor())
    XCTAssertEqual(shown.document.string, EditorAppTestCase.files["Sources/App/Greeter.swift"])
    XCTAssertEqual(shown.state.selection.primary.head, 7)
  }

  func testADefinitionInTheSameFileSelectsIt() throws {
    let editor = try self.open("Sources/App/main.swift")
    self.language.definitions = [LSPLocation(uri: LSPURI.uri(self.path("Sources/App/main.swift")),
                                             range: LSPRange(start: LSPPosition(line: 0, character: 4), end: LSPPosition(line: 0, character: 12)))]
    editor.select(editor.document.lineStart(1) + 8 ..< editor.document.lineStart(1) + 8, reveal: .none)
    self.window.press("j", modifiers: [.control, .command])
    self.app.step()
    XCTAssertEqual(editor.state.selection.primary.head, 4)
  }
}
