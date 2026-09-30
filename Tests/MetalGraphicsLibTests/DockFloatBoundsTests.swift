@testable import MetalGraphicsLib
import simd
import XCTest

/// A float stays in its area's content, below the window's title bar row: what is drawn above
/// the area — a navigation bar and its toolbar, the traffic lights — never covers its tab, and
/// its tab never covers them. Restored, dropped or dragged, it is placed back inside.
@MainActor
final class DockFloatBoundsTests: XCTestCase {
  /// A docked A, and B floating at `frame`.
  private func makeSpace(floatAt frame: DockRect) -> DockSpace {
    let kinds = ["a", "b"].map { kind in
      DockPanelKind(kind, title: kind.uppercased()) { _ in Rectangle(.contentBackground) }
    }
    return DockSpace(name: "float-bounds", kinds: kinds, persists: false) {
      var layout = DockLayout()
      layout.addPanel(kind: "a", title: "A", id: "a")
      layout.addPanel(kind: "b", title: "B", id: "b")
      layout.hosts = [
        DockHost(id: "main", root: .group(["a"]), floating: [DockFloat(node: .group(["b"]), frame: frame)])
      ]
      return layout
    }
  }

  private func float(_ h: UIHarness) -> DockFloatView {
    h.all(DockFloatView.self).first { $0.mounted }!
  }

  /// The docked group's top left: where the area's content starts.
  private func contentOrigin(_ h: UIHarness) -> float2 {
    h.all(DockTabsView.self).first { $0.panels.contains("a") && $0.mounted }!.rect.min
  }

  private func tab(_ panel: String, _ h: UIHarness) -> DockTabItem {
    h.all(DockTabItem.self).first { $0.panel == panel && $0.mounted }!
  }

  /// As the Storybook restored it: a float saved above the area, under a page's bar and toolbar.
  func testARestoredFloatAboveItsAreaSitsBelowTheBar() {
    let space = self.makeSpace(floatAt: DockRect(x: 10, y: -40, width: 220, height: 140))
    var canvas = 0
    let area = DockArea(space, host: "main")
    let h = UIHarness(size: float2(480, 360)) {
      NavigationStack {
        area
          .navigationTitle("Stories")
          .toolbar {
            Button("Canvas") { canvas += 1 }
          } trailing: {}
      }
    }
    h.settle()
    let bar = try! XCTUnwrap(h.first(StackNavigationBar.self))
    let float = self.float(h)
    let content = self.contentOrigin(h)
    XCTAssertGreaterThanOrEqual(content.y, bar.size.y - 0.5, "the area is under the bar")
    XCTAssertEqual(float.rect.min.y, content.y, accuracy: 0.5, "pulled down into its area")
    XCTAssertEqual(float.rect.min.x, content.x + 10, accuracy: 0.5, "and left where it was across")
    // The toolbar is not covered: its button takes the click.
    let button = try! XCTUnwrap(h.all(Text.self).first { $0.text == "Canvas" })
    h.click(at: button.position + button.size * 0.5)
    XCTAssertEqual(canvas, 1)
    // Nor is the float's tab: it picks the float up, and the move commits inside the area.
    let tab = self.tab("b", h)
    XCTAssertGreaterThanOrEqual(tab.position.y, content.y)
    let start = tab.position + float2(10, tab.size.y * 0.5)
    h.drag(from: start, to: start + float2(60, 40), steps: 3)
    let frame = try! XCTUnwrap(space.layout.host("main")?.floating.first?.frame)
    XCTAssertEqual(frame.origin, float2(70, 40))
  }

  /// Dragged up into the title bar's row, a float stops below it: the traffic lights stay clear.
  func testAFloatDraggedIntoTheTitleBarRowStopsBelowIt() {
    let space = self.makeSpace(floatAt: DockRect(x: 60, y: 120, width: 200, height: 120))
    let h = UIHarness(size: float2(480, 360)) { DockArea(space, host: "main") }
    h.context.setTitleBar(.standard)
    h.settle()
    let tab = self.tab("b", h)
    let start = tab.position + float2(10, tab.size.y * 0.5)
    h.mouseDown(at: start)
    h.mouseDrag(to: start + float2(0, -60))
    h.mouseDrag(to: float2(start.x, 4))
    XCTAssertEqual(self.float(h).dragOrigin?.y ?? -1, TitleBarInsets.standard.top, accuracy: 0.5, "drawn where it will land")
    h.mouseUp(at: float2(start.x, 4))
    let frame = try! XCTUnwrap(space.layout.host("main")?.floating.first?.frame)
    XCTAssertEqual(frame.origin.y, TitleBarInsets.standard.top, accuracy: 0.5)
    XCTAssertEqual(self.float(h).rect.min.y, TitleBarInsets.standard.top, accuracy: 0.5)
  }

  /// Its top edge, resized upwards, stops there too; the bottom stays where it was.
  func testAFloatsTopEdgeStopsBelowTheTitleBarRow() {
    let space = self.makeSpace(floatAt: DockRect(x: 60, y: 120, width: 200, height: 120))
    let h = UIHarness(size: float2(480, 360)) { DockArea(space, host: "main") }
    h.context.setTitleBar(.standard)
    h.settle()
    let rect = self.float(h).rect
    let edge = float2((rect.min.x + rect.max.x) * 0.5, rect.min.y + 1)
    h.drag(from: edge, to: float2(edge.x, 2), steps: 3)
    let frame = try! XCTUnwrap(space.layout.host("main")?.floating.first?.frame)
    XCTAssertEqual(frame.origin.y, TitleBarInsets.standard.top, accuracy: 0.5)
    XCTAssertEqual(frame.origin.y + frame.height, 240, accuracy: 0.5)
  }

  /// Restored past the right and bottom edges — saved in a bigger window — enough of its bar
  /// comes back to take it again. It may still hang off those edges, as a window off screen.
  func testARestoredFloatPastTheEdgesComesBackInReach() {
    let space = self.makeSpace(floatAt: DockRect(x: 900, y: 700, width: 200, height: 120))
    let h = UIHarness(size: float2(480, 360)) { DockArea(space, host: "main") }
    h.settle()
    XCTAssertEqual(self.float(h).rect.min, float2(480, 360) - DockMetrics.floatKeptInView)
    // Placed, not saved: the layout keeps its frame until the float is moved.
    XCTAssertEqual(space.layout.host("main")?.floating.first?.frame.origin, float2(900, 700))
    // Its bar takes a press there.
    let start = self.float(h).rect.min + float2(20, 15)
    h.drag(from: start, to: start - float2(200, 150), steps: 3)
    XCTAssertEqual(space.layout.host("main")?.floating.first?.frame.origin, float2(220, 180))
  }
}
