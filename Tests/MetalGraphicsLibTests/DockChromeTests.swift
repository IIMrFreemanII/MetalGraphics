@testable import MetalGraphicsLib
import simd
import XCTest

/// The window and docking chrome shown in place: traffic lights, a title bar, a floating panel,
/// drop markers and preview, dock tabs and a tab bar.
@MainActor
final class DockChromeTests: XCTestCase {
  func testTabsSelectAndClose() {
    var selected: [Int] = []
    var closed: [Int] = []
    let bar = DockTabBar(
      tabs: [.init("Greeter.swift", icon: .document, isEdited: true), .init("main.swift", icon: .document)],
      style: .document, selection: 0, onSelect: { selected.append($0) }, onClose: { closed.append($0) }
    )
    let h = UIHarness(size: float2(480, 120)) { VStack { bar; Spacer() } }
    h.settle()
    XCTAssertEqual(bar.getSize().y, 40)
    let main = try! XCTUnwrap(h.all(Text.self).first { $0.text == "main.swift" })
    h.click(at: main.position + float2(4, 4))
    XCTAssertEqual(selected, [1])
    // The cross shows on hover, at the tab's trailing edge.
    let tab = try! XCTUnwrap(h.all(DockTabItem.self).last)
    h.move(to: tab.position + float2(4, 4))
    h.click(at: tab.closeRect.min + float2(4, 4))
    XCTAssertEqual(closed, [1])
  }

  func testTrafficLightsReportTheirButton() {
    var pressed: [String] = []
    let lights = TrafficLights(onClose: { pressed.append("close") }, onMinimize: { pressed.append("minimize") }, onZoom: { pressed.append("zoom") })
    let h = UIHarness { lights }
    h.settle()
    let buttons = h.all(HittableView.self)
    XCTAssertEqual(buttons.count, 3)
    for button in buttons { h.click(at: button.position + button.size * 0.5) }
    XCTAssertEqual(pressed, ["close", "minimize", "zoom"])
    XCTAssertEqual(buttons[1].position.x - buttons[0].position.x, 20)
  }

  func testLooks() {
    let h = UIHarness(size: float2(480, 420)) {
      VStack(alignment: .leading, spacing: 14) {
        DockTabBar(tabs: [.init("Outline"), .init("Inspector"), .init("Problems", badge: 3)], selection: 1)
        DockTabBar(tabs: [.init("Greeter.swift", icon: .document, iconColor: .hue(.orange), isEdited: true), .init("main.swift", icon: .document, iconColor: .hue(.orange))], style: .document)
        TitleBar("Notes").frame(width: 300)
        HStack(alignment: .top, spacing: 16) {
          FloatingPanel(grip: true) { Text("Inspector").padding(12) }.frame(width: 160, height: 100)
          DropMarkers(hovered: .right)
          DropPreview().frame(width: 100, height: 96)
        }
        HStack(spacing: 20) {
          TrafficLights()
          TrafficLights().showsGlyphs(true)
          TrafficLights(inactive: true)
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(.contentBackground)
    }
    h.settle()
    assertSnapshot(h.snapshot(), named: "chrome-light", testCase: self)
    h.context.setTheme(.dark)
    h.settle()
    assertSnapshot(h.snapshot(), named: "chrome-dark", testCase: self)
    h.context.setTheme(.light)
  }
}
