@testable import MetalGraphicsLib
import XCTest

final class GapBufferTests: XCTestCase {
  func testRandomEditsMatchAnArray() {
    var generator = SystemRandomNumberGenerator()
    let buffer = GapBuffer(Array("hello world".utf16))
    var model = Array("hello world".utf16)
    for _ in 0 ..< 2000 {
      let a = Int.random(in: 0 ... model.count, using: &generator)
      let b = Int.random(in: a ... min(model.count, a + 8), using: &generator)
      let text = (0 ..< Int.random(in: 0 ... 12, using: &generator)).map { _ in UInt16.random(in: 0x61 ... 0x7A) }
      buffer.replace(a ..< b, with: text)
      model.replaceSubrange(a ..< b, with: text)
      XCTAssertEqual(buffer.count, model.count)
      let lo = Int.random(in: 0 ... model.count, using: &generator)
      let hi = Int.random(in: lo ... model.count, using: &generator)
      XCTAssertEqual(buffer.units(in: lo ..< hi), Array(model[lo ..< hi]))
    }
    XCTAssertEqual(buffer.units(in: 0 ..< buffer.count), model)
  }
}

final class LineTreeTests: XCTestCase {
  private func tree(_ lengths: [Int32]) -> LineTree {
    LineTree(lengths: lengths, heights: lengths.map { Float($0 % 3 + 10) },
             records: lengths.indices.map { LineRecord(id: UInt32($0)) })
  }

  func testRandomSplicesMatchArrays() {
    var lengths: [Int32] = (0 ..< 3000).map { _ in Int32.random(in: 1 ... 80) }
    var heights: [Float] = lengths.map { Float($0 % 3 + 10) }
    let tree = self.tree(lengths)
    for step in 0 ..< 400 {
      let a = Int.random(in: 0 ..< lengths.count)
      let b = Int.random(in: a ... min(lengths.count, a + (step % 7 == 0 ? 1500 : 5)))
      let inserted = (0 ..< Int.random(in: (b == a ? 1 : 0) ... 700)).map { _ in Int32.random(in: 1 ... 80) }
      guard lengths.count - (b - a) + inserted.count > 0 else { continue }
      let newHeights = inserted.map { Float($0 % 5 + 12) }
      tree.replaceLines(a ..< b, lengths: inserted, heights: newHeights,
                        records: inserted.map { _ in LineRecord(id: 0) })
      lengths.replaceSubrange(a ..< b, with: inserted)
      heights.replaceSubrange(a ..< b, with: newHeights)
      XCTAssertEqual(tree.lineCount, lengths.count)
      XCTAssertEqual(tree.length, lengths.reduce(0) { $0 + Int($1) })
      // Probe a few lines.
      for _ in 0 ..< 5 {
        let line = Int.random(in: 0 ..< lengths.count)
        let start = lengths[..<line].reduce(0) { $0 + Int($1) }
        XCTAssertEqual(tree.start(of: line), start)
        XCTAssertEqual(tree.line(containing: start), line)
        XCTAssertEqual(tree.line(containing: start + Int(lengths[line]) - 1), line)
        let top = heights[..<line].reduce(0.0) { $0 + Double($1) }
        XCTAssertEqual(tree.top(of: line), top, accuracy: 0.01)
        XCTAssertEqual(tree.line(atY: top + 0.5), line)
      }
    }
  }

  func testHeightsAndLengthsAdjustInPlace() {
    let tree = self.tree([5, 5, 5, 0])
    tree.adjustLength(of: 1, by: 3)
    XCTAssertEqual(tree.start(of: 2), 13)
    XCTAssertEqual(tree.setHeight(30, of: 0), 18)
    XCTAssertEqual(tree.top(of: 1), 30)
    XCTAssertEqual(tree.line(containing: 18), 3)
    XCTAssertEqual(tree.line(atY: 1e9), 3)
  }

  func testHundredThousandLinesQueryFast() {
    let tree = self.tree(Array(repeating: 40, count: 100_000))
    measure {
      for i in 0 ..< 1_000 {
        let line = (i * 7919) % 100_000
        tree.adjustLength(of: line, by: 1)
        _ = tree.line(containing: line * 40)
        _ = tree.top(of: line)
      }
    }
  }
}

