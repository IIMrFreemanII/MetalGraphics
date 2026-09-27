/// Highlights Swift: keywords, types, calls, numbers, strings with interpolation, multi-line
/// and raw strings, nested block comments, attributes and compiler directives.
///
/// A tokenizer over the line's UTF-16 units, not a parser: a capitalized identifier is a type,
/// one followed by `(` a call. The state across lines holds what a line can leave open: a block
/// comment and its nesting depth, or a multi-line string and its raw `#` count.
public final class SwiftStyler: TextStyler {
  public init() {}

  public var lineComment: String? { "//" }

  // State: the mode in the low byte, a comment's depth or a raw string's `#` count above it.
  private enum Mode: UInt64 {
    case code = 0
    case blockComment = 1
    case multilineString = 2
  }

  private static func state(_ mode: Mode, _ count: Int = 0) -> StyleState {
    StyleState(mode.rawValue | UInt64(count) << 8)
  }

  public func styleLine(_ text: UnsafeBufferPointer<UInt16>, state: StyleState, into spans: inout [TextSpan]) -> StyleState {
    // The spans move into the scanner and back, so appending copies nothing.
    var scanner = Scanner(text: text, spans: [])
    swap(&scanner.spans, &spans)
    defer { swap(&scanner.spans, &spans) }
    let mode = Mode(rawValue: state.raw & 0xFF) ?? .code
    let count = Int(state.raw >> 8)
    var i = 0
    switch mode {
    case .blockComment:
      let (end, depth) = scanner.blockComment(from: 0, depth: max(count, 1))
      if depth > 0 { return Self.state(.blockComment, depth) }
      i = end
    case .multilineString:
      let (end, closed) = scanner.multilineString(from: 0, hashes: count)
      if !closed { return state }
      i = end
    case .code:
      break
    }
    return scanner.code(from: i, until: text.count, nested: false)
  }

  /// Walks one line, appending spans.
  private struct Scanner {
    let text: UnsafeBufferPointer<UInt16>
    var spans: [TextSpan]

    init(text: UnsafeBufferPointer<UInt16>, spans: [TextSpan]) {
      self.text = text
      self.spans = spans
    }

    mutating func add(_ start: Int, _ end: Int, _ token: TextToken) {
      guard end > start else { return }
      if let last = self.spans.last, last.token == token, Int(last.end) == start {
        self.spans[self.spans.count - 1].end = Int32(end)
      } else {
        self.spans.append(TextSpan(start: Int32(start), end: Int32(end), token: token))
      }
    }

    func at(_ i: Int) -> UInt16 {
      i < self.text.count ? self.text[i] : 0
    }

    /// Code from `start`; inside an interpolation, up to its closing `)`. Returns the state the
    /// line ends in, and for an interpolation, where it ended in `raw` of the state.
    mutating func code(from start: Int, until end: Int, nested: Bool) -> StyleState {
      var i = start
      var parens = 0
      while i < end {
        let c = self.text[i]
        switch c {
        case 0x2F where self.at(i + 1) == 0x2F:   // //
          self.add(i, end, .comment)
          return nested ? StyleState(UInt64(end)) : SwiftStyler.state(.code)
        case 0x2F where self.at(i + 1) == 0x2A:   // /*
          let (next, depth) = self.blockComment(from: i + 2, depth: 1, openedAt: i)
          if depth > 0 { return nested ? StyleState(UInt64(end)) : SwiftStyler.state(.blockComment, depth) }
          i = next
        case 0x22, 0x23 where self.isStringStart(i):   // " or #"
          var hashes = 0
          while self.at(i + hashes) == 0x23 { hashes += 1 }
          let quote = i + hashes
          if self.at(quote + 1) == 0x22 && self.at(quote + 2) == 0x22 {
            // """ ends the line's code: the rest is the multi-line string's.
            self.add(i, quote + 3, .string)
            let (next, closed) = self.multilineString(from: quote + 3, hashes: hashes)
            if !closed { return nested ? StyleState(UInt64(end)) : SwiftStyler.state(.multilineString, hashes) }
            i = next
          } else {
            i = self.string(from: i, quote: quote, hashes: hashes)
          }
        case 0x28:   // (
          parens += 1
          self.add(i, i + 1, .punctuation)
          i += 1
        case 0x29:   // )
          if nested && parens == 0 { return StyleState(UInt64(i)) }
          parens -= 1
          self.add(i, i + 1, .punctuation)
          i += 1
        case 0x40:   // @attribute
          let e = self.identifierEnd(i + 1)
          self.add(i, max(e, i + 1), .attribute)
          i = max(e, i + 1)
        case 0x23:   // #directive
          let e = self.identifierEnd(i + 1)
          self.add(i, max(e, i + 1), .directive)
          i = max(e, i + 1)
        case 0x30 ... 0x39:
          let e = self.numberEnd(i)
          self.add(i, e, .number)
          i = e
        default:
          if Self.isIdentifierStart(c) {
            let e = self.identifierEnd(i)
            self.identifier(i, e)
            i = e
          } else if c == 0x60 {   // `escaped`
            var e = i + 1
            while e < end && self.text[e] != 0x60 { e += 1 }
            i = min(e + 1, end)
          } else if Self.isOperator(c) {
            var e = i + 1
            while e < end && Self.isOperator(self.text[e]) && !(self.text[e] == 0x2F && (self.at(e + 1) == 0x2F || self.at(e + 1) == 0x2A)) { e += 1 }
            self.add(i, e, .operatorSymbol)
            i = e
          } else if c == 0x7B || c == 0x7D || c == 0x5B || c == 0x5D || c == 0x2C || c == 0x3A || c == 0x3B || c == 0x2E {
            self.add(i, i + 1, .punctuation)
            i += 1
          } else {
            i += 1
          }
        }
      }
      return nested ? StyleState(UInt64(end)) : SwiftStyler.state(.code)
    }

