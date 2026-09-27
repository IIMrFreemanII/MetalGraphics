@testable import Editor
@testable import MetalGraphicsLib
import XCTest

// The editing aids of a file's tab: the find bar, going to a line, opening a file by name,
// and what typing Swift adds (pairs, indentation, the bracket at the caret).
final class EditingE2ETests: EditorAppTestCase {
  /// Greeter.swift open, with the keyboard.
  private func openGreeter() throws -> TextEditor {
    self.openPackage()
    try self.openInNavigator("Sources/App/Greeter.swift")
    return try XCTUnwrap(self.shownEditor())
  }

  private func line(of editor: TextEditor) -> Int {
    editor.document.position(of: editor.state.selection.primary.head).line
  }

  // MARK: - Find

  func testCommandFFindsAndReturnGoesToEachMatch() throws {
    let editor = try self.openGreeter()
    self.window.press("f", modifiers: .command)
    XCTAssertTrue(self.window.shows("Done"))
    self.window.type("name")
    self.app.step()
    XCTAssertEqual(editor.searchMatches.count, 2)
    XCTAssertTrue(self.window.shows("2 matches"))

    self.window.press(.return)
    self.app.step()
    XCTAssertEqual(editor.state.selectedText, "name")
    XCTAssertEqual(self.line(of: editor), 1)
    XCTAssertTrue(self.window.shows("1 of 2"))

    self.window.press("g", modifiers: .command)
    self.app.step()
    XCTAssertEqual(self.line(of: editor), 3)
    XCTAssertTrue(self.window.shows("2 of 2"))
    self.window.press("g", modifiers: [.command, .shift])
    self.app.step()
    XCTAssertEqual(self.line(of: editor), 1)
  }

  func testReplaceAllCanBeUndoneInOneStep() throws {
    let editor = try self.openGreeter()
    let original = editor.document.string
    self.window.press("f", modifiers: .command)
    self.window.type("name")
    try self.window.type("title", into: "Replace")
    try self.window.tap("All")
    self.app.step()
    XCTAssertEqual(editor.document.string, original.replacingOccurrences(of: "name", with: "title"))
    XCTAssertTrue(self.window.shows("No matches"))

    editor.perform(.undo)
    self.app.step()
    XCTAssertEqual(editor.document.string, original)
  }

  func testDoneClosesTheBarAndClearsTheHighlights() throws {
    let editor = try self.openGreeter()
    self.window.press("f", modifiers: .command)
    self.window.type("name")
    self.app.step()
    try self.window.tap("Done")
    self.app.step()
    XCTAssertFalse(self.window.shows("Done"))
    XCTAssertEqual(editor.searchMatches, [])
    XCTAssertTrue(editor.isFocused, "the text has the keyboard back")
  }

  func testEscapeInTheFindFieldClosesTheBar() throws {
    let editor = try self.openGreeter()
    self.window.press("f", modifiers: .command)
    self.window.type("name")
    self.window.press(.escape)
    self.app.step()
    XCTAssertFalse(self.window.shows("Done"))
    XCTAssertEqual(editor.searchMatches, [])
    XCTAssertTrue(editor.isFocused)
  }

  func testTheFindBarStartsWithTheSelection() throws {
    let editor = try self.openGreeter()
    let range = try XCTUnwrap(editor.document.string.range(of: "greeting"))
    let start = editor.document.string.utf16.distance(from: editor.document.string.startIndex, to: range.lowerBound)
    editor.select(start ..< start + 8, reveal: .none)
    self.window.press("f", modifiers: .command)
    self.app.step()
    XCTAssertEqual(editor.searchMatches.count, 1)
    XCTAssertTrue(self.window.shows("1 of 1"))
  }

  // MARK: - Go to line

