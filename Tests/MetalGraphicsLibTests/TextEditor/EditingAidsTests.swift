@testable import MetalGraphicsLib
import AppKit
import simd
import XCTest

// What a code editor adds to typing: find and replace, the bracket at the caret and its partner,
// pairs typed together, and indentation that follows blocks.
@MainActor
final class EditingAidsTests: XCTestCase {
  private func harness(_ text: String, configure: (TextEditor) -> Void = { _ in }) -> (UIHarness, TextEditor) {
    let editor = TextEditor(document: TextDocument(text))
    configure(editor)
    let h = UIHarness(size: float2(420, 300)) { editor }
    h.click(on: editor.focusable)
    return (h, editor)
  }

  private func caret(_ editor: TextEditor, at offset: Int) {
    editor.select(offset ..< offset, reveal: .none)
  }

  // MARK: - Find and replace

  func testFindNextWrapsAndFindPreviousGoesBack() {
    let (h, editor) = self.harness("one two one three one") { _ = $0.searchQuery("one") }
    self.caret(editor, at: 5)
    XCTAssertTrue(editor.findNext())
    XCTAssertEqual(editor.state.selection.primary.range, 8 ..< 11)
    XCTAssertTrue(editor.matchPosition == (2, 3))
    editor.findNext()
    XCTAssertEqual(editor.state.selection.primary.range, 18 ..< 21)
    editor.findNext()
    XCTAssertEqual(editor.state.selection.primary.range, 0 ..< 3, "wraps to the first")
    editor.findNext(forward: false)
    XCTAssertEqual(editor.state.selection.primary.range, 18 ..< 21, "and back to the last")
    h.step()
    XCTAssertEqual(editor.styling.currentMatch, 18 ..< 21)
    // Moving away leaves no current match.
    self.caret(editor, at: 2)
    XCTAssertNil(editor.styling.currentMatch)
    XCTAssertTrue(editor.matchPosition == (0, 3))
  }

  func testOptionsNarrowTheMatches() {
    let (h, editor) = self.harness("Name name rename names")
    h.step()
    editor.setSearchQuery("name", h.context)
    XCTAssertEqual(editor.searchMatches.count, 4)
    editor.setSearchOptions(TextSearchOptions(caseSensitive: true), h.context)
    XCTAssertEqual(editor.searchMatches, [5 ..< 9, 12 ..< 16, 17 ..< 21])
    editor.setSearchOptions(TextSearchOptions(wholeWord: true), h.context)
    XCTAssertEqual(editor.searchMatches, [0 ..< 4, 5 ..< 9])
    editor.setSearchQuery("n(a)me", h.context)
    editor.setSearchOptions(TextSearchOptions(regex: true), h.context)
    XCTAssertEqual(editor.searchMatches.count, 4)
    editor.setSearchQuery("n(", h.context)
    XCTAssertEqual(editor.searchMatches, [], "a pattern that does not compile matches nothing")
  }

  func testReplaceCurrentThenNext() {
    let (h, editor) = self.harness("a x a x a") { _ = $0.searchQuery("a") }
    defer { withExtendedLifetime(h) {} }
    // A match starting at the caret is the next one.
    self.caret(editor, at: 0)
    editor.findNext()
    XCTAssertEqual(editor.state.selection.primary.range, 0 ..< 1)
    self.caret(editor, at: 1)
    editor.findNext()
    XCTAssertEqual(editor.state.selection.primary.range, 4 ..< 5)
    XCTAssertTrue(editor.replaceCurrent(with: "bb"))
    XCTAssertEqual(editor.document.string, "a x bb x a")
    XCTAssertEqual(editor.state.selection.primary.range, 9 ..< 10, "the next match is selected")
    // With no match selected it only finds one.
    self.caret(editor, at: 1)
    XCTAssertFalse(editor.replaceCurrent(with: "zz"))
    XCTAssertEqual(editor.document.string, "a x bb x a")
  }

  func testReplaceAllIsOneUndoStepAndFillsInGroups() {
    let (h, editor) = self.harness("let a = f(1)\nlet b = f(22)\n") {
      _ = $0.searchQuery("f\\((\\d+)\\)").searchOptions(TextSearchOptions(regex: true))
    }
    XCTAssertEqual(editor.replaceAll(with: "g($1, $1)"), 2)
    XCTAssertEqual(editor.document.string, "let a = g(1, 1)\nlet b = g(22, 22)\n")
    h.press("z", characters: "z", modifiers: .command)
    XCTAssertEqual(editor.document.string, "let a = f(1)\nlet b = f(22)\n")
  }

  // MARK: - Brackets