    func isStringStart(_ i: Int) -> Bool {
      var j = i
      while self.at(j) == 0x23 { j += 1 }
      return self.at(j) == 0x22
    }

    /// A one-line string starting at `start`, its quote at `quote`. Returns where it ends.
    mutating func string(from start: Int, quote: Int, hashes: Int) -> Int {
      var i = quote + 1
      var segment = start
      let end = self.text.count
      while i < end {
        let c = self.text[i]
        if c == 0x5C && self.hashesFollow(i + 1, hashes) {   // \ with the raw hashes
          let after = i + 1 + hashes
          if self.at(after) == 0x28 {   // \( interpolation
            self.add(segment, after + 1, .string)
            let stop = Int(self.code(from: after + 1, until: end, nested: true).raw)
            if stop < end {
              self.add(stop, stop + 1, .string)
              i = stop + 1
            } else {
              return end
            }
            segment = i
            continue
          }
          i = after + 1
          continue
        }
        if c == 0x22 && self.hashesFollow(i + 1, hashes) {
          self.add(segment, i + 1 + hashes, .string)
          return i + 1 + hashes
        }
        i += 1
      }
      self.add(segment, end, .string)
      return end
    }

    func hashesFollow(_ i: Int, _ count: Int) -> Bool {
      for k in 0 ..< count where self.at(i + k) != 0x23 { return false }
      return true
    }

    /// The rest of a multi-line string from `start`: where it closes, or the line's end.
    mutating func multilineString(from start: Int, hashes: Int) -> (Int, Bool) {
      var i = start
      let end = self.text.count
      var segment = start
      while i < end {
        let c = self.text[i]
        if c == 0x5C && self.hashesFollow(i + 1, hashes) && self.at(i + 1 + hashes) == 0x28 {
          let after = i + 1 + hashes
          self.add(segment, after + 1, .string)
          let stop = Int(self.code(from: after + 1, until: end, nested: true).raw)
          guard stop < end else { return (end, false) }
          self.add(stop, stop + 1, .string)
          i = stop + 1
          segment = i
          continue
        }
        if c == 0x22 && self.at(i + 1) == 0x22 && self.at(i + 2) == 0x22 && self.hashesFollow(i + 3, hashes) {
          self.add(segment, i + 3 + hashes, .string)
          return (i + 3 + hashes, true)
        }
        i += 1
      }
      self.add(segment, end, .string)
      return (end, false)
    }

    /// A block comment from `start`, `depth` deep: where it ends, and the depth left open.
    mutating func blockComment(from start: Int, depth: Int, openedAt: Int? = nil) -> (Int, Int) {
      var i = start
      var depth = depth
      let end = self.text.count
      while i < end && depth > 0 {
        if self.text[i] == 0x2F && self.at(i + 1) == 0x2A {
          depth += 1
          i += 2
        } else if self.text[i] == 0x2A && self.at(i + 1) == 0x2F {
          depth -= 1
          i += 2
        } else {
          i += 1
        }
      }
      self.add(openedAt ?? start, i, .comment)
      return (i, depth)
    }

    mutating func identifier(_ start: Int, _ end: Int) {
      if let keyword = SwiftStyler.keyword(self.text, start, end) {
        self.add(start, end, keyword)
        return
      }
      let first = self.text[start]
      if first >= 0x41 && first <= 0x5A {
        self.add(start, end, .type)
        return
      }
      // A call: the name, then `(`.
      var j = end
      while j < self.text.count && self.text[j] == 0x20 { j += 1 }
      if self.at(j) == 0x28 {
        self.add(start, end, .function)
      }
    }

