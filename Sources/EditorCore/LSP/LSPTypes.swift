import Foundation

/// A place in a document: a line, and a column in UTF-16 units, both from 0. The editor's
/// `TextDocument` counts in UTF-16 too, so no conversion is needed.
public struct LSPPosition: Sendable, Hashable {
  public var line: Int
  public var character: Int

  public init(line: Int, character: Int) {
    self.line = line
    self.character = character
  }

  var json: JSON { ["line": .number(Double(self.line)), "character": .number(Double(self.character))] }

  init?(_ json: JSON?) {
    guard let line = json?["line"]?.int, let character = json?["character"]?.int else { return nil }
    self.init(line: line, character: character)
  }
}

public struct LSPRange: Sendable, Hashable {
  public var start: LSPPosition
  public var end: LSPPosition

  public init(start: LSPPosition, end: LSPPosition) {
    self.start = start
    self.end = end
  }

  var json: JSON { ["start": self.start.json, "end": self.end.json] }

  init?(_ json: JSON?) {
    guard let start = LSPPosition(json?["start"]), let end = LSPPosition(json?["end"]) else { return nil }
    self.init(start: start, end: end)
  }
}

/// A replacement of `range` by `text`, in the document as it was before it.
public struct LSPTextEdit: Sendable, Hashable {
  public var range: LSPRange
  public var text: String

  public init(range: LSPRange, text: String) {
    self.range = range
    self.text = text
  }

  init?(_ json: JSON?) {
    guard let range = LSPRange(json?["range"]), let text = json?["newText"]?.string else { return nil }
    self.init(range: range, text: text)
  }
}

public struct LSPDiagnostic: Sendable, Hashable {
  public enum Severity: Int, Sendable { case error = 1, warning = 2, information = 3, hint = 4 }

  public var range: LSPRange
  public var severity: Severity
  public var message: String

  public init(range: LSPRange, severity: Severity, message: String) {
    self.range = range
    self.severity = severity
    self.message = message
  }

  init?(_ json: JSON) {
    guard let range = LSPRange(json["range"]), let message = json["message"]?.string else { return nil }
    self.init(range: range, severity: json["severity"]?.int.flatMap(Severity.init(rawValue:)) ?? .error, message: message)
  }
}

public struct LSPLocation: Sendable, Hashable {
  public var uri: String
  public var range: LSPRange

  public init(uri: String, range: LSPRange) {
    self.uri = uri
    self.range = range
  }

  /// A `Location`, or a `LocationLink`'s target.
  init?(_ json: JSON) {
    if let uri = json["uri"]?.string, let range = LSPRange(json["range"]) {
      self.init(uri: uri, range: range)
    } else if let uri = json["targetUri"]?.string, let range = LSPRange(json["targetSelectionRange"] ?? json["targetRange"]) {
      self.init(uri: uri, range: range)
    } else {
      return nil
    }
  }

  /// The file's path, when `uri` names a file.
  public var path: String? { LSPURI.path(self.uri) }
}

/// A completion the server offers.
public struct LSPCompletionItem: Sendable, Hashable, Identifiable {
  public enum Kind: Int, Sendable {
    case text = 1, method, function, constructor, field, variable, `class`, interface, module, property, unit, value,
         `enum`, keyword, snippet, color, file, reference, folder, enumMember, constant, `struct`, event, `operator`,
         typeParameter
  }

  public var label: String
  public var kind: Kind?
  /// The type, or the signature.
  public var detail: String?
  /// What typing is matched against; the label when nil.
  public var filterText: String?
  public var sortText: String?
  /// What is inserted: the edit, else `insertText`, else the label.
  public var textEdit: LSPTextEdit?
  public var insertText: String?
  /// Its place in the server's list, which keeps ids apart.
  public var index: Int

  public var id: Int { self.index }

  public init(label: String, kind: Kind? = nil, detail: String? = nil, filterText: String? = nil, sortText: String? = nil,
              textEdit: LSPTextEdit? = nil, insertText: String? = nil, index: Int = 0) {
    self.label = label
    self.kind = kind
    self.detail = detail
    self.filterText = filterText
    self.sortText = sortText
    self.textEdit = textEdit
    self.insertText = insertText
    self.index = index
  }

  init?(_ json: JSON, index: Int) {
    guard let label = json["label"]?.string else { return nil }
    self.init(
      label: label, kind: json["kind"]?.int.flatMap(Kind.init(rawValue:)), detail: json["detail"]?.string,
      filterText: json["filterText"]?.string, sortText: json["sortText"]?.string, textEdit: LSPTextEdit(json["textEdit"]),
      insertText: json["insertText"]?.string, index: index
    )
  }

  /// What typing is matched against.
  public var matchText: String { self.filterText ?? self.label }

  /// The text to insert, with snippet placeholders (`${1:name}`, `$0`) reduced to their text.
  public var textToInsert: String {
    Self.strippingPlaceholders(self.textEdit?.text ?? self.insertText ?? self.label)
  }

  /// `f(${1:x}, ${2:y})` → `f(x, y)`; `$0` and `$1` go.
  public static func strippingPlaceholders(_ snippet: String) -> String {
    guard snippet.contains("$") else { return snippet }
    var out = ""
    var scalars = Array(snippet.unicodeScalars)[...]
    while let scalar = scalars.popFirst() {
      guard scalar == "$" else {
        out.unicodeScalars.append(scalar)
        continue
      }
      if scalars.first == "{" {
        scalars.removeFirst()
        // Digits, then ":default}".
        while let next = scalars.first, next.properties.numericType != nil { scalars.removeFirst() }
        if scalars.first == ":" { scalars.removeFirst() }
        var depth = 1
        while let next = scalars.popFirst() {
          if next == "{" { depth += 1 }
          if next == "}" { depth -= 1; if depth == 0 { break } }
          out.unicodeScalars.append(next)
        }
      } else {
        while let next = scalars.first, next.properties.numericType != nil { scalars.removeFirst() }
      }
    }
    return out
  }
}

/// `file://` URIs and paths.
public enum LSPURI {
  public static func uri(_ path: String) -> String {
    URL(fileURLWithPath: path).absoluteString
  }

  public static func path(_ uri: String) -> String? {
    guard let url = URL(string: uri), url.isFileURL else { return nil }
    return url.standardizedFileURL.path
  }
}

/// A hover's contents as plain text: `MarkupContent`, a `MarkedString`, or a list of them.
enum LSPHover {
  static func text(_ json: JSON?) -> String? {
    guard let contents = json?["contents"] else { return nil }
    let text: String
    if let value = contents["value"]?.string {
      text = value
    } else if let string = contents.string {
      text = string
    } else if let array = contents.array {
      text = array.compactMap { $0.string ?? $0["value"]?.string }.joined(separator: "\n\n")
    } else {
      return nil
    }
    let plain = self.plain(fromMarkdown: text).trimmingCharacters(in: .whitespacesAndNewlines)
    return plain.isEmpty ? nil : plain
  }

  /// Markdown without its code fences and emphasis marks: what a tooltip shows.
  static func plain(fromMarkdown text: String) -> String {
    text.split(separator: "\n", omittingEmptySubsequences: false)
      .filter { !$0.hasPrefix("```") && $0 != "---" }
      .map { line in line.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "`", with: "") }
      .joined(separator: "\n")
  }
}
