// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

/// Every Swift target: Swift 6 with approachable concurrency.
let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
  name: "MetalGraphics",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "MetalGraphicsLib", targets: ["MetalGraphicsLib"]),
    .library(name: "ReactiveUI", targets: ["ReactiveUI"]),
    .executable(name: "Demo", targets: ["Demo"]),
    .executable(name: "Editor", targets: ["Editor"]),
  ],
  dependencies: [
    // Pinned to the newest release that has a prebuilt for the current toolchain (Swift 6.4,
    // Xcode 27 beta); 603/604 have none, so they compile from source: ~3.5 min per clean
    // Release build. Bump once download.swift.org/prebuilts/swift-syntax/<ver>/ has one.
    .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "602.0.0"),
  ],
  targets: [
    // The retained-mode UI and its Metal renderer. `Shaders/` is compiled into the target's
    // `default.metallib` (in `Bundle.module`) by the `MetalShaders` plugin.
    .target(
      name: "MetalGraphicsLib",
      exclude: ["Shaders"],
      swiftSettings: swiftSettings,
      plugins: ["MetalShaders"]
    ),

    // Compiles a target's `Shaders/*.metal` into `default.metallib`.
    .plugin(name: "MetalShaders", capability: .buildTool()),

    // The compiler plugin. Builds for the host, never linked into the app.
    .macro(
      name: "ReactiveUIMacrosPlugin",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ],
      swiftSettings: swiftSettings
    ),

    // Macro declarations only. Deliberately holds zero runtime symbols, and must never
    // depend on MetalGraphicsLib: generated code emits unqualified names that resolve at
    // the use site, where MetalGraphicsLib is imported.
    .target(name: "ReactiveUI", dependencies: ["ReactiveUIMacrosPlugin"], swiftSettings: swiftSettings),

    // The demo app: `swift run Demo`.
    .executableTarget(
      name: "Demo",
      dependencies: ["MetalGraphicsLib", "ReactiveUI"],
      resources: [.process("Resources")],
      swiftSettings: swiftSettings,
      // Lets InjectionNext interpose hot-reloaded functions. See docs/HotReload.md.
      linkerSettings: [.unsafeFlags(["-Xlinker", "-interposable"], .when(configuration: .debug))]
    ),

    // The Swift editor's model, with no UI: the workspace's files, reading and saving them.
    // Foundation only, so its tests need no window.
    .target(name: "EditorCore", swiftSettings: swiftSettings),

    // The Swift editor: `swift run Editor [folder]`. See docs/Editor.md.
    .executableTarget(
      name: "Editor",
      dependencies: ["MetalGraphicsLib", "ReactiveUI", "EditorCore"],
      swiftSettings: swiftSettings,
      linkerSettings: [.unsafeFlags(["-Xlinker", "-interposable"], .when(configuration: .debug))]
    ),

    .testTarget(
      name: "MetalGraphicsLibTests",
      dependencies: ["MetalGraphicsLib", "ReactiveUI"],
      // Golden images, found next to the tests through `#filePath`.
      exclude: ["__Snapshots__", "TextEditor/__Snapshots__"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "DemoTests",
      dependencies: ["Demo", "MetalGraphicsLib", "ReactiveUI"],
      exclude: ["__Snapshots__"],
      swiftSettings: swiftSettings
    ),
    .testTarget(name: "EditorCoreTests", dependencies: ["EditorCore"], swiftSettings: swiftSettings),
    .testTarget(
      name: "EditorTests",
      dependencies: ["Editor", "EditorCore", "MetalGraphicsLib", "ReactiveUI"],
      exclude: ["__Snapshots__"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "ReactiveUIMacrosTests",
      dependencies: [
        "ReactiveUIMacrosPlugin",
        // The generic flavour, so expansion failures can be reported to Swift Testing; the
        // XCTest one only produces warnings there. See MacroAssertions.swift.
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
      ],
      swiftSettings: swiftSettings
    ),

    // Development tools. `swift run layoutchecks`, `swift run uidrive …`.
    .executableTarget(
      name: "layoutchecks",
      dependencies: ["MetalGraphicsLib"],
      path: "Tools/layoutchecks",
      // A standalone SwiftUI program: `swiftc Tools/layoutchecks/oracle.swift`.
      exclude: ["oracle.swift"],
      swiftSettings: swiftSettings
    ),
    // Top-level script code, written for the Swift 5 language mode.
    .executableTarget(name: "uidrive", path: "Tools/uidrive", swiftSettings: [.swiftLanguageMode(.v5)]),
  ],
  swiftLanguageModes: [.v6]
)
