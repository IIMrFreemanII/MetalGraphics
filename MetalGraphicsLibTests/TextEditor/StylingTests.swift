@testable import MetalGraphicsLib
import simd
import XCTest

final class SwiftStylerTests: XCTestCase {
  private func tokens(_ line: String, _ state: StyleState = .initial) -> ([String: TextToken], StyleState) {
    let units = Array(line.utf16)
    var spans: [TextSpan] = []
    let end = units.withUnsafeBufferPointer { SwiftStyler().styleLine($0, state: state, into: &spans) }
    var result: [String: TextToken] = [:]
    for span in spans {
      let text = String(decoding: units[Int(span.start) ..< Int(span.end)], as: UTF16.self)
      result[text] = span.token
    }
    return (result, end)
  }

  func testKeywordsTypesCallsAndLiterals() {
    let (tokens, state) = self.tokens("let view: TextEditor = make(42, \"hi\") // done")
    XCTAssertEqual(tokens["let"], .keyword)
    XCTAssertEqual(tokens["TextEditor"], .type)
    XCTAssertEqual(tokens["make"], .function)
    XCTAssertEqual(tokens["42"], .number)
    XCTAssertEqual(tokens["\"hi\""], .string)
    XCTAssertEqual(tokens["// done"], .comment)
    XCTAssertNil(tokens["view"])
    XCTAssertEqual(state, .initial)
  }

  func testInterpolationIsCode() {
    let (tokens, _) = self.tokens("print(\"n = \\(count + 1)!\")")
    XCTAssertEqual(tokens["1"], .number)
    XCTAssertEqual(tokens["\"n = \\("], .string)
    XCTAssertEqual(tokens[")!\""], .string)
  }

  func testBlockCommentsNestAcrossLines() {
    let (first, open) = self.tokens("x /* one /* two")
    XCTAssertEqual(first["/* one /* two"], .comment)
    let (second, still) = self.tokens("*/ three", open)
    XCTAssertEqual(second["*/ three"], .comment)
    let (third, closed) = self.tokens("*/ let y", still)
    XCTAssertEqual(third["*/"], .comment)
    XCTAssertEqual(third["let"], .keyword)
    XCTAssertEqual(closed, .initial)
  }

  func testMultilineAndRawStrings() {
    let (first, open) = self.tokens("let s = \"\"\"")
    XCTAssertEqual(first["\"\"\""], .string)
    let (second, _) = self.tokens("  body \\(x) \"quoted\"", open)
    XCTAssertEqual(second["x"], nil)
    let (third, closed) = self.tokens("  \"\"\"", open)
    XCTAssertEqual(third["  \"\"\""], .string)
    XCTAssertEqual(closed, .initial)
    let (raw, _) = self.tokens("#\"a \"quoted\" b\"#")
    XCTAssertEqual(raw["#\"a \"quoted\" b\"#"], .string)
  }

  func testAttributesAndDirectives() {
    let (tokens, _) = self.tokens("@MainActor #if DEBUG")
    XCTAssertEqual(tokens["@MainActor"], .attribute)
    XCTAssertEqual(tokens["#if"], .directive)
  }
}

/// Counts the lines it styles.
final class CountingStyler: TextStyler {
  let inner = SwiftStyler()
  var count = 0
  var lineComment: String? { "//" }

  func styleLine(_ text: UnsafeBufferPointer<UInt16>, state: StyleState, into spans: inout [TextSpan]) -> StyleState {
    self.count += 1
    return self.inner.styleLine(text, state: state, into: &spans)
  }
}

@MainActor
final class EditorStylingTests: XCTestCase {
  private static let source = (1 ... 60).map { "func f\($0)() { let x = \($0) }" }.joined(separator: "\n")

  private func harness(_ text: String = EditorStylingTests.source, size: float2 = float2(320, 240)) -> (UIHarness, TextEditor, CountingStyler) {
    let styler = CountingStyler()
    let editor = TextEditor(document: TextDocument(text)).styler(styler)
    let h = UIHarness(size: size) { editor }
    return (h, editor, styler)
  }

  private func token(at offset: Int, _ editor: TextEditor) -> TextToken {
    let line = editor.document.line(containing: offset)
    let column = Int32(offset - editor.document.lineStart(line))
    let layout = editor.layout.layout(line)
    for run in layout.runs where run.start <= column && column < run.end {
      if run.paint.text == editor.theme[.comment]?.foreground { return .comment }
      if run.paint.text == editor.theme[.keyword]?.foreground { return .keyword }
      if run.paint.text == editor.theme[.number]?.foreground { return .number }
    }
    return .plain
  }

