#if DEBUG
import Foundation

/// Recompiles MetalGraphicsLib's shaders when a `.metal` or `.h` in `Shaders/` changes, and swaps
/// `Graphics2D`'s pipelines. Compiling runs on the watcher's queue; only the swap touches the
/// main thread. A compile error is printed and the running pipelines are kept.
///
/// Not reloaded: the bake kernels (`SDFBaker`, `VectorBaker`) — atlases they already baked
/// would not change anyway.
enum ShaderReloader {
  static func watch(_ shaders: URL, renderer: ViewRenderer) -> FileWatcher {
    let queue = DispatchQueue(label: "HotReload.shaders", qos: .userInitiated)
    // `xcrun metal` spends ~7 s looking the toolchain up on every call; the compiler it finds
    // takes under 1 s. Resolve it once, lazily, on the watcher's queue.
    nonisolated(unsafe) var compiler: (metal: String, sdk: String)?

    return FileWatcher(directory: shaders, extensions: ["metal", "h"], queue: queue) { changed in
      let start = Date()
      print("🔥 HotReload: compiling shaders (\(changed.map(\.lastPathComponent).joined(separator: ", ")))…")

      if compiler == nil {
        let metal = HotReload.run(["/usr/bin/xcrun", "-sdk", "macosx", "-f", "metal"])
        let sdk = HotReload.run(["/usr/bin/xcrun", "-sdk", "macosx", "--show-sdk-path"])
        guard metal.status == 0, sdk.status == 0 else {
          print("🔥 HotReload: no Metal compiler found:\n\(metal.output)\(sdk.output)")
          return
        }
        compiler = (
          metal.output.trimmingCharacters(in: .whitespacesAndNewlines),
          sdk.output.trimmingCharacters(in: .whitespacesAndNewlines)
        )
      }
      guard let compiler else { return }

      let sources = ((try? FileManager.default.contentsOfDirectory(at: shaders, includingPropertiesForKeys: nil)) ?? [])
        .filter { $0.pathExtension == "metal" }
        .map(\.path)
        .sorted()
      let output = FileManager.default.temporaryDirectory
        .appending(path: "MetalGraphicsLib-\(UUID().uuidString).metallib")
      // The same flags Xcode passes for MetalGraphicsLib (`MTL_FAST_MATH = YES`, deployment target).
      let result = HotReload.run(
        [compiler.metal, "-isysroot", compiler.sdk, "-target", "air64-apple-macos26.0",
         "-fmetal-math-mode=fast", "-fmetal-math-fp32-functions=fast"]
          + sources + ["-o", output.path]
      )
      guard result.status == 0 else {
        print("🔥 HotReload: shader compile failed, keeping the running shaders\n\(result.output)")
        return
      }

      Task { @MainActor [weak renderer] in
        defer { try? FileManager.default.removeItem(at: output) }
        guard let renderer, let graphics = renderer.graphics2D else { return }
        do {
          try graphics.reloadShaders(from: output)
          // The frame loop skips frames with nothing invalidated; without this the old image stays.
          renderer.uiContext.invalidate(.render)
          print("🔥 HotReload: shaders reloaded in \(HotReload.elapsed(since: start))")
        } catch {
          print("🔥 HotReload: shader reload failed, keeping the running shaders\n\(error)")
        }
      }
    }
  }
}
#endif
