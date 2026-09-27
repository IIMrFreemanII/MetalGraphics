@testable import MetalGraphicsLib
import ReactiveUI
import simd
import XCTest

// `HeadlessApp` itself: windows opened from scenes, stepped in order on the test's thread, a
// shared model between them, `openWindow` from a handler, scene storage across a relaunch, dock
// windows torn out and docked back, and the same script giving the same frames every run.

private enum Choice: String {
  case first, second
}

/// Shown by every `SyncReader` window of these tests.
nonisolated(unsafe) private var sharedModel = SyncModel()

private let readerScene = RetainedScene("Reader", id: "reader", defaultSize: CGSize(width: 320, height: 240)) { _ in
  SyncReader(model: sharedModel)
}

private let openerScene = RetainedScene("Opener", id: "opener", defaultSize: CGSize(width: 320, height: 240)) { _ in
  VStack(spacing: 8) {
    Button("Open Inspector") { openWindow(id: "inspector") }
    Text("Opener")
  }
}

private let inspectorScene = RetainedScene("Inspector", id: "inspector", kind: .single, defaultSize: CGSize(width: 240, height: 160)) { _ in
  Text("Inspector")
}

/// Shows the choice its window stored, and stores the other on a tap.
private let storageScene = RetainedScene("Storage", id: "storage", defaultSize: CGSize(width: 320, height: 240)) { scene in
  let choice = scene.storage.value("choice", default: Choice.first)
  return VStack(spacing: 8) {
    Text("Chose \(choice.rawValue)")
    Button("Choose second") { scene.storage.set(Choice.second, for: "choice") }
  }
}

private func makeDockSpace() -> DockSpace {
  DockSpace(
    name: "headless",
    kinds: ["a", "b"].map { kind in DockPanelKind(kind, title: kind.uppercased()) { _ in Text("Panel \(kind.uppercased())") } },
    persists: false
  ) {
    var layout = DockLayout()
    layout.addPanel(kind: "a", title: "A", id: "a")
    layout.addPanel(kind: "b", title: "B", id: "b")
    layout.hosts = [DockHost(id: "main", root: .row([.group(["a"]), .group(["b"])]))]
    return layout
  }
}

@MainActor
final class HeadlessAppTests: XCTestCase {
  private var app: HeadlessApp?

  override func setUp() {
    super.setUp()
    sharedModel = SyncModel()
  }

  override func tearDown() {
    self.app?.close()
    self.app = nil
    super.tearDown()
  }

  private func makeApp(_ scenes: [RetainedScene]) -> HeadlessApp {
    let app = HeadlessApp(scenes: scenes)
    self.app = app
    return app
  }

  // MARK: - Windows

  func testLaunchOpensTheFirstGroupAndGoesIdle() throws {
    let app = self.makeApp([readerScene])
    let window = try XCTUnwrap(app.launch())
    XCTAssertEqual(window.sceneID, "reader")
    XCTAssertEqual(window.size, float2(320, 240))
    XCTAssertTrue(window.shows("0"))
    XCTAssertGreaterThan(window.renders, 0)
    XCTAssertTrue(window.isKey)

    XCTAssertNotNil(app.settle())
    let renders = window.renders
    app.step(frames: 30)
    XCTAssertEqual(window.renders, renders, "An idle window draws nothing")
  }

  func testAWriteInOneWindowReachesTheOther() throws {
    let app = self.makeApp([readerScene])
    let a = app.open(id: "reader")
    let b = app.open(id: "reader")
    app.step()
    XCTAssertFalse(b.shows("On"))

    try a.toggle("Flag")
    XCTAssertTrue(sharedModel.flag)
    XCTAssertTrue(a.shows("On"))
    // `b` steps after `a` in the same frame, and its delivery ran before its frame.
    XCTAssertTrue(b.shows("On"))
  }

  func testAWriteFromTheTestReachesEveryWindow() {
    let app = self.makeApp([readerScene])
    let a = app.open(id: "reader")
    let b = app.open(id: "reader")
    app.step()

    sharedModel.count = 4
    XCTAssertFalse(a.shows("4"), "Delivered on the window's next turn, not during the write")
    app.step()
    XCTAssertTrue(a.shows("4"))
    XCTAssertTrue(b.shows("4"))
  }

  func testTypingGoesThroughTheRealInputPath() throws {
    let app = self.makeApp([readerScene])
    let window = try XCTUnwrap(app.launch())
    try window.type("bc", into: "Label")
    XCTAssertEqual(sharedModel.label, "abc")
    window.press(.delete)
    XCTAssertEqual(sharedModel.label, "ab")
    window.paste("!")
    XCTAssertEqual(sharedModel.label, "ab!")
  }

