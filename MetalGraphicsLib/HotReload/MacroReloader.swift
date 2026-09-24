#if DEBUG
import Foundation

/// Hot reload for the ReactiveUI macros. When a plugin source changes:
///
/// 1. rebuild the plugin with SwiftPM, in the package's own `.build` (~2.5 s incremental);
/// 2. swap it in for the plugin Xcode's compile commands load (`-load-plugin-executable`), which
///    sits next to the app in `Build/Products/<config>`; every `swift-frontend` launches the
///    plugin afresh, so the next compile expands with the new code;
/// 3. re-save every source file that uses `@Component`, unchanged, so InjectionNext recompiles
///    and re-injects each one. `HotReload` coalesces the injections into one tree rebuild.
///
/// Only the plugin reloads. The `ReactiveUI` target (the macro declarations) needs a rebuild.
enum MacroReloader {
  static func watch(repoRoot: URL) -> FileWatcher? {
    let package = repoRoot.appending(path: "ReactiveUIMacros")
    let installed = Bundle.main.bundleURL.deletingLastPathComponent().appending(path: "ReactiveUIMacrosPlugin")
    guard FileManager.default.fileExists(atPath: installed.path) else {
      print("🔥 HotReload: no macro plugin at \(installed.path); macro reload is off")
      return nil
    }
    let componentDirectories = ["GPURayMarching", "MetalGraphicsLib"].map { repoRoot.appending(path: $0) }
    let queue = DispatchQueue(label: "HotReload.macros", qos: .userInitiated)

    return FileWatcher(
      directory: package.appending(path: "Sources/ReactiveUIMacrosPlugin"), extensions: ["swift"], queue: queue
    ) { changed in
      let start = Date()
      print("🔥 HotReload: rebuilding macros (\(changed.map(\.lastPathComponent).joined(separator: ", ")))…")

      let build = HotReload.run(["/usr/bin/xcrun", "swift", "build", "--package-path", package.path])
      guard build.status == 0 else {
        print("🔥 HotReload: macro build failed\n\(build.output)")
        return
      }
      let binPath = HotReload.run(["/usr/bin/xcrun", "swift", "build", "--package-path", package.path, "--show-bin-path"])
      let built = URL(fileURLWithPath: binPath.output.trimmingCharacters(in: .whitespacesAndNewlines))
        .appending(path: "ReactiveUIMacrosPlugin")

      // Copy beside the target, then rename over it: a compile that is launching the plugin
      // right now sees either the old binary or the new one, never half of one.
      let staged = installed.appendingPathExtension("hotreload")
      do {
        try? FileManager.default.removeItem(at: staged)
        try FileManager.default.copyItem(at: built, to: staged)
        guard rename(staged.path, installed.path) == 0 else {
          throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: installed.path])
        }
      } catch {
        print("🔥 HotReload: could not install the macro plugin: \(error)")
        return
      }

      let components = componentFiles(in: componentDirectories)
      print("🔥 HotReload: macros rebuilt in \(HotReload.elapsed(since: start)); re-injecting \(components.count) component files")
      // Registered before the first save, so no injection can arrive ahead of it.
      DispatchQueue.main.sync {
        MainActor.assumeIsolated { HotReload.expectInjections(components.count) }
      }
      for file in components {
        // Same bytes, saved atomically the way Xcode saves: InjectionNext's watcher ignores
        // in-place writes. The editor has nothing to reconcile, since the content is unchanged.
        if let data = try? Data(contentsOf: file) {
          try? data.write(to: file, options: .atomic)
        }
      }
    }
  }

  private static func componentFiles(in directories: [URL]) -> [URL] {
    directories.flatMap { directory -> [URL] in
      guard let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else { return [] }
      return files.compactMap { $0 as? URL }.filter { url in
        // The attribute itself, at the start of a line; not a mention in a comment.
        url.pathExtension == "swift"
          && (try? String(contentsOf: url, encoding: .utf8))?
            .range(of: #"(?m)^\s*@Component\b"#, options: .regularExpression) != nil
      }
    }
  }
}
#endif
