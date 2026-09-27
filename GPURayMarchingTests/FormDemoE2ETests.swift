@testable import MetalGraphicsLib
import XCTest

// The Form demo's controls, driven as a user would: typing, Return, toggles.
final class FormDemoE2ETests: AppTestCase {
  override func setUp() {
    super.setUp()
    try! self.main.tap("Form")
  }

  func testTypingANameSignsIn() throws {
    try self.main.type("Ada", into: "Name")
    XCTAssertTrue(self.main.shows("Ada"))
    XCTAssertFalse(self.main.shows("Guest"))
  }

  func testReturnSubmitsTheName() throws {
    try self.main.type("Ada", into: "Name")
    XCTAssertTrue(self.main.find(text: "nothing yet").count == 1)
    self.main.press(.return)
    XCTAssertTrue(self.main.find(text: "nothing yet").isEmpty)
  }

  func testTogglingNotifications() throws {
    let toggle = try XCTUnwrap(try self.main.control(labelled: "Notifications").element as? Toggle)
    XCTAssertTrue(toggle.isOn)
    try self.main.toggle("Notifications")
    XCTAssertFalse(toggle.isOn)
  }
}
