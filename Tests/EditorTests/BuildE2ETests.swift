@testable import Editor
import EditorCore
@testable import MetalGraphicsLib
import XCTest

// Building and running from the editor: the console, the Problems list, the problems in the
// file's text, and files changed on disk.
final class BuildE2ETests: EditorAppTestCase {
  /// A build that fails: an error in Greeter.swift, a warning in main.swift.
  private func failingBuild() {
    let greeter = self.path("Sources/App/Greeter.swift")
    let main = self.path("Sources/App/main.swift")
    self.builds.output = [
      ("Building for debugging...\n", false),
      ("\(greeter):4:36: error: cannot find 'nam' in scope\n", false),
      ("\(main):2:1: warning: result unused\n", false),
      ("error: fatalError\n", true),
    ]
    self.builds.status = 1
  }

  private func consoleText() -> String? {
    self.window.all(ConsolePanel.self).first { $0.mounted }?.document.string
  }

  func testCommandBBuildsAndShowsTheOutput() throws {
    self.openPackage()
    self.failingBuild()
    self.window.press("b", modifiers: .command)
    self.app.step()
    XCTAssertEqual(self.builds.started.map(\.task), [.build])
    XCTAssertEqual(self.builds.started.first?.folder, self.root.path)
    XCTAssertTrue(self.consoleText()?.hasPrefix("Building for debugging...\n") == true)
    XCTAssertTrue(self.consoleText()?.hasSuffix("error: fatalError\n") == true)
    XCTAssertTrue(self.window.shows("Build failed: 1 error, 1 warning"))
    XCTAssertEqual(BuildModel.shared.problems.count, 2)
  }

  func testTheProblemsListOpensTheFileAtTheProblem() throws {
    self.openPackage()
    self.failingBuild()
    self.window.press("b", modifiers: .command)
    self.app.step()
    let problems = try XCTUnwrap(IDE.space.layout.panels.first { $0.value.kind == IDE.problemsKind }?.key)
    try self.window.panel(problems).tap()
    self.app.step()
    XCTAssertTrue(self.window.shows("1 error, 1 warning"))
    XCTAssertTrue(self.window.shows("Sources/App/Greeter.swift:4:36"))

    try self.window.tap("cannot find 'nam' in scope")
    self.app.step()
    let editor = try XCTUnwrap(self.shownEditor())
    XCTAssertEqual(editor.document.string, EditorAppTestCase.files["Sources/App/Greeter.swift"])
    let head = editor.document.position(of: editor.state.selection.primary.head)
    XCTAssertEqual(head.line, 3)
    XCTAssertEqual(head.column, 35)
    // Underlined in the text: the word at the column.
    let marks = editor.document.diagnostics.marks
    XCTAssertEqual(marks.count, 1)
    XCTAssertEqual(marks.first.map { editor.document.substring($0.range) }, "name")
    XCTAssertEqual(marks.first?.payload.severity, .error)
    XCTAssertEqual(marks.first?.payload.message, "cannot find 'nam' in scope")
  }

  func testAnOpenFileIsUnderlinedAsTheBuildReportsAndClearedByTheNext() throws {
    self.openPackage()
    try self.openInNavigator("Sources/App/main.swift")
    let editor = try XCTUnwrap(self.shownEditor())
    self.failingBuild()
    self.window.press("b", modifiers: .command)
    self.app.step()
    XCTAssertEqual(editor.document.diagnostics.marks.map(\.payload.severity), [.warning])

    self.builds.output = [("Build complete!\n", false)]
    self.builds.status = 0
    self.window.press("b", modifiers: .command)
    self.app.step()
    XCTAssertEqual(editor.document.diagnostics.marks.count, 0)
    XCTAssertTrue(self.window.shows("Build succeeded"))
    XCTAssertEqual(self.consoleText(), "Build complete!\n", "a new build starts the console over")
  }

