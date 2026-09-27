@testable import Demo
@testable import MetalGraphicsLib
import XCTest

/// The app, launched in memory for each test: its scenes (`AppScenes.all`) in a `HeadlessApp`,
/// with fresh statics, private storage and the workspace's dock windows managed, as the app's
/// launch does. `main` is the Demos window it opens.
@MainActor
class AppTestCase: XCTestCase {
  private(set) var app: HeadlessApp!

  override func setUp() {
    super.setUp()
    self.app = HeadlessApp(scenes: AppScenes.all)
    self.prepareLaunch()
    self.app.launch()
  }

  override func tearDown() {
    self.app.close()
    self.app = nil
    super.tearDown()
  }

  /// The first Demos window.
  var main: HeadlessWindow {
    self.app.window(AppScenes.demos.id)!
  }

  /// Quits and relaunches the app: every window reopens from its storage.
  func relaunch() {
    self.app.relaunch { self.prepareLaunch() }
  }

  /// What `DemoApp.init` and a new process do before the first window.
  private func prepareLaunch() {
    AppScenes.resetForTesting()
    self.app.manageDocking(Workspace.space)
  }
}
