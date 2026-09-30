@testable import MetalGraphicsLib
import simd
import XCTest

// The design system's shapes: content under a translucent window's title bar, the shared list
// row, the dock's two tab styles, and a form's column.

@MainActor
final class TitleBarTests: XCTestCase {
  private func split(_ link: NavigationLink) -> UIHarness {
    UIHarness(size: float2(600, 300)) {
      NavigationSplitView {
        link.navigationDestination(for: String.self) { value in Text("Page \(value)").navigationTitle("Page") }
      } detail: {
        Text("Select")
      }
    }
  }

  private func contains(_ regions: [float4], _ point: float2) -> Bool {
    regions.contains { r in point.x >= r.x && point.x < r.x + r.z && point.y >= r.y && point.y < r.y + r.w }
  }

  /// Under a title bar the sidebar runs to the top with its content below the traffic lights,
  /// the bar shares the title bar's row, and the empty parts of that row drag the window.
  func testASplitViewMakesRoomForTheTitleBar() {
    let link = NavigationLink("Inbox", value: "inbox")
    let h = self.split(link)
    h.settle()
    XCTAssertEqual(link.face.position.y, NavigationMetrics.sidebarVerticalInset)
    XCTAssertEqual(h.first(StackNavigationBar.self)?.size.y, NavigationMetrics.barHeight)
    XCTAssertTrue(h.context.titleBarDragRegions.isEmpty)

    h.context.setTitleBar(.standard)
    h.settle()
    XCTAssertEqual(link.face.position.y, TitleBarInsets.unifiedBarHeight)
    XCTAssertEqual(h.first(StackNavigationBar.self)?.size.y, TitleBarInsets.unifiedBarHeight)
    let regions = h.context.titleBarDragRegions
    XCTAssertTrue(self.contains(regions, float2(40, 20)), "the traffic lights' strip of the sidebar")
    XCTAssertTrue(self.contains(regions, float2(400, 20)), "the bar")
    XCTAssertFalse(self.contains(regions, float2(40, 70)), "the sidebar's links")

    // Full screen: no title bar over the content.
    h.context.setTitleBar(.zero)
    h.settle()
    XCTAssertEqual(link.face.position.y, NavigationMetrics.sidebarVerticalInset)
    XCTAssertTrue(h.context.titleBarDragRegions.isEmpty)
  }

  func testTheSelectedSidebarLinkIsMediumWeight() {
    let link = NavigationLink("Inbox", value: "inbox")
    let h = self.split(link)
    h.settle()
    h.click(at: link.face.position + link.face.size * 0.5)
    h.settle()
    XCTAssertTrue(link.face.isSelected)
    XCTAssertEqual(h.all(Text.self).first { $0.text == "Inbox" }?.font.weight, .medium)
    // A 26 pt row.
    XCTAssertEqual(link.face.size.y, 26, accuracy: 1)
  }

  // MARK: - List row

  func testAListRowHighlightsOnHoverAndSelection() {
    var taps = 0
    let row = ListRow(action: { taps += 1 }) { Text("Row") }
    let h = UIHarness(size: float2(200, 60)) { row.frame(width: 200) }
    h.settle()
    let face = h.first(ListRowFace.self)!
    XCTAssertEqual(face.size.y, 24)
    let background = h.pixel(at: float2(100, 30))

    h.move(to: float2(100, face.position.y + 12))
    h.step()
    XCTAssertTrue(face.isHovered)
    XCTAssertNotEqual(h.pixel(at: float2(100, face.position.y + 12)), background)
    // Moving within it changes nothing: no frame.
    h.settle()
    h.move(to: float2(110, face.position.y + 12))
    h.step()
    XCTAssertFalse(h.context.needsRender)

    h.click(at: float2(100, face.position.y + 12))
    XCTAssertEqual(taps, 1)

    row.setSelected(true, h.context)
    XCTAssertTrue(h.context.pending.contains(.layout), "a standard row's label turns medium")
    h.settle()
    XCTAssertEqual(h.first(Text.self)?.font.weight, .medium)
  }

  func testAProminentRowIsFilledWithTheAccent() {
    let row = ListRow(selected: true, selectionStyle: .prominent) { Text("Row") }
    let h = UIHarness(size: float2(200, 40)) { row.frame(width: 200) }
    h.settle()
    let accent = Theme.light[.accent]
    let pixel = h.pixel(at: float2(190, h.first(ListRowFace.self)!.position.y + 12))
    XCTAssertEqual(Float(pixel.z) / 255, accent.z, accuracy: 0.02)
    XCTAssertEqual(Float(pixel.x) / 255, accent.x, accuracy: 0.02)
  }

  // MARK: - Form

