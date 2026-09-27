@testable import MetalGraphicsLib
import simd
import XCTest

// The Markdown demo: styled as written, wrapped, an image below its line, chips inserted at
// the caret that take taps of their own.
final class MarkdownDemoE2ETests: AppTestCase {
  private var editor: TextEditor { self.main.first(TextEditor.self)! }

  override func setUp() {
    super.setUp()
    try! self.main.tap("Markdown")
  }

  func testLinesWrapAndHeadingsAreLarger() {
    let editor = self.editor
    XCTAssertEqual(editor.lineWrapping, .soft)
    XCTAssertLessThanOrEqual(editor.scrollView.contentSize.x, editor.scrollView.size.x + 0.5)
    XCTAssertGreaterThan(editor.layout.layout(2).fragmentCount, 1)
    XCTAssertGreaterThan(editor.layout.layout(0).height, editor.layout.layout(2).height / Float(editor.layout.layout(2).fragmentCount) * 1.4)
  }

  func testAChipGoesInAtTheCaretAndTakesTaps() throws {
    let editor = self.editor
    let caret = editor.layout.caretRect(6, affinity: .downstream)
    self.main.click(at: editor.content.textOrigin + float2(caret.x, Float(caret.top) + caret.height * 0.5))
    try self.main.tap("Insert chip")
    XCTAssertEqual(editor.document.attachments.marks.count, 1)
    XCTAssertTrue(self.main.shows("Chip 1 · 0"))
    try self.main.tap("Chip 1 · 0")
    XCTAssertTrue(self.main.shows("Chip 1 · 1"))
  }

  func testLooksRight() throws {
    XCTAssertNotNil(self.app.settle())
    assertSnapshot(self.main.snapshot(), named: "markdown-demo", testCase: self)
  }
}