  func testAFileOpenedWithTheConsoleBelowTakesMostOfTheWidth() throws {
    self.openPackage()
    self.window.press("b", modifiers: .command)
    self.app.step()
    let welcome = try XCTUnwrap(IDE.space.layout.panels.first { $0.value.kind == IDE.welcomeKind }?.key)
    IDE.space.close(panel: welcome)
    self.app.step()
    try self.window.tap("README.md")
    self.app.step()
    let layout = IDE.space.layout
    let group = try XCTUnwrap(layout.tabs(holding: self.filePanels[0].id)).id
    func splitHolding(_ node: DockNode) -> DockSplit? {
      guard case .split(let split) = node else { return nil }
      if split.children.contains(where: { $0.id == group }) { return split }
      return split.children.lazy.compactMap(splitHolding).first
    }
    let split = try XCTUnwrap(layout.host(IDE.host)?.root.flatMap(splitHolding))
    XCTAssertEqual(split.fractions, [0.24, 0.76])
    // Beside the navigator and the outline both, above the console.
    XCTAssertEqual(split.axis, .horizontal)
    let kinds = Set(split.children[0].panels.compactMap { layout.panels[$0]?.kind })
    XCTAssertEqual(kinds, [IDE.navigatorKind, IDE.outlineKind])
    guard case .split(let root)? = layout.host(IDE.host)?.root else { return XCTFail("no root split") }
    XCTAssertEqual(root.axis, .vertical)
    XCTAssertTrue(root.children.last.map { $0.panels.contains { layout.panels[$0]?.kind == IDE.consoleKind } } ?? false)
  }

  func testUnsavedEditsAreSavedBeforeTheBuild() throws {
    self.openPackage()
    try self.openInNavigator("Sources/App/main.swift")
    self.window.type("// edited\n")
    var onDisk = ""
    self.builds.onStart = { onDisk = self.contents("Sources/App/main.swift") }
    self.window.press("b", modifiers: .command)
    self.app.step()
    XCTAssertTrue(onDisk.hasPrefix("// edited\n"))
  }

  func testRunUsesTheChosenProductAndStopEndsIt() throws {
    Services.describePackage = { _ in PackageInfo(name: "Sample", executables: ["App", "Tool"]) }
    self.openPackage()
    XCTAssertEqual(BuildModel.shared.product, "App")
    self.builds.finishesAtOnce = false
    self.builds.output = [("Hello, World!\n", false)]
    self.window.press("r", modifiers: .command)
    self.app.step()
    XCTAssertEqual(self.builds.started.map(\.task), [.run(product: "App")])
    XCTAssertTrue(self.window.shows("Running App…"))
    XCTAssertEqual(self.consoleText(), "Hello, World!\n")
    // Nothing else starts while it runs.
    self.window.press("b", modifiers: .command)
    self.app.step()
    XCTAssertEqual(self.builds.started.count, 1)

    self.window.press(".", modifiers: .command)
    self.app.step()
    XCTAssertEqual(BuildModel.shared.state, .stopped)
    XCTAssertTrue(self.window.shows("Run stopped"))

    // The product button, titled with the one Run starts, picks the next.
    try self.window.tap("App")
    self.app.step()
    XCTAssertEqual(BuildModel.shared.product, "Tool")
    XCTAssertTrue(self.window.shows("Tool"))
  }

  // MARK: - Changes on disk

  func testACleanFileShowsWhatChangedOnDisk() throws {
    self.openPackage()
    try self.openInNavigator("Sources/App/main.swift")
    let editor = try XCTUnwrap(self.shownEditor())
    // Later than the file's time, whatever the file system's resolution.
    try self.write("print(\"changed\")\n", to: "Sources/App/main.swift")
    IDE.filesChanged([self.path("Sources/App/main.swift")])
    self.app.step()
    XCTAssertEqual(editor.document.string, "print(\"changed\")\n")
    XCTAssertEqual(IDE.space.layout.panels[self.filePanels[0].id]?.title, "main.swift", "not dirty")
  }

  func testEditsAreKeptWhenTheFileChangesOnDisk() throws {
    self.openPackage()
    try self.openInNavigator("Sources/App/main.swift")
    let editor = try XCTUnwrap(self.shownEditor())
    self.window.type("// mine\n")
    try self.write("print(\"theirs\")\n", to: "Sources/App/main.swift")
    IDE.filesChanged([])
    self.app.step()
    XCTAssertTrue(editor.document.string.hasPrefix("// mine\n"))
    XCTAssertTrue(self.window.shows("Changed on disk; saving will replace it"))
  }

  func testNewFilesShowInTheNavigator() throws {
    self.openPackage()
    try self.window.tap("Sources")
    try self.window.tap("App")
    try self.write("struct New {}\n", to: "Sources/App/New.swift")
    IDE.filesChanged([self.path("Sources/App/New.swift")])
    self.app.step()
    XCTAssertTrue(self.window.shows("New.swift"))
  }

  /// Writes `text` over `relative`, dated a second on, so it reads as changed.
  private func write(_ text: String, to relative: String) throws {
    let path = self.path(relative)
    try Data(text.utf8).write(to: URL(fileURLWithPath: path))
    try FileManager.default.setAttributes([.modificationDate: Date().addingTimeInterval(1)], ofItemAtPath: path)
  }
}
