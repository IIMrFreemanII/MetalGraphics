@testable import MetalGraphicsLib
import XCTest

// The docking layout as a value: every move, and what `normalize` keeps tidy.

final class DockLayoutTests: XCTestCase {
  /// main: a row of [a, b] and a column of [c] over [d].
  private func makeLayout() -> (DockLayout, left: String, c: String, d: String) {
    var layout = DockLayout()
    for panel in ["a", "b", "c", "d"] {
      layout.addPanel(kind: "k", title: panel.uppercased(), id: panel)
    }
    let left = DockNode.group(["a", "b"])
    let c = DockNode.group(["c"])
    let d = DockNode.group(["d"])
    layout.hosts = [DockHost(id: "main", root: .row([left, .column([c, d])]))]
    return (layout, left.id, c.id, d.id)
  }

  private func groups(_ node: DockNode?) -> [[String]] {
    switch node {
    case nil: return []
    case .tabs(let tabs): return [tabs.panels]
    case .split(let split): return split.children.flatMap(self.groups)
    }
  }

  func testPlacePutsNewPanelsAtATarget() {
    var (layout, left, c, _) = self.makeLayout()
    let e = layout.addPanel(kind: "k", title: "E", id: "e")
    XCTAssertTrue(layout.place(.group([e]), at: .node(left, .center)))
    XCTAssertEqual(self.groups(layout.host("main")?.root), [["a", "b", "e"], ["c"], ["d"]])
    XCTAssertEqual(layout.tabs(holding: "e")?.selected, "e")

    let f = layout.addPanel(kind: "k", title: "F", id: "f")
    XCTAssertTrue(layout.place(.group([f]), at: .node(c, .right)))
    XCTAssertEqual(self.groups(layout.host("main")?.root), [["a", "b", "e"], ["c"], ["f"], ["d"]])

    // Nowhere to go: nothing changes, and a panel placed nowhere is forgotten.
    let g = layout.addPanel(kind: "k", title: "G", id: "g")
    XCTAssertFalse(layout.place(.group([g]), at: .node("missing", .center)))
    layout.normalize()
    XCTAssertNil(layout.panels["g"])
  }

  func testCenterDropAddsTabsAndShowsThem() {
    var (layout, left, _, _) = self.makeLayout()
    XCTAssertNotNil(layout.move(.panel("d"), to: .node(left, .center)))
    XCTAssertEqual(self.groups(layout.host("main")?.root), [["a", "b", "d"], ["c"]])
    XCTAssertEqual(layout.tabs(holding: "d")?.selected, "d")
    // The column of one left behind is gone: `c` sits in the row directly.
    guard case .split(let row) = layout.host("main")?.root else { return XCTFail() }
    XCTAssertEqual(row.children.count, 2)
    XCTAssertEqual(row.fractions.reduce(0, +), 1, accuracy: 1e-5)
  }

  func testEdgeDropSplitsTheGroup() {
    var (layout, _, c, _) = self.makeLayout()
    layout.move(.panel("b"), to: .node(c, .left))
    guard case .split(let row) = layout.host("main")?.root, case .split(let column) = row.children[1],
          case .split(let inner) = column.children[0]
    else { return XCTFail("\(String(describing: layout.host("main")?.root))") }
    XCTAssertEqual(inner.axis, .horizontal)
    XCTAssertEqual(self.groups(.split(inner)), [["b"], ["c"]])
    XCTAssertEqual(self.groups(.split(row)), [["a"], ["b"], ["c"], ["d"]])
  }

  func testEdgeDropAlongTheSplitsAxisJoinsIt() {
    var (layout, _, c, _) = self.makeLayout()
    // The column is vertical: a drop on c's top goes into it, not into a new split.
    layout.move(.panel("a"), to: .node(c, .top))
    guard case .split(let row) = layout.host("main")?.root, case .split(let column) = row.children[1] else {
      return XCTFail()
    }
    XCTAssertEqual(column.axis, .vertical)
    XCTAssertEqual(self.groups(.split(column)), [["a"], ["c"], ["d"]])
    XCTAssertEqual(column.fractions.reduce(0, +), 1, accuracy: 1e-5)
  }

  func testHostEdgeDockAlongEverything() {
    var (layout, _, _, d) = self.makeLayout()
    layout.move(.node(d), to: .hostEdge("main", .bottom))
    guard case .split(let column) = layout.host("main")?.root else { return XCTFail() }
    XCTAssertEqual(column.axis, .vertical)
    XCTAssertEqual(self.groups(column.children.last), [["d"]])
    XCTAssertEqual(column.fractions.last!, DockMetrics.edgeFraction, accuracy: 1e-5)
  }