    static func isIdentifierStart(_ c: UInt16) -> Bool {
      (c >= 0x61 && c <= 0x7A) || (c >= 0x41 && c <= 0x5A) || c == 0x5F || c >= 0xC0
    }

    static func isIdentifierPart(_ c: UInt16) -> Bool {
      Self.isIdentifierStart(c) || (c >= 0x30 && c <= 0x39)
    }

    static func isOperator(_ c: UInt16) -> Bool {
      switch c {
      case 0x2B, 0x2D, 0x2A, 0x2F, 0x25, 0x3D, 0x3C, 0x3E, 0x21, 0x26, 0x7C, 0x5E, 0x7E, 0x3F: true
      default: false
      }
    }

    func identifierEnd(_ start: Int) -> Int {
      var i = start
      while i < self.text.count && Self.isIdentifierPart(self.text[i]) { i += 1 }
      return i
    }

    func numberEnd(_ start: Int) -> Int {
      var i = start + 1
      let end = self.text.count
      while i < end {
        let c = self.text[i]
        let isDigitLike = (c >= 0x30 && c <= 0x39) || (c >= 0x61 && c <= 0x66) || (c >= 0x41 && c <= 0x46)
          || c == 0x5F || c == 0x78 || c == 0x6F || c == 0x62 || c == 0x70 || c == 0x50
        if isDigitLike {
          i += 1
        } else if c == 0x2E, i + 1 < end, self.text[i + 1] >= 0x30 && self.text[i + 1] <= 0x39 {
          i += 1
        } else if (c == 0x2D || c == 0x2B), i > start, self.text[i - 1] == 0x65 || self.text[i - 1] == 0x45 || self.text[i - 1] == 0x70 {
          i += 1
        } else {
          break
        }
      }
      return i
    }
  }

  // MARK: - Keywords

  private static let keywordList = [
    "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init", "inout",
    "internal", "let", "open", "operator", "private", "precedencegroup", "protocol", "public", "rethrows", "static",
    "struct", "subscript", "typealias", "var", "break", "case", "catch", "continue", "default", "defer", "do", "else",
    "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw", "switch", "where", "while", "Any", "as",
    "await", "false", "is", "nil", "self", "Self", "super", "throws", "true", "try", "async", "some", "any", "final",
    "lazy", "mutating", "nonmutating", "optional", "override", "required", "unowned", "weak", "convenience",
    "dynamic", "indirect", "get", "set", "willSet", "didSet", "consuming", "borrowing", "sending", "nonisolated",
    "isolated", "actor", "macro", "package", "each", "then",
  ]

  /// Keywords by a hash of their units: looked up with no string made.
  private static let keywords: [UInt64: [(units: [UInt16], token: TextToken)]] = {
    var table: [UInt64: [(units: [UInt16], token: TextToken)]] = [:]
    for word in keywordList {
      let units = Array(word.utf16)
      let token: TextToken = ["true", "false", "nil"].contains(word) ? .constant : .keyword
      let hash = units.withUnsafeBufferPointer { SwiftStyler.hash($0, 0, $0.count) }
      table[hash, default: []].append((units, token))
    }
    return table
  }()

  private static func hash(_ text: UnsafeBufferPointer<UInt16>, _ start: Int, _ end: Int) -> UInt64 {
    var hash: UInt64 = 0xCBF2_9CE4_8422_2325
    for i in start ..< end {
      hash ^= UInt64(text[i])
      hash = hash &* 0x100_0000_01B3
    }
    return hash
  }

  fileprivate static func keyword(_ text: UnsafeBufferPointer<UInt16>, _ start: Int, _ end: Int) -> TextToken? {
    let length = end - start
    guard length >= 2 && length <= 16, let candidates = Self.keywords[Self.hash(text, start, end)] else { return nil }
    outer: for candidate in candidates where candidate.units.count == length {
      for k in 0 ..< length where candidate.units[k] != text[start + k] { continue outer }
      return candidate.token
    }
    return nil
  }
}

// A new line after `{`, `(` or `[` goes one level in; `}`, `)` or `]` typed first on a line goes
// one level out. Lexical, as the styler is: a bracket in a trailing comment still counts.
extension SwiftStyler: IndentationRules {
  public func opensBlock(_ text: [UInt16]) -> Bool {
    guard let last = text.last else { return false }
    return self.closer(forOpener: last) != nil
  }

  public func closer(forOpener unit: UInt16) -> UInt16? {
    switch unit {
    case 0x7B: 0x7D
    case 0x28: 0x29
    case 0x5B: 0x5D
    default: nil
    }
  }

  public func closesBlock(_ unit: UInt16) -> Bool {
    unit == 0x7D || unit == 0x29 || unit == 0x5D
  }
}
