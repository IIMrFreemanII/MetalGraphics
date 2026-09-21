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
    .package(url: "https://github.com/swiftlang/swift-syntax.git", "603.0.0" ..< "605.0.0"),
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
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)
