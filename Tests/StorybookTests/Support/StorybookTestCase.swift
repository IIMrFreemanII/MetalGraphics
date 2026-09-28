@testable import MetalGraphicsLib
@testable import Storybook
import XCTest

/// The Storybook, launched in memory for each test: its window in a `HeadlessApp`, with a fresh
/// model and dock layout, as a new process starts. `window` is the Storybook window.
@MainActor
class StorybookTestCase: XCTestCase {
  private(set) var app: HeadlessApp!

  override func setUp() {
    super.setUp()
    CalendarView.today = { StoryFixtures.now }
    self.app = HeadlessApp(scenes: StorybookScenes.all, screenSize: float2(1600, 1000))
    self.prepareLaunch()
    self.app.launch()
  }

  override func tearDown() {
    self.app.close()
    self.app = nil
    CalendarView.today = Date.init
    super.tearDown()
  }

  var window: HeadlessWindow {
    self.app.window(StorybookScenes.main.id)!
  }

  var model: StorybookModel { .shared }

  func relaunch() {
    self.app.relaunch { self.prepareLaunch() }
  }

  /// Shows `id` and lets the canvas settle.
  func show(_ id: StoryID) {
    self.model.select(id, in: StoryRegistry.catalog())
    XCTAssertNotNil(self.app.settle())
  }

  /// The canvas panel shown.
  var canvas: CanvasPanel? {
    self.window.all(CanvasPanel.self).first { $0.mounted }
  }

  private func prepareLaunch() {
    StorybookScenes.resetForTesting()
    self.app.manageDocking(StorybookDock.space)
  }
}
