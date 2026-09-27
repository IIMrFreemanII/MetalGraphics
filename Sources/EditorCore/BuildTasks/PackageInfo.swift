import Foundation

/// What a Swift package declares, as far as the editor needs: its executable products, to run.
public struct PackageInfo: Sendable, Equatable {
  public var name: String
  public var executables: [String]

  public init(name: String, executables: [String]) {
    self.name = name
    self.executables = executables
  }

  /// Reads `swift package describe --type json` output.
  public static func parse(_ json: Data) -> PackageInfo? {
    struct Description: Decodable {
      struct Product: Decodable {
        let name: String
        let type: [String: AnyDecodable?]
      }
      let name: String
      let products: [Product]?
    }
    guard let description = try? JSONDecoder().decode(Description.self, from: json) else { return nil }
    let executables = (description.products ?? []).filter { $0.type["executable"] != nil }.map(\.name).sorted()
    return PackageInfo(name: description.name, executables: executables)
  }

  /// Asks SwiftPM about the package at `folder`: slow (it resolves the package), so run it off
  /// the window threads. Nil for a folder that is not a package.
  public static func describe(_ folder: String) -> PackageInfo? {
    guard FileManager.default.fileExists(atPath: folder + "/Package.swift") else { return nil }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["swift", "package", "describe", "--type", "json"]
    process.currentDirectoryURL = URL(fileURLWithPath: folder)
    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
    } catch {
      return nil
    }
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { return nil }
    return self.parse(data)
  }
}

/// Any JSON value, skipped: a product's type is `{"executable": null}` or `{"library": ["automatic"]}`.
private struct AnyDecodable: Decodable {
  init(from decoder: Decoder) throws {}
}
