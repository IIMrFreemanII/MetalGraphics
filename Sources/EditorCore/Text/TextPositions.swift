/// Column conversions between the units tools count in: compilers count UTF-8 bytes, the editor
/// and language servers UTF-16 units.
public enum TextPositions {
  /// The UTF-16 column of the character `utf8Column` bytes into `line`. A column inside a
  /// character, or past the end, goes to its end.
  public static func utf16Column(fromUTF8 utf8Column: Int, in line: String) -> Int {
    guard utf8Column > 0 else { return 0 }
    var bytes = 0
    var units = 0
    for scalar in line.unicodeScalars {
      guard bytes < utf8Column else { break }
      bytes += UTF8.width(scalar)
      units += UTF16.width(scalar)
    }
    return units
  }

  /// The UTF-8 column of `utf16Column` units into `line`.
  public static func utf8Column(fromUTF16 utf16Column: Int, in line: String) -> Int {
    guard utf16Column > 0 else { return 0 }
    var bytes = 0
    var units = 0
    for scalar in line.unicodeScalars {
      guard units < utf16Column else { break }
      bytes += UTF8.width(scalar)
      units += UTF16.width(scalar)
    }
    return bytes
  }

  /// `path` from `root`'s folder down: "Sources/App/main.swift". `path` itself when it is not
  /// inside `root`.
  public static func relativePath(_ path: String, from root: String) -> String {
    let prefix = root.hasSuffix("/") ? root : root + "/"
    return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
  }
}
