@testable import EditorCore
import Foundation
import XCTest

final class TextFileIOTests: XCTestCase {
  func testUTF8RoundTripsWithItsLineEndings() throws {
    let root = try makeFolder(["a.swift": "let a = \"é\"\r\nlet b = 2\r\n"], in: self)
    let url = root.appendingPathComponent("a.swift")
    let contents = try TextFileIO.read(url)
    XCTAssertEqual(contents.text, "let a = \"é\"\r\nlet b = 2\r\n")
    XCTAssertEqual(contents.encoding, .utf8)
    XCTAssertFalse(contents.hasBOM)

    try TextFileIO.write(contents, to: url)
    XCTAssertEqual(try Data(contentsOf: url), Data("let a = \"é\"\r\nlet b = 2\r\n".utf8))
  }

  func testAByteOrderMarkIsReadAndWrittenBack() throws {
    let utf8 = Data([0xEF, 0xBB, 0xBF]) + Data("hi".utf8)
    let contents = try TextFileIO.decode(utf8)
    XCTAssertEqual(contents, TextFileContents(text: "hi", encoding: .utf8, hasBOM: true))
    XCTAssertEqual(try TextFileIO.encode(contents), utf8)

    let utf16 = Data([0xFF, 0xFE, 0x68, 0x00, 0x69, 0x00])
    let wide = try TextFileIO.decode(utf16)
    XCTAssertEqual(wide, TextFileContents(text: "hi", encoding: .utf16LittleEndian, hasBOM: true))
    XCTAssertEqual(try TextFileIO.encode(wide), utf16)
  }

  func testBinaryIsRefused() {
    XCTAssertThrowsError(try TextFileIO.decode(Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0x01]))) { error in
      XCTAssertEqual(error as? TextFileError, .binary)
    }
  }

  func testBytesThatAreNotUTF8ReadAsLatin1() throws {
    let contents = try TextFileIO.decode(Data([0x63, 0x61, 0x66, 0xE9]))
    XCTAssertEqual(contents.text, "café")
    XCTAssertEqual(contents.encoding, .isoLatin1)
    XCTAssertEqual(try TextFileIO.encode(contents), Data([0x63, 0x61, 0x66, 0xE9]))
  }

  func testAMissingFileIsUnreadable() {
    XCTAssertThrowsError(try TextFileIO.read(URL(fileURLWithPath: "/no/such/file.swift"))) { error in
      guard case .unreadable? = error as? TextFileError else { return XCTFail("\(error)") }
    }
  }
}

final class TextPositionsTests: XCTestCase {
  func testUTF8ColumnsBecomeUTF16Columns() {
    // "é" is 2 bytes and 1 unit; "😀" 4 bytes and 2 units.
    let line = "é😀x"
    XCTAssertEqual(TextPositions.utf16Column(fromUTF8: 0, in: line), 0)
    XCTAssertEqual(TextPositions.utf16Column(fromUTF8: 2, in: line), 1)
    XCTAssertEqual(TextPositions.utf16Column(fromUTF8: 6, in: line), 3)
    XCTAssertEqual(TextPositions.utf16Column(fromUTF8: 7, in: line), 4)
    XCTAssertEqual(TextPositions.utf16Column(fromUTF8: 99, in: line), 4)
    XCTAssertEqual(TextPositions.utf8Column(fromUTF16: 3, in: line), 6)
  }

  func testRelativePaths() {
    XCTAssertEqual(TextPositions.relativePath("/a/b/Sources/x.swift", from: "/a/b"), "Sources/x.swift")
    XCTAssertEqual(TextPositions.relativePath("/c/x.swift", from: "/a/b"), "/c/x.swift")
  }
}