final class ChangeSetTests: XCTestCase {
  func testMappingAroundAChange() {
    let set = ChangeSet(TextChange(range: 5 ..< 8, with: "abcd"))
    XCTAssertEqual(set.map(2), 2)
    XCTAssertEqual(set.map(5), 5)
    XCTAssertEqual(set.map(6, .before), 5)
    XCTAssertEqual(set.map(6, .after), 9)
    XCTAssertEqual(set.map(8), 9)
    XCTAssertEqual(set.map(10), 11)
    let insertion = ChangeSet(TextChange(range: 3 ..< 3, with: "xy"))
    XCTAssertEqual(insertion.map(3, .before), 3)
    XCTAssertEqual(insertion.map(3, .after), 5)
    XCTAssertEqual(insertion.map(0 ..< 3), 0 ..< 3)
    XCTAssertEqual(insertion.map(3 ..< 6), 5 ..< 8)
  }

  func testSeveralChangesInvert() {
    let document = TextDocument("one two three")
    let set = ChangeSet([TextChange(range: 8 ..< 13, with: "3"), TextChange(range: 0 ..< 3, with: "1")])
    let (_, inverse) = document.apply(set, origin: .program)
    XCTAssertEqual(document.string, "1 two 3")
    document.apply(inverse, origin: .program)
    XCTAssertEqual(document.string, "one two three")
  }
}

final class TextDocumentTests: XCTestCase {
  func testLinesFollowEdits() {
    let document = TextDocument("alpha\nbeta\ngamma")
    XCTAssertEqual(document.lineCount, 3)
    XCTAssertEqual(document.lineText(1), "beta")
    document.replace(8 ..< 8, with: "X\nY")
    XCTAssertEqual(document.string, "alpha\nbeX\nYta\ngamma")
    XCTAssertEqual(document.lineCount, 4)
    XCTAssertEqual(document.lineText(2), "Yta")
    document.replace(3 ..< 12, with: "")
    XCTAssertEqual(document.string, "alpa\ngamma")
    XCTAssertEqual(document.lineCount, 2)
    XCTAssertEqual(document.position(of: 8).line, 1)
    XCTAssertEqual(document.position(of: 8).column, 3)
  }

  func testLineEndingsAreNormalized() {
    let document = TextDocument("a\r\nb\rc")
    XCTAssertEqual(document.string, "a\nb\nc")
    XCTAssertEqual(document.lineEnding, .crlf)
    XCTAssertEqual(document.stringWithOriginalLineEndings, "a\r\nb\r\nc")
    document.replace(1 ..< 1, with: "\r\n")
    XCTAssertEqual(document.lineCount, 4)
  }

  func testEmptyDocumentHasOneLine() {
    let document = TextDocument()
    XCTAssertEqual(document.lineCount, 1)
    XCTAssertEqual(document.lineRange(0), 0 ..< 0)
    document.append("x\n")
    XCTAssertEqual(document.lineCount, 2)
    document.replace(0 ..< 2, with: "")
    XCTAssertEqual(document.lineCount, 1)
  }

  func testLineIDsChangeOnlyForEditedLines() {
    let document = TextDocument("a\nb\nc")
    let ids = (0 ..< 3).map(document.lineID)
    document.replace(2 ..< 2, with: "x")
    XCTAssertEqual(document.lineID(0), ids[0])
    XCTAssertNotEqual(document.lineID(1), ids[1])
    XCTAssertEqual(document.lineID(2), ids[2])
    document.replace(0 ..< 0, with: "new\n")
    XCTAssertEqual(document.lineID(3), ids[2])
  }

  func testStoredSpansMoveWithEdits() {
    let document = TextDocument()
    document.append("error: bad\n", token: .error)
    document.append("fine", token: .output)
    XCTAssertEqual(document.spans(ofLine: 0), [TextSpan(start: 0, end: 11, token: .error)])
    XCTAssertEqual(document.spans(ofLine: 1), [TextSpan(start: 0, end: 4, token: .output)])
    document.replace(0 ..< 0, with: ">> ")
    XCTAssertEqual(document.spans(ofLine: 0), [TextSpan(start: 3, end: 14, token: .error)])
    // Joining the lines keeps both runs, the second moved to follow the first.
    document.replace(13 ..< 14, with: "")
    XCTAssertEqual(document.spans(ofLine: 0), [TextSpan(start: 3, end: 13, token: .error), TextSpan(start: 13, end: 17, token: .output)])
  }