  func testCommandLGoesToALine() throws {
    let editor = try self.openGreeter()
    self.window.press("l", modifiers: .command)
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.window.shows("Go to Line"))
    self.window.type("4:5")
    self.window.press(.return)
    XCTAssertNotNil(self.app.settle())
    XCTAssertFalse(self.window.shows("Go to Line"))
    XCTAssertEqual(editor.document.position(of: editor.state.selection.primary.head).line, 3)
    XCTAssertEqual(editor.document.position(of: editor.state.selection.primary.head).column, 4)
    XCTAssertTrue(editor.isFocused)
  }

  func testALineOutOfRangeIsRefused() throws {
    _ = try self.openGreeter()
    self.window.press("l", modifiers: .command)
    XCTAssertNotNil(self.app.settle())
    self.window.type("99")
    self.window.press(.return)
    self.app.step()
    XCTAssertTrue(self.window.shows("Type a line from 1 to 5."))
    XCTAssertEqual(GoToLineSheet.parse("12:3")?.0, 12)
    XCTAssertNil(GoToLineSheet.parse("twelve"))
  }

  // MARK: - Quick open

  func testCommandPOpensAFileByName() throws {
    self.openPackage()
    self.window.press("p", modifiers: .command)
    XCTAssertNotNil(self.app.settle())
    // Every file, those in closed folders too.
    XCTAssertTrue(self.window.shows("main.swift"))
    self.window.type("gre")
    self.app.step()
    XCTAssertTrue(self.window.shows("Greeter.swift"))
    XCTAssertFalse(self.window.shows("main.swift"))
    self.window.press(.return)
    XCTAssertNotNil(self.app.settle())
    XCTAssertEqual(self.filePanels.map(\.path), [self.path("Sources/App/Greeter.swift")])
    XCTAssertEqual(self.shownEditor()?.document.string, EditorAppTestCase.files["Sources/App/Greeter.swift"])
  }

  func testEscapeClosesQuickOpen() throws {
    self.openPackage()
    self.window.press("p", modifiers: .command)
    XCTAssertNotNil(self.app.settle())
    self.window.type("gre")
    self.window.press(.escape)
    XCTAssertNotNil(self.app.settle())
    XCTAssertFalse(self.window.shows("Open Quickly"))
    XCTAssertEqual(self.filePanels.count, 0)
  }

  func testATappedResultOpens() throws {
    self.openPackage()
    self.window.press("p", modifiers: .command)
    XCTAssertNotNil(self.app.settle())
    try self.window.tap("main.swift")
    XCTAssertNotNil(self.app.settle())
    XCTAssertEqual(self.filePanels.map(\.path), [self.path("Sources/App/main.swift")])
  }

  // MARK: - Typing Swift

  func testSwiftTypingPairsAndIndents() throws {
    let editor = try self.openGreeter()
    let end = editor.document.length
    editor.select(end ..< end, reveal: .none)
    self.window.type("\nfunc f(")
    XCTAssertTrue(editor.document.string.hasSuffix("}\nfunc f()"))
    self.window.type(") {")
    XCTAssertTrue(editor.document.string.hasSuffix("}\nfunc f() {}"), "the ) typed over, the { brought its }")
    self.window.press(.return)
    XCTAssertTrue(editor.document.string.hasSuffix("}\nfunc f() {\n    \n}"))
    // Before a word, nothing is paired.
    editor.select(0 ..< 0, reveal: .none)
    self.window.type("(")
    XCTAssertTrue(editor.document.string.hasPrefix("(struct"))
  }

  func testTheBracketAtTheCaretShowsItsPartner() throws {
    let editor = try self.openGreeter()
    // After `struct Greeter {`.
    editor.select(16 ..< 16, reveal: .none)
    self.app.step()
    XCTAssertEqual(editor.styling.bracketPair?.0, 15)
    XCTAssertEqual(editor.styling.bracketPair?.1, editor.document.length - 1)
  }

  func testMarkdownTypesNoPairs() throws {
    self.openPackage()
    try self.openInNavigator("README.md")
    let editor = try XCTUnwrap(self.shownEditor())
    editor.select(editor.document.length ..< editor.document.length, reveal: .none)
    self.window.type("(")
    XCTAssertEqual(editor.document.string, "# Sample\n(")
  }
}
