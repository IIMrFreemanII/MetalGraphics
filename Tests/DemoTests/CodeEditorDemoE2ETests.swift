@testable import Demo
@testable import MetalGraphicsLib
import simd
import XCTest

// The Code Editor demo, driven as a user would: typing, the status line, wrap, search,
// diagnostics, and a hundred thousand lines.
final class CodeEditorDemoE2ETests: AppTestCase {
  private var editor: TextEditor { self.main.first(TextEditor.self)! }

  override func setUp() {
    super.setUp()
    try! self.main.tap("Code Editor")
  }

  /// Clicks the start of `line`, focusing the editor there.
  private func click(line: Int) {
    let editor = self.editor
    let caret = editor.layout.caretRect(editor.document.lineStart(line), affinity: .downstream)
    self.main.click(at: editor.content.textOrigin + float2(caret.x + 1, Float(caret.top) + caret.height * 0.5))
  }

  func testAClickUpdatesTheStatusLine() throws {
    self.click(line: 8)
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.main.shownTexts.contains { $0.hasPrefix("Ln 9, Col 1") }, "\(self.main.shownTexts.suffix(2))")
    try self.main.tap("Mark TODOs")
    self.click(line: 9)
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.main.shownTexts.contains { $0.hasPrefix("Ln 10, Col 1") }, "\(self.main.shownTexts.suffix(2))")
  }

  func testStatusAfterMarkingThenClicking() throws {
    try self.main.tap("Mark TODOs")
    let editor = self.editor
    XCTAssertNotNil(editor.onSelectionChange)
    self.click(line: 8)
    XCTAssertEqual(editor.document.position(of: editor.state.selection.primary.head).line, 8)
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.main.shownTexts.contains { $0.hasPrefix("Ln 9, Col 1") }, "\(self.main.shownTexts.suffix(2))")
  }

  func testTypingUpdatesTheStatusLine() throws {
    self.click(line: 2)
    self.main.type("abc")
    XCTAssertTrue(self.editor.document.lineText(2).hasPrefix("abc"))
    XCTAssertTrue(self.main.shownTexts.contains { $0.hasPrefix("Ln 3, Col 4") })
  }

  func testWrapFitsLongLinesToTheWidth() throws {
    self.click(line: 0)
    self.main.type(String(repeating: "wrapped words ", count: 30))
    XCTAssertGreaterThan(self.editor.scrollView.contentSize.x, self.editor.scrollView.size.x)
    try self.main.toggle("Wrap")
    XCTAssertEqual(self.editor.lineWrapping, .soft)
    XCTAssertLessThanOrEqual(self.editor.scrollView.contentSize.x, self.editor.scrollView.size.x + 0.5)
    XCTAssertGreaterThan(self.editor.layout.layout(0).fragmentCount, 1)
  }

  func testSearchHighlightsAndTodosAreMarked() throws {
    try self.main.type("shape", into: "Find")
    XCTAssertGreaterThan(self.editor.searchMatches.count, 3)
    try self.main.tap("Mark TODOs")
    XCTAssertEqual(self.editor.document.diagnostics.marks.count, 2)
  }

  func testAHundredThousandLinesScrollToTheEnd() throws {
    try self.main.tap("Load 100k lines")
    XCTAssertGreaterThan(self.editor.document.lineCount, 100_000)
    self.click(line: 0)
    self.main.press(.downArrow, modifiers: .command)
    XCTAssertEqual(self.editor.state.selection.primary.head, self.editor.document.length)
    XCTAssertEqual(self.editor.content.visible.last?.line, self.editor.document.lineCount - 1)
    XCTAssertLessThan(self.editor.layout.shapedCount, 400)
    self.main.type("x")
    XCTAssertTrue(self.editor.document.string.hasSuffix("x"))
    XCTAssertNotNil(self.app.settle(maxFrames: 200))
  }

  func testLooksRight() throws {
    try self.main.tap("Mark TODOs")
    self.click(line: 8)
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.main.shownTexts.contains { $0.hasPrefix("Ln 9, Col 1") }, "\(self.main.shownTexts.suffix(2))")
    assertSnapshot(self.main.snapshot(), named: "code-editor-demo", testCase: self)
  }
}
