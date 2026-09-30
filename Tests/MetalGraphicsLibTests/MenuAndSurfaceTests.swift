@testable import MetalGraphicsLib
import simd
import XCTest

/// Menus, context menus, and the surfaces and picker panels shown in place.
@MainActor
final class MenuAndSurfaceTests: XCTestCase {
  func testAMenuOpensChoosesAndCloses() {
    var chosen: [String] = []
    let menu = Menu("Sort") {
      MenuItem("Name", checked: true) { chosen.append("name") }
      MenuItem("Date", shortcut: "⌘D") { chosen.append("date") }
      MenuSeparator()
      MenuItem("Delete", role: .destructive, disabled: true) { chosen.append("delete") }
    }
    let h = UIHarness(size: float2(400, 300)) { menu.padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) }
    h.settle()
    h.click(at: float2(40, 32))
    h.settle()
    let date = try! XCTUnwrap(h.overlayAll(Text.self).first { $0.text == "Date" })
    XCTAssertTrue(h.overlayAll(Text.self).contains { $0.text == "⌘D" })
    h.click(at: date.position + float2(4, 4))
    h.settle()
    XCTAssertEqual(chosen, ["date"])
    XCTAssertTrue(h.overlayAll(Text.self).isEmpty, "closed")
  }

  func testArrowsAndReturnChooseADisabledItemIsSkipped() {
    var chosen: [String] = []
    let menu = Menu("Sort") {
      MenuItem("Name") { chosen.append("name") }
      MenuItem("Size", disabled: true) { chosen.append("size") }
      MenuItem("Date") { chosen.append("date") }
    }
    let h = UIHarness(size: float2(400, 300)) { menu.padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) }
    h.settle()
    h.click(at: float2(40, 32))
    h.settle()
    h.press(.downArrow)
    h.press(.downArrow)
    h.press(.return)
    h.settle()
    XCTAssertEqual(chosen, ["date"])
  }

  func testARightClickOpensAContextMenuAndALeftClickStillTaps() {
    var taps = 0
    var chosen: [String] = []
    let target = Button("Row") { taps += 1 }
      .contextMenu {
        MenuItem("Rename") { chosen.append("rename") }
        MenuItem("Delete", role: .destructive) { chosen.append("delete") }
      }
    let h = UIHarness(size: float2(400, 300)) { target.padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) }
    h.settle()
    h.click(at: float2(36, 32))
    XCTAssertEqual(taps, 1)
    h.rightClick(at: float2(36, 32))
    h.settle()
    XCTAssertEqual(taps, 1, "a right click on a view with a context menu does not tap")
    let rename = try! XCTUnwrap(h.overlayAll(Text.self).first { $0.text == "Rename" })
    h.click(at: rename.position + float2(4, 4))
    h.settle()
    XCTAssertEqual(chosen, ["rename"])
  }

  func testARightClickWithoutAContextMenuStillTaps() {
    var taps = 0
    let h = UIHarness { Button("Tap") { taps += 1 } }
    h.settle()
    h.rightClick(at: float2(160, 120))
    XCTAssertEqual(taps, 1)
  }

  func testHelpShowsAfterARestAndGoesWhenThePointerLeaves() {
    var taps = 0
    let button = Button("Build") { taps += 1 }.help("Build the package (⌘B)")
    let h = UIHarness(size: float2(400, 300)) { button }
    h.settle()
    h.move(to: float2(200, 150))
    XCTAssertTrue(h.overlayAll(Text.self).isEmpty, "not at once")
    XCTAssertTrue(h.isIdle, "idle while it waits: a wake times it, not an animation")
    h.advance(0.7)
    XCTAssertNotNil(h.settle())
    let tip = try! XCTUnwrap(h.overlayAll(Text.self).first { $0.text == "Build the package (⌘B)" })
    XCTAssertGreaterThan(tip.position.y, 150, "under the button")
    // It takes no clicks: the button under the pointer still does.
    h.click(at: float2(200, 150))
    XCTAssertEqual(taps, 1)
    h.move(to: float2(10, 10))
    XCTAssertNotNil(h.settle())
    XCTAssertTrue(h.overlayAll(Text.self).isEmpty)
  }

  func testAlertsLayOutTheirActions() {
    let two = Alert("Delete “Notes”?", message: "This can’t be undone.") {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {}
    }
    let three = Alert("Save changes?", message: "Your changes will be lost.") {
      Button("Save") {}
      Button("Don’t Save", role: .destructive) {}
      Button("Cancel", role: .cancel) {}
    }
    let h = UIHarness(size: float2(620, 320)) { HStack(alignment: .top, spacing: 20) { two; three } }
    h.settle()
    let texts = h.all(Text.self)
    func y(_ text: String) -> Float { texts.first { $0.text == text }!.position.y }
    XCTAssertEqual(y("Cancel"), y("Delete"), accuracy: 1, "two side by side")
    XCTAssertLessThan(y("Save"), y("Don’t Save"))
    XCTAssertLessThan(y("Don’t Save"), texts.last { $0.text == "Cancel" }!.position.y, "stacked, cancel last")
    XCTAssertEqual(two.getSize().x, Alert.width)
  }

  func testAConfirmationDialogAddsCancel() {
    let dialog = ConfirmationDialog("Discard the draft?") { Button("Discard", role: .destructive) {} }
    let h = UIHarness(size: float2(400, 300)) { dialog }
    h.settle()
    XCTAssertTrue(h.all(Text.self).contains { $0.text == "Cancel" })
  }

  func testPickerPanelsReportAndFollow() {
    var colors: [float4] = []
    let panel = ColorPickerPanel(selection: float4(1, 0, 0, 1)) { colors.append($0) }  // design: a picked colour
    var dates: [Date] = []
    let day = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 14, minute: 30))!
    let time = TimePanel(selection: day) { dates.append($0) }
    let h = UIHarness(size: float2(700, 400)) { HStack(alignment: .top, spacing: 20) { panel; time } }
    h.settle()
    // A swatch: the grid's top left.
    let swatch = try! XCTUnwrap(h.all(HittableView.self).first)
    h.click(at: swatch.position + float2(4, 4))
    XCTAssertEqual(colors.count, 1)
    // The hour's +.
    let plus = h.all(HittableView.self).filter { $0.position.x > 400 }.map(\.position)
    XCTAssertFalse(plus.isEmpty)
    time.setSelection(day.addingTimeInterval(3600), h.context)
    h.settle()
    XCTAssertTrue(h.all(Text.self).contains { $0.text == "Hour: 15" })
  }

  // Two columns under 500 pt: `UIHarness` draws only a band that wide.
  func testLooks() {
    let h = UIHarness(size: float2(500, 420)) {
      HStack(alignment: .top, spacing: 16) {
        VStack(alignment: .leading, spacing: 16) {
          MenuPanel(width: 164) {
            MenuItem("Cut", shortcut: "⌘X") {}
            MenuItem("Copy", shortcut: "⌘C") {}
            MenuItem("Show Minimap", checked: true) {}
            MenuSeparator()
            MenuItem("Delete", role: .destructive) {}
            MenuItem("Rename…", disabled: true) {}
          }
          Popover { Text("A popover's card").padding(12) }
        }
        VStack(alignment: .leading, spacing: 16) {
          Alert("Delete “Notes”?", message: "This can’t be undone.") {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {}
          }
          Sheet(title: "Rename", width: 260) {
            Text("Greeter.swift").foregroundColor(.secondaryLabel)
          } actions: {
            Button("Cancel", role: .cancel) {}
            Button("Rename") {}.buttonStyle(.borderedProminent)
          }
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(.windowBackground)
    }
    h.settle()
    assertSnapshot(h.snapshot(), named: "surfaces-light", testCase: self)
    h.context.setTheme(.dark)
    h.settle()
    assertSnapshot(h.snapshot(), named: "surfaces-dark", testCase: self)
    h.context.setTheme(.light)
  }
}
