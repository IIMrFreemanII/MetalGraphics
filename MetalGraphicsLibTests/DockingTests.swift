import AppKit
import Foundation
@testable import MetalGraphicsLib
import simd
import Synchronization
import XCTest

// Docking in one window, driven headlessly: picking panels up by their tabs, the drop markers,
// docking, floating, resizing, and what a panel keeps as it moves. Moving between windows is at
// the end, with two windows on threads of their own.

/// How many times each kind of test panel was made.
private let madePanels = Mutex<[String: Int]>([:])

private enum Note: String {
  case none, written
}

private func makeKinds() -> [DockPanelKind] {
  let colors: [String: float4] = [
    "a": float4(0.9, 0.3, 0.3, 1), "b": float4(0.3, 0.7, 0.3, 1),
    "c": float4(0.3, 0.4, 0.9, 1), "d": float4(0.9, 0.7, 0.2, 1),
  ]
  return colors.map { kind, color in
    DockPanelKind(kind, title: kind.uppercased()) { _ in
      madePanels.withLock { $0[kind, default: 0] += 1 }
      return Rectangle(color).padding(6)
    }
  }
}

/// main: a row of [A, B] beside a column of [C] over [D].
private func makeSpace() -> DockSpace {
  DockSpace(name: "test", kinds: makeKinds(), persists: false) {
    var layout = DockLayout()
    for panel in ["a", "b", "c", "d"] {
      layout.addPanel(kind: panel, title: panel.uppercased(), id: panel)
    }
    layout.hosts = [DockHost(id: "main", root: .row([.group(["a", "b"]), .column([.group(["c"]), .group(["d"])])]))]
    return layout
  }
}

@MainActor
final class DockingTests: XCTestCase {
  override func setUp() {
    super.setUp()
    madePanels.withLock { $0 = [:] }
  }

  private func groups(_ node: DockNode?) -> [[String]] {
    switch node {
    case nil: return []
    case .tabs(let tabs): return [tabs.panels]
    case .split(let split): return split.children.flatMap(self.groups)
    }
  }

  private func tab(_ panel: String, in h: UIHarness) -> DockTabItem {
    h.all(DockTabItem.self).first { $0.panel == panel && $0.mounted }!
  }

  private func group(holding panel: String, in h: UIHarness) -> DockTabsView {
    h.all(DockTabsView.self).first { $0.panels.contains(panel) && $0.mounted }!
  }

  private func center(_ rect: ClipRect) -> float2 {
    (rect.min + rect.max) * 0.5
  }

  private func center(of tab: DockTabItem) -> float2 {
    tab.position + float2(10, tab.size.y * 0.5)
  }

  /// Where group `panel` is in shows its marker for `zone`.
  private func marker(_ zone: DockZone, onGroupOf panel: String, in h: UIHarness) -> float2 {
    let rect = self.group(holding: panel, in: h).rect
    let c = self.center(rect)
    let spacing = min(DockMetrics.markerSpacing, max((simd_reduce_min(rect.max - rect.min) - DockMetrics.markerSize) * 0.5, 0))
    return switch zone {
    case .center: c
    case .left: c - float2(spacing, 0)
    case .right: c + float2(spacing, 0)
    case .top: c - float2(0, spacing)
    case .bottom: c + float2(0, spacing)
    }
  }

  /// Picks `panel` up by its tab and moves to `point`, a few frames, without letting go.
  private func pickUp(_ panel: String, to point: float2, in h: UIHarness) {
    let start = self.center(of: self.tab(panel, in: h))
    h.mouseDown(at: start)
    for step in 1 ... 4 {
      h.mouseDrag(to: start + (point - start) * Float(step) / 4)
    }
  }

  // MARK: - Building

