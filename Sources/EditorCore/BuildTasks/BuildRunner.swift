import Foundation

/// What to do with a package.
public enum BuildTask: Sendable, Equatable {
  case build
  /// Builds and runs an executable product; nil for the package's only one.
  case run(product: String?)
  case test
}

/// Runs builds and what they build, and streams what they print. An app keeps one; tests swap
/// in a fake that prints canned output.
public protocol BuildService: AnyObject, Sendable {
  /// Starts `task` in the package at `folder`. `output` gets what it prints as it prints it,
  /// on any thread; `finished` its exit status, once, after the last output.
  func start(
    _ task: BuildTask, in folder: String,
    output: @escaping @Sendable (_ text: String, _ isError: Bool) -> Void,
    finished: @escaping @Sendable (_ status: Int32) -> Void
  )
  /// Ends what runs: a terminate, and a kill two seconds later if it is still running.
  func stop()
  var isRunning: Bool { get }
}

/// Runs a command as a child process, streaming its standard output and error.
public final class ProcessRunner: @unchecked Sendable {
  private let lock = NSLock()
  private var process: Process?
  private let queue = DispatchQueue(label: "ProcessRunner", qos: .userInitiated)

  public init() {}

  public var isRunning: Bool {
    self.lock.withLock { self.process?.isRunning ?? false }
  }

  /// Starts `executable` with `arguments` in `directory`. Fails at once, through `finished` with
  /// status -1 and a line on `output`, when it cannot start. Ignored while another runs.
  public func start(
    _ executable: String, _ arguments: [String], in directory: String, environment: [String: String]? = nil,
    output: @escaping @Sendable (String, Bool) -> Void, finished: @escaping @Sendable (Int32) -> Void
  ) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.currentDirectoryURL = URL(fileURLWithPath: directory)
    if let environment {
      process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
    }
    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr
    process.standardInput = FileHandle.nullDevice

    // Both pipes drained to their end before `finished`: a process can exit with output still
    // in its pipes.
    let group = DispatchGroup()
    for (pipe, isError) in [(stdout, false), (stderr, true)] {
      group.enter()
      let handle = pipe.fileHandleForReading
      let done = OnceFlag()
      handle.readabilityHandler = { handle in
        let data = handle.availableData
        if data.isEmpty {
          handle.readabilityHandler = nil
          if done.set() { group.leave() }
          return
        }
        output(String(decoding: data, as: UTF8.self), isError)
      }
    }
    process.terminationHandler = { [weak self] process in
      let status = process.terminationStatus
      group.notify(queue: self?.queue ?? .global()) {
        self?.lock.withLock { if self?.process === process { self?.process = nil } }
        finished(status)
      }
    }

    let started: Bool = self.lock.withLock {
      guard self.process == nil else { return false }
      self.process = process
      return true
    }
    guard started else { return }
    do {
      try process.run()
    } catch {
      self.lock.withLock { self.process = nil }
      stdout.fileHandleForReading.readabilityHandler = nil
      stderr.fileHandleForReading.readabilityHandler = nil
      output("Could not start \(executable): \(error.localizedDescription)\n", true)
      finished(-1)
    }
  }

  /// Terminates what runs, then kills it if it is still running two seconds later.
  public func stop() {
    guard let process = self.lock.withLock({ self.process }), process.isRunning else { return }
    process.terminate()
    let pid = process.processIdentifier
    self.queue.asyncAfter(deadline: .now() + 2) {
      if process.isRunning { kill(pid, SIGKILL) }
    }
  }
}

/// Set once, from any thread.
private final class OnceFlag: @unchecked Sendable {
  private let lock = NSLock()
  private var isSet = false

  /// True the first time.
  func set() -> Bool {
    self.lock.withLock {
      defer { self.isSet = true }
      return !self.isSet
    }
  }
}

/// `swift build`, `swift run` and `swift test`, through `xcrun`, so the selected Xcode's
/// toolchain builds.
public final class SwiftPMBuildService: BuildService, @unchecked Sendable {
  private let runner = ProcessRunner()

  public init() {}

  public var isRunning: Bool { self.runner.isRunning }

  public static func arguments(for task: BuildTask) -> [String] {
    switch task {
    case .build: ["swift", "build"]
    case .run(let product): ["swift", "run"] + (product.map { [$0] } ?? [])
    case .test: ["swift", "test"]
    }
  }

  public func start(
    _ task: BuildTask, in folder: String,
    output: @escaping @Sendable (String, Bool) -> Void, finished: @escaping @Sendable (Int32) -> Void
  ) {
    // Colour codes would show as text; unbuffered, a run's output arrives as it is printed.
    let environment = ["NSUnbufferedIO": "YES", "TERM": "dumb"]
    self.runner.start("/usr/bin/xcrun", Self.arguments(for: task), in: folder, environment: environment,
                      output: output, finished: finished)
  }

  public func stop() {
    self.runner.stop()
  }
}
