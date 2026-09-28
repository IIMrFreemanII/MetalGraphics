@testable import MetalGraphicsLib
import simd
import XCTest

/// The design system's smaller components, as the web mirror has them: a labelled `ListRow`,
/// `Tooltip`, `ToggleChip`, `StatusBar`, `InsertionLine`, `ScrollIndicator`, `SidebarTitle`,
/// `DockGap` and a pill `Picker`. Sizes, states, setters, and how they look light and dark.
@MainActor
final class DesignComponentsTests: XCTestCase {
  // MARK: - ListRow

  func testALabelledRowHasItsPartsInOrder() {
    let row = ListRow("cannot find 'nam' in scope", subtitle: "Greeter.swift:4:36", detail: "Error", status: .error, height: 38)
    let h = UIHarness(size: float2(400, 80)) { row }
    h.settle()
    let texts = h.all(Text.self).map(\.text)
    XCTAssertEqual(texts, ["cannot find 'nam' in scope", "Greeter.swift:4:36", "Error"])
    XCTAssertEqual(row.getSize().y, 38)
    // The status square comes first, 8 points, at the leading inset.
    let mark = try! XCTUnwrap(h.all(Background.self).first)
    XCTAssertEqual(mark.getSize(), float2(8, 8))
    let label = h.all(Text.self)[0]
    XCTAssertGreaterThan(label.position.x, 8 + 8 + 8)
    // The detail sits at the trailing edge.
    let detail = h.all(Text.self)[2]
    XCTAssertEqual(detail.position.x + detail.size.x, 400 - 8 - 8, accuracy: 1)
  }

  func testALabelledRowsPartsComeAndGo() {
    let row = ListRow("main.swift")
    let h = UIHarness(size: float2(300, 60)) { row }
    h.settle()
    XCTAssertEqual(h.all(Text.self).map(\.text), ["main.swift"])
    row.setSubtitle("Sources/App", h.context)
    row.setDetail("12 KB", h.context)
    row.setStatus(.warning, h.context)
    h.settle()
    XCTAssertEqual(h.all(Text.self).map(\.text), ["main.swift", "Sources/App", "12 KB"])
    XCTAssertEqual(h.all(Background.self).count, 1)
    row.setLabel("Greeter.swift", h.context)
    row.setSubtitle(nil, h.context)
    row.setStatus(nil, h.context)
    h.settle()
    XCTAssertEqual(h.all(Text.self).map(\.text), ["Greeter.swift", "12 KB"])
    XCTAssertEqual(h.all(Background.self).count, 0)
  }

  func testAccessoriesGoBetweenTheStatusAndTheLabel() {
    let badge = KindBadge("S", color: KindBadge.color(forLetter: "S"))
    let row = ListRow("Greeter", status: .note, content: { badge })
    let h = UIHarness(size: float2(300, 40)) { row }
    h.settle()
    let label = try! XCTUnwrap(h.all(Text.self).first { $0.text == "Greeter" })
    XCTAssertTrue(badge.mounted)
    XCTAssertLessThan(badge.position.x, label.position.x)
    XCTAssertEqual(KindBadge.color(forLetter: "Pr"), .hue(.indigo))
    XCTAssertEqual(KindBadge.color(forLetter: "?"), .hue(.gray))
  }

  // MARK: - Chips, tooltips, bars

  func testAToggleChipReportsAFlipAndShowsWhatItIsGiven() {
    var reported: [Bool] = []
    let chip = ToggleChip("Aa", isOn: false) { reported.append($0) }
    let h = UIHarness { chip }
    h.settle()
    h.click(at: float2(160, 120))
    XCTAssertEqual(reported, [true])
    XCTAssertFalse(chip.isOn, "controlled: it shows what it is given")
    chip.setIsOn(true, h.context)
    XCTAssertTrue(chip.isOn)
    XCTAssertTrue(h.context.needsRender)
  }