  func testMarksMoveAndReadOnlyRefusesEdits() {
    let document = TextDocument("history\n> ")
    let id = document.readOnly.add(0 ..< 8, ())
    let state = EditorState(document: document)
    state.setSelection(.caret(3))
    XCTAssertFalse(state.apply(EditorTransaction(changes: ChangeSet(TextChange(range: 3 ..< 3, with: "x")))))
    XCTAssertTrue(state.apply(EditorTransaction(changes: ChangeSet(TextChange(range: 8 ..< 8, with: "y")))))
    XCTAssertEqual(document.string, "history\ny> ")
    document.insert("out\n", at: 8)
    XCTAssertEqual(document.readOnly.mark(id)?.range, 0 ..< 8)
    document.readOnly.setRange(0 ..< 12, of: id)
    XCTAssertFalse(state.canEdit(9 ..< 10))
    XCTAssertTrue(state.canEdit(12 ..< 13))
  }

  func testMapOffsetFromAnOlderRevision() {
    let document = TextDocument("abcdef")
    let revision = document.revision
    document.replace(0 ..< 0, with: "12")
    document.replace(8 ..< 8, with: "!")
    XCTAssertEqual(document.mapOffset(3, fromRevision: revision), 5)
    for _ in 0 ..< 70 { document.append(".") }
    XCTAssertNil(document.mapOffset(3, fromRevision: revision))
  }

  func testComposedCharactersAreNotSplit() {
    // e + combining acute, a flag (two regional indicators), a family emoji (ZWJ sequence).
    let text = "e\u{301}🇺🇦👨‍👩‍👧x"
    let document = TextDocument(text)
    var stops = [0]
    while stops.last! < document.length {
      stops.append(TextBoundaries.next(after: stops.last!, in: document))
    }
    XCTAssertEqual(stops.count, 5)   // 4 characters
    var back = [document.length]
    while back.last! > 0 { back.append(TextBoundaries.previous(before: back.last!, in: document)) }
    XCTAssertEqual(back.reversed(), stops)
    XCTAssertEqual(TextBoundaries.snap(1, in: document), 0)
  }

  func testWordMotion() {
    let document = TextDocument("let fooBar = baz_qux(1)")
    XCTAssertEqual(TextBoundaries.wordEnd(after: 0, in: document), 3)
    XCTAssertEqual(TextBoundaries.wordEnd(after: 3, in: document), 10)
    XCTAssertEqual(TextBoundaries.wordStart(before: 10, in: document), 4)
    XCTAssertEqual(TextBoundaries.subwordEnd(after: 4, in: document), 7)
    XCTAssertEqual(TextBoundaries.word(at: 15, in: document), 13 ..< 20)
  }
}

/// A monospace grid: every character is 1 wide, lines never wrap.
final class GridLayout: TextLayoutQueries {
  let document: TextDocument
  init(_ document: TextDocument) { self.document = document }

  func verticalMove(from offset: Int, affinity: TextAffinity, goalX: Float?, lines: Int)
    -> (offset: Int, affinity: TextAffinity, goalX: Float) {
    let (line, column) = self.document.position(of: offset)
    let goal = goalX ?? Float(column)
    let target = line + lines
    if target < 0 { return (0, .downstream, goal) }
    if target >= self.document.lineCount { return (self.document.length, .downstream, goal) }
    return (self.document.offset(line: target, column: Int(goal)), .downstream, goal)
  }

  func visualLineBoundary(of offset: Int, affinity: TextAffinity, forward: Bool) -> (offset: Int, affinity: TextAffinity) {
    let range = self.document.lineRange(self.document.line(containing: offset))
    return (forward ? range.upperBound : range.lowerBound, .downstream)
  }

  var linesPerPage: Int { 10 }
}

final class EditorStateTests: XCTestCase {
  private var now: Double = 0

  private func state(_ text: String, caret: Int? = nil) -> (EditorState, GridLayout) {
    let document = TextDocument(text)
    let state = EditorState(document: document)
    state.clock = { [unowned self] in self.now }
    state.setSelection(.caret(caret ?? document.length))
    return (state, GridLayout(document))
  }

  private func type(_ text: String, _ state: EditorState) {
    for character in text {
      state.perform(.insertText(String(character)), layout: nil)
      self.now += 0.1
    }
  }

