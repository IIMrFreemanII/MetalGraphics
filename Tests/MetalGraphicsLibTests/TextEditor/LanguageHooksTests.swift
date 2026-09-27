@testable import MetalGraphicsLib
import AppKit
import simd
import XCTest

// What a language's features build on: the caret's place for a list by it, a hover that waits
// for the pointer to rest, and ⌘-click.
@MainActor
final class LanguageHooksTests: XCTestCase {
  private func harness(_ text: String = "let greeting = 1\nprint(greeting)") -> (UIHarness, TextEditor) {
    let editor = TextEditor(document: TextDocument(text)).lineNumbers()
    let h = UIHarness(size: float2(360, 200)) { editor.padding(20) }
    h.step()
    return (h, editor)
  }

  func testTheCaretRectIsInTheEditorsOwnCoordinates() throws {
    let (_, editor) = self.harness()
    XCTAssertEqual(editor.origin, float2(20, 20))
    XCTAssertEqual(editor.bounds, float2(320, 160))
    let first = try XCTUnwrap(editor.caretRect(for: 0))
    let second = try XCTUnwrap(editor.caretRect(for: 17))  // line 2's start
    XCTAssertEqual(first.origin.x, second.origin.x, accuracy: 0.5)
    XCTAssertEqual(second.origin.y - first.origin.y, editor.layout.rowHeight, accuracy: 0.5)
    XCTAssertGreaterThan(first.origin.x, editor.gutter.size.x, "past the gutter")
    XCTAssertEqual(first.height, editor.layout.rowHeight, accuracy: 0.5)
    // And back.
    XCTAssertEqual(editor.offset(atLocal: second.origin + float2(1, second.height * 0.5)), 17)
  }

  func testAHoverIsReportedOnceThePointerRests() throws {
    let (h, editor) = self.harness()
    var reports: [Int?] = []
    editor.onTextHover = { offset, _ in reports.append(offset) }
    let over = try XCTUnwrap(editor.caretRect(for: 20))
    let point = editor.origin + over.origin + float2(3, over.height * 0.5)
    h.move(to: point)
    h.advance(0.3)
    XCTAssertEqual(reports, [], "not yet")
    h.advance(0.3)
    XCTAssertEqual(reports, [20])
    // Moving on ends it, and starts waiting again.
    h.move(to: point + float2(0, -editor.layout.rowHeight))
    XCTAssertEqual(reports, [20, nil])
    h.advance(0.6)
    XCTAssertEqual(reports.count, 3)
    h.mouseExit()
    XCTAssertEqual(reports.last, .some(nil))
    XCTAssertNotNil(h.settle(), "no wake left once it ended")
  }

  func testNothingIsReportedPastTheEndOfALine() throws {
    let (h, editor) = self.harness()
    var reports: [Int?] = []
    editor.onTextHover = { offset, _ in reports.append(offset) }
    let end = try XCTUnwrap(editor.caretRect(for: 16))
    h.move(to: editor.origin + end.origin + float2(120, end.height * 0.5))
    h.advance(0.6)
    XCTAssertEqual(reports, [])
  }

  func testCommandClickReportsTheOffsetInsteadOfMovingTheCaret() throws {
    let (h, editor) = self.harness()
    var clicked: [Int] = []
    editor.onCommandClick = { clicked.append($0) }
    editor.select(0 ..< 0, reveal: .none)
    let target = try XCTUnwrap(editor.caretRect(for: 24))
    let point = editor.origin + target.origin + float2(2, target.height * 0.5)
    h.input.commandPressed = true
    h.click(at: point)
    h.input.commandPressed = false
    XCTAssertEqual(clicked, [24])
    XCTAssertEqual(editor.state.selection.primary.head, 0)
    h.click(at: point)
    XCTAssertEqual(editor.state.selection.primary.head, 24)
    XCTAssertEqual(clicked, [24])
  }
}
