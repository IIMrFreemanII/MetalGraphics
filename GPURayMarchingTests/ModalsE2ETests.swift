@testable import MetalGraphicsLib
import XCTest

// The Modals demo, driven as a user would: over the app's window, and in windows of their own.
final class ModalsE2ETests: AppTestCase {
  override func setUp() {
    super.setUp()
    try! self.main.tap("Modals")
    XCTAssertNotNil(self.app.settle())
  }

  /// Picks where presentations show.
  private func show(in placement: String) throws {
    try self.main.tap(placement)
    XCTAssertNotNil(self.app.settle())
  }

  func testRenamingOnASheetOverTheWindow() throws {
    try self.main.tap("Rename…")
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.main.shows("Rename"))
    XCTAssertEqual(self.app.windows.count, 1, "over the app's window")

    try self.main.type("Ada", into: "Name")
    try self.main.tap("Save")
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.main.shows("Document: NotesAda"))
    XCTAssertTrue(self.main.shows("Last: Closed the rename sheet"))
    XCTAssertFalse(self.main.shows("Rename"))
  }

  func testRenamingOnAnAttachedSheetWindow() throws {
    try self.show(in: "Attached window")
    try self.main.tap("Rename…")
    XCTAssertNotNil(self.app.settle())
    let sheet = try XCTUnwrap(self.app.presentation(over: self.main))
    XCTAssertTrue(sheet.shows("Rename"))
    XCTAssertTrue(sheet.isKey)

    try sheet.type("Ada", into: "Name")
    try sheet.tap("Save")
    XCTAssertNotNil(self.app.settle())
    XCTAssertFalse(sheet.isOpen)
    XCTAssertTrue(self.main.isKey)
    XCTAssertTrue(self.main.shows("Document: NotesAda"), "the binding wrote through to the window it came from")
  }

  func testDiscardingAsksOnAnAlertOverTheSheetWindow() throws {
    try self.show(in: "Floating window")
    try self.main.tap("Rename…")
    XCTAssertNotNil(self.app.settle())
    let sheet = try XCTUnwrap(self.app.presentation(over: self.main))
    try sheet.tap("Discard…")
    XCTAssertNotNil(self.app.settle())
    let alert = try XCTUnwrap(self.app.presentation(over: sheet), "the sheet's own style")
    try alert.tap("Discard")
    XCTAssertNotNil(self.app.settle())
    XCTAssertFalse(alert.isOpen)
    XCTAssertFalse(sheet.isOpen, "the sheet dismissed itself")
    XCTAssertTrue(self.main.shows("Document: Notes"))
  }

  func testDeleteAlertInAFloatingWindow() throws {
    try self.show(in: "Floating window")
    try self.main.tap("Delete…")
    XCTAssertNotNil(self.app.settle())
    let alert = try XCTUnwrap(self.app.presentation(over: self.main))
    XCTAssertTrue(alert.shows("Delete “Notes”?"))
    alert.press(.escape)
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.main.shows("Last: Kept Notes"))
  }

  func testNoteSheetsFollowTheirItem() throws {
    try self.main.tap("Ideas")
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(self.main.shows("A popover that points from a window's edge."))
    try self.main.tap("Done")
    XCTAssertNotNil(self.app.settle())
    XCTAssertFalse(self.main.shows("Ideas") && self.main.shows("Done"))
  }

  func testTheInlineOverrideStaysInTheWindow() throws {
    try self.show(in: "Floating window")
    try self.main.tap("Always over the app window")
    XCTAssertNotNil(self.app.settle())
    XCTAssertEqual(self.app.windows.count, 1)
    XCTAssertTrue(self.main.shows("Over the app window"))
  }

  func testPopoverWindowGoesOnAClickInItsWindow() throws {
    try self.show(in: "Attached window")
    try self.main.tap("Info")
    XCTAssertNotNil(self.app.settle())
    let popover = try XCTUnwrap(self.app.presentation(over: self.main))
    XCTAssertTrue(popover.shows("A popover points at what shows it."))
    self.main.click(at: float2(5, 5))
    XCTAssertNotNil(self.app.settle())
    XCTAssertFalse(popover.isOpen)
  }

  func testRelaunchWithASheetOpen() throws {
    try self.show(in: "Attached window")
    try self.main.tap("Rename…")
    XCTAssertNotNil(self.app.settle())
    self.relaunch()
    XCTAssertEqual(self.app.windows.map(\.sceneID), [AppScenes.demos.id], "state starts afresh")
    XCTAssertTrue(self.main.shows("Document: Notes"))
  }
}
