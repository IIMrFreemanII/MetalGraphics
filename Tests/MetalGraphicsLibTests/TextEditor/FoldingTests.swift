@testable import MetalGraphicsLib
import AppKit
import simd
import XCTest

// Folding: lines hidden after a range's first, skipped by drawing and the caret, shown again by
// the chevron, the "⋯", an edit inside or the caret reaching in.
@MainActor
final class FoldingTests: XCTestCase {
  /// Lines "0 {" … : a block from line 1 to line 5, another inside from 2 to 4.
  private let text = "top\nfunc f() {\n  if x {\n    a\n  }\n}\nbottom"
  private var outer: Range<Int> { 13 ..< 35 }   // "{" on line 1 … "}" on line 5
  private var inner: Range<Int> { 22 ..< 33 }   // "{" on line 2 … "}" on line 4

  private func harness(_ text: String? = nil) -> (UIHarness, TextEditor) {
    let editor = TextEditor(document: TextDocument(text ?? self.text)).lineNumbers()
    let h = UIHarness(size: float2(360, 240)) { editor }
    h.click(on: editor.focusable)
    return (h, editor)
  }

  private func shownLines(_ editor: TextEditor) -> [Int] {
    editor.content.visible.map(\.line)
  }

  func testTheRangesAreWhatTheTextSays() {
    let units = Array(self.text.utf16)
    XCTAssertEqual(String(decoding: units[self.outer], as: UTF16.self), "{\n  if x {\n    a\n  }\n}")
    XCTAssertEqual(String(decoding: units[self.inner], as: UTF16.self), "{\n    a\n  }")
  }

  func testFoldingHidesTheLinesAfterTheFirst() {
    let (h, editor) = self.harness()
    let height = editor.layout.totalHeight
    XCTAssertTrue(editor.fold(self.outer))
    h.step()
    XCTAssertEqual(self.shownLines(editor), [0, 1, 6])
    XCTAssertEqual(editor.layout.totalHeight, height - 4 * Double(editor.layout.rowHeight), accuracy: 0.5)
    XCTAssertNotNil(editor.foldMarkerRect(forLine: 1))
    XCTAssertFalse(editor.fold(self.outer), "folded already")
    XCTAssertFalse(editor.fold(0 ..< 3), "one line: nothing to fold")

    XCTAssertTrue(editor.unfold(at: self.outer.lowerBound))
    h.step()
    XCTAssertEqual(self.shownLines(editor), Array(0 ... 6))
    XCTAssertEqual(editor.layout.totalHeight, height, accuracy: 0.5)
  }

  func testTheCaretSkipsFoldedLines() {
    let (h, editor) = self.harness()
    editor.fold(self.outer)
    editor.select(1 ..< 1, reveal: .none)
    h.press(.downArrow)
    h.press(.downArrow)
    XCTAssertEqual(editor.document.line(containing: editor.state.selection.primary.head), 6)
    h.press(.upArrow)
    XCTAssertEqual(editor.document.line(containing: editor.state.selection.primary.head), 1)
    XCTAssertEqual(editor.foldedRanges, [self.outer], "moving over it leaves it folded")
  }

  func testACaretInsideMovesOutAndOneReachingInUnfolds() {
    let (h, editor) = self.harness()
    editor.select(26 ..< 26, reveal: .none)  // on line 3
    editor.fold(self.outer)
    XCTAssertEqual(editor.state.selection.primary.head, editor.document.lineRange(1).upperBound)
    editor.select(26 ..< 26, reveal: .none)
    h.step()
    XCTAssertEqual(editor.foldedRanges, [])
    XCTAssertEqual(self.shownLines(editor), Array(0 ... 6))
  }

  func testAnEditInsideUnfoldsAndOneOutsideMovesTheFold() {
    let (h, editor) = self.harness()
    editor.fold(self.inner)
    editor.select(0 ..< 0, reveal: .none)
    h.type("// ")
    XCTAssertEqual(editor.foldedRanges, [self.inner.lowerBound + 3 ..< self.inner.upperBound + 3])
    XCTAssertEqual(editor.foldingRanges, [], "none offered")
    editor.document.replace(28 ..< 29, with: "b", origin: .user)
    XCTAssertEqual(editor.foldedRanges, [])
    h.step()
    XCTAssertEqual(self.shownLines(editor), Array(0 ... 6))
  }

