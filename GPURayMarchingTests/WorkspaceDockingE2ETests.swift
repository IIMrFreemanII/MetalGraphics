@testable import MetalGraphicsLib
import simd
import XCTest

// The Workspace window's panels: torn out into windows of their own, docked back, and where
// they were after a relaunch.
final class WorkspaceDockingE2ETests: AppTestCase {
  private func openWorkspace() -> HeadlessWindow {
    let workspace = self.app.open(id: Workspace.windowID)
    self.app.step()
    return workspace
  }

  /// Notes' tab dragged well to the right of the workspace window.
  private func tearOutNotes(from workspace: HeadlessWindow) throws -> HeadlessWindow {
    let panel = try XCTUnwrap(self.notesPanelID())
    try workspace.panel(panel).drag(toScreen: workspace.origin + float2(workspace.size.x + 300, 200))
    XCTAssertNotNil(self.app.settle())
    return try XCTUnwrap(self.app.window("dock"))
  }

  private func notesPanelID() -> String? {
    Workspace.space.layout.panels.first { $0.value.kind == "notes" }?.key
  }

  func testATornOutPanelGetsAWindowOfItsOwn() throws {
    let workspace = self.openWorkspace()
    let dock = try self.tearOutNotes(from: workspace)
    XCTAssertTrue(dock.isVisible)
    XCTAssertEqual(dock.title, "Notes")
    XCTAssertNil(workspace.all(DockTabItem.self).first { $0.mounted && $0.panel == self.notesPanelID() })
    XCTAssertTrue(Workspace.space.layout.hosts.contains { $0.isDetached })
  }

  func testAPanelDockedBackClosesItsWindow() throws {
    let workspace = self.openWorkspace()
    let dock = try self.tearOutNotes(from: workspace)
    let outline = try XCTUnwrap(workspace.all(DockTabsView.self).first { $0.mounted && $0.panels.contains { Workspace.space.layout.panels[$0]?.kind == "outline" } })
    let middle = workspace.origin + (outline.rect.min + outline.rect.max) * 0.5
    try dock.panel(try XCTUnwrap(self.notesPanelID())).drag(toScreen: middle)
    XCTAssertNotNil(self.app.settle())
    XCTAssertNil(self.app.window("dock"))
    XCTAssertFalse(Workspace.space.layout.hosts.contains { $0.isDetached })
    XCTAssertTrue(outline.panels.contains { $0 == self.notesPanelID() })
  }

  func testATornOutPanelKeepsItsWindowAfterARelaunch() throws {
    let workspace = self.openWorkspace()
    let frame = try self.tearOutNotes(from: workspace).frame
    self.relaunch()
    let dock = try XCTUnwrap(self.app.window("dock"))
    XCTAssertTrue(dock.isVisible)
    XCTAssertEqual(dock.frame, frame)
    XCTAssertNotNil(self.app.window(Workspace.windowID))
  }

  func testClosingTheWorkspaceHidesItsPanelWindows() throws {
    let workspace = self.openWorkspace()
    let dock = try self.tearOutNotes(from: workspace)
    workspace.close()
    XCTAssertNotNil(self.app.settle())
    XCTAssertFalse(dock.isVisible)

    let reopened = self.openWorkspace()
    XCTAssertNotNil(self.app.settle())
    XCTAssertTrue(dock.isVisible)
    XCTAssertNotNil(reopened.first(DockArea.self))
  }
}
