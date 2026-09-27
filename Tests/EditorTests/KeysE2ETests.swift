@testable import Editor
@testable import MetalGraphicsLib
import XCTest

// The window's keys reach it whatever has focus, or nothing.
final class KeysE2ETests: EditorAppTestCase {
  func testWindowKeysWorkWithOnlyTheNavigator() throws {
    let welcome = try XCTUnwrap(IDE.space.layout.panels.first { $0.value.kind == IDE.welcomeKind }?.key)
    IDE.space.close(panel: welcome)
    self.app.step()
    self.openPackage()
    XCTAssertTrue(self.window.shows("Sources"))
  }

  func testWindowKeysWorkAfterTheFocusedTabCloses() throws {
    self.openPackage()
    try self.openInNavigator("README.md")
    XCTAssertTrue(try XCTUnwrap(self.shownEditor()).isFocused)
    IDE.space.close(panel: try XCTUnwrap(self.filePanels.first?.id))
    self.app.step()
    self.window.press("p", modifiers: .command)
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.window.shows("Open Quickly"))
  }
}
