@testable import MetalGraphicsLib
import simd
import XCTest

// Presentations in windows of their own, in a `HeadlessApp`: where their windows open, what the
// window they were shown from still gets, and how each way of closing them writes their binding
// back.

/// What a presenter window's tree shows and records. One per test.
private final class Probe {
  var kind = PresentationKind.sheet
  var style = PresentationWindowStyle.attached
  var shown = false
  var dismissed = 0
  var taps = 0
  var log: [String] = []
  var nestedShown = false
  var presenter: PresentationElement!
  var nested: PresentationElement?

  var binding: Binding<Bool> { Binding(get: { self.shown }, set: { self.shown = $0 }) }
  var nestedBinding: Binding<Bool> { Binding(get: { self.nestedShown }, set: { self.nestedShown = $0 }) }
}

nonisolated(unsafe) private var probe = Probe()

private let presenterScene = RetainedScene("Presenter", id: "presenter", defaultSize: CGSize(width: 400, height: 300)) { _ in
  let p = probe
  let base = VStack(spacing: 8) {
    Button("Under") { p.taps += 1 }
    Text("Presenter")
  }
  .frame(width: 400, height: 300)

  let presenter: PresentationElement
  switch p.kind {
  case .sheet:
    let nested = Text("Sheet body").alert("Sure?", isPresented: p.nestedBinding) {
      Button("Yes") { p.log.append("yes") }
    }
    p.nested = nested
    presenter = base.sheet(isPresented: p.binding, onDismiss: { p.dismissed += 1 }) {
      VStack(spacing: 8) {
        nested
        Rectangle(float4(0.2, 0.5, 0.9, 1)).frame(width: 240, height: 60)
      }
      .padding(20)
    }
  case .alert:
    presenter = base.alert("Delete “Notes”?", isPresented: p.binding) {
      Button("Delete", role: .destructive) { p.log.append("delete") }
      Button("Keep") { p.log.append("keep") }
      Button("Cancel", role: .cancel) { p.log.append("cancel") }
    } message: {
      Text("This cannot be undone.")
    }
  case .confirmationDialog:
    presenter = base.confirmationDialog("Save?", isPresented: p.binding) {
      Button("Save") { p.log.append("save") }
    }
  case .popover:
    presenter = Rectangle(.blue).frame(width: 60, height: 24)
      .popover(isPresented: p.binding) { Text("Details").padding(12) }
    p.presenter = presenter
    return ZStack(alignment: .topLeading) {
      base
      presenter.padding(Inset(left: 100, top: 40, right: 0, bottom: 0))
    }
    .presentationWindow(p.style)
  case .fullScreenCover:
    presenter = base.fullScreenCover(isPresented: p.binding, onDismiss: { p.dismissed += 1 }) { Text("Covering") }
  }
  p.presenter = presenter
  return presenter.presentationWindow(p.style)
}

private let otherScene = RetainedScene("Other", id: "other", defaultSize: CGSize(width: 200, height: 150)) { _ in
  Text("Other")
}

@MainActor
final class PresentationWindowTests: XCTestCase {
  private var app: HeadlessApp?

  override func tearDown() {
    self.app?.close()
    self.app = nil
    super.tearDown()
  }

  private func launch(_ kind: PresentationKind, _ style: PresentationWindowStyle = .attached) -> (HeadlessApp, HeadlessWindow) {
    probe = Probe()
    probe.kind = kind
    probe.style = style
    let app = HeadlessApp(scenes: [presenterScene, otherScene])
    self.app = app
    let main = app.launch()!
    XCTAssertNotNil(app.settle())
    return (app, main)
  }

  /// Presents as if its binding just went true, and returns its window.
  @discardableResult
  private func present(_ app: HeadlessApp, _ main: HeadlessWindow) -> HeadlessWindow? {
    main.perform {
      probe.shown = true
      probe.presenter.setIsPresented(true, main.context)
    }
    XCTAssertNotNil(app.settle())
    return app.presentation(over: main)
  }

  // MARK: - Sheets

