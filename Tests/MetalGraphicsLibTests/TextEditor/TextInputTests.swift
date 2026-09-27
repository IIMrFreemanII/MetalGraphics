@testable import MetalGraphicsLib
import AppKit
import simd
import XCTest

@MainActor
final class EditorWakeTests: XCTestCase {
  private func focusedEditor(_ text: String = "blink") -> (UIHarness, TextEditor) {
    let editor = TextEditor(document: TextDocument(text))
    let h = UIHarness { editor }
    h.click(on: editor.focusable)
    return (h, editor)
  }

  func testWakeFiresAtItsTimeWithoutKeepingFramesBusy() {
    final class Target: WakeTarget {
      var fired: [Double] = []
      func wake(_ context: UIContext, now: Double) { self.fired.append(now) }
    }
    let target = Target()
    let h = UIHarness { Rectangle(.blue) }
    XCTAssertNotNil(h.settle())
    h.context.requestWake(at: h.now + 0.25, for: target)
    XCTAssertTrue(h.context.isIdle)
    XCTAssertEqual(h.context.nextWakeTime, h.now + 0.25)
    h.step(frames: 10)
    XCTAssertTrue(target.fired.isEmpty)
    h.advance(0.2)
    XCTAssertEqual(target.fired.count, 1)
    XCTAssertNil(h.context.nextWakeTime)
  }

  func testCaretBlinksOnlyAtItsEdgesThenStops() {
    let (h, editor) = self.focusedEditor()
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(editor.caretVisible)
    let renders = h.renders
    // Half a second later it turns off, with one frame drawn, and back on after another half.
    h.advance(0.5)
    XCTAssertFalse(editor.caretVisible)
    XCTAssertEqual(h.renders, renders + 1)
    h.advance(0.5)
    XCTAssertTrue(editor.caretVisible)
    XCTAssertEqual(h.renders, renders + 2)
    // A minute after the last input it stays on, and nothing more is drawn.
    h.advance(61)
    XCTAssertTrue(editor.caretVisible)
    XCTAssertNil(h.context.nextWakeTime)
    let settled = h.renders
    h.advance(5)
    XCTAssertEqual(h.renders, settled)
  }

  func testTypingKeepsTheCaretSolid() {
    let (h, editor) = self.focusedEditor()
    for _ in 0 ..< 6 {
      h.advance(0.3)
      h.type("x")
      XCTAssertTrue(editor.caretVisible)
    }
  }

  func testBlurredEditorDoesNotBlink() {
    let (h, editor) = self.focusedEditor()
    h.context.focus(nil)
    h.step()
    XCTAssertNil(h.context.nextWakeTime)
    XCTAssertFalse(editor.isFocused)
  }

  func testDragHeldBelowTheTextScrollsAndSelects() {
    let text = (1 ... 200).map { "line \($0)" }.joined(separator: "\n")
    let editor = TextEditor(document: TextDocument(text))
    let h = UIHarness { editor }
    let start = editor.content.textOrigin + float2(2, 4)
    h.mouseDown(at: start)
    h.mouseDrag(to: float2(100, 300))   // below the window
    let offset = editor.scrollView.offset.y
    h.advance(0.5)
    XCTAssertGreaterThan(editor.scrollView.offset.y, offset + 100)
    XCTAssertGreaterThan(editor.state.selection.primary.upperBound, 200)
    h.mouseUp(at: float2(100, 300))
    let stopped = editor.scrollView.offset.y
    h.advance(0.5)
    XCTAssertEqual(editor.scrollView.offset.y, stopped)
  }
}

@MainActor
final class TextInputTests: XCTestCase {
  private func focusedEditor(_ text: String, caret: Int) -> (UIHarness, TextEditor) {
    let editor = TextEditor(document: TextDocument(text))
    let h = UIHarness { editor }
    h.click(on: editor.focusable)
    editor.state.setSelection(.caret(caret))
    h.step()
    return (h, editor)
  }

  func testCompositionIsMarkedThenCommitted() {
    let (h, editor) = self.focusedEditor("ab", caret: 1)
    h.compose("k")
    h.compose("か")
    h.compose("かな")
    XCTAssertEqual(editor.document.string, "aかなb")
    XCTAssertEqual(editor.state.markedRange, 1 ..< 3)
    let snapshot = h.context.textInputSnapshot()
    XCTAssertTrue(snapshot.isActive)
    XCTAssertEqual(snapshot.marked, NSRange(location: 1, length: 2))
    XCTAssertEqual(snapshot.selection, NSRange(location: 3, length: 0))
    h.commit("仮名")
    XCTAssertEqual(editor.document.string, "a仮名b")
    XCTAssertNil(editor.state.markedRange)
    h.press("z", characters: "z", modifiers: .command)
    XCTAssertEqual(editor.document.string, "ab")
  }