  func testFloatThenDockBack() {
    var (layout, left, _, _) = self.makeLayout()
    let frame = DockRect(x: 10, y: 20, width: 200, height: 150)
    let group = layout.move(.panel("c"), to: .float("main", frame))
    XCTAssertEqual(layout.host("main")?.floating.count, 1)
    XCTAssertEqual(layout.host("main")?.floating.first?.frame, frame)
    XCTAssertEqual(self.groups(layout.host("main")?.root), [["a", "b"], ["d"]])
    layout.move(.node(group!), to: .node(left, .right))
    XCTAssertEqual(layout.host("main")?.floating.count, 0)
    XCTAssertEqual(self.groups(layout.host("main")?.root), [["a", "b"], ["c"], ["d"]])
  }

  func testTearOutMakesADetachedHostAndMergingRemovesIt() {
    var (layout, left, c, _) = self.makeLayout()
    layout.move(.node(c), to: .newHost("w"))
    XCTAssertEqual(layout.host("w")?.isDetached, true)
    XCTAssertEqual(self.groups(layout.host("w")?.root), [["c"]])
    // The whole window docks back: its host goes.
    layout.move(.host("w"), to: .node(left, .center))
    XCTAssertNil(layout.host("w"))
    XCTAssertEqual(self.groups(layout.host("main")?.root), [["a", "b", "c"], ["d"]])
  }

  func testTwoWindowsMergeKeepingTheirSplit() {
    var (layout, _, c, d) = self.makeLayout()
    layout.move(.node(c), to: .newHost("w1"))
    layout.move(.node(d), to: .newHost("w2"))
    guard case .tabs(let target) = layout.host("w1")?.root else { return XCTFail() }
    layout.move(.host("w2"), to: .node(target.id, .bottom))
    XCTAssertNil(layout.host("w2"))
    guard case .split(let column) = layout.host("w1")?.root else { return XCTFail() }
    XCTAssertEqual(column.axis, .vertical)
    XCTAssertEqual(self.groups(.split(column)), [["c"], ["d"]])
  }

  func testCenterDropOfATreeFlattensItsPanels() {
    var (layout, left, _, _) = self.makeLayout()
    guard case .split(let row) = layout.host("main")?.root else { return XCTFail() }
    let column = row.children[1].id
    layout.move(.node(column), to: .node(left, .center))
    XCTAssertEqual(self.groups(layout.host("main")?.root), [["a", "b", "c", "d"]])
  }

  func testMovesIntoThemselvesAreRefused() {
    var (layout, _, c, _) = self.makeLayout()
    let before = layout
    // Its only panel dropped on its own group would leave nothing to drop on.
    XCTAssertNil(layout.move(.panel("c"), to: .node(c, .left)))
    guard case .split(let row) = layout.host("main")?.root else { return XCTFail() }
    XCTAssertNil(layout.move(.node(row.id), to: .node(c, .center)))
    XCTAssertNil(layout.move(.host("main"), to: .hostEdge("main", .left)))
    XCTAssertEqual(layout, before)
  }

  func testClosingForgetsPanelsAndEmptyWindows() {
    var (layout, _, c, _) = self.makeLayout()
    layout.move(.node(c), to: .newHost("w"))
    layout.close(panel: "c")
    XCTAssertNil(layout.host("w"))
    XCTAssertNil(layout.panels["c"])
    layout.close(panel: "a")
    XCTAssertEqual(self.groups(layout.host("main")?.root), [["b"], ["d"]])
    // A host the app placed stays, empty.
    layout.close(panel: "b")
    layout.close(panel: "d")
    XCTAssertNotNil(layout.host("main"))
    XCTAssertNil(layout.host("main")?.root)
  }

  func testSelectionStaysOnAPanel() {
    var (layout, left, _, _) = self.makeLayout()
    layout.select(panel: "b")
    XCTAssertEqual(layout.tabs(holding: "a")?.selected, "b")
    layout.move(.panel("b"), to: .hostEdge("main", .right))
    XCTAssertEqual(layout.tabs(holding: "a")?.selected, "a")
    XCTAssertEqual(layout.tabs(holding: "a")?.id, left)
  }

  func testRoundTripsThroughJSON() throws {
    var (layout, _, c, _) = self.makeLayout()
    layout.move(.panel("a"), to: .float("main", DockRect(x: 1, y: 2, width: 300, height: 200)))
    layout.move(.node(c), to: .newHost("w"))
    layout.hosts[layout.hosts.count - 1].screenFrame = DockRect(x: 100, y: 200, width: 400, height: 300)
    layout.panels["d"]?.storage = #"{"k":"v"}"#
    layout.windowStyle = .custom
    let decoded = try JSONDecoder().decode(DockLayout.self, from: JSONEncoder().encode(layout))
    XCTAssertEqual(decoded, layout)
  }
}
