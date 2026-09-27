@testable import EditorCore
import XCTest

final class FuzzyMatcherTests: XCTestCase {
  private let paths = [
    "Sources/Editor/FileEditorPanel.swift",
    "Sources/Editor/NavigatorPanel.swift",
    "Sources/EditorCore/IO/TextFileIO.swift",
    "Sources/MetalGraphicsLib/RetainedModeUI/TextEditor/View/TextEditor.swift",
    "docs/Editor.md",
    "Package.swift",
  ]

  func testCharactersMustAppearInOrder() {
    XCTAssertNotNil(FuzzyMatcher.score("fep", "Sources/Editor/FileEditorPanel.swift"))
    XCTAssertNil(FuzzyMatcher.score("lef", "FileEditor"))
    XCTAssertNil(FuzzyMatcher.score("xyz", "Package.swift"))
    XCTAssertEqual(FuzzyMatcher.score("", "anything"), 0)
  }

  func testWordStartsInTheNameRankFirst() {
    XCTAssertEqual(FuzzyMatcher.rank("fep", self.paths).first, "Sources/Editor/FileEditorPanel.swift")
    XCTAssertEqual(FuzzyMatcher.rank("texted", self.paths).first,
                   "Sources/MetalGraphicsLib/RetainedModeUI/TextEditor/View/TextEditor.swift")
    XCTAssertEqual(FuzzyMatcher.rank("package", self.paths).first, "Package.swift")
  }

  func testAMatchInTheNameBeatsOneInTheFolders() {
    // "editor" is in the folder of every Editor source, but the name of only one of these.
    XCTAssertEqual(FuzzyMatcher.rank("editor", self.paths).first, "docs/Editor.md")
  }

  func testCaseAndSpacesAreIgnoredAndTheLimitHolds() {
    XCTAssertEqual(FuzzyMatcher.rank("NAV PANEL", self.paths), ["Sources/Editor/NavigatorPanel.swift"])
    XCTAssertEqual(FuzzyMatcher.rank("s", self.paths, limit: 2).count, 2)
  }
}