  func testShowsTheLayout() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    XCTAssertEqual(h.all(DockTabsView.self).filter(\.mounted).count, 3)
    XCTAssertEqual(h.all(DockTabItem.self).filter(\.mounted).map(\.panel).sorted(), ["a", "b", "c", "d"])
    // Only the shown panels are made.
    XCTAssertEqual(madePanels.withLock { $0 }, ["a": 1, "c": 1, "d": 1])
    assertSnapshot(h.snapshot(), named: "layout", testCase: self)
  }

  func testPressingATabShowsIt() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    h.click(at: self.center(of: self.tab("b", in: h)))
    XCTAssertEqual(space.layout.tabs(holding: "b")?.selected, "b")
    XCTAssertEqual(madePanels.withLock { $0["b"] }, 1)
    // Back: A was kept, not made again.
    h.click(at: self.center(of: self.tab("a", in: h)))
    XCTAssertEqual(madePanels.withLock { $0["a"] }, 1)
  }

  // MARK: - Floating and docking

  func testDraggingATabOutFloatsItThere() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    // Over a docked group's content, away from its markers.
    let end = float2(30, 250)
    self.pickUp("b", to: end, in: h)
    let float = h.all(DockFloatView.self).first { $0.mounted }!
    // Held by its tab, as it was picked up: drawn there by an offset, not laid out again.
    let tab = self.tab("b", in: h)
    let drawn = tab.position + (float.dragOrigin ?? float.rect.min) - float.rect.min
    XCTAssertTrue(ClipRect(position: drawn, size: tab.size).contains(end))
    XCTAssertNotNil(float.dragOrigin)
    h.mouseUp(at: end)
    XCTAssertEqual(space.layout.host("main")?.floating.count, 1)
    XCTAssertEqual(self.groups(space.layout.host("main")?.floating.first?.node), [["b"]])
    XCTAssertEqual(self.groups(space.layout.host("main")?.root), [["a"], ["c"], ["d"]])
    XCTAssertTrue(h.settle() != nil)
    assertSnapshot(h.snapshot(), named: "floating", testCase: self)
  }

  func testMarkersShowWhileDragging() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    self.pickUp("d", to: self.marker(.left, onGroupOf: "a", in: h), in: h)
    let overlay = h.first(DockDropOverlay.self)!
    // The group's five, and the area's four edges.
    XCTAssertEqual(overlay.markers.count, 9)
    XCTAssertEqual(overlay.markers.filter(\.isHovered).map(\.zone), [.left])
    XCTAssertNotNil(overlay.preview)
    assertSnapshot(h.snapshot(), named: "markers", testCase: self)
    h.press(.escape)
    XCTAssertFalse(overlay.isShown)
  }

  func testDropOnAGroupsMiddleAddsATab() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    let target = self.marker(.center, onGroupOf: "a", in: h)
    self.pickUp("d", to: target, in: h)
    h.mouseUp(at: target)
    XCTAssertEqual(self.groups(space.layout.host("main")?.root), [["a", "b", "d"], ["c"]])
    XCTAssertEqual(space.layout.tabs(holding: "d")?.selected, "d")
    XCTAssertTrue(space.layout.host("main")!.floating.isEmpty)
  }

  func testDropOnAGroupsEdgeSplitsIt() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    let target = self.marker(.bottom, onGroupOf: "a", in: h)
    self.pickUp("b", to: target, in: h)
    h.mouseUp(at: target)
    guard case .split(let row) = space.layout.host("main")?.root, case .split(let left) = row.children[0] else {
      return XCTFail("\(String(describing: space.layout.host("main")?.root))")
    }
    XCTAssertEqual(left.axis, .vertical)
    XCTAssertEqual(self.groups(.split(left)), [["a"], ["b"]])
    h.settle()
    XCTAssertGreaterThan(self.group(holding: "b", in: h).position.y, self.group(holding: "a", in: h).position.y)
  }

  func testDropOnTheAreasEdgeDocksAlongIt() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    let edge = float2(200, 300 - DockMetrics.edgeInset - DockMetrics.markerSize * 0.5)
    self.pickUp("c", to: edge, in: h)
    h.mouseUp(at: edge)
    guard case .split(let column) = space.layout.host("main")?.root else { return XCTFail() }
    XCTAssertEqual(column.axis, .vertical)
    XCTAssertEqual(self.groups(column.children.last), [["c"]])
  }

  func testTheWholeGroupMovesByItsBar() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    // Right of the tabs, in the bar.
    let bar = self.group(holding: "a", in: h).barRect
    let start = float2(bar.max.x - 10, (bar.min.y + bar.max.y) * 0.5)
    h.mouseDown(at: start)
    h.mouseDrag(to: start + float2(10, 10))
    XCTAssertEqual(self.groups(space.layout.host("main")?.floating.first?.node), [["a", "b"]])
    // The rest has taken the space it left.
    let target = self.marker(.center, onGroupOf: "c", in: h)
    h.mouseDrag(to: target)
    h.mouseUp(at: target)
    XCTAssertEqual(self.groups(space.layout.host("main")?.root), [["c", "a", "b"], ["d"]])
  }

  func testAFloatMovesAndDocks() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    self.pickUp("b", to: float2(30, 250), in: h)
    h.mouseUp(at: float2(30, 250))
    // Moved by its tab: a group of one floating moves as it is.
    let float = h.all(DockFloatView.self).first { $0.mounted }!
    let frame = float.frame
    let start = self.center(of: self.tab("b", in: h))
    h.drag(from: start, to: start + float2(20, -30), steps: 3)
    XCTAssertEqual(space.layout.host("main")?.floating.first?.frame.origin ?? .zero, frame.origin + float2(20, -30))
    // And docks back.
    let target = self.marker(.center, onGroupOf: "d", in: h)
    self.pickUp("b", to: target, in: h)
    h.mouseUp(at: target)
    XCTAssertTrue(space.layout.host("main")!.floating.isEmpty)
    XCTAssertEqual(self.groups(space.layout.host("main")?.root), [["a"], ["c"], ["d", "b"]])
  }

  func testEscapePutsTheFloatBack() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    self.pickUp("b", to: float2(30, 250), in: h)
    h.mouseUp(at: float2(30, 250))
    let before = space.layout.host("main")!.floating[0].frame
    let start = self.center(of: self.tab("b", in: h))
    h.mouseDown(at: start)
    h.mouseDrag(to: start + float2(40, 0))
    h.mouseDrag(to: start + float2(80, 0))
    h.press(.escape)
    h.mouseUp(at: start + float2(80, 0))
    XCTAssertEqual(space.layout.host("main")!.floating[0].frame, before)
    XCTAssertEqual(h.all(DockFloatView.self).first { $0.mounted }!.frame, before)
  }

  func testAFloatResizesFromItsCorner() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    self.pickUp("b", to: float2(40, 60), in: h)
    h.mouseUp(at: float2(40, 60))
    let float = h.all(DockFloatView.self).first { $0.mounted }!
    let before = float.frame
    XCTAssertLessThan(float.rect.max.y, 300)
    let corner = float.rect.max - 2
    h.drag(from: corner, to: corner + float2(-30, -20), steps: 3)
    let after = space.layout.host("main")!.floating[0].frame
    XCTAssertEqual(after.origin, before.origin)
    XCTAssertEqual(after.size, simd_max(before.size + float2(-30, -20), DockMetrics.minFloat))
  }

  func testASashResizesTheSplit() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    let a = self.group(holding: "a", in: h)
    let width = a.size.x
    let sash = float2(a.rect.max.x + DockMetrics.gap * 0.5, 150)
    h.drag(from: sash, to: sash + float2(-60, 0), steps: 3)
    guard case .split(let row) = space.layout.host("main")?.root else { return XCTFail() }
    XCTAssertEqual(row.fractions[0], (width - 60) / (400 - DockMetrics.gap), accuracy: 0.01)
    XCTAssertEqual(a.size.x, width - 60, accuracy: 1)
    // Still over the sash, which moved with it.
    XCTAssertEqual(h.pointerStyle, .columnResize)
    h.move(to: sash - float2(0, 50))
    XCTAssertEqual(h.pointerStyle, .default)
  }

  func testTheCloseButtonClosesThePanel() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    let tab = self.tab("a", in: h)
    h.move(to: self.center(of: tab))
    h.click(at: self.center(tab.closeRect))
    XCTAssertNil(space.layout.panels["a"])
    XCTAssertEqual(self.groups(space.layout.host("main")?.root), [["b"], ["c"], ["d"]])
  }

  func testAPanelMovedInItsWindowKeepsItsElement() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    let content = h.all(DockPanelHost.self).first { $0.panel.id == "c" }!
    let target = self.marker(.right, onGroupOf: "a", in: h)
    self.pickUp("c", to: target, in: h)
    h.mouseUp(at: target)
    h.settle()
    XCTAssertEqual(madePanels.withLock { $0["c"] }, 1)
    XCTAssertTrue(h.all(DockPanelHost.self).contains { $0 === content && $0.mounted })
  }

  func testGroupsDroppedFromAnotherWindowTakeThePointer() {
    let space = makeSpace()
    guard case .split(let row) = space.layout.host("main")?.root, case .split(let column) = row.children[1] else {
      return XCTFail()
    }
    space.move(.node(column.id), to: .newHost("w"))
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    let area = h.first(DockArea.self)!
    let point = float2(400 - DockMetrics.edgeInset - DockMetrics.markerSize * 0.5, 150)
    area.remoteHover(point)
    XCTAssertTrue(area.remoteDrop(point, source: "w"))
    h.step()
    XCTAssertEqual(self.groups(space.layout.host("main")?.root), [["a", "b"], ["c"], ["d"]])
    // Its tab shows it; its bar picks it up.
    let bar = self.group(holding: "d", in: h).barRect
    h.mouseDown(at: float2(bar.max.x - 10, bar.min.y + 10))
    h.mouseDrag(to: float2(bar.max.x - 20, bar.min.y + 60))
    h.mouseDrag(to: float2(bar.max.x - 30, bar.min.y + 80))
    XCTAssertEqual(space.layout.host("main")?.floating.count, 1)
  }

  func testPanelStorageFollowsThePanel() {
    let space = makeSpace()
    let h = UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }
    let host = h.all(DockPanelHost.self).first { $0.panel.id == "c" }!
    XCTAssertEqual(host.panel.storage.value("note", default: Note.none), .none)
    host.panel.storage.set(Note.written, for: "note")
    XCTAssertEqual(space.layout.panels["c"]?.storage, #"{"note":"written"}"#)
    // Not shared with other panels, as scene storage is.
    let other = h.all(DockPanelHost.self).first { $0.panel.id == "d" }!
    XCTAssertEqual(other.panel.storage.value("note", default: Note.none), .none)
  }
}

