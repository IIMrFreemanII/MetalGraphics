@testable import MetalGraphicsLib
import simd
import XCTest

final class MarkdownStylerTests: XCTestCase {
  private func style(_ lines: [String]) -> [[String: TextToken]] {
    let styler = MarkdownStyler()
    var state = StyleState.initial
    return lines.map { line in
      let units = Array(line.utf16)
      var spans: [TextSpan] = []
      state = units.withUnsafeBufferPointer { styler.styleLine($0, state: state, into: &spans) }
      var tokens: [String: TextToken] = [:]
      for span in spans {
        tokens[String(decoding: units[Int(span.start) ..< Int(span.end)], as: UTF16.self)] = span.token
      }
      return tokens
    }
  }

  func testHeadingsListsAndQuotes() {
    let result = self.style(["## Title", "- item", "3. third", "> quoted", "---"])
    XCTAssertEqual(result[0]["##"], .markup)
    XCTAssertEqual(result[0][" Title"], .heading2)
    XCTAssertEqual(result[1]["-"], .listMarker)
    XCTAssertEqual(result[2]["3."], .listMarker)
    XCTAssertEqual(result[3][" quoted"], .quote)
    XCTAssertEqual(result[4]["---"], .markup)
  }

  func testInlineStyles() {
    let tokens = self.style(["a **b** *c* ~~d~~ `e` [f](g)"])[0]
    XCTAssertEqual(tokens["b"], .strong)
    XCTAssertEqual(tokens["c"], .emphasis)
    XCTAssertEqual(tokens["d"], .strikethrough)
    XCTAssertEqual(tokens["`e`"], .code)
    XCTAssertEqual(tokens["f"], .link)
    XCTAssertEqual(tokens["](g)"], .markup)
  }

  func testSwiftFencesAreHighlightedAcrossLines() {
    let result = self.style(["```swift", "let x = \"\"\"", "not code", "\"\"\"", "```", "# after"])
    XCTAssertEqual(result[1]["let"], .keyword)
    XCTAssertEqual(result[2]["not code"], .string)
    XCTAssertEqual(result[4]["```"], .markup)
    XCTAssertEqual(result[5][" after"], .heading1)
  }

  func testImagesAreBlocks() {
    let units = Array("See ![a cat](cat) and ![a dog](dog)".utf16)
    var blocks: [BlockDecoration] = []
    units.withUnsafeBufferPointer { MarkdownStyler().blocks($0, state: .initial, into: &blocks) }
    XCTAssertEqual(blocks.map(\.source), ["cat", "dog"])
  }
}

/// Makes a tappable box for each attachment, and counts what it made.
final class BoxAttachments: TextAttachmentProvider {
  var made = 0
  var taps: [TextAttachmentID] = []

  func makeElement(for id: TextAttachmentID, source: String?) -> UIElement {
    self.made += 1
    return Rectangle(float4(0.9, 0.5, 0.1, 1)).onTap { [unowned self] _ in self.taps.append(id) }
  }

  func size(for id: TextAttachmentID, source: String?, maxWidth: Float) -> float2 {
    source == nil ? float2(30, 14) : float2(min(maxWidth, 120), 60)
  }
}

@MainActor
final class EditorAttachmentTests: XCTestCase {
  func testInlineAttachmentTakesSpaceAndIsTappable() {
    let provider = BoxAttachments()
    let editor = TextEditor(document: TextDocument("before  after")).attachmentProvider(provider)
    let h = UIHarness { editor }
    h.click(on: editor.focusable)
    editor.state.setSelection(.caret(7))
    h.step()
    XCTAssertTrue(editor.insertAttachment(TextAttachmentID(1)))
    h.step()
    XCTAssertEqual(editor.document.string, "before \u{FFFC} after")
    XCTAssertEqual(editor.content.attachments.children.count, 1)
    let box = editor.content.attachments.children[0]
    XCTAssertEqual(box.getSize(), float2(30, 14))
    // The text after it moved right by its width.
    let after = editor.layout.caretRect(9, affinity: .downstream).x - editor.layout.caretRect(7, affinity: .downstream).x
    XCTAssertGreaterThanOrEqual(after, 30)
    // A click on it reaches it, not the editor.
    let placed = editor.content.visible[0].layout.attachments[0]
    h.click(at: editor.content.textOrigin + placed.origin + placed.size * 0.5)
    XCTAssertEqual(provider.taps, [TextAttachmentID(1)])
    // Deleting its character removes it.
    editor.state.setSelection(.caret(8))
    h.press(.delete)
    XCTAssertEqual(editor.content.attachments.children.count, 0)
    XCTAssertTrue(editor.document.attachments.isEmpty)
  }

