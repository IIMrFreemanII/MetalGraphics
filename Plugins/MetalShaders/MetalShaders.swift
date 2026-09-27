import Foundation
import PackagePlugin

/// Compiles a target's `Shaders/*.metal` into `default.metallib`, which SwiftPM puts in the
/// target's resource bundle: `device.makeDefaultLibrary(bundle: .module)` loads it. The target
/// excludes `Shaders/`, so neither SwiftPM nor Xcode handles the files a second time.
///
/// The flags match `ShaderReloader`, which recompiles the same files when one changes.
@main
struct MetalShaders: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
    let shaders = target.directoryURL.appending(path: "Shaders")
    let files = try FileManager.default.contentsOfDirectory(at: shaders, includingPropertiesForKeys: nil)
      .sorted { $0.path < $1.path }
    let sources = files.filter { $0.pathExtension == "metal" }
    // Headers are inputs too, so editing one rebuilds the library.
    let headers = files.filter { $0.pathExtension == "h" }

    let work = context.pluginWorkDirectoryURL
    let output = work.appending(path: "default.metallib")
    return [
      .buildCommand(
        displayName: "Compiling Metal shaders for \(target.name)",
        executable: URL(fileURLWithPath: "/usr/bin/xcrun"),
        arguments: [
          "-sdk", "macosx", "metal",
          "-target", "air64-apple-macos26.0",
          "-fmetal-math-mode=fast", "-fmetal-math-fp32-functions=fast",
          // The plugin sandbox only lets the compiler write inside the work directory.
          "-fmodules-cache-path=\(work.appending(path: "ModuleCache").path)",
          "-o", output.path,
        ] + sources.map(\.path),
        environment: ["TMPDIR": work.path],
        inputFiles: sources + headers,
        outputFiles: [output]
      ),
    ]
  }
}
