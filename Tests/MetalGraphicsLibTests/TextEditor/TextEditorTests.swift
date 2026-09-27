@testable import MetalGraphicsLib
import AppKit
import simd
import XCTest

@MainActor
final class TextEditorTests: XCTestCase {
  private func harness(_ text: String, size: float2 = float2(320, 240), configure: (TextEditor) -> Void = { _ in })
    -> (UIHarness, TextEditor) {
    let editor = TextEditor(document: TextDocument(text))
    configure(editor)
    let h = UIHarness(size: size) { editor }
    return (h, editor)
  }

  /// Where the caret at `offset` is drawn, in the window: the middle of its row.
  private func point(of offset: Int, _ editor: TextEditor) -> float2 {
    let caret = editor.layout.caretRect(offset, affinity: .downstream)
    return editor.content.textOrigin + float2(caret.x, Float(caret.top) + caret.height * 0.5)
  }

  private func click(_ h: UIHarness, _ editor: TextEditor, at offset: Int, count: Int = 1) {
    h.click(at: self.point(of: offset, editor), count: count)
  }

  func testAControllerSelectsRevealsAndFocusesFromCode() {
    let text = (0 ..< 300).map { "line \($0)" }.joined(separator: "\n")
    let controller = EditorController()
    let (h, editor) = self.harness(text) { _ = $0.controller(controller) }
    XCTAssertTrue(controller.editor === editor)

    controller.goTo(line: 200, column: 2)
    h.step()
    let head = editor.state.selection.primary.head
    XCTAssertEqual(editor.document.position(of: head).line, 200)
    XCTAssertEqual(editor.document.position(of: head).column, 2)
    // Centred: lines on both sides of it show.
    let lines = editor.content.visible.map(\.line)
    XCTAssertLessThan(try XCTUnwrap(lines.first), 197)
    XCTAssertGreaterThan(try XCTUnwrap(lines.last), 203)

    let range = editor.document.lineRange(3)
    controller.select(range)
    h.step()
    XCTAssertEqual(editor.state.selectedText, "line 3")
    XCTAssertTrue(editor.content.visible.contains { $0.line == 3 })

    XCTAssertFalse(editor.isFocused)
    controller.focus()
    h.step()
    XCTAssertTrue(editor.isFocused)
    // Past the end, clamped.
    controller.select(0 ..< 1_000_000, reveal: .none)
    XCTAssertEqual(editor.state.selection.primary.range, 0 ..< editor.document.length)
  }

