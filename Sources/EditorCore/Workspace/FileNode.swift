import Foundation

/// A file or folder of a workspace, and what a folder holds: a value, scanned once and shared by
/// every window. Folders come before files, each sorted by name as Finder sorts them.
public struct FileNode: Sendable, Hashable, Identifiable {
  /// Absolute, standardized.
  public let path: String
  public let name: String
  public let isDirectory: Bool
  public var children: [FileNode]

  public var id: String { self.path }

  public init(path: String, name: String, isDirectory: Bool, children: [FileNode] = []) {
    self.path = path
    self.name = name
    self.isDirectory = isDirectory
    self.children = children
  }

  /// The node at `path`, this one or one inside it.
  public func node(at path: String) -> FileNode? {
    if self.path == path { return self }
    guard self.isDirectory, path.hasPrefix(self.path) else { return nil }
    for child in self.children {
      if let found = child.node(at: path) { return found }
    }
    return nil
  }

  /// Every file inside, depth first, in the order the tree shows them.
  public var allFiles: [FileNode] {
    var files: [FileNode] = []
    self.collectFiles(into: &files)
    return files
  }

  private func collectFiles(into files: inout [FileNode]) {
    for child in self.children {
      if child.isDirectory {
        child.collectFiles(into: &files)
      } else {
        files.append(child)
      }
    }
  }

  /// Folders first, then by name, ignoring case and reading numbers as numbers.
  static func precedes(_ a: FileNode, _ b: FileNode) -> Bool {
    if a.isDirectory != b.isDirectory { return a.isDirectory }
    return a.name.localizedStandardCompare(b.name) == .orderedAscending
  }
}

/// Reads a folder into a `FileNode` tree, leaving out what a developer never opens by hand.
public enum WorkspaceScanner {
  /// Left out wherever they are, besides every name starting with a dot: build products, which
  /// can hold more files than the scan's limit, and are never edited by hand.
  public static let ignoredNames: Set<String> = ["build", "DerivedData", "node_modules", "graphify-out"]

  /// The tree under `root`, at most `limit` entries deep and wide, so a folder picked by
  /// mistake (a home folder) does not hang the scan.
  public static func scan(_ root: URL, limit: Int = 50_000) -> FileNode {
    let root = root.standardizedFileURL
    var remaining = limit
    return self.scan(root, name: root.lastPathComponent, remaining: &remaining)
  }

  public static func isIgnored(_ name: String) -> Bool {
    name.hasPrefix(".") || self.ignoredNames.contains(name)
  }

  private static func scan(_ url: URL, name: String, remaining: inout Int) -> FileNode {
    let manager = FileManager.default
    var node = FileNode(path: url.path, name: name, isDirectory: true)
    guard let names = try? manager.contentsOfDirectory(atPath: url.path) else { return node }
    var children: [FileNode] = []
    for child in names where !self.isIgnored(child) {
      guard remaining > 0 else { break }
      remaining -= 1
      let childURL = url.appendingPathComponent(child)
      var isDirectory: ObjCBool = false
      guard manager.fileExists(atPath: childURL.path, isDirectory: &isDirectory) else { continue }
      // A package or bundle folder (.app, .xcodeproj) is still a folder here.
      if isDirectory.boolValue {
        children.append(self.scan(childURL, name: child, remaining: &remaining))
      } else {
        children.append(FileNode(path: childURL.path, name: child, isDirectory: false))
      }
    }
    children.sort(by: FileNode.precedes)
    node.children = children
    return node
  }
}