  func testBlocksShowBelowTheirLinesAndMountOnlyInView() {
    let provider = BoxAttachments()
    var text = ""
    for i in 0 ..< 40 { text += i % 10 == 0 ? "![img](pic\(i))\n" : "line \(i)\n" }
    let editor = TextEditor(document: TextDocument(text)).styler(MarkdownStyler()).attachmentProvider(provider)
    let h = UIHarness { editor }
    XCTAssertNotNil(h.settle())
    let first = editor.layout.layout(0)
    XCTAssertEqual(first.attachments.count, 1)
    XCTAssertGreaterThan(first.height, 60)
    // Two images in view of 240 points; the rest are not built.
    XCTAssertLessThanOrEqual(editor.content.attachments.children.count, 3)
    XCTAssertLessThanOrEqual(provider.made, 3)
    let orders = h.context.hitGridRebuilds
    h.scroll(by: float2(0, -3000), at: float2(160, 120))
    XCTAssertTrue(editor.content.attachments.children.allSatisfy(\.mounted))
    XCTAssertGreaterThan(h.context.hitGridRebuilds, orders)
    XCTAssertLessThanOrEqual(editor.content.attachments.children.count, 3)
  }
}

@MainActor
final class SoftWrapTests: XCTestCase {
  private static let long = (1 ... 40).map { "word\($0)" }.joined(separator: " ")

  func testLongLinesWrapAndTheCaretMovesByScreenLines() {
    let editor = TextEditor(document: TextDocument(Self.long + "\nshort")).lineWrapping(.soft)
    let h = UIHarness(size: float2(300, 240)) { editor }
    h.click(on: editor.focusable)
    let layout = editor.layout.layout(0)
    XCTAssertGreaterThan(layout.fragmentCount, 3)
    XCTAssertLessThanOrEqual(editor.scrollView.contentSize.x, editor.scrollView.size.x + 0.5)
    editor.state.setSelection(.caret(0))
    h.press(.downArrow)
    // One screen line down: the start of the second fragment, still on the first line.
    XCTAssertEqual(editor.document.line(containing: editor.state.selection.primary.head), 0)
    XCTAssertEqual(Int32(editor.state.selection.primary.head), layout.fragmentStarts[1])
    // ⌘→ goes to the end of that screen line, and stays drawn there.
    h.press(.rightArrow, modifiers: .command)
    XCTAssertEqual(Int32(editor.state.selection.primary.head), layout.fragmentStarts[2])
    XCTAssertEqual(editor.state.selection.primary.affinity, .upstream)
    let caret = editor.layout.caretRect(editor.state.selection.primary.head, affinity: .upstream)
    XCTAssertEqual(caret.top, Double(layout.rowTops[1]), accuracy: 0.5)
  }

  func testWiderEditorsWrapLess() {
    func fragments(_ width: Float) -> Int {
      let editor = TextEditor(document: TextDocument(Self.long)).lineWrapping(.soft)
      _ = UIHarness(size: float2(width, 240)) { editor }
      return editor.layout.layout(0).fragmentCount
    }
    XCTAssertLessThan(fragments(600), fragments(300))
  }

  func testMixedSizesMakeTallerLines() {
    let editor = TextEditor(document: TextDocument("# Big\nsmall")).styler(MarkdownStyler())
    let h = UIHarness { editor }
    XCTAssertNotNil(h.settle())
    XCTAssertGreaterThan(editor.layout.layout(0).height, editor.layout.layout(1).height * 1.4)
    assertSnapshot(h.snapshot(), named: "markdown-heading", testCase: self)
  }
}