  func testNestedFoldsStayFoldedWhenTheOuterOneOpens() {
    let (h, editor) = self.harness()
    editor.fold(self.inner)
    editor.fold(self.outer)
    h.step()
    XCTAssertEqual(self.shownLines(editor), [0, 1, 6])
    editor.unfold(at: self.outer.lowerBound)
    h.step()
    XCTAssertEqual(self.shownLines(editor), [0, 1, 2, 5, 6])
  }

  func testTheGutterChevronFoldsAndUnfolds() {
    let (h, editor) = self.harness()
    h.step()
    editor.setFoldingRanges([self.outer, self.inner], h.context)
    h.step()
    XCTAssertEqual(editor.foldState(ofLine: 1), false)
    XCTAssertNil(editor.foldState(ofLine: 3))
    let gutter = editor.gutter
    let y = editor.content.textOrigin.y + Float(editor.layout.lineTop(1)) + editor.layout.rowHeight * 0.5
    let chevron = float2(gutter.position.x + gutter.size.x - FoldingTestsSupport.foldColumn * 0.5, y)
    h.click(at: chevron)
    XCTAssertEqual(editor.foldedRanges, [self.outer])
    XCTAssertEqual(editor.foldState(ofLine: 1), true)
    h.click(at: chevron)
    XCTAssertEqual(editor.foldedRanges, [])
  }

  func testAClickOnTheMarkerUnfolds() {
    let (h, editor) = self.harness()
    editor.fold(self.outer)
    h.step()
    let marker = try! XCTUnwrap(editor.foldMarkerRect(forLine: 1))
    h.click(at: (marker.min + marker.max) * 0.5)
    XCTAssertEqual(editor.foldedRanges, [])
  }

  func testFoldAtTheCaretPicksTheInnermostRange() {
    let (h, editor) = self.harness()
    h.step()
    editor.setFoldingRanges([self.outer, self.inner], h.context)
    editor.select(26 ..< 26, reveal: .none)
    XCTAssertTrue(editor.foldAtCaret())
    XCTAssertEqual(editor.foldedRanges, [self.inner])
    XCTAssertTrue(editor.foldAtCaret())
    XCTAssertEqual(Set(editor.foldedRanges), [self.inner, self.outer])
    editor.unfoldAll()
    XCTAssertEqual(editor.foldedRanges, [])
  }

  func testOptionCommandArrowsFoldAndUnfoldAndPlainArrowsStillMove() {
    let (h, editor) = self.harness()
    h.step()
    editor.setFoldingRanges([self.outer, self.inner], h.context)
    editor.select(26 ..< 26, reveal: .none)
    h.press(.leftArrow)
    XCTAssertEqual(editor.state.selection.primary.head, 25)
    h.press(.leftArrow, modifiers: [.command, .option])
    XCTAssertEqual(editor.foldedRanges, [self.inner])
    h.press(.rightArrow, modifiers: [.command, .option])
    XCTAssertEqual(editor.foldedRanges, [])
    h.press(.leftArrow, modifiers: .command)
    XCTAssertEqual(editor.foldedRanges, [])
  }

  func testFoldingAHugeRangeIsQuickAndTypingAfterItStaysQuick() {
    let text = "struct Big {\n" + String(repeating: "  let x = 1\n", count: 100_000) + "}\n"
    let (h, editor) = self.harness(text)
    let range = 11 ..< text.utf16.count - 1
    let start = Date()
    XCTAssertTrue(editor.fold(range))
    h.step()
    XCTAssertLessThan(Date().timeIntervalSince(start), 0.5)
    XCTAssertEqual(self.shownLines(editor), [0, 100_002])
    editor.select(editor.document.length ..< editor.document.length, reveal: .none)
    let typing = Date()
    h.type("abc")
    XCTAssertLessThan(Date().timeIntervalSince(typing), 0.5)
    XCTAssertEqual(editor.foldedRanges.count, 1)
    XCTAssertNotNil(h.settle(), "idle again")
  }
}

/// The gutter's chevron column, as the tests reach it.
@MainActor
enum FoldingTestsSupport {
  static let foldColumn = EditorGutterView.foldColumn
}
