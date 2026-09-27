@testable import MetalGraphicsLib
import XCTest

// `AppModel` shared by the Windows demo and the Shared State window: a window opened from a
// handler, and writes in one reaching the other.
final class SharedStateE2ETests: AppTestCase {
  /// The Windows demo in `main`, and the Shared State window opened from it.
  private func openSharedState() throws -> HeadlessWindow {
    try self.main.tap("Windows")
    try self.main.tap("Open Shared State window")
    let shared = try XCTUnwrap(self.app.window(SharedStateWindow.id))
    self.app.step()
    return shared
  }

  func testTheWindowsDemoOpensTheSharedStateWindow() throws {
    let shared = try self.openSharedState()
    XCTAssertTrue(shared.isKey)
    XCTAssertTrue(shared.shows("Hello from every window"))

    // A single window: asking again brings the same one back.
    try self.main.tap("Open Shared State window")
    XCTAssertEqual(self.app.windows.filter { $0.sceneID == SharedStateWindow.id }.count, 1)
    XCTAssertTrue(shared.isKey)
  }

  func testCountingInOneWindowShowsInTheOther() throws {
    let shared = try self.openSharedState()
    try shared.tap("+")
    XCTAssertEqual(AppModel.shared.count, 1)
    XCTAssertTrue(shared.shows("1"))
    XCTAssertTrue(self.main.shows("Count: 1"))

    try self.main.tap("+")
    XCTAssertTrue(shared.shows("2"))
  }

  func testHighlightingInOneWindowShowsInTheOther() throws {
    let shared = try self.openSharedState()
    XCTAssertFalse(self.main.shows("Highlighted in every window"))
    try shared.toggle("Highlight")
    XCTAssertTrue(self.main.shows("Highlighted in every window"))
  }

  func testTheSharedStateWindowLooksRight() throws {
    let shared = try self.openSharedState()
    XCTAssertNotNil(self.app.settle())
    assertSnapshot(shared.snapshot(), named: "shared-state", testCase: self)
  }
}
