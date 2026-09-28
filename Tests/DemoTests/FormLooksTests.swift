@testable import Demo
@testable import MetalGraphicsLib
import XCTest

// How the Demos window's sidebar, the Form demo and the popovers its controls open look, light and
// dark. The dates are fixed, so the calendar and the summary never follow the wall clock.
final class FormLooksTests: AppTestCase {
  private static let moment = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 14, minute: 30))!

  override func setUp() {
    FormDemo.now = { FormLooksTests.moment }
    CalendarView.today = { FormLooksTests.moment }
    super.setUp()
  }

  override func tearDown() {
    FormDemo.now = Date.init
    CalendarView.today = Date.init
    super.tearDown()
  }

  /// `element` in light, then in dark, grown by `margin` for its shadow.
  private func assertLooks(_ element: () -> UIElement?, margin: Float = 0, named name: String, file: StaticString = #filePath, line: UInt = #line) throws {
    XCTAssertNotNil(self.app.settle(), file: file, line: line)
    let shown = try XCTUnwrap(element(), file: file, line: line)
    assertSnapshot(self.main.snapshot(of: shown, margin: margin), named: "\(name)-light", file: file, line: line, testCase: self)
    self.app.setAppearance(.dark)
    XCTAssertNotNil(self.app.settle(), file: file, line: line)
    assertSnapshot(self.main.snapshot(of: shown, margin: margin), named: "\(name)-dark", file: file, line: line, testCase: self)
  }

  /// The popover open in the Demos window, in light then in dark, with room for its shadow.
  private func assertPopover(named name: String, file: StaticString = #filePath, line: UInt = #line) throws {
    XCTAssertNotNil(self.app.settle(), file: file, line: line)
    let popover = try XCTUnwrap(self.main.all(PopoverLayer.self).first { $0.mounted }, file: file, line: line)
    assertSnapshot(self.main.snapshot(of: popover, margin: 24), named: "\(name)-light", file: file, line: line, testCase: self)
    self.app.setAppearance(.dark)
    XCTAssertNotNil(self.app.settle(), file: file, line: line)
    assertSnapshot(self.main.snapshot(of: popover, margin: 24), named: "\(name)-dark", file: file, line: line, testCase: self)
  }

  func testSidebar() throws {
    try self.assertLooks({ self.main.all(Sidebar.self).first { $0.mounted } }, named: "sidebar")
  }

  func testForm() throws {
    try self.main.tap("Form")
    XCTAssertNotNil(self.app.settle())
    let image = self.main.snapshot()
    assertSnapshot(image, named: "form-light", testCase: self)
    self.app.setAppearance(.dark)
    XCTAssertNotNil(self.app.settle())
    assertSnapshot(self.main.snapshot(), named: "form-dark", testCase: self)
  }

  /// Scrolls the form until `label` is in view, and taps its control.
  private func open(_ label: String) throws {
    try self.main.tap("Form")
    let scroll = try XCTUnwrap(self.main.all(ScrollView.self).first { $0.mounted && ($0.nearestAncestor(Form.self) != nil || HeadlessQuery.first(Form.self, in: $0) != nil) })
    for _ in 0 ..< 40 where !self.main.shows(label) {
      self.main.scroll(by: float2(0, -120), at: HeadlessQuery.geometry(of: scroll)!.center)
    }
    try self.main.control(labelled: label).tap()
    self.app.step()
  }

  func testPickerMenu() throws {
    try self.open("Theme")
    try self.assertPopover(named: "picker-menu")
  }

  func testColorPopover() throws {
    try self.open("Tint")
    try self.assertPopover(named: "color-popover")
  }

  func testDatePopover() throws {
    try self.open("Due")
    try self.assertPopover(named: "date-popover")
  }

  func testTimePopover() throws {
    try self.main.tap("Form")
    try self.main.tap("14:30")
    self.app.step()
    try self.assertPopover(named: "time-popover")
  }
}