// Between windows: each area on a `WindowThread` of its own, as the app runs them. Not on the
// main actor, unlike the tests above, since its closures run on those threads.
final class DockWindowsTests: XCTestCase {
  override func setUp() {
    super.setUp()
    madePanels.withLock { $0 = [:] }
  }

  private func groups(_ node: DockNode?) -> [[String]] {
    switch node {
    case nil: return []
    case .tabs(let tabs): return [tabs.panels]
    case .split(let split): return split.children.flatMap(self.groups)
    }
  }

  /// The middle marker of the group holding `panel`.
  private func middle(ofGroupOf panel: String, in h: UIHarness) -> float2 {
    let rect = h.all(DockTabsView.self).first { $0.panels.contains(panel) && $0.mounted }!.rect
    return (rect.min + rect.max) * 0.5
  }

  func testADetachedWindowDocksIntoAnother() {
    let space = makeSpace()
    // C in a window of its own.
    guard case .split(let row) = space.layout.host("main")?.root, case .split(let column) = row.children[1] else {
      return XCTFail()
    }
    space.move(.node(column.children[0].id), to: .newHost("w"))

    let a = WindowThread(name: "A"), b = WindowThread(name: "B")
    a.start()
    b.start()
    defer {
      a.stop(); b.stop()
      XCTAssertTrue(a.waitUntilFinished(timeout: 5))
      XCTAssertTrue(b.waitUntilFinished(timeout: 5))
    }
    let main = on(a) { Box(UIHarness(size: float2(400, 300)) { DockArea(space, host: "main") }) }
    let window = on(b) { Box(UIHarness(size: float2(240, 200)) { DockArea(space, host: "w") }) }

    // Something written in the detached window's panel.
    on(b) {
      let panel = window.value.all(DockPanelHost.self).first { $0.panel.id == "c" }!
      panel.panel.storage.set(Note.written, for: "note")
    }
    // The main thread drags the window over A's group [A, B] and lets go on its middle marker.
    let point = on(a) { self.middle(ofGroupOf: "a", in: main.value) }
    let docked = on(a) { () -> Bool in
      let area = main.value.first(DockArea.self)!
      area.remoteHover(point)
      let shown = main.value.first(DockDropOverlay.self)!.markers.contains { $0.isHovered && $0.zone == .center }
      return shown && area.remoteDrop(point, source: "w")
    }
    XCTAssertTrue(docked)
    XCTAssertNil(space.layout.host("w"))
    XCTAssertEqual(self.groups(space.layout.host("main")?.root), [["a", "b", "c"], ["d"]])

    // A shows C, made anew there from its kind and its storage; B's area empties.
    let note = on(a) { () -> Note? in
      main.value.step()
      return main.value.all(DockPanelHost.self).first { $0.panel.id == "c" && $0.mounted }?
        .panel.storage.value("note", default: Note.none)
    }
    XCTAssertEqual(note, .written)
    XCTAssertEqual(madePanels.withLock { $0["c"] }, 2)
    let left = on(b) { () -> Int in
      window.value.step()
      return window.value.all(DockTabsView.self).filter(\.mounted).count
    }
    XCTAssertEqual(left, 0)
  }
}

