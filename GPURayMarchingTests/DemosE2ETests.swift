@testable import MetalGraphicsLib
import XCTest

// The Demos window: its sidebar, picking a demo, and each window reopening on its own demo.
final class DemosE2ETests: AppTestCase {
  func testLaunchShowsEveryDemoInTheSidebar() {
    for demo in Demo.allCases {
      XCTAssertFalse(self.main.find(text: demo.title).isEmpty, "No \(demo.title) in the sidebar")
    }
    XCTAssertTrue(self.main.isKey)
  }

  func testPickingADemoShowsIt() throws {
    try self.main.tap("Form")
    XCTAssertTrue(self.main.shows("Signed in as"))
    XCTAssertTrue(self.main.shows("Guest"))
  }

  func testTheDemoIsReopenedAfterARelaunch() throws {
    try self.main.tap("Form")
    self.relaunch()
    XCTAssertTrue(self.main.shows("Signed in as"))
  }

  func testEachWindowKeepsItsOwnDemo() throws {
    try self.main.tap("Form")
    let second = self.app.open(id: AppScenes.demos.id)
    self.app.step()
    // A new window opens on the demo last picked in any.
    XCTAssertTrue(second.shows("Signed in as"))
    try second.tap("Windows")
    XCTAssertTrue(second.shows("Shared by every window"))
    XCTAssertTrue(self.main.shows("Signed in as"))

    self.relaunch()
    XCTAssertTrue(try XCTUnwrap(self.app.window(AppScenes.demos.id, index: 0)).shows("Signed in as"))
    XCTAssertTrue(try XCTUnwrap(self.app.window(AppScenes.demos.id, index: 1)).shows("Shared by every window"))
  }
}