  func testAMultilineTooltipWrapsAt420() {
    let long = String(repeating: "A hover card wraps its text. ", count: 12)
    let tip = Tooltip(long, multiline: true)
    let h = UIHarness(size: float2(600, 300)) { tip }
    h.settle()
    let text = try! XCTUnwrap(h.all(Text.self).first)
    XCTAssertLessThanOrEqual(text.size.x, TooltipMetrics.maxWidth - 16)
    XCTAssertGreaterThan(text.size.y, 30, "several lines")
    let short = Tooltip("Build")
    let g = UIHarness { short }
    g.settle()
    XCTAssertEqual(try! XCTUnwrap(g.all(Text.self).first).size.y, 15, accuracy: 3)
  }

  func testAStatusBarIs24High() {
    let bar = StatusBar(position: "Ln 2, Col 11", problem: "", file: "Greeter.swift")
    let h = UIHarness(size: float2(400, 100)) { VStack { Spacer(); bar } }
    h.settle()
    XCTAssertEqual(bar.getSize().y, StatusBarMetrics.height)
    bar.setProblem("The file changed on disk.", h.context)
    h.settle()
    XCTAssertTrue(h.all(Text.self).contains { $0.text == "The file changed on disk." })
  }

  func testSmallPiecesTakeTheirSizes() {
    let line = InsertionLine(indent: 12)
    let bar = ScrollIndicator(length: 80)
    let gap = DockGap(vertical: true)
    let h = UIHarness(size: float2(300, 200)) {
      HStack(alignment: .top, spacing: 10) {
        line.frame(width: 100)
        bar
        gap.frame(height: 60)
      }
    }
    h.settle()
    XCTAssertEqual(line.getSize(), float2(100, InsertionLine.thickness))
    XCTAssertEqual(bar.getSize(), float2(5, 80))
    XCTAssertEqual(gap.getSize(), float2(1, 60))
  }

  func testAPickerCanDropItsChevrons() {
    let plain = Picker("", selection: 0, content: { Text("Oct 1, 2026").tag(0) }).menuIndicator(.hidden)
    let chevrons = Picker("", selection: 0, content: { Text("Oct 1, 2026").tag(0) })
    let h = UIHarness { VStack(alignment: .leading, spacing: 8) { plain; chevrons } }
    h.settle()
    XCTAssertLessThan(plain.getSize().x, chevrons.getSize().x, "no ⌃⌄ tile")
  }

  // MARK: - Looks

  private func gallery() -> UIElement {
    VStack(alignment: .leading, spacing: 10) {
      SidebarTitle("Problems")
      ListRow("cannot find 'nam' in scope", subtitle: "Sources/App/Greeter.swift:4:36", status: .error, height: 38, spacing: 10)
      ListRow("result unused", subtitle: "Sources/App/main.swift:2:1", status: .warning, selected: true, height: 38, spacing: 10)
      ListRow("print(_:)", detail: "Void", selected: true, selectionStyle: .prominent, margin: 0, spacing: 8, content: {
        KindBadge("M", color: KindBadge.color(forLetter: "M"))
      })
      HStack(spacing: 6) {
        ToggleChip("Aa", isOn: true)
        ToggleChip("Word", isOn: false)
        ToggleChip(".*", isOn: true)
        Spacer()
        Tooltip("Build and run (⌘R)")
      }
      .padding(Inset(horizontal: 8))
      InsertionLine(indent: 8)
      HStack(spacing: 10) {
        ScrollIndicator(length: 40)
        DockGap().frame(height: 40)
        Tooltip("let greeting: String\nThe text to print.", multiline: true)
      }
      .padding(Inset(horizontal: 8))
      StatusBar(position: "Ln 4, Col 36", problem: "1 error", file: "Greeter.swift")
    }
    .frame(width: 420)
    .padding(Inset(vertical: 12, horizontal: 0))
    .background(.contentBackground)
  }

  func testLooks() {
    let h = UIHarness(size: float2(420, 380)) { self.gallery() }
    h.settle()
    assertSnapshot(h.snapshot(), named: "components-light", testCase: self)
    h.context.setTheme(.dark)
    h.settle()
    assertSnapshot(h.snapshot(), named: "components-dark", testCase: self)
    h.context.setTheme(.light)
  }
}
