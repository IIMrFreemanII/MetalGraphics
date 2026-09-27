#if DEBUG
import Foundation

/// Hot reload for the ReactiveUI macros. When a plugin source changes:
///
/// 1. rebuild the plugin with SwiftPM, in a scratch directory of its own so it never waits on
///    the lock of the app's build (~2.5 s incremental);
/// 2. swap it in for the plugin the compile commands load (`-load-plugin-executable`), which
///    sits next to the app's executable (`ReactiveUIMacrosPlugin`, or `ReactiveUIMacrosPlugin-tool`
///    from SwiftPM's older native build system); every `swift-frontend` launches the plugin
///    afresh, so the next compile expands with the new code;
/// 3. re-save every source file that uses `@Component` or `@Model`, unchanged, so InjectionNext recompiles
///    and re-injects each one. `HotReload` coalesces the injections into one tree rebuild.
///
/// Only the plugin reloads. The `ReactiveUI` target (the macro declarations) needs a rebuild.
enum MacroReloader {
  static func watch(repoRoot: URL) -> FileWatcher? {
    // A bare executable's bundle is the directory it is in; an app's is the `.app` beside it.
    let executableDirectory = Bundle.main.bundleURL.pathExtension == "app"
      ? Bundle.main.bundleURL.deletingLastPathComponent() : Bundle.main.bundleURL
    let pluginNames = ["ReactiveUIMacrosPlugin", "ReactiveUIMacrosPlugin-tool"]
    guard let installed = pluginNames.map({ executableDirectory.appending(path: $0) })
      .first(where: { FileManager.default.fileExists(atPath: $0.path) })
    else {
      print("🔥 HotReload: no macro plugin in \(executableDirectory.path); macro reload is off")
      return nil
    }
    let componentDirectories = ["Sources/Demo", "Sources/MetalGraphicsLib"].map { repoRoot.appending(path: $0) }
    let scratch = repoRoot.appending(path: ".build/hotreload-macros")
    let swiftBuild = ["/usr/bin/xcrun", "swift", "build", "--package-path", repoRoot.path, "--scratch-path", scratch.path]
    let queue = DispatchQueue(label: "HotReload.macros", qos: .userInitiated)

    return FileWatcher(
      directory: repoRoot.appending(path: "Sources/ReactiveUIMacrosPlugin"), extensions: ["swift"], queue: queue
    ) { changed in
      let start = Date()
      print("🔥 HotReload: rebuilding macros (\(changed.map(\.lastPathComponent).joined(separator: ", ")))…")

      let build = HotReload.run(swiftBuild + ["--target", "ReactiveUIMacrosPlugin"])
      guard build.status == 0 else {
        print("🔥 HotReload: macro build failed\n\(build.output)")
        return
      }
      let binPath = HotReload.run(swiftBuild + ["--show-bin-path"])
      let binDirectory = URL(fileURLWithPath: binPath.output.trimmingCharacters(in: .whitespacesAndNewlines))
      guard let built = pluginNames.map({ binDirectory.appending(path: $0) })
        .first(where: { FileManager.default.fileExists(atPath: $0.path) })
      else {
        print("🔥 HotReload: the macro build left no plugin in \(binDirectory.path)")
        return
      }

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
            .range(of: #"(?m)^\s*(@\w+\s+)*@(Component|Model)\b"#, options: .regularExpression) != nil
      }
    }
  }
}
#endif
