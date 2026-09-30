@testable import Editor
import EditorCore
@testable import MetalGraphicsLib
import simd
import XCTest

// How the editor's pieces look, light and dark: the find bar, the completion list, a hover, the
// status line and the Problems list. Cropped to the panel, so the temporary folder's name in
// the navigator never reaches a golden.
final class EditorLooksTests: EditorAppTestCase {
  private let items = [
    LSPCompletionItem(label: "print(_:)", kind: .function, detail: "Void", sortText: "1", insertText: "print(${1:items})", index: 0),
    LSPCompletionItem(label: "precondition(_:)", kind: .function, detail: "Void", sortText: "2", insertText: "precondition(${1:c})", index: 1),
    LSPCompletionItem(label: "private", kind: .keyword, sortText: "3", index: 2),
  ]

  private func open(_ relative: String) throws -> TextEditor {
    self.openPackage()
    try self.openInNavigator(relative)
    return try XCTUnwrap(self.shownEditor())
  }

  private var filePanel: FileEditorPanel? {
    self.window.all(FileEditorPanel.self).first { $0.mounted }
  }

  /// `element` in light, then in dark.
  private func assertLooks(_ element: () -> UIElement?, named name: String, file: StaticString = #filePath, line: UInt = #line) throws {
    XCTAssertNotNil(self.app.settle(), file: file, line: line)
    let shown = try XCTUnwrap(element(), file: file, line: line)
    assertSnapshot(self.window.snapshot(of: shown), named: "\(name)-light", file: file, line: line, testCase: self)
    self.app.setAppearance(.dark)
    XCTAssertNotNil(self.app.settle(), file: file, line: line)
    assertSnapshot(self.window.snapshot(of: shown), named: "\(name)-dark", file: file, line: line, testCase: self)
  }

  func testFindBar() throws {
    let editor = try self.open("Sources/App/Greeter.swift")
    self.window.press("f", modifiers: .command)
    self.window.type("name")
    self.window.press(.return)
    self.app.step()
    XCTAssertEqual(editor.searchMatches.count, 2)
    try self.assertLooks({ self.filePanel }, named: "find-bar")
  }

  func testCompletionList() throws {
    let editor = try self.open("Sources/App/main.swift")
    self.language.completions = self.items
    let end = editor.document.length
    editor.select(end ..< end, reveal: .none)
    self.window.type("\npr")
    self.app.step()
    XCTAssertTrue(self.window.shows("private"))
    try self.assertLooks({ self.filePanel }, named: "completion")
  }

  func testHover() throws {
    let editor = try self.open("Sources/App/main.swift")
    self.language.hoverText = "let greeting: String\nThe text to print, made by a Greeter from its name."
    let rect = try XCTUnwrap(editor.caretRect(for: 6))
    self.window.move(to: editor.origin + rect.origin + float2(3, rect.height * 0.5))
    self.app.advance(0.7)
    XCTAssertTrue(self.window.shows(self.language.hoverText!))
    try self.assertLooks({ self.filePanel }, named: "hover")
  }

  func testProblemsList() throws {
    self.openPackage()
    let greeter = self.path("Sources/App/Greeter.swift")
    let main = self.path("Sources/App/main.swift")
    self.builds.output = [
      ("\(greeter):4:36: error: cannot find 'nam' in scope\n", false),
      ("\(main):2:1: warning: result unused\n", false),
    ]
    self.builds.status = 1
    self.window.press("b", modifiers: .command)
    self.app.step()
    let problems = try XCTUnwrap(IDE.space.layout.panels.first { $0.value.kind == IDE.problemsKind }?.key)
    try self.window.panel(problems).tap()
    self.app.step()
    XCTAssertTrue(self.window.shows("1 error, 1 warning"))
    try self.assertLooks({ self.window.all(ProblemsPanel.self).first { $0.mounted } }, named: "problems")
  }
}
