@testable import Demo
@testable import MetalGraphicsLib
import simd
import XCTest

// The Console demo, typed into as a user would.
final class ConsoleDemoE2ETests: AppTestCase {
  private var editor: TextEditor { self.main.first(TextEditor.self)! }

  override func setUp() {
    super.setUp()
    try! self.main.tap("Console")
    // Focus it, at the prompt.
    let editor = self.editor
    self.main.click(at: editor.scrollView.position + editor.scrollView.size - float2(20, 20))
  }

  private var lines: [String] {
    self.editor.document.string.components(separatedBy: "\n")
  }

  func testReturnRunsTheLine() {
    self.main.type("echo hello\n")
    XCTAssertEqual(Array(self.lines.suffix(3)), ["› echo hello", "hello", "› "])
    self.main.type("nope\n")
    XCTAssertTrue(self.lines.contains("nope: command not found"))
  }

  func testTheHistoryIsReadOnlyButTypingThereGoesToThePrompt() {
    self.main.type("echo one\n")
    let editor = self.editor
    let before = editor.document.string
    // A click in the history, then typing: it lands at the prompt.
    let caret = editor.layout.caretRect(3, affinity: .downstream)
    self.main.click(at: editor.content.textOrigin + float2(caret.x, Float(caret.top) + caret.height * 0.5))
    self.main.type("x")
    XCTAssertEqual(editor.document.string, before + "x")
    // Deleting there is refused.
    self.main.click(at: editor.content.textOrigin + float2(caret.x, Float(caret.top) + caret.height * 0.5))
    self.main.press(.delete)
    XCTAssertEqual(editor.document.string, before + "x")
    // Undo takes back the typing at the prompt, and never the history.
    self.main.press("z", modifiers: .command)
    self.main.press("z", modifiers: .command)
    XCTAssertEqual(editor.document.string, before)
  }

  func testHistoryCanBeCopied() {
    self.main.type("echo copied\n")
    let editor = self.editor
    let line = editor.document.lineCount - 2
    editor.state.setSelection(EditorSelection(SelectionRange(anchor: editor.document.lineStart(line), head: editor.document.lineRange(line).upperBound)))
    self.main.press("c", modifiers: .command)
    self.app.step()
    XCTAssertEqual(self.app.pasteboard, "copied")
  }

  func testUpAndDownRecall() {
    self.main.type("echo first\n")
    self.main.type("echo second\n")
    self.main.type("draft")
    self.main.press(.upArrow)
    XCTAssertEqual(self.lines.last, "› echo second")
    self.main.press(.upArrow)
    XCTAssertEqual(self.lines.last, "› echo first")
    self.main.press(.downArrow)
    self.main.press(.downArrow)
    XCTAssertEqual(self.lines.last, "› draft")
  }

  func testAHundredThousandLinesFollowTheTail() {
    self.main.type("count 100000\n")
    let editor = self.editor
    XCTAssertGreaterThan(editor.document.lineCount, 100_000)
    XCTAssertEqual(editor.content.visible.last?.line, editor.document.lineCount - 1)
    XCTAssertEqual(self.lines.last, "› ")
    XCTAssertLessThan(editor.layout.shapedCount, 400)
    self.main.type("echo still quick\n")
    XCTAssertEqual(self.lines.suffix(2).first, "still quick")
    XCTAssertEqual(editor.content.visible.last?.line, editor.document.lineCount - 1)
    XCTAssertNotNil(self.app.settle(maxFrames: 200))
  }

  func testLooksRight() {
    self.main.type("echo hello, console\n")
    self.main.type("error something failed\n")
    self.main.type("count 3\n")
    XCTAssertNotNil(self.app.settle())
    assertSnapshot(self.main.snapshot(), named: "console-demo", testCase: self)
  }
}