  func testTheBracketAtTheCaretAndItsPartnerAreFound() {
    let text = "func f(a: Int) {\n  g(\")\", [a])\n}"
    let (h, editor) = self.harness(text) { _ = $0.styler(SwiftStyler()).bracketMatching() }
    self.caret(editor, at: 16)  // after `{`
    h.step()
    XCTAssertEqual(editor.styling.bracketPair?.0, 15)
    XCTAssertEqual(editor.styling.bracketPair?.1, text.utf16.count - 1)
    // `g(` finds its `)` past the one in the string.
    let open = 20
    self.caret(editor, at: open + 1)
    h.step()
    XCTAssertEqual(editor.styling.bracketPair?.0, open)
    XCTAssertEqual(editor.styling.bracketPair?.1, 29)
    // Nothing beside the caret: nothing highlighted, and nothing done per idle frame.
    self.caret(editor, at: 2)
    h.step()
    XCTAssertNil(editor.styling.bracketPair)
    XCTAssertNotNil(h.settle())
  }

  // MARK: - Pairs

  func testAnOpeningBracketBringsItsClosingOne() {
    let (h, editor) = self.harness("") { _ = $0.autoClosingPairs() }
    h.type("f(")
    XCTAssertEqual(editor.document.string, "f()")
    XCTAssertEqual(editor.state.selection.primary.head, 2)
    h.type("x)")
    XCTAssertEqual(editor.document.string, "f(x)", "the closing half is typed over")
    XCTAssertEqual(editor.state.selection.primary.head, 4)
  }

  func testBackspaceDeletesAnEmptyPair() {
    let (h, editor) = self.harness("") { _ = $0.autoClosingPairs() }
    h.type("[")
    h.press(.delete)
    XCTAssertEqual(editor.document.string, "")
  }

  func testAPairGoesAroundTheSelection() {
    let (h, editor) = self.harness("value") { _ = $0.autoClosingPairs() }
    editor.select(0 ..< 5, reveal: .none)
    h.type("(")
    XCTAssertEqual(editor.document.string, "(value)")
    XCTAssertEqual(editor.state.selectedText, "value")
  }

  func testNoPairBeforeAWordOrAQuoteAfterOne() {
    let (h, editor) = self.harness("word") { _ = $0.autoClosingPairs() }
    self.caret(editor, at: 0)
    h.type("(")
    XCTAssertEqual(editor.document.string, "(word")
    self.caret(editor, at: 5)
    h.type("\"")
    XCTAssertEqual(editor.document.string, "(word\"")
  }

  // MARK: - Indentation

  func testReturnAfterABraceIndentsAndSplitsAnEmptyBlock() {
    let (h, editor) = self.harness("  func f() {}") { _ = $0.styler(SwiftStyler()) }
    self.caret(editor, at: 12)
    h.press(.return)
    XCTAssertEqual(editor.document.string, "  func f() {\n      \n  }")
    XCTAssertEqual(editor.state.selection.primary.head, 19)
    h.type("x")
    h.press(.return)
    XCTAssertEqual(editor.document.string, "  func f() {\n      x\n      \n  }")
  }

  func testAClosingBraceTypedFirstOnALineGoesOut() {
    let (h, editor) = self.harness("if a {\n        ") { _ = $0.styler(SwiftStyler()) }
    self.caret(editor, at: editor.document.length)
    h.type("}")
    XCTAssertEqual(editor.document.string, "if a {\n    }")
    // Typed after text, it stays where it is.
    h.type(" }")
    XCTAssertEqual(editor.document.string, "if a {\n    } }")
  }

  func testWithoutRulesANewLineKeepsTheIndentation() {
    let (h, editor) = self.harness("    a {")
    self.caret(editor, at: 7)
    h.press(.return)
    XCTAssertEqual(editor.document.string, "    a {\n    ")
  }

  // MARK: - Gutter

  func testProblemsDrawADotByTheirLineNumber() {
    let (h, editor) = self.harness("ok\nbad\nok") { _ = $0.lineNumbers() }
    h.step()
    let before = h.snapshot()
    editor.setDiagnostics([TextDiagnostic(3 ..< 6, .error, "no")], h.context)
    h.step()
    let after = h.snapshot()
    // Something new is drawn in the gutter on the second line, and nowhere on the first.
    let gutter = editor.gutter
    let lineHeight = editor.layout.rowHeight
    let row = { (line: Float) in gutter.position.y + editor.theme.textInset.y + lineHeight * (line + 0.5) }
    func differs(atY y: Float) -> Bool {
      (Int(gutter.position.x) ..< Int(gutter.position.x + 12)).contains { x in
        pixel(before, x, Int(y)) != pixel(after, x, Int(y))
      }
    }
    XCTAssertTrue(differs(atY: row(1)))
    XCTAssertFalse(differs(atY: row(0)))
  }
}

/// The pixel at point `x`, `y` of `image`, drawn at 2 pixels per point.
private func pixel(_ image: CGImage, _ x: Int, _ y: Int) -> [UInt8] {
  let data = image.dataProvider!.data! as Data
  let offset = (y * 2) * image.bytesPerRow + (x * 2) * (image.bitsPerPixel / 8)
  return Array(data[offset ..< offset + 4])
}