  func testAFormIsACentredColumnWithItsFieldsAtTheTrailingEdge() {
    let h = UIHarness(size: float2(900, 300)) {
      Form {
        Section("Account") {
          TextField("Name", text: "")
        }
      }
    }
    h.settle()
    let card = h.first(SectionCard.self)!
    XCTAssertEqual(card.size.x, FormMetrics.maxWidth)
    XCTAssertEqual(card.position.x, (900 - FormMetrics.maxWidth) * 0.5, accuracy: 1)
    let box = h.first(FieldBox.self)!
    XCTAssertEqual(box.size.x, FormMetrics.fieldWidth)
    XCTAssertEqual(box.position.x + box.size.x, card.position.x + card.size.x - FormMetrics.rowInset.right, accuracy: 1)
  }
}

// MARK: - Dock tab styles

@MainActor
final class DockTabStyleTests: XCTestCase {
  private func makeSpace() -> DockSpace {
    let kinds = [
      DockPanelKind("files", title: "Files", background: .sidebarTint) { _ in Rectangle(.clear) },
      DockPanelKind(
        "doc", title: "Doc", tabStyle: .document, tabIcon: { _ in (.document, .hue(.orange)) }
      ) { _ in Rectangle(.clear) },
    ]
    return DockSpace(name: "tab-styles", kinds: kinds, persists: false) {
      var layout = DockLayout()
      layout.addPanel(kind: "files", title: "Files", id: "files")
      layout.addPanel(kind: "doc", title: "Main.swift", id: "main")
      layout.addPanel(kind: "doc", title: "Other.swift", id: "other")
      layout.hosts = [DockHost(id: "main", root: .row([.group(["files"]), .group(["main", "other"])]))]
      return layout
    }
  }

  private func group(_ panel: String, _ h: UIHarness) -> DockTabsView {
    h.all(DockTabsView.self).first { $0.panels.contains(panel) && $0.mounted }!
  }

  private func tab(_ panel: String, _ h: UIHarness) -> DockTabItem {
    h.all(DockTabItem.self).first { $0.panel == panel && $0.mounted }!
  }

  func testEachStyleHasItsBar() {
    let space = self.makeSpace()
    let h = UIHarness(size: float2(600, 300)) { DockArea(space, host: "main") }
    h.settle()
    XCTAssertEqual(self.group("files", h).barHeight, DockTabMetrics.panel.barHeight)
    XCTAssertEqual(self.group("main", h).barHeight, DockTabMetrics.document.barHeight)
    XCTAssertEqual(self.tab("main", h).size.y, DockTabMetrics.document.pillHeight)
    XCTAssertEqual(self.tab("files", h).size.y, DockTabMetrics.panel.pillHeight)
  }

  /// At the window's top, a panel bar sits under the title bar's empty row, and a document bar
  /// is that row, its tabs clear of the traffic lights.
  func testTabBarsShareTheTitleBarRow() {
    let space = self.makeSpace()
    let h = UIHarness(size: float2(600, 300)) { DockArea(space, host: "main") }
    h.context.setTitleBar(TitleBarInsets(top: 32, leading: 400))
    h.settle()
    let files = self.group("files", h)
    XCTAssertEqual(files.rowHeight, TitleBarInsets.dockRowHeight)
    XCTAssertEqual(files.barRect.min.y, TitleBarInsets.dockRowHeight)
    let documents = self.group("main", h)
    XCTAssertEqual(documents.rowHeight, 0)
    XCTAssertGreaterThanOrEqual(self.tab("main", h).position.x, 400)
    XCTAssertFalse(h.context.titleBarDragRegions.isEmpty)
  }

  /// The close button shows only while the pointer is over the tab.
  func testTheCloseButtonShowsOnHover() {
    let space = self.makeSpace()
    let h = UIHarness(size: float2(600, 300)) { DockArea(space, host: "main") }
    h.settle()
    let main = self.tab("main", h)
    let close = main.closeRect
    let point = (close.min + close.max) * 0.5
    let before = h.pixel(at: point)
    h.move(to: main.position + float2(20, main.size.y * 0.5))
    h.settle()
    XCTAssertNotEqual(h.pixel(at: point), before, "the cross is drawn once hovered")
    h.click(at: point)
    XCTAssertNil(space.layout.panels["main"])
  }

  func testATabShowsItsIconEditedDotAndBadge() {
    let space = self.makeSpace()
    // Wide enough that no tab is squeezed, with the dot or without.
    let h = UIHarness(size: float2(900, 300)) { DockArea(space, host: "main") }
    h.settle()
    let width = self.tab("main", h).size.x
    space.decorate(panel: "main") { $0.isEdited = true }
    h.settle()
    XCTAssertTrue(self.tab("main", h).isEdited)
    XCTAssertEqual(self.tab("main", h).size.x, width + DockTabMetrics.gap + DockTabMetrics.dotSize, accuracy: 0.5)
    space.decorate(panel: "files") { $0.badge = 3 }
    h.settle()
    XCTAssertEqual(self.tab("files", h).badge, 3)
    // Decorations are not saved with the layout.
    let data = try! JSONEncoder().encode(space.layout.panels["main"]!)
    XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("isEdited"))
  }
}