  func testTypingInALineRestylesOnlyThatLine() {
    let (h, editor, styler) = self.harness()
    h.click(on: editor.focusable)
    editor.state.setSelection(.caret(editor.document.lineRange(3).upperBound - 2))
    XCTAssertNotNil(h.settle())
    let before = styler.count
    h.type("y")
    // Its end state, then its tokens when it is shaped again.
    XCTAssertLessThanOrEqual(styler.count - before, 3)
  }

  func testOpeningACommentRestylesTheLinesBelowAndClosingItRestoresThem() {
    let (h, editor, _) = self.harness()
    h.click(on: editor.focusable)
    let third = editor.document.lineStart(2)
    XCTAssertEqual(self.token(at: third, editor), .keyword)
    editor.state.setSelection(.caret(editor.document.lineStart(1)))
    h.type("/*")
    XCTAssertEqual(self.token(at: editor.document.lineStart(2), editor), .comment)
    XCTAssertEqual(self.token(at: editor.document.lineStart(8), editor), .comment)
    h.press(.delete)
    h.press(.delete)
    XCTAssertEqual(self.token(at: editor.document.lineStart(2), editor), .keyword)
    XCTAssertEqual(self.token(at: editor.document.lineStart(8), editor), .keyword)
  }

  func testFarLinesAreStyledProvisionallyThenInTheBackground() {
    let text = "/*\n" + (1 ... 20_000).map { "let v\($0) = \($0)" }.joined(separator: "\n") + "\n*/"
    let (h, editor, _) = self.harness(text)
    h.click(on: editor.focusable)
    h.press(.downArrow, modifiers: .command)
    // Past the frontier: styled as if nothing were open.
    let last = editor.content.visible.last!.line
    XCTAssertLessThan(editor.styling.frontier, last - 1000)
    XCTAssertEqual(self.token(at: editor.document.lineStart(last - 2), editor), .keyword)
    // Background styling reaches it, finds it inside the comment, and redraws it.
    h.step(frames: 10)
    XCTAssertFalse(editor.styling.needsBackgroundWork)
    XCTAssertEqual(self.token(at: editor.document.lineStart(last - 2), editor), .comment)
    XCTAssertNotNil(h.settle())
  }

  func testSearchAndDiagnosticsAreDrawnOverTokens() {
    let text = "let total = count + count\n// TODO: tidy up\nreturn count"
    let editor = TextEditor(document: TextDocument(text)).styler(SwiftStyler()).lineNumbers(true)
    let h = UIHarness(size: float2(320, 100)) { editor }
    editor.setSearchQuery("count", h.context)
    editor.setDiagnostics([TextDiagnostic(29 ..< 33, .warning), TextDiagnostic(4 ..< 9, .error)], h.context)
    XCTAssertEqual(editor.searchMatches.count, 3)
    XCTAssertNotNil(h.settle())
    assertSnapshot(h.snapshot(), named: "search-diagnostics", testCase: self)
    // Diagnostics move with the text.
    editor.document.replace(0 ..< 0, with: "  ")
    XCTAssertEqual(editor.document.diagnostics.marks.map(\.range), [6 ..< 11, 31 ..< 35])
  }

  func testHighlightedCodeLooksRight() {
    let text = """
    @MainActor
    struct Point: Hashable {
      /* a comment */ var x = 1.5
      func moved(by d: Int) -> Self { .init(x: x + Double(d)) }
    }
    let s = "sum \\(1 + 2)"
    """
    let editor = TextEditor(document: TextDocument(text)).styler(SwiftStyler()).lineNumbers(true)
    let h = UIHarness(size: float2(360, 130)) { editor }
    XCTAssertNotNil(h.settle())
    assertSnapshot(h.snapshot(), named: "swift-highlighting", testCase: self)
  }

  func testDenseCodeStaysWellUnderThePerCellShapeLimit() {
    // 10 pt monospaced code, 120 columns, every line full, a search matching often.
    let line = String(repeating: "let a = b + c; ", count: 8)
    let editor = TextEditor(document: TextDocument((1 ... 80).map { _ in line }.joined(separator: "\n")))
      .styler(SwiftStyler()).lineNumbers(true)
    editor.setSearchQuery("a", UIContext())
    let h = UIHarness(size: float2(500, 500)) { editor.font(.system(size: 10, design: .monospaced)) }
    h.click(on: editor.focusable)
    h.press("a", characters: "a", modifiers: .command)
    XCTAssertNotNil(h.settle())
    XCTAssertGreaterThan(h.graphics.grid.maxShapesPerCell, 20)
    XCTAssertLessThan(h.graphics.grid.maxShapesPerCell, 160)
  }
}
