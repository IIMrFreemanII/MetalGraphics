/// One line of a file tree as a navigator shows it: indented by `depth`, a folder with its
/// disclosure, or a file.
public struct FileTreeRow: Sendable, Hashable, Identifiable {
  public let path: String
  public let name: String
  public let depth: Int
  public let isDirectory: Bool
  public let isExpanded: Bool

  /// The path, marked for an expanded folder: a list keyed by it builds a folder's row again
  /// when it opens or closes, to show its disclosure the other way.
  public var id: String { self.isExpanded ? self.path + "/" : self.path }

  public init(path: String, name: String, depth: Int, isDirectory: Bool, isExpanded: Bool) {
    self.path = path
    self.name = name
    self.depth = depth
    self.isDirectory = isDirectory
    self.isExpanded = isExpanded
  }
}

extension FileNode {
  /// What a navigator shows of this folder: its children, and the children of every folder in
  /// `expanded`, flattened in order. The folder itself is not a row.
  public func rows(expanded: Set<String>) -> [FileTreeRow] {
    var rows: [FileTreeRow] = []
    self.appendRows(depth: 0, expanded: expanded, into: &rows)
    return rows
  }

  private func appendRows(depth: Int, expanded: Set<String>, into rows: inout [FileTreeRow]) {
    for child in self.children {
      let isExpanded = child.isDirectory && expanded.contains(child.path)
      rows.append(FileTreeRow(
        path: child.path, name: child.name, depth: depth, isDirectory: child.isDirectory, isExpanded: isExpanded
      ))
      if isExpanded {
        child.appendRows(depth: depth + 1, expanded: expanded, into: &rows)
      }
    }
  }

  /// The folders from this one down to `path`'s, not counting this one: what to expand to show
  /// `path`.
  public func ancestors(of path: String) -> [String] {
    var folders: [String] = []
    var current = self
    while let next = current.children.first(where: { $0.isDirectory && path.hasPrefix($0.path + "/") }) {
      folders.append(next.path)
      current = next
    }
    return folders
  }
}