  func testTypingAndDeletingUndoAsRuns() {
    let (state, layout) = self.state("")
    self.type("hello world", state)
    XCTAssertEqual(state.document.string, "hello world")
    state.perform(.delete(.character, forward: false), layout: layout)
    state.perform(.delete(.character, forward: false), layout: layout)
    XCTAssertEqual(state.document.string, "hello wor")
    state.perform(.undo, layout: layout)
    XCTAssertEqual(state.document.string, "hello world")
    state.perform(.undo, layout: layout)
    XCTAssertEqual(state.document.string, "")
    state.perform(.redo, layout: layout)
    XCTAssertEqual(state.document.string, "hello world")
    XCTAssertEqual(state.selection.primary.head, 11)
  }

  func testAPauseOrAMoveStartsANewStep() {
    let (state, layout) = self.state("")
    self.type("ab", state)
    self.now += 5
    self.type("cd", state)
    state.perform(.move(.character, forward: false, extend: false), layout: layout)
    state.perform(.move(.character, forward: true, extend: false), layout: layout)
    self.type("ef", state)
    state.perform(.undo, layout: layout)
    XCTAssertEqual(state.document.string, "abcd")
    state.perform(.undo, layout: layout)
    XCTAssertEqual(state.document.string, "ab")
  }

  func testMovesAndSelections() {
    let (state, layout) = self.state("one two\nthree\nfour", caret: 0)
    state.perform(.move(.word, forward: true, extend: true), layout: layout)
    XCTAssertEqual(state.selectedText, "one")
    state.perform(.move(.visualLine, forward: true, extend: false), layout: layout)
    XCTAssertEqual(state.document.position(of: state.selection.primary.head).line, 1)
    XCTAssertEqual(state.document.position(of: state.selection.primary.head).column, 3)
    state.perform(.move(.visualLine, forward: true, extend: false), layout: layout)
    state.perform(.move(.visualLine, forward: true, extend: false), layout: layout)
    XCTAssertEqual(state.selection.primary.head, state.document.length)
    state.perform(.move(.lineBoundary, forward: false, extend: false), layout: layout)
    XCTAssertEqual(state.selection.primary.head, 14)
    state.perform(.selectLine, layout: layout)
    XCTAssertEqual(state.selectedText, "four")
    state.perform(.selectAll, layout: layout)
    XCTAssertEqual(state.selection.primary.range, 0 ..< state.document.length)
  }

  func testNewlineKeepsIndentationAndTabIndents() {
    let (state, layout) = self.state("    let x")
    state.perform(.insertNewline, layout: layout)
    XCTAssertEqual(state.document.string, "    let x\n    ")
    state.perform(.insertTab, layout: layout)
    XCTAssertEqual(state.document.string, "    let x\n        ")
    state.perform(.selectAll, layout: layout)
    state.perform(.outdent, layout: layout)
    XCTAssertEqual(state.document.string, "let x\n    ")
    state.perform(.indent, layout: layout)
    XCTAssertEqual(state.document.string, "    let x\n        ")
  }

  func testToggleComment() {
    let (state, layout) = self.state("a\n  b\n\nc", caret: 0)
    state.lineComment = "//"
    state.perform(.selectAll, layout: layout)
    state.perform(.toggleComment, layout: layout)
    XCTAssertEqual(state.document.string, "// a\n//   b\n\n// c")
    state.perform(.toggleComment, layout: layout)
    XCTAssertEqual(state.document.string, "a\n  b\n\nc")
  }

  func testKillAndYank() {
    let (state, layout) = self.state("abc def\nxyz", caret: 4)
    state.perform(.delete(.paragraphBoundary, forward: true), layout: layout)
    XCTAssertEqual(state.document.string, "abc \nxyz")
    state.perform(.move(.document, forward: true, extend: false), layout: layout)
    state.perform(.yank, layout: layout)
    XCTAssertEqual(state.document.string, "abc \nxyzdef")
  }

