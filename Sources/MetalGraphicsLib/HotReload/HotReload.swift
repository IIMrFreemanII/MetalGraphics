#if DEBUG
import Foundation

/// Debug-only hot reload: Swift edits through InjectionNext, shader and macro edits through our
/// own watchers. See `docs/HotReload.md`.
///
/// Nothing here runs per frame: every piece waits on a file or injection event, off the main
/// thread. Once per reload the main thread posts the rebuild to every window's thread.
@MainActor enum HotReload {
  /// The repository root, from this file's location at compile time. Missing when the app was
  /// built on another machine, which turns the source watchers off.
  nonisolated static let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // HotReload
    .deletingLastPathComponent()  // MetalGraphicsLib
    .deletingLastPathComponent()  // Sources
    .deletingLastPathComponent()

  private static var started = false
  private static var watchers: [FileWatcher] = []
  private static var pendingRebuild: Task<Void, Never>?
  /// Injections still due from a macro reload, which re-injects every component file one at a
  /// time, about a second apart. The tree is rebuilt once, after the last of them.
  private static var awaitedInjections = 0

  /// Installs the injection observer and the source watchers, once for the whole app. Every
  /// window's renderer calls it; each reload then acts on every window in `WindowRegistry`, on the window's thread.
  static func startIfNeeded() {
    guard !started else { return }
    started = true

    // The sources InjectionNext watches; a launch environment value, if any, wins.
    setenv("INJECTION_PROJECT_ROOT", repoRoot.path, 0)
    let injecting = loadInjectionBundle()

    // Posted once per injected file.
    NotificationCenter.default.addObserver(
      forName: Notification.Name("INJECTION_BUNDLE_NOTIFICATION"), object: nil, queue: .main
    ) { _ in
      MainActor.assumeIsolated { injected() }
    }

    guard FileManager.default.fileExists(atPath: repoRoot.appending(path: "Sources/MetalGraphicsLib").path) else {
      print("🔥 HotReload: sources not found at \(repoRoot.path); shader and macro reload are off")
      return
    }
    watchers.append(ShaderReloader.watch(repoRoot.appending(path: "Sources/MetalGraphicsLib/Shaders")))
    if injecting, let macros = MacroReloader.watch(repoRoot: repoRoot) {
      watchers.append(macros)
    }
  }

  /// InjectionNext is the maintained successor of InjectionIII; the latter is a fallback.
  private static func loadInjectionBundle() -> Bool {
    let bundles = [
      "/Applications/InjectionNext.app/Contents/Resources/macOSInjection.bundle",
      "/Applications/InjectionIII.app/Contents/Resources/macOSInjection.bundle",
    ]
    var installed = false
    for path in bundles where FileManager.default.fileExists(atPath: path) {
      installed = true
      do {
        try Bundle(path: path)?.loadAndReturnError()
        print("🔥 HotReload: loaded \(path)")
        return true
      } catch {
        // Usually library validation: the Debug app must not use the hardened runtime.
        print("🔥 HotReload: could not load \(path): \(error)")
      }
    }
    if !installed {
      print("🔥 HotReload: InjectionNext is not installed, so Swift edits need a rebuild (see docs/HotReload.md)")
    }
    return false
  }

  /// Called by `MacroReloader` just before it re-saves `count` files for re-injection.
  static func expectInjections(_ count: Int) {
    awaitedInjections = count
  }

  private static func injected() {
    if awaitedInjections > 0 { awaitedInjections -= 1 }
    // Mid-batch, wait long enough to cover the next file's compile, so a file that fails to
    // inject cannot hold the rebuild back for good; otherwise rebuild after a short quiet period.
    scheduleRebuild(after: awaitedInjections > 0 ? .seconds(5) : .milliseconds(200))
  }

  private static func scheduleRebuild(after delay: Duration) {
    pendingRebuild?.cancel()
    pendingRebuild = Task {
      try? await Task.sleep(for: delay)
      guard !Task.isCancelled else { return }
      awaitedInjections = 0
      let windows = WindowRegistry.live
      print("🔥 HotReload: rebuilding the UI tree in \(windows.count) window(s)")
      for window in windows {
        window.post { $0.hotReload() }
      }
    }
  }

  /// Runs a tool to completion, stdout and stderr merged. Blocks, so only call it off the main
  /// thread.
  nonisolated static func run(_ arguments: [String], in directory: URL? = nil) -> (status: Int32, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: arguments[0])
    process.arguments = Array(arguments.dropFirst())
    if let directory { process.currentDirectoryURL = directory }
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
      try process.run()
    } catch {
      return (-1, String(describing: error))
    }
    // Read before waiting: a full pipe would otherwise block the tool forever.
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return (process.terminationStatus, String(decoding: data, as: UTF8.self))
  }

  nonisolated static func elapsed(since start: Date) -> String {
    String(format: "%.1f s", Date().timeIntervalSince(start))
  }
}
#endif
