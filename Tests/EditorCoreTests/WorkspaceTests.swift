@testable import EditorCore
import Foundation
import XCTest

/// Makes a folder of files under a fresh temporary directory, removed with the test.
func makeFolder(_ files: [String: String], in test: XCTestCase) throws -> URL {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("EditorCoreTests-\(UUID().uuidString)", isDirectory: true)
  for (path, text) in files {
    let url = root.appendingPathComponent(path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(text.utf8).write(to: url)
  }
  test.addTeardownBlock { try? FileManager.default.removeItem(at: root) }
  return root.standardizedFileURL
}

final class WorkspaceScannerTests: XCTestCase {
  func testFoldersComeFirstAndNamesSortAsFinderDoes() throws {
    let root = try makeFolder([
      "b.swift": "", "a10.swift": "", "a2.swift": "", "Sources/x.swift": "", "Assets/y.png": "",
    ], in: self)
    let tree = WorkspaceScanner.scan(root)
    XCTAssertEqual(tree.children.map(\.name), ["Assets", "Sources", "a2.swift", "a10.swift", "b.swift"])
    XCTAssertEqual(tree.path, root.path)
    XCTAssertTrue(tree.children[0].isDirectory)
  }

  func testHiddenAndBuildFoldersAreLeftOut() throws {
    let root = try makeFolder([
      "main.swift": "", ".build/debug/x.o": "", ".git/HEAD": "", ".DS_Store": "", "DerivedData/x": "",
    ], in: self)
    XCTAssertEqual(WorkspaceScanner.scan(root).children.map(\.name), ["main.swift"])
  }

  func testTheScanStopsAtItsLimit() throws {
    let root = try makeFolder(Dictionary(uniqueKeysWithValues: (0 ..< 20).map { ("f\($0).txt", "") }), in: self)
    XCTAssertEqual(WorkspaceScanner.scan(root, limit: 5).children.count, 5)
  }

  func testAllFilesListsEveryFileInTreeOrder() throws {
    let root = try makeFolder(["Sources/App/main.swift": "", "Sources/App/Util.swift": "", "README.md": ""], in: self)
    let names = WorkspaceScanner.scan(root).allFiles.map(\.name)
    XCTAssertEqual(names, ["main.swift", "Util.swift", "README.md"])
  }
}

final class FileTreeRowsTests: XCTestCase {
  private func tree() throws -> FileNode {
    let root = try makeFolder(["Sources/App/main.swift": "", "Sources/Lib/lib.swift": "", "README.md": ""], in: self)
    return WorkspaceScanner.scan(root)
  }

  func testOnlyExpandedFoldersShowTheirContents() throws {
    let tree = try self.tree()
    XCTAssertEqual(tree.rows(expanded: []).map(\.name), ["Sources", "README.md"])

    let sources = tree.path + "/Sources"
    let rows = tree.rows(expanded: [sources, sources + "/App"])
    XCTAssertEqual(rows.map(\.name), ["Sources", "App", "main.swift", "Lib", "README.md"])
    XCTAssertEqual(rows.map(\.depth), [0, 1, 2, 1, 0])
    XCTAssertEqual(rows.map(\.isExpanded), [true, true, false, false, false])
  }

  func testAnExpandedFolderHasAnIDOfItsOwn() throws {
    let tree = try self.tree()
    let sources = tree.path + "/Sources"
    let closed = tree.rows(expanded: [])[0]
    let open = tree.rows(expanded: [sources])[0]
    XCTAssertEqual(closed.path, open.path)
    XCTAssertNotEqual(closed.id, open.id)
  }

  func testAncestorsAreTheFoldersDownToAFile() throws {
    let tree = try self.tree()
    XCTAssertEqual(tree.ancestors(of: tree.path + "/Sources/App/main.swift"),
                   [tree.path + "/Sources", tree.path + "/Sources/App"])
    XCTAssertEqual(tree.ancestors(of: tree.path + "/README.md"), [])
  }

  func testNodeAtFindsFilesInside() throws {
    let tree = try self.tree()
    XCTAssertEqual(tree.node(at: tree.path + "/Sources/Lib/lib.swift")?.name, "lib.swift")
    XCTAssertNil(tree.node(at: "/elsewhere/lib.swift"))
  }
}