  func testOpenWindowFromAHandlerOpensItAfterTheStep() throws {
    let app = self.makeApp([openerScene, inspectorScene])
    let opener = try XCTUnwrap(app.launch())
    XCTAssertNil(app.window("inspector"))

    try opener.tap("Open Inspector")
    let inspector = try XCTUnwrap(app.window("inspector"))
    XCTAssertTrue(inspector.isKey)
    app.step()
    XCTAssertTrue(inspector.shows("Inspector"))

    // A single window opens once; asking again brings it back to the front.
    try opener.tap("Open Inspector")
    XCTAssertEqual(app.windows.filter { $0.sceneID == "inspector" }.count, 1)
    XCTAssertTrue(inspector.isKey)
  }

  func testAMissingTextSaysWhatIsShown() throws {
    let app = self.makeApp([openerScene, inspectorScene])
    let window = try XCTUnwrap(app.launch())
    XCTAssertThrowsError(try window.tap("Nope")) { error in
      let description = String(describing: error)
      XCTAssertTrue(description.contains("\"Open Inspector\""), description)
    }
  }

  func testClosingAWindowUnmountsItsTree() throws {
    let app = self.makeApp([readerScene])
    let window = try XCTUnwrap(app.launch())
    let reader = try XCTUnwrap(window.first(SyncReader.self))
    window.close()
    XCTAssertFalse(reader.mounted)
    XCTAssertTrue(app.windows.isEmpty)
    // A write with no reader left reaches no one.
    sharedModel.count = 1
    app.step()
  }

  // MARK: - Storage

  func testSceneStorageSurvivesARelaunch() throws {
    let app = self.makeApp([storageScene])
    let window = try XCTUnwrap(app.launch())
    XCTAssertTrue(window.shows("Chose first"))
    try window.tap("Choose second")

    app.relaunch()
    let reopened = try XCTUnwrap(app.window("storage"))
    XCTAssertFalse(reopened === window)
    XCTAssertTrue(reopened.shows("Chose second"))
  }

  func testTheAppDoesNotTouchTheRealDefaults() throws {
    let app = self.makeApp([storageScene])
    let window = try XCTUnwrap(app.launch())
    try window.tap("Choose second")
    app.close()
    XCTAssertNil(UserDefaults.standard.string(forKey: "UIStorage.choice"))
  }

  // MARK: - Docking

  func testATabDraggedOutOpensAWindowAndDocksBack() throws {
    let space = makeDockSpace()
    let workspace = RetainedScene("Workspace", id: "workspace", defaultSize: CGSize(width: 480, height: 320)) { _ in
      DockArea(space, host: "main")
    }
    let app = self.makeApp([workspace])
    app.manageDocking(space)
    let main = try XCTUnwrap(app.launch())
    XCTAssertTrue(main.shows("Panel B"))

    // B's tab, dragged well out of the window: B gets a window of its own.
    let outside = main.origin + float2(700, 200)
    try main.panel("b").drag(toScreen: outside)
    app.settle()
    let host = try XCTUnwrap(space.layout.hosts.first { $0.isDetached })
    let dock = try XCTUnwrap(app.window("dock"))
    XCTAssertTrue(dock.isVisible)
    XCTAssertTrue(dock.shows("Panel B"))
    XCTAssertFalse(main.shows("Panel B"))
    XCTAssertNotNil(host.screenFrame)

    // Its tab, dragged over A's group in the main window: B docks there, and its window closes.
    let groupOfA = try XCTUnwrap(main.all(DockTabsView.self).first { $0.mounted && $0.panels.contains("a") })
    let target = main.origin + (groupOfA.rect.min + groupOfA.rect.max) * 0.5
    try dock.panel("b").drag(toScreen: target)
    app.settle()
    XCTAssertFalse(space.layout.hosts.contains { $0.isDetached })
    XCTAssertNil(app.window("dock"))
    XCTAssertTrue(main.shows("Panel B"))
  }

  // MARK: - Determinism

  func testTheSameScriptGivesTheSameFrames() throws {
    func run() throws -> (renders: Int, pixels: [UInt8]) {
      sharedModel = SyncModel()
      let app = self.makeApp([readerScene])
      let a = try XCTUnwrap(app.launch())
      let b = app.open(id: "reader")
      try a.toggle("Flag")
      try b.type("x", into: "Label")
      a.move(to: float2(20, 20))
      app.advance(0.3)
      let result = (a.renders + b.renders, Array(b.snapshot().dataProvider!.data! as Data))
      app.close()
      return result
    }
    let first = try run()
    let second = try run()
    XCTAssertEqual(first.renders, second.renders)
    XCTAssertEqual(first.pixels, second.pixels)
  }
}
