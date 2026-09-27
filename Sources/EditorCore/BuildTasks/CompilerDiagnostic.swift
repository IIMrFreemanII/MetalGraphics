import Foundation

/// A problem the compiler reported: `/path/File.swift:12:5: error: cannot find 'x' in scope`.
public struct CompilerDiagnostic: Sendable, Hashable, Identifiable {
  public enum Severity: String, Sendable, Hashable, Comparable {
    case note, remark, warning, error

    private var rank: Int {
      switch self {
      case .note: 0
      case .remark: 1
      case .warning: 2
      case .error: 3
      }
    }

    public static func < (a: Severity, b: Severity) -> Bool { a.rank < b.rank }
  }

  /// Absolute, as the compiler printed it.
  public let path: String
  /// From 1.
  public let line: Int
  /// From 1, in UTF-8 bytes, as compilers count; 1 when the compiler gave none.
  public let column: Int
  public let severity: Severity
  public let message: String

  public var id: String { "\(self.path):\(self.line):\(self.column):\(self.severity.rawValue):\(self.message)" }

  public init(path: String, line: Int, column: Int, severity: Severity, message: String) {
    self.path = path
    self.line = line
    self.column = column
    self.severity = severity
    self.message = message
  }
}

/// Finds compiler diagnostics in build output, a line at a time.
public enum CompilerDiagnosticParser {
  // `path:line:column: severity: message`, or without the column, as the linker and some tools
  // print. The path is absolute; it may hold colons, so the numbers anchor the match.
  private static let pattern = try! NSRegularExpression(
    pattern: #"^(/.+?):(\d+)(?::(\d+))?: (error|warning|note|remark): (.*)$"#
  )

  /// The diagnostic `line` reports, if it is one.
  public static func parse(_ line: String) -> CompilerDiagnostic? {
    // Cheap test first: most lines of a build are not diagnostics.
    guard line.hasPrefix("/"), line.contains(": ") else { return nil }
    let text = line.hasSuffix("\r") ? String(line.dropLast()) : line
    let range = NSRange(text.startIndex..., in: text)
    guard let match = self.pattern.firstMatch(in: text, range: range) else { return nil }
    func group(_ i: Int) -> String? {
      Range(match.range(at: i), in: text).map { String(text[$0]) }
    }
    guard let path = group(1), let line = group(2).flatMap(Int.init), let kind = group(4),
          let severity = CompilerDiagnostic.Severity(rawValue: kind), let message = group(5)
    else { return nil }
    return CompilerDiagnostic(
      path: URL(fileURLWithPath: path).standardizedFileURL.path, line: line,
      column: group(3).flatMap(Int.init) ?? 1, severity: severity, message: message
    )
  }
}
