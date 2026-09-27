@testable import Editor
@testable import MetalGraphicsLib
import XCTest

// Opening a folder, browsing its tree, and opening files from it in tabs.
final class NavigatorE2ETests: EditorAppTestCase {
  func testTheWindowStartsWithNoFolder() {
    XCTAssertTrue(self.window.shows("No Folder"))
    XCTAssertTrue(self.window.shows("Swift Editor"))
  }

  func testCommandOShowsTheFolderTopLevel() {
    self.openPackage()
    XCTAssertTrue(self.window.shows(self.root.lastPathComponent))
    XCTAssertTrue(self.window.shows("Sources"))
    XCTAssertTrue(self.window.shows("Package.swift"))
    XCTAssertTrue(self.window.shows("README.md"))
    // Build products and hidden folders are left out.
    XCTAssertFalse(self.window.shows(".build"))
    // Folders stay closed until opened.
    XCTAssertFalse(self.window.shows("App"))
  }

  func testTappingAFolderOpensAndClosesIt() throws {
    self.openPackage()
    try self.window.tap("Sources")
    self.app.step()
    XCTAssertTrue(self.window.shows("App"))
    try self.window.tap("App")
    self.app.step()
    XCTAssertTrue(self.window.shows("Greeter.swift"))
    XCTAssertTrue(self.window.shows("main.swift"))

    try self.window.tap("Sources")
    self.app.step()
    XCTAssertFalse(self.window.shows("App"))
    XCTAssertFalse(self.window.shows("main.swift"))
  }

  func testTappingAFileOpensItInATab() throws {
    self.openPackage()
    try self.openInNavigator("Sources/App/Greeter.swift")

    XCTAssertEqual(self.filePanels.map(\.path), [self.path("Sources/App/Greeter.swift")])
    let editor = try XCTUnwrap(self.shownEditor())
    XCTAssertEqual(editor.document.string, EditorAppTestCase.files["Sources/App/Greeter.swift"])
    XCTAssertTrue(editor.styler is SwiftStyler)
    // The first file takes the welcome tab's place.
    XCTAssertFalse(IDE.space.layout.panels.values.contains { $0.kind == IDE.welcomeKind })
    XCTAssertEqual(WorkspaceModel.shared.activeFile, self.path("Sources/App/Greeter.swift"))
  }

  func testOpeningAFileAgainSelectsItsTab() throws {
    self.openPackage()
    try self.openInNavigator("Sources/App/Greeter.swift")
    try self.window.tap("main.swift")
    self.app.step()
    XCTAssertEqual(self.filePanels.count, 2)
    XCTAssertEqual(self.shownEditor()?.document.string, EditorAppTestCase.files["Sources/App/main.swift"])

    try self.window.tap("Greeter.swift")
    self.app.step()
    XCTAssertEqual(self.filePanels.count, 2)
    XCTAssertEqual(self.shownEditor()?.document.string, EditorAppTestCase.files["Sources/App/Greeter.swift"])
  }

  func testFilesOpenBesideTheNavigatorOnceEveryTabIsClosed() throws {
    self.openPackage()
    try self.openInNavigator("README.md")
    let readme = try XCTUnwrap(self.filePanels.first?.id)
    IDE.space.close(panel: readme)
    self.app.step()
    XCTAssertNil(self.shownEditor())

    try self.window.tap("Package.swift")
    self.app.step()
    XCTAssertEqual(self.shownEditor()?.document.string, EditorAppTestCase.files["Package.swift"])
    guard case .split(let split)? = IDE.space.layout.host(IDE.host)?.root else { return XCTFail("no split") }
    XCTAssertEqual(split.fractions, [0.24, 0.76])
  }

  func testTheFolderAndItsOpenFoldersComeBackAfterARelaunch() throws {
    self.openPackage()
    try self.openInNavigator("Sources/App/main.swift")
    self.relaunch()
    IDE.openFolderAtLaunch(arguments: ["Editor"], environment: [:])
    self.app.step()
    XCTAssertTrue(self.window.shows("Greeter.swift"))
    XCTAssertEqual(self.shownEditor()?.document.string, EditorAppTestCase.files["Sources/App/main.swift"])
  }
}