  func testMultipleCursorsTypeAndPasteLines() {
    let (state, layout) = self.state("a\nb\nc")
    state.setSelection(EditorSelection([.caret(1), .caret(3), .caret(5)]))
    state.perform(.insertText("!"), layout: layout)
    XCTAssertEqual(state.document.string, "a!\nb!\nc!")
    state.perform(.paste("1\n2\n3"), layout: layout)
    XCTAssertEqual(state.document.string, "a!1\nb!2\nc!3")
    state.perform(.undo, layout: layout)
    state.perform(.undo, layout: layout)
    XCTAssertEqual(state.document.string, "a\nb\nc")
  }

  func testProgramEditsKeepUndoValid() {
    let (state, layout) = self.state("> ", caret: 2)
    self.type("ls", state)
    // Output appended after everything typed leaves the history alone; a caret where it is
    // inserted goes after it.
    state.document.append("\nout")
    XCTAssertEqual(state.selection.primary.head, 8)
    state.perform(.undo, layout: layout)
    XCTAssertEqual(state.document.string, "> \nout")
    // Inserted before it, the history shifts.
    state.perform(.redo, layout: layout)
    state.document.insert("top\n", at: 0)
    state.perform(.undo, layout: layout)
    XCTAssertEqual(state.document.string, "top\n> \nout")
  }

  func testFilterRedirectsTyping() {
    let (state, layout) = self.state("history\n> ", caret: 2)
    state.document.readOnly.add(0 ..< 8, ())
    state.filter = { transaction, state in
      // Typing into the history goes to the end instead.
      guard transaction.changes.changes.contains(where: { !state.canEdit($0.range) }) else { return true }
      let end = state.document.length
      let text = transaction.changes.changes.flatMap(\.text)
      transaction.changes = ChangeSet(TextChange(range: end ..< end, text: text))
      transaction.selection = .caret(end + text.count)
      return true
    }
    state.perform(.insertText("x"), layout: layout)
    XCTAssertEqual(state.document.string, "history\n> x")
    XCTAssertEqual(state.selection.primary.head, 11)
  }

  func testComposingIsCommittedAsOneStep() {
    let (state, layout) = self.state("ab", caret: 1)
    state.setMarkedText("k", selected: 1 ..< 1)
    state.setMarkedText("か", selected: 1 ..< 1)
    state.setMarkedText("かな", selected: 2 ..< 2)
    XCTAssertEqual(state.document.string, "aかなb")
    XCTAssertEqual(state.markedRange, 1 ..< 3)
    state.commitText("仮名")
    XCTAssertEqual(state.document.string, "a仮名b")
    XCTAssertNil(state.markedRange)
    XCTAssertEqual(state.selection.primary.head, 3)
    state.perform(.undo, layout: layout)
    XCTAssertEqual(state.document.string, "ab")
    XCTAssertEqual(state.selection.primary.head, 1)
  }

  func testComposingOverASelectionRestoresItOnUndo() {
    let (state, layout) = self.state("hello")
    state.setSelection(EditorSelection(SelectionRange(anchor: 0, head: 5)))
    state.setMarkedText("´", selected: 1 ..< 1)
    state.commitText("é")
    XCTAssertEqual(state.document.string, "é")
    state.perform(.undo, layout: layout)
    state.perform(.undo, layout: layout)
    XCTAssertEqual(state.document.string, "hello")
  }

  func testComposingInReadOnlyTextIsRefused() {
    let (state, _) = self.state("abc", caret: 1)
    state.document.readOnly.add(0 ..< 3, ())
    XCTAssertFalse(state.setMarkedText("k", selected: 1 ..< 1))
    XCTAssertEqual(state.document.string, "abc")
    XCTAssertNil(state.markedRange)
  }

  func testTranspose() {
    let (state, layout) = self.state("abc", caret: 1)
    state.perform(.transpose, layout: layout)
    XCTAssertEqual(state.document.string, "bac")
    state.perform(.move(.document, forward: true, extend: false), layout: layout)
    state.perform(.transpose, layout: layout)
    XCTAssertEqual(state.document.string, "bca")
  }

  func testSelectorsMapToCommands() {
    XCTAssertEqual(EditorCommand(selector: "moveWordLeftAndModifySelection:"), .move(.word, forward: false, extend: true))
    XCTAssertEqual(EditorCommand(selector: "deleteToEndOfParagraph:"), .delete(.paragraphBoundary, forward: true))
    XCTAssertEqual(EditorCommand(selector: "insertNewline:"), .insertNewline)
    XCTAssertNil(EditorCommand(selector: "noop:"))
  }
}
