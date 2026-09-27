import EditorCore
import Foundation
import MetalGraphicsLib
import ReactiveUI

/// Where a build is.
enum BuildState: String, Sendable {
  case idle, building, running, testing, succeeded, failed, stopped

  var isActive: Bool { self == .building || self == .running || self == .testing }
}

/// The build, shared by every window: what the console and the Problems list show, and what the
/// file tabs underline. Written as output arrives (at most once per `Services.outputDelay`) and
/// when a build ends; never per frame.
@Model
final class BuildModel {
  static let shared = BuildModel()

  var state: BuildState = .idle
  /// "Build succeeded", "Build failed: 2 errors, 1 warning".
  var summary: String = ""
  /// Moves on as output arrives: consoles pull what they have not shown from `BuildController.log`.
  var logVersion: Int = 0
  /// What the compiler reported, in the order printed.
  var problems: [CompilerDiagnostic] = []
  /// The package's executables, and the one ⌘R runs.
  var products: [String] = []
  var product: String = ""

  func reset() {
    self.state = .idle
    self.summary = ""
    self.logVersion = 0
    self.problems = []
    self.products = []
    self.product = ""
  }
}

/// Starts and stops builds and runs, from any thread, and feeds what they print to the log and
/// the model.
final class BuildController: @unchecked Sendable {
  static let shared = BuildController()
  /// Which executable ⌘R ran last, per folder.
  static let productKey = "Editor.product"

  let log = BuildLog()
  private let lock = NSLock()
  private var service: (any BuildService)?
  private var stopping = false
  private var flushPending = false

  /// ⌘B, ⌘R, ⌘U: saves every file, then runs `task` in the open folder. Ignored while one runs.
  func start(_ task: BuildTask) {
    let model = BuildModel.shared
    let root = WorkspaceModel.shared.rootPath
    guard !root.isEmpty, !model.state.isActive else { return }
    let task: BuildTask = if case .run(nil) = task, !model.product.isEmpty { .run(product: model.product) } else { task }
    model.state = switch task {
    case .build: .building
    case .run: .running
    case .test: .testing
    }
    model.summary = switch task {
    case .build: "Building…"
    case .run(let product): "Running \(product ?? "")…"
    case .test: "Testing…"
    }
    self.log.reset()
    model.problems = []
    model.logVersion += 1
    self.lock.withLock { self.stopping = false }
    IDE.showBuildPanels()

    // After every file is on disk.
    OpenFiles.shared.saveAll { [self] in
      let service = Services.makeBuildService()
      self.lock.withLock { self.service = service }
      service.start(task, in: root, output: { [self] text, isError in
        self.log.append(text, isError: isError)
        self.scheduleFlush()
      }, finished: { [self] status in
        self.log.finish()
        self.flush()
        self.finished(task, status: status)
      })
    }
  }

  /// ⌘.: ends the build or run.
  func stop() {
    let service = self.lock.withLock { () -> (any BuildService)? in
      self.stopping = true
      return self.service
    }
    service?.stop()
  }

  private func finished(_ task: BuildTask, status: Int32) {
    let stopped = self.lock.withLock {
      self.service = nil
      return self.stopping
    }
    let model = BuildModel.shared
    let problems = self.log.diagnostics
    let errors = problems.count { $0.severity == .error }
    let warnings = problems.count { $0.severity == .warning }
    let counts = [errors > 0 ? Self.count(errors, "error") : nil, warnings > 0 ? Self.count(warnings, "warning") : nil]
      .compactMap { $0 }.joined(separator: ", ")
    let verb = switch task {
    case .build: "Build"
    case .run: "Run"
    case .test: "Tests"
    }
    if stopped {
      model.state = .stopped
      model.summary = "\(verb) stopped"
    } else if status == 0 {
      model.state = .succeeded
      model.summary = counts.isEmpty ? "\(verb) succeeded" : "\(verb) succeeded: \(counts)"
    } else {
      model.state = .failed
      model.summary = counts.isEmpty ? "\(verb) failed (exit \(status))" : "\(verb) failed: \(counts)"
    }
  }

  static func count(_ n: Int, _ noun: String) -> String {
    n == 1 ? "1 \(noun)" : "\(n) \(noun)s"
  }

  /// Output tells the windows at most once per `Services.outputDelay`: a build printing
  /// thousands of lines is a few updates a second, not one per line.
  private func scheduleFlush() {
    let delay = Services.outputDelay
    guard delay > 0 else { return self.flush() }
    let schedule = self.lock.withLock { () -> Bool in
      defer { self.flushPending = true }
      return !self.flushPending
    }
    guard schedule else { return }
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) { [self] in
      self.flush()
    }
  }

  private func flush() {
    self.lock.withLock { self.flushPending = false }
    let model = BuildModel.shared
    model.logVersion += 1
    model.problems = self.log.diagnostics
  }

  /// The package's executables, read in the background when a folder opens.
  func loadProducts(_ root: String) {
    Services.background {
      let products = Services.describePackage(root)?.executables ?? []
      guard WorkspaceModel.shared.rootPath == root else { return }
      let model = BuildModel.shared
      model.products = products
      let stored = UIStorage.value(Self.productKey + "." + root, default: StoredText(rawValue: "")).rawValue
      model.product = products.contains(stored) ? stored : (products.first ?? "")
    }
  }

  /// The next executable to run, round the list.
  func selectNextProduct() {
    let model = BuildModel.shared
    let products = model.products
    guard !products.isEmpty else { return }
    let index = products.firstIndex(of: model.product).map { ($0 + 1) % products.count } ?? 0
    model.product = products[index]
    UIStorage.set(StoredText(rawValue: products[index]), for: Self.productKey + "." + WorkspaceModel.shared.rootPath)
  }
}
