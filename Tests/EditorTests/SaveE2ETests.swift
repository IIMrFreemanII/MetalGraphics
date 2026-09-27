@testable import Editor
@testable import MetalGraphicsLib
import XCTest

// Editing a file, seeing that it has unsaved changes, saving it, and closing it with changes.
final class SaveE2ETests: EditorAppTestCase {
  private var greeterTitle: String? {
    IDE.space.layout.panels[self.filePanels.first { $0.path.hasSuffix("Greeter.swift") }?.id ?? ""]?.title
  }

  /// Greeter.swift open, the caret at its very start.
  private func openGreeter() throws -> TextEditor {
    self.openPackage()
    try self.openInNavigator("Sources/App/Greeter.swift")
    let editor = try XCTUnwrap(self.shownEditor())
    XCTAssertTrue(editor.isFocused, "a file just opened takes the keyboard")
    return editor
  }

  func testTypingMarksTheTabAndCommandSSavesIt() throws {
    let editor = try self.openGreeter()
    XCTAssertEqual(self.greeterTitle, "Greeter.swift")

    self.window.type("// Greets.\n")
    XCTAssertEqual(self.greeterTitle, "● Greeter.swift")
    XCTAssertTrue(editor.document.string.hasPrefix("// Greets.\nstruct Greeter"))
    XCTAssertEqual(self.contents("Sources/App/Greeter.swift"), EditorAppTestCase.files["Sources/App/Greeter.swift"])

    self.window.press("s", modifiers: .command)
    XCTAssertEqual(self.contents("Sources/App/Greeter.swift"), editor.document.string)
    XCTAssertEqual(self.greeterTitle, "Greeter.swift")
  }

  func testCommandOptionSSavesEveryFile() throws {
    _ = try self.openGreeter()
    self.window.type("// 1\n")
    try self.window.tap("main.swift")
    self.app.step()
    self.window.type("// 2\n")

    self.window.press("s", modifiers: [.command, .option])
    self.app.step()
    XCTAssertTrue(self.contents("Sources/App/Greeter.swift").hasPrefix("// 1\n"))
    XCTAssertTrue(self.contents("Sources/App/main.swift").hasPrefix("// 2\n"))
  }

  func testUnsavedTextSurvivesSwitchingTabs() throws {
    _ = try self.openGreeter()
    self.window.type("// kept\n")
    try self.window.tap("main.swift")
    self.app.step()
    try self.window.tap("Greeter.swift")
    self.app.step()
    XCTAssertTrue(self.shownEditor()?.document.string.hasPrefix("// kept\n") == true)
    XCTAssertEqual(self.greeterTitle, "● Greeter.swift")
  }

  func testClosingAnUnsavedTabAsksAndCanSave() throws {
    let editor = try self.openGreeter()
    self.window.type("// saved on close\n")
    let panel = try XCTUnwrap(self.filePanels.first?.id)
    let area = try XCTUnwrap(self.window.first(DockArea.self))
    area.closePanel(panel)
    self.app.step()
    XCTAssertNotNil(IDE.space.layout.panels[panel], "an unsaved tab stays open until the user says")
    XCTAssertTrue(self.window.shows("Save changes to “Greeter.swift”?"))

    try self.window.tap("Save")
    XCTAssertNotNil(self.app.settle())
    XCTAssertNil(IDE.space.layout.panels[panel])
    XCTAssertEqual(self.contents("Sources/App/Greeter.swift"), editor.document.string)
  }

  func testDontSaveClosesAndLeavesTheFile() throws {
    _ = try self.openGreeter()
    self.window.type("// dropped\n")
    let panel = try XCTUnwrap(self.filePanels.first?.id)
    try XCTUnwrap(self.window.first(DockArea.self)).closePanel(panel)
    self.app.step()
    try self.window.tap("Don’t Save")
    XCTAssertNotNil(self.app.settle())
    XCTAssertNil(IDE.space.layout.panels[panel])
    XCTAssertEqual(self.contents("Sources/App/Greeter.swift"), EditorAppTestCase.files["Sources/App/Greeter.swift"])

    // Opened again, it is the file on disk.
    try self.window.tap("Greeter.swift")
    self.app.step()
    XCTAssertEqual(self.shownEditor()?.document.string, EditorAppTestCase.files["Sources/App/Greeter.swift"])
  }

  func testAFileKeepsItsLineEndings() throws {
    try Data("let a = 1\r\nlet b = 2\r\n".utf8).write(to: self.root.appendingPathComponent("CRLF.swift"))
    self.openPackage()
    try self.openInNavigator("CRLF.swift")
    self.window.type("x")
    self.window.press("s", modifiers: .command)
    XCTAssertEqual(self.contents("CRLF.swift"), "xlet a = 1\r\nlet b = 2\r\n")
  }

  func testARelaunchReopensTheTabFromDisk() throws {
    _ = try self.openGreeter()
    self.window.type("// across a relaunch\n")
    self.relaunch()
    IDE.openFolderAtLaunch(arguments: ["Editor"], environment: [:])
    self.app.step()
    // A relaunch keeps the tab, reading the file afresh: unsaved text is lost with the process.
    XCTAssertEqual(self.shownEditor()?.document.string, EditorAppTestCase.files["Sources/App/Greeter.swift"])
  }
}