// A detached window's native title bar: a press on it, off its buttons, drags the window through
// `DockWindows`, and so docks it.
@MainActor
final class DockWindowTitleBarTests: XCTestCase {
  func testANativeTitleBarPressHoldsTheWindow() {
    let window = DockWindow(space: makeSpace(), host: "w", handle: WindowHandle(threadlessNamed: "test"))
    defer { window.close() }
    window.apply(.native)
    XCTAssertFalse(window.isMovable)
    let content = window.contentLayoutRect
    let titleBar = window.frame.height - content.maxY
    XCTAssertGreaterThan(titleBar, 0)

    // In the title bar, above the content: held from the content's top left, y up is negative.
    let grab = window.titleBarGrab(at: NSPoint(x: 150, y: content.maxY + titleBar / 2))
    XCTAssertEqual(grab?.x, Float(150 - content.minX))
    XCTAssertEqual(grab.map { Double($0.y) } ?? 0, -Double(titleBar / 2), accuracy: 0.001)
    // The content is the area's.
    XCTAssertNil(window.titleBarGrab(at: NSPoint(x: 150, y: content.midY)))
    // The traffic lights keep their clicks.
    let close = window.standardWindowButton(.closeButton)!
    let center = close.convert(NSPoint(x: close.bounds.midX, y: close.bounds.midY), to: nil)
    XCTAssertNil(window.titleBarGrab(at: center))
  }

  func testTheCustomLooksTitleBarIsTheAreas() {
    let window = DockWindow(space: makeSpace(), host: "w", handle: WindowHandle(threadlessNamed: "test"))
    defer { window.close() }
    window.apply(.custom)
    XCTAssertNil(window.titleBarGrab(at: NSPoint(x: 150, y: window.frame.height - 10)))
  }
}

/// Holds what one thread hands another in a test.
private final class Box<T>: @unchecked Sendable {
  var value: T
  init(_ value: T) { self.value = value }
}

/// Runs `body` on `thread` and waits for it.
@discardableResult
private func on<T>(_ thread: WindowThread, _ body: @escaping () -> T) -> T {
  nonisolated(unsafe) let body = body
  let result = Box<T?>(nil)
  let done = DispatchSemaphore(value: 0)
  thread.executor.post {
    result.value = body()
    done.signal()
  }
  done.wait()
  return result.value!
}