  func testListenersHearEachChangeSetBeforeAndAfter() {
    final class Recorder: TextDocumentListener {
      var events: [String] = []
      func document(_ document: TextDocument, willApply changes: ChangeSet, origin: EditOrigin) {
        self.events.append("will \(document.revision) \(document.string) \(changes.changes.count)")
      }
      func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin) {
        self.events.append("did \(document.revision) \(document.string)")
      }
    }
    let document = TextDocument("abc")
    let recorder = Recorder()
    document.addListener(recorder)
    document.apply(ChangeSet([TextChange(range: 0 ..< 1, with: "X"), TextChange(range: 2 ..< 3, with: "Z")]), origin: .user)
    XCTAssertEqual(recorder.events, ["will 0 abc 2", "did 1 XbZ"])
    document.removeListener(recorder)
    document.replace(0 ..< 1, with: "Y")
    XCTAssertEqual(recorder.events.count, 2)
  }

  func testClickFocusesAndTypingEdits() {
    let (h, editor) = self.harness("hello world")
    self.click(h, editor, at: 5)
    XCTAssertTrue(editor.isFocused)
    XCTAssertEqual(editor.state.selection.primary.head, 5)
    h.type(", there")
    XCTAssertEqual(editor.document.string, "hello, there world")
    h.press(.delete)
    h.press(.delete, modifiers: .option)
    XCTAssertEqual(editor.document.string, "hello,  world")
    // Undo takes back the word, then the character, then the typing.
    h.press("z", characters: "z", modifiers: .command)
    XCTAssertEqual(editor.document.string, "hello, ther world")
    h.press("z", characters: "z", modifiers: .command)
    XCTAssertEqual(editor.document.string, "hello, there world")
    h.press("z", characters: "z", modifiers: .command)
    XCTAssertEqual(editor.document.string, "hello world")
  }

  func testArrowsAndShiftSelect() {
    let (h, editor) = self.harness("one two\nthree")
    self.click(h, editor, at: 0)
    h.press(.rightArrow, modifiers: [.option, .shift])
    XCTAssertEqual(editor.state.selectedText, "one")
    h.press(.downArrow)
    XCTAssertEqual(editor.document.position(of: editor.state.selection.primary.head).line, 1)
    h.press(.leftArrow, modifiers: .command)
    XCTAssertEqual(editor.state.selection.primary.head, 8)
    h.press(.upArrow, modifiers: [.command, .shift])
    XCTAssertEqual(editor.state.selection.primary.range, 0 ..< 8)
  }

  func testDoubleAndTripleClickSelectWordAndLine() {
    let (h, editor) = self.harness("alpha beta gamma\nsecond")
    let at = self.point(of: 8, editor)
    h.click(at: at, count: 1)
    h.click(at: at, count: 2)
    XCTAssertEqual(editor.state.selectedText, "beta")
    h.click(at: at, count: 3)
    XCTAssertEqual(editor.state.selectedText, "alpha beta gamma\n")
  }

  func testDragSelects() {
    let (h, editor) = self.harness("drag across these words")
    h.drag(from: self.point(of: 5, editor), to: self.point(of: 11, editor))
    XCTAssertEqual(editor.state.selectedText, "across")
  }

  func testCopyCutAndPaste() {
    let saved = Pasteboard.write
    copiedBox.value = []
    Pasteboard.write = { text in copiedBox.value.append(text) }
    defer { Pasteboard.write = saved }
    let (h, editor) = self.harness("copy me")
    self.click(h, editor, at: 0)
    h.press("a", characters: "a", modifiers: .command)
    h.press("c", characters: "c", modifiers: .command)
    XCTAssertEqual(copiedBox.value, ["copy me"])
    h.press(.rightArrow)
    h.input.keyPresses.append(KeyPress(key: "v", characters: "v", modifiers: .command, phase: .down, keyCode: nil, pasteboard: "!"))
    h.step()
    XCTAssertEqual(editor.document.string, "copy me!")
  }

  func testLargeDocumentShapesOnlyWhatIsInView() {
    let text = (1 ... 100_000).map { "line \($0) of a long document" }.joined(separator: "\n")
    let (h, editor) = self.harness(text) { $0.lineNumbers(true) }
    XCTAssertLessThan(editor.layout.shapedCount, 40)
    XCTAssertGreaterThan(editor.scrollView.contentSize.y, 1_000_000)
    h.scroll(by: float2(0, -50_000), at: float2(160, 120))
    XCTAssertLessThan(editor.layout.shapedCount, 80)
    XCTAssertGreaterThan(editor.content.visible.first!.line, 1000)
    // To the end: only the last screenful is shaped.
    self.click(h, editor, at: editor.document.lineStart(editor.content.visible.first!.line + 1))
    h.press(.downArrow, modifiers: .command)
    XCTAssertEqual(editor.state.selection.primary.head, editor.document.length)
    XCTAssertEqual(editor.content.visible.last!.line, 99_999)
    XCTAssertLessThan(editor.layout.shapedCount, 120)
  }

  func testTypingNeverLaysOutTheTree() {
    let (h, editor) = self.harness("a\nb\nc")
    self.click(h, editor, at: 1)
    XCTAssertNotNil(h.settle())
    let passes = h.context.layoutPasses
    let height = editor.scrollView.contentSize.y
    h.type("xyz")
    h.press(.return)
    h.press(.return)
    XCTAssertEqual(editor.document.string, "axyz\n\n\nb\nc")
    XCTAssertEqual(h.context.layoutPasses, passes)
    XCTAssertGreaterThan(editor.scrollView.contentSize.y, height)
  }

  func testCaretStaysInViewWhileTyping() {
    let (h, editor) = self.harness("")
    self.click(h, editor, at: 0)
    for _ in 0 ..< 40 { h.press(.return) }
    let caret = self.point(of: editor.state.selection.primary.head, editor)
    XCTAssertGreaterThan(editor.scrollView.offset.y, 0)
    XCTAssertLessThan(caret.y, editor.scrollView.position.y + editor.scrollView.size.y)
  }

  func testIdleEditorDrawsNothing() {
    let (h, editor) = self.harness("still")
    _ = editor
    XCTAssertNotNil(h.settle())
    let renders = h.renders
    h.step(frames: 30)
    XCTAssertEqual(h.renders, renders)
  }

  func testStringBindingReportsOncePerFrameAndIgnoresItsEcho() {
    var text = "abc"
    var reports = 0
    let editor = TextEditor(text: Binding(get: { text }, set: { text = $0; reports += 1 }))
    let h = UIHarness { editor }
    h.click(at: self.point(of: 3, editor))
    h.type("d")
    XCTAssertEqual(text, "abcd")
    XCTAssertEqual(reports, 1)
    editor.setText("replaced", h.context)
    XCTAssertEqual(editor.document.string, "replaced")
  }

  func testLooksRight() {
    let (h, editor) = self.harness("func greet(name: String) {\n  print(\"Hello, \\(name)!\")\n}\n\nlet x = 42", size: float2(320, 140)) {
      $0.lineNumbers(true)
    }
    self.click(h, editor, at: 29)
    h.press(.rightArrow, modifiers: [.shift, .option])
    XCTAssertNotNil(h.settle())
    assertSnapshot(h.snapshot(), named: "plain-selection-gutter", testCase: self)
  }
  func testLayoutAskedForAfterLayoutIsDrawn() {
    // A change made by `afterLayout` work is laid out on the next frame, and drawn then too.
    let text = Text("before")
    let h = UIHarness { text }
    XCTAssertNotNil(h.settle())
    h.context.afterLayout { text.setText("after, and longer", h.context) }
    h.context.invalidate(.render)
    XCTAssertNotNil(h.settle())
    let settled = h.targetPixels()
    h.context.invalidate(.render)
    h.step()
    XCTAssertTrue(settled == h.targetPixels(), "what settled is not what the tree draws")
  }

  func testSelectionChangeIsReportedAfterAClick() {
    var reported: [Int] = []
    let editor = TextEditor(document: TextDocument("one\ntwo\nthree")).onSelectionChange { reported.append($0.primary.head) }
    let h = UIHarness { editor }
    h.click(at: self.point(of: 5, editor))
    XCTAssertEqual(reported.last, 5)
  }
}

/// What a test's `Pasteboard.write` replacement copied.
private final class CopiedBox: @unchecked Sendable {
  var value: [String] = []
}

private let copiedBox = CopiedBox()
