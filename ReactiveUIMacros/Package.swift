// swift-tools-version: 6.3

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "ReactiveUIMacros",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "ReactiveUI", targets: ["ReactiveUI"]),
  ],
  dependencies: [
    // Pinned to the newest release that has a prebuilt for the current toolchain (Swift 6.4,
    // Xcode 27 beta); 603/604 have none, so they compile from source: ~3.5 min per clean
    // Release build. Bump once download.swift.org/prebuilts/swift-syntax/<ver>/ has one.
    .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "602.0.0"),
  ],
  targets: [
    // The compiler plugin. Builds for the host, never linked into the app.
    .macro(
      name: "ReactiveUIMacrosPlugin",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ]
    ),

    // Macro declarations only. Deliberately holds zero runtime symbols, and must never
    // depend on MetalGraphicsLib: generated code emits unqualified names that resolve at
    // the use site, where MetalGraphicsLib is imported.
    .target(name: "ReactiveUI", dependencies: ["ReactiveUIMacrosPlugin"]),

    .testTarget(
      name: "ReactiveUIMacrosTests",
      dependencies: [
        "ReactiveUIMacrosPlugin",
        // The generic flavour, so expansion failures can be reported to Swift Testing; the
        // XCTest one only produces warnings there. See MacroAssertions.swift.
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
      ]
    ),
  ]
)
