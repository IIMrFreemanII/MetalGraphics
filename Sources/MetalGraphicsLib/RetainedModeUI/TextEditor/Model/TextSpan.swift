/// What a stretch of text is — a keyword, a comment, a heading — which an `EditorTheme` turns
/// into a look. The built-in kinds cover code and markdown; an app adds its own from
/// `TextToken.firstCustom` up, and gives them styles in its theme.
public struct TextToken: RawRepresentable, Hashable, Sendable {
  public var rawValue: UInt16
  public init(rawValue: UInt16) { self.rawValue = rawValue }

  public static let plain = TextToken(rawValue: 0)
  public static let keyword = TextToken(rawValue: 1)
  public static let type = TextToken(rawValue: 2)
  public static let function = TextToken(rawValue: 3)
  public static let string = TextToken(rawValue: 4)
  public static let number = TextToken(rawValue: 5)
  public static let comment = TextToken(rawValue: 6)
  public static let attribute = TextToken(rawValue: 7)
  public static let directive = TextToken(rawValue: 8)
  public static let operatorSymbol = TextToken(rawValue: 9)
  public static let punctuation = TextToken(rawValue: 10)
  public static let variable = TextToken(rawValue: 11)
  public static let constant = TextToken(rawValue: 12)
  public static let heading1 = TextToken(rawValue: 13)
  public static let heading2 = TextToken(rawValue: 14)
  public static let heading3 = TextToken(rawValue: 15)
  public static let heading4 = TextToken(rawValue: 16)
  public static let heading5 = TextToken(rawValue: 17)
  public static let heading6 = TextToken(rawValue: 18)
  public static let emphasis = TextToken(rawValue: 19)
  public static let strong = TextToken(rawValue: 20)
  public static let strongEmphasis = TextToken(rawValue: 21)
  public static let code = TextToken(rawValue: 22)
  public static let link = TextToken(rawValue: 23)
  public static let markup = TextToken(rawValue: 24)
  public static let quote = TextToken(rawValue: 25)
  public static let listMarker = TextToken(rawValue: 26)
  public static let strikethrough = TextToken(rawValue: 27)
  /// Console output kinds.
  public static let output = TextToken(rawValue: 28)
  public static let error = TextToken(rawValue: 29)
  public static let prompt = TextToken(rawValue: 30)
  public static let success = TextToken(rawValue: 31)
  public static let firstCustom = TextToken(rawValue: 64)

  static let builtInCount = 32

  public static func heading(_ level: Int) -> TextToken {
    TextToken(rawValue: TextToken.heading1.rawValue + UInt16(max(1, min(level, 6)) - 1))
  }
}

/// A token over part of one line, in UTF-16 columns from the line's start.
public struct TextSpan: Hashable, Sendable {
  public var start: Int32
  public var end: Int32
  public var token: TextToken

  public init(start: Int32, end: Int32, token: TextToken) {
    self.start = start
    self.end = end
    self.token = token
  }

  public init(_ range: Range<Int>, _ token: TextToken) {
    self.init(start: Int32(range.lowerBound), end: Int32(range.upperBound), token: token)
  }
}