  func testAttachedSheetOpensAWindowHangingFromItsParent() throws {
    let (app, main) = self.launch(.sheet)
    let sheet = try XCTUnwrap(self.present(app, main))
    XCTAssertEqual(sheet.sceneID, WindowPresentation.sceneID)
    XCTAssertEqual(app.windows.count, 2)
    XCTAssertTrue(sheet.isKey)
    XCTAssertTrue(sheet.shows("Sheet body"))
    XCTAssertEqual(sheet.size.x, 280, "its content's width")
    XCTAssertEqual(sheet.origin.y, main.origin.y, "from the top of its window")
    XCTAssertEqual(sheet.frame.center.x, main.frame.center.x, accuracy: 1)
    XCTAssertEqual(main.context.inputBlocks, 1)
    XCTAssertTrue(main.context.overlays.isEmpty, "nothing over the window itself")
  }

  func testEscapeClosesTheSheetWindowAndWritesBack() throws {
    let (app, main) = self.launch(.sheet)
    let sheet = try XCTUnwrap(self.present(app, main))
    sheet.press(.escape)
    XCTAssertFalse(probe.shown)
    XCTAssertNotNil(app.settle())
    XCTAssertFalse(sheet.isOpen)
    XCTAssertNil(sheet.renderer.graphics2D, "its tree is gone")
    XCTAssertEqual(app.windows.count, 1)
    XCTAssertTrue(main.isKey, "the keyboard goes back")
    XCTAssertEqual(main.context.inputBlocks, 0)
    XCTAssertEqual(probe.dismissed, 1)
  }

  func testAClickOnTheParentIsTakenAndDismisses() throws {
    let (app, main) = self.launch(.sheet)
    try XCTUnwrap(self.present(app, main))
    try main.tap("Under")
    XCTAssertEqual(probe.taps, 0, "the parent gets nothing")
    XCTAssertFalse(probe.shown)
    XCTAssertNotNil(app.settle())
    try main.tap("Under")
    XCTAssertEqual(probe.taps, 1, "live again once it has gone")
  }

  func testTheParentIsBlockedWhileTheSheetShows() throws {
    let (app, main) = self.launch(.sheet)
    let sheet = try XCTUnwrap(self.present(app, main))
    main.press(.tab)
    XCTAssertTrue(sheet.isKey, "keys go to the sheet")
    XCTAssertNil(main.context.focused)
  }

  func testFloatingSheetIsCentredAndItsCloseButtonDismisses() throws {
    let (app, main) = self.launch(.sheet, .floating)
    let sheet = try XCTUnwrap(self.present(app, main))
    XCTAssertEqual(sheet.frame.center.x, main.frame.center.x, accuracy: 1)
    XCTAssertLessThan(sheet.origin.y, main.frame.center.y)
    sheet.close()
    app.step()
    XCTAssertFalse(probe.shown)
    XCTAssertNotNil(app.settle())
    XCTAssertFalse(sheet.isOpen)
  }

  func testUnmountingThePresenterClosesItsWindow() throws {
    let (app, main) = self.launch(.sheet)
    let sheet = try XCTUnwrap(self.present(app, main))
    main.perform { main.root.setChild(Text("Gone"), main.context) }
    XCTAssertNotNil(app.settle())
    XCTAssertFalse(sheet.isOpen)
    XCTAssertTrue(probe.shown, "no write-back")
    XCTAssertEqual(probe.dismissed, 0)
  }

  func testClosingThePresenterWindowClosesTheSheet() throws {
    let (app, main) = self.launch(.sheet)
    let sheet = try XCTUnwrap(self.present(app, main))
    main.close()
    XCTAssertNotNil(app.settle())
    XCTAssertFalse(sheet.isOpen)
    XCTAssertTrue(app.windows.isEmpty)
  }

  // MARK: - Nesting

  func testAnAlertFromASheetOpensOverTheSheetAndGoesWithIt() throws {
    let (app, main) = self.launch(.sheet)
    let sheet = try XCTUnwrap(self.present(app, main))
    let nested = try XCTUnwrap(probe.nested)
    sheet.perform {
      probe.nestedShown = true
      nested.setIsPresented(true, sheet.context)
    }
    XCTAssertNotNil(app.settle())
    let alert = try XCTUnwrap(app.presentation(over: sheet), "its style is the sheet's")
    XCTAssertTrue(alert.shows("Sure?"))
    XCTAssertEqual(sheet.context.inputBlocks, 1)

    main.perform {
      probe.shown = false
      probe.presenter.setIsPresented(false, main.context)
    }
    XCTAssertFalse(probe.nestedShown, "written back as it goes with the sheet")
    XCTAssertNotNil(app.settle())
    XCTAssertFalse(alert.isOpen)
    XCTAssertFalse(sheet.isOpen)
    XCTAssertEqual(app.windows.count, 1)
  }