  func testMarkedTextIsUnderlined() {
    let (h, editor) = self.focusedEditor("", caret: 0)
    h.compose("にほんご", selected: NSRange(location: 0, length: 2))
    XCTAssertNotNil(h.settle())
    assertSnapshot(h.snapshot(), named: "marked-text", testCase: self)
    _ = editor
  }

  func testKeysCarryingInputMethodActions() {
    let (h, editor) = self.focusedEditor("hello", caret: 5)
    // As the view sends them: the key, and what the input method made of it.
    func key(_ actions: [TextInputAction]) {
      h.input.keyPresses.append(KeyPress(
        key: "\0", characters: "", modifiers: [], phase: .down, keyCode: nil, pasteboard: nil, textInput: actions
      ))
      h.step()
    }
    key([.setMarked("´", selected: NSRange(location: 1, length: 0), replacement: nil)])
    XCTAssertEqual(editor.document.string, "hello´")
    key([.insert("é", replacement: nil)])
    XCTAssertEqual(editor.document.string, "helloé")
    key([.command("moveToBeginningOfDocument:")])
    XCTAssertEqual(editor.state.selection.primary.head, 0)
    key([.command("insertNewline:")])
    XCTAssertEqual(editor.document.string, "\nhelloé")
    key([])   // kept by the input method
    XCTAssertEqual(editor.document.string, "\nhelloé")
  }

  func testAReplacementRangeFromAnOlderRevisionIsMapped() {
    let (h, editor) = self.focusedEditor("abc", caret: 3)
    let revision = editor.document.revision
    editor.document.replace(0 ..< 0, with: "12")
    h.step()
    // The accent menu replacing the "c" it saw at 2 ..< 3.
    h.input.textInputs.append(.insert("ç", replacement: NSRange(location: 2, length: 1)))
    h.input.textInputRevision = revision
    h.step()
    XCTAssertEqual(editor.document.string, "12abç")
  }

  func testComposingInReadOnlyTextEndsTheComposition() {
    let (h, editor) = self.focusedEditor("locked", caret: 3)
    editor.document.readOnly.add(0 ..< 6, ())
    h.compose("k")
    XCTAssertEqual(editor.document.string, "locked")
    XCTAssertNil(h.context.textInputSnapshot().marked)
  }

  func testOutputArrivingWhileComposingKeepsTheComposition() {
    let (h, editor) = self.focusedEditor("› ", caret: 2)
    h.compose("にほ")
    editor.document.insert("output\n", at: 0)
    h.step()
    XCTAssertEqual(editor.state.markedRange, 9 ..< 11)
    XCTAssertEqual(h.context.textInputSnapshot().marked, NSRange(location: 9, length: 2))
    h.commit("日本")
    XCTAssertEqual(editor.document.string, "output\n› 日本")
  }

  func testLosingFocusCommitsTheComposition() {
    let (h, editor) = self.focusedEditor("", caret: 0)
    h.compose("abc")
    h.context.focus(nil)
    h.step()
    XCTAssertNil(editor.state.markedRange)
    XCTAssertEqual(editor.document.string, "abc")
    XCTAssertFalse(h.context.textInputSnapshot().isActive)
  }

  func testSnapshotPredictionMatchesTheEditor() {
    let (h, editor) = self.focusedEditor("hello world", caret: 5)
    var predicted = h.context.textInputSnapshot()
    let actions: [TextInputAction] = [
      .setMarked("x", selected: NSRange(location: 1, length: 0), replacement: nil),
      .setMarked("xyz", selected: NSRange(location: 1, length: 1), replacement: nil),
      .insert("XYZ", replacement: nil),
      .insert("!", replacement: nil),
    ]
    for action in actions {
      predicted = predicted.applying(action)
      h.input.textInputs.append(action)
      h.step()
      let actual = h.context.textInputSnapshot()
      XCTAssertEqual(predicted.selection, actual.selection, "\(action)")
      XCTAssertEqual(predicted.marked, actual.marked, "\(action)")
      XCTAssertEqual(predicted.length, actual.length, "\(action)")
      XCTAssertEqual(predicted.substring(NSRange(location: 0, length: 20))?.0, actual.substring(NSRange(location: 0, length: 20))?.0)
    }
    XCTAssertEqual(editor.document.string, "helloXYZ! world")
  }

  func testTextFieldComposesThenCommits() {
    var name = "a"
    let field = TextField("Name", text: Binding(get: { name }, set: { name = $0 }))
    let h = UIHarness { field }
    h.click(on: h.first(FocusableElement.self)!)
    h.press(.end)
    h.compose("k")
    h.compose("か")
    XCTAssertEqual(name, "a")
    XCTAssertEqual(h.context.textInputSnapshot().text, "aか")
    XCTAssertEqual(h.context.textInputSnapshot().marked, NSRange(location: 1, length: 1))
    h.commit("化")
    XCTAssertEqual(name, "a化")
    XCTAssertNil(h.context.textInputSnapshot().marked)
    // A command from the input method works as its key does.
    h.input.textInputs.append(.command("deleteBackward:"))
    h.step()
    XCTAssertEqual(name, "a")
  }
}
