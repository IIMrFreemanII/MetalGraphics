@testable import Editor
@testable import MetalGraphicsLib
import EditorCore
import Foundation
import XCTest

/// The editor, launched in memory for each test, over a small Swift package made afresh in a
/// temporary folder. The folder picker picks that folder, and scans run at once, so nothing
/// waits on real time. `window` is the editor's window.
@MainActor
class EditorAppTestCase: XCTestCase {
  private(set) var app: HeadlessApp!
  /// The package's folder, standardized.
  private(set) var root: URL!
  /// What ⌘B, ⌘R and ⌘U run: canned output, no toolchain.
  let builds = FakeBuildService()

  static let files: [String: String] = [
    "Package.swift": """
    // swift-tools-version: 6.0
    import PackageDescription

    let package = Package(name: "Sample", targets: [.executableTarget(name: "App")])
    """,
    "Sources/App/main.swift": """
    let greeting = Greeter(name: "World").greeting
    print(greeting)
    """,
    "Sources/App/Greeter.swift": """
    struct Greeter {
      var name: String

      var greeting: String { "Hello, \\(name)!" }
    }
    """,
    "README.md": "# Sample\n",
    ".build/debug/App.o": "binary",
  ]

  override func setUp() {
    super.setUp()
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("EditorTests-\(UUID().uuidString)", isDirectory: true)
    for (path, text) in Self.files {
      let url = root.appendingPathComponent(path)
      try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      try! Data(text.utf8).write(to: url)
    }
    self.root = root.standardizedFileURL
    self.app = HeadlessApp(scenes: EditorScenes.all)
    self.prepareLaunch()
    self.app.launch()
  }

  override func tearDown() {
    self.app.close()
    self.app = nil
    try? FileManager.default.removeItem(at: self.root)
    super.tearDown()
  }

  var window: HeadlessWindow {
    self.app.window(IDE.windowID)!
  }

  func path(_ relative: String) -> String {
    self.root.appendingPathComponent(relative).path
  }

  func contents(_ relative: String) -> String {
    (try? String(contentsOfFile: self.path(relative), encoding: .utf8)) ?? ""
  }

  /// Quits and relaunches the app: the window and its panels reopen from storage.
  func relaunch() {
    self.app.relaunch { self.prepareLaunch() }
  }

  /// Opens the package with ⌘O, as a user would.
  func openPackage() {
    self.window.press("o", modifiers: .command)
    self.app.step()
  }

  /// Opens `relative`'s file through the navigator, a folder at a time.
  func openInNavigator(_ relative: String) throws {
    for name in relative.split(separator: "/") {
      try self.window.tap(String(name))
    }
    self.app.step()
  }

  /// The editor of the file tab shown, in `window` or the editor's window.
  func shownEditor(in window: HeadlessWindow? = nil) -> TextEditor? {
    (window ?? self.window).all(TextEditor.self).first { $0.mounted }
  }

  /// The ids of the file panels in the layout, with their paths.
  var filePanels: [(id: String, path: String)] {
    IDE.space.layout.panels
      .filter { $0.value.kind == IDE.fileKind }
      .map { ($0.key, IDE.path(of: $0.value)) }
      .sorted { $0.path < $1.path }
  }

  /// What `EditorApp.init` and a new process do before the first window, with the folder
  /// picker and background queue made immediate.
  private func prepareLaunch() {
    EditorScenes.resetForTesting()
    let path = self.root.path
    Services.background = { $0() }
    Services.chooseFolder = { done in done(path) }
    let builds = self.builds
    Services.makeBuildService = { builds }
    Services.describePackage = { _ in nil }
    Services.watchFolder = { _, _ in nil }
    Services.outputDelay = 0
    self.app.manageDocking(IDE.space)
  }
}

/// Builds that print what a test gives them, at once, on the thread that started them.
final class FakeBuildService: BuildService, @unchecked Sendable {
  /// What each start prints, standard error or not.
  var output: [(String, Bool)] = []
  var status: Int32 = 0
  /// False to leave it running until `stop` or `finish`.
  var finishesAtOnce = true
  /// What was started, and the files as they were on disk then.
  private(set) var started: [(task: BuildTask, folder: String)] = []
  var onStart: (() -> Void)?
  private var pending: (@Sendable (Int32) -> Void)?

  var isRunning: Bool { self.pending != nil }

  func start(
    _ task: BuildTask, in folder: String,
    output: @escaping @Sendable (String, Bool) -> Void, finished: @escaping @Sendable (Int32) -> Void
  ) {
    self.started.append((task, folder))
    self.onStart?()
    for (text, isError) in self.output {
      output(text, isError)
    }
    if self.finishesAtOnce {
      finished(self.status)
    } else {
      self.pending = finished
    }
  }

  func finish(_ status: Int32) {
    let pending = self.pending
    self.pending = nil
    pending?(status)
  }

  func stop() {
    self.finish(15)
  }
}
