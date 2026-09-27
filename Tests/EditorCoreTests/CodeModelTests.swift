import SwiftCodeModel
import XCTest

final class CodeModelTests: XCTestCase {
  private let source = """
  import Foundation

  // MARK: - Shapes

  /* A block comment
     over two lines. */
  struct Point: Hashable {
    var x: Double
    var y: Double

    func distance(to other: Point) -> Double {
      let dx = other.x - x
      return dx
    }
  }

  enum Shape {
    case circle, square
  }

  extension Point {
    init(both: Double) { self.init(x: both, y: both) }
  }
  """

  /// The text of `range` in `source`, counted in UTF-16.
  private func text(_ range: Range<Int>, in source: String) -> String {
    let units = Array(source.utf16)
    return String(decoding: units[range], as: UTF16.self)
  }

  func testTheOutlineListsDeclarationsWithTheirDepth() {
    let analysis = CodeModel.analyze(self.source)
    let outline = analysis.symbols.map { "\(String(repeating: "  ", count: $0.depth))\($0.kind.rawValue) \($0.name)" }
    XCTAssertEqual(outline, [
      "mark Shapes",
      "struct Point",
      "  variable x",
      "  variable y",
      "  function distance(to:)",
      "enum Shape",
      "  enumCase circle",
      "  enumCase square",
      "extension Point",
      "  initializer init(both:)",
    ])
    // Locals are not in it.
    XCTAssertFalse(analysis.symbols.contains { $0.name == "dx" })
  }

  func testRangesAreUTF16AndPointAtTheNames() {
    let analysis = CodeModel.analyze(self.source)
    for symbol in analysis.symbols where symbol.kind != .mark && symbol.kind != .function && symbol.kind != .initializer
      && symbol.kind != .extension {
      XCTAssertEqual(self.text(symbol.nameRange, in: self.source), symbol.name)
    }
    let distance = try! XCTUnwrap(analysis.symbols.first { $0.kind == .function })
    XCTAssertEqual(self.text(distance.nameRange, in: self.source), "distance")
    XCTAssertTrue(self.text(distance.range, in: self.source).hasPrefix("func distance(to other: Point)"))
    XCTAssertTrue(self.text(distance.range, in: self.source).hasSuffix("return dx\n  }"))
  }

  func testWideCharactersBeforeASymbolDoNotShiftIt() {
    // "é" is 2 UTF-8 bytes and 1 UTF-16 unit; "😀" 4 and 2.
    let source = "let s = \"é😀\"\nstruct Café {\n  var 😀: Int\n}\n"
    let analysis = CodeModel.analyze(source)
    let cafe = try! XCTUnwrap(analysis.symbols.first { $0.kind == .struct })
    XCTAssertEqual(self.text(cafe.nameRange, in: source), "Café")
    let emoji = try! XCTUnwrap(analysis.symbols.first { $0.kind == .variable && $0.depth == 1 })
    XCTAssertEqual(self.text(emoji.nameRange, in: source), "😀")
    XCTAssertEqual(analysis.foldingRanges.map { self.text($0, in: source) }, ["{\n  var 😀: Int\n}"])
  }

  func testFoldingRangesAreBracesAndCommentsSpanningLines() {
    let analysis = CodeModel.analyze(self.source)
    let folded = analysis.foldingRanges.map { self.text($0, in: self.source) }
    XCTAssertTrue(folded.contains("/* A block comment\n   over two lines. */"))
    XCTAssertTrue(folded.contains { $0.hasPrefix("{\n  var x: Double") && $0.hasSuffix("}\n}") })
    XCTAssertTrue(folded.contains { $0.hasPrefix("{\n    let dx") })
    XCTAssertTrue(folded.contains("{\n  case circle, square\n}"))
    // One line: nothing to fold.
    XCTAssertFalse(folded.contains { $0.hasPrefix("{ self.init") })
    // Sorted by start.
    XCTAssertEqual(analysis.foldingRanges, analysis.foldingRanges.sorted { $0.lowerBound < $1.lowerBound })
  }

  func testBrokenCodeStillHasAnOutline() {
    let analysis = CodeModel.analyze("struct A {\n  func f( {\n}\nstruct B {}\n")
    XCTAssertTrue(analysis.symbols.contains { $0.name == "A" })
    XCTAssertTrue(analysis.symbols.contains { $0.name == "B" })
  }

  func testALargeFileIsQuick() {
    let file = String(repeating: self.source + "\n", count: 400)  // ~10k lines
    let start = Date()
    let analysis = CodeModel.analyze(file)
    XCTAssertEqual(analysis.symbols.count, 4000)
    XCTAssertLessThan(Date().timeIntervalSince(start), 2.0)
  }
}
