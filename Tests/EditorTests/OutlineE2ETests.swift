@testable import Editor
@testable import MetalGraphicsLib
import SwiftCodeModel
import XCTest

// The Outline of the file in front, kept up with typing, and folding from the parse.
final class OutlineE2ETests: EditorAppTestCase {
  private func outlinePanel() -> OutlinePanel? {
    self.window.all(OutlinePanel.self).first { $0.mounted }
  }

  private func openGreeter() throws -> TextEditor {
    self.openPackage()
    try self.openInNavigator("Sources/App/Greeter.swift")
    self.app.step()
    return try XCTUnwrap(self.shownEditor())
  }

  func testTheOutlineShowsTheFileInFront() throws {
    _ = try self.openGreeter()
    let names = self.outlinePanel()?.items.map(\.symbol.name)
    XCTAssertEqual(names, ["Greeter", "name", "greeting"])
    XCTAssertTrue(self.window.shows("Greeter.swift"))

    // Another tab in front: its outline.
    try self.window.tap("main.swift")
    self.app.step()
    XCTAssertEqual(self.outlinePanel()?.items.map(\.symbol.name), ["greeting"])
    // Markdown has none.
    try self.window.tap("README.md")
    self.app.step()
    XCTAssertEqual(self.outlinePanel()?.items.count, 0)
    XCTAssertTrue(self.window.shows("No symbols in README.md"))
  }

  func testTheOutlineFollowsTyping() throws {
    let editor = try self.openGreeter()
    editor.select(0 ..< 0, reveal: .none)
    self.window.type("enum Mode {}\n")
    self.app.step()
    XCTAssertEqual(self.outlinePanel()?.items.map(\.symbol.name), ["Mode", "Greeter", "name", "greeting"])
  }

  func testAClickOnASymbolSelectsIt() throws {
    let editor = try self.openGreeter()
    editor.select(0 ..< 0, reveal: .none)
    try self.window.tap("greeting")
    self.app.step()
    let head = editor.state.selection.primary.head
    let text = editor.document.string as NSString
    XCTAssertEqual(head, text.range(of: "greeting").location)
    XCTAssertTrue(editor.isFocused)
  }

  func testTheStructCanFoldFromTheParse() throws {
    let editor = try self.openGreeter()
    XCTAssertEqual(editor.foldingRanges.count, 1, "the struct's braces; the one-line getter does not fold")
    editor.select(20 ..< 20, reveal: .none)
    self.window.press(.leftArrow, modifiers: [.command, .option])
    self.app.step()
    XCTAssertEqual(editor.foldedRanges, editor.foldingRanges)
    XCTAssertEqual(editor.content.visible.map(\.line), [0])
    self.window.press(.rightArrow, modifiers: [.command, .option])
    self.app.step()
    XCTAssertEqual(editor.foldedRanges, [])
  }

  func testALayoutSavedWithoutAnOutlineGetsOne() throws {
    let outline = try XCTUnwrap(IDE.space.layout.panels.first { $0.value.kind == IDE.outlineKind }?.key)
    IDE.space.close(panel: outline)
    XCTAssertFalse(IDE.space.layout.panels.values.contains { $0.kind == IDE.outlineKind })
    IDE.ensureOutlinePanel()
    self.app.step()
    let layout = IDE.space.layout
    let added = try XCTUnwrap(layout.panels.first { $0.value.kind == IDE.outlineKind }?.key)
    // A tab beside the navigator, which stays in front.
    let group = try XCTUnwrap(layout.tabs(holding: added))
    XCTAssertEqual(group.panels.map { layout.panels[$0]?.kind }, [IDE.navigatorKind, IDE.outlineKind])
    XCTAssertEqual(group.selected.flatMap { layout.panels[$0]?.kind }, IDE.navigatorKind)
  }
}