  // MARK: - Alerts and dialogs

  func testAlertWindowButtonsAndKeys() throws {
    let (app, main) = self.launch(.alert, .floating)
    var alert = try XCTUnwrap(self.present(app, main))
    XCTAssertEqual(alert.size.x, 260)
    alert.press(.return)
    XCTAssertEqual(probe.log, ["keep"])
    XCTAssertFalse(probe.shown)
    XCTAssertNotNil(app.settle())

    alert = try XCTUnwrap(self.present(app, main))
    try alert.tap("Delete")
    XCTAssertEqual(probe.log, ["keep", "delete"])
    XCTAssertFalse(probe.shown)
    XCTAssertNotNil(app.settle())

    alert = try XCTUnwrap(self.present(app, main))
    try main.tap("Under")
    XCTAssertEqual(probe.log, ["keep", "delete", "cancel"], "a click outside cancels")
  }

  func testDialogWindowGetsCancel() throws {
    let (app, main) = self.launch(.confirmationDialog)
    let dialog = try XCTUnwrap(self.present(app, main))
    XCTAssertTrue(dialog.shows("Cancel"))
    dialog.press(.escape)
    XCTAssertFalse(probe.shown)
    XCTAssertEqual(probe.log, [])
  }

  // MARK: - Popovers and covers

  func testPopoverWindowPointsAtItsSourceAndGoesWithTheKeyboard() throws {
    let (app, main) = self.launch(.popover)
    let popover = try XCTUnwrap(self.present(app, main))
    XCTAssertEqual(main.context.inputBlocks, 0, "a popover blocks nothing")
    XCTAssertEqual(popover.origin.y, main.origin.y + 40 + 24 + 4, accuracy: 1, "below its source")
    XCTAssertEqual(popover.frame.center.x, main.origin.x + 130, accuracy: 1, "centred on it")

    app.makeKey(app.open(id: "other"))
    app.step()
    XCTAssertFalse(probe.shown, "the keyboard went elsewhere")
    XCTAssertNotNil(app.settle())
    XCTAssertFalse(popover.isOpen)
  }

  func testAttachedCoverFollowsItsWindow() throws {
    let (app, main) = self.launch(.fullScreenCover)
    let cover = try XCTUnwrap(self.present(app, main))
    XCTAssertEqual(cover.frame, main.frame)
    main.resize(to: float2(500, 360))
    XCTAssertEqual(cover.size, float2(500, 360))
    try main.tap("Under")
    XCTAssertTrue(probe.shown, "a cover has nothing outside to click")
    cover.press(.escape)
    XCTAssertFalse(probe.shown)
  }

  func testFloatingCoverFillsTheScreen() throws {
    let (app, main) = self.launch(.fullScreenCover, .floating)
    let cover = try XCTUnwrap(self.present(app, main))
    XCTAssertEqual(cover.origin, .zero)
    XCTAssertEqual(cover.size, app.screenSize)
  }

  // MARK: - Lifetime and cost

  func testRelaunchDropsThePresentation() throws {
    let (app, main) = self.launch(.sheet)
    try XCTUnwrap(self.present(app, main))
    // As a new process's state would be.
    app.relaunch { probe.shown = false }
    XCTAssertEqual(app.windows.map(\.sceneID), ["presenter"])
  }

  func testBothWindowsGoIdle() throws {
    let (app, main) = self.launch(.sheet)
    let sheet = try XCTUnwrap(self.present(app, main))
    let renders = (main.renders, sheet.renders)
    app.step(frames: 30)
    XCTAssertEqual(main.renders, renders.0)
    XCTAssertEqual(sheet.renders, renders.1)
  }

  func testSnapshots() throws {
    var (app, main) = self.launch(.sheet)
    var window = try XCTUnwrap(self.present(app, main))
    assertSnapshot(window.snapshot(), named: "sheet-window", testCase: self)

    (app, main) = self.launch(.alert)
    window = try XCTUnwrap(self.present(app, main))
    assertSnapshot(window.snapshot(), named: "alert-window", testCase: self)

    (app, main) = self.launch(.popover)
    window = try XCTUnwrap(self.present(app, main))
    assertSnapshot(window.snapshot(), named: "popover-window", testCase: self)
  }
}
