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
  /// The language server: canned answers, and a copy of each file as the edits sent left it.
  let language = FakeLanguageService()

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
    Services.parseDelay = 0
    Services.parseQueue = { $0() }
    let language = self.language
    Services.makeLanguageService = { _ in language }
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

/// A language server that answers at once, on the calling thread, with what a test gives it, and
/// keeps each file's text as the edits it is sent make it: the editor's sync is right when that
/// text is the document's.
final class FakeLanguageService: LanguageService, @unchecked Sendable {
  private(set) var texts: [String: String] = [:]
  private(set) var versions: [String: Int] = [:]
  private(set) var opened: [String] = []
  private(set) var closed: [String] = []
  private(set) var saved: [String] = []
  /// How many changes came as the whole text.
  private(set) var replacements = 0
  var completions: [LSPCompletionItem] = []
  private(set) var completionPositions: [LSPPosition] = []
  var hoverText: String? = nil
  var definitions: [LSPLocation] = []
  private(set) var definitionPositions: [LSPPosition] = []
  var onDiagnostics: (@Sendable (String, Int?, [LSPDiagnostic]) -> Void)?
  var onLog: (@Sendable (String) -> Void)?
  var isAlive = true
  private var nextRequest = 1

  func open(path: String, text: String, version: Int) {
    self.opened.append(path)
    self.texts[path] = text
    self.versions[path] = version
  }

  func change(path: String, version: Int, edits: [LSPTextEdit]) {
    var units = Array((self.texts[path] ?? "").utf16)
    for edit in edits {
      let start = Self.offset(edit.range.start, in: units)
      let end = Self.offset(edit.range.end, in: units)
      units.replaceSubrange(start ..< max(start, end), with: Array(edit.text.utf16))
    }
    self.texts[path] = String(decoding: units, as: UTF16.self)
    self.versions[path] = version
  }

  func replace(path: String, version: Int, text: String) {
    self.replacements += 1
    self.texts[path] = text
    self.versions[path] = version
  }

  func save(path: String) { self.saved.append(path) }
  func close(path: String) { self.closed.append(path) }

  /// True to hold completions back until `answerCompletions`, as a real server answers later.
  var holdsCompletions = false
  private var held: [@Sendable ([LSPCompletionItem]) -> Void] = []

  func answerCompletions() {
    let held = self.held
    self.held = []
    for reply in held { reply(self.completions) }
  }

  func completion(path: String, at position: LSPPosition, reply: @escaping @Sendable ([LSPCompletionItem]) -> Void) -> Int {
    self.completionPositions.append(position)
    if self.holdsCompletions {
      self.held.append(reply)
    } else {
      reply(self.completions)
    }
    self.nextRequest += 1
    return self.nextRequest
  }

  func hover(path: String, at position: LSPPosition, reply: @escaping @Sendable (String?) -> Void) {
    reply(self.hoverText)
  }

  func definition(path: String, at position: LSPPosition, reply: @escaping @Sendable ([LSPLocation]) -> Void) {
    self.definitionPositions.append(position)
    reply(self.definitions)
  }

  func cancel(_ request: Int) {}
  func shutdown() {}

  /// The server publishing diagnostics for `path`.
  func publish(_ path: String, _ diagnostics: [LSPDiagnostic], version: Int? = nil) {
    self.onDiagnostics?(path, version, diagnostics)
  }

  /// A line and UTF-16 column's offset in `units`.
  static func offset(_ position: LSPPosition, in units: [UInt16]) -> Int {
    var line = 0
    var index = 0
    while line < position.line, index < units.count {
      if units[index] == 0x0A { line += 1 }
      index += 1
    }
    return min(index + position.character, units.count)
  }
}
