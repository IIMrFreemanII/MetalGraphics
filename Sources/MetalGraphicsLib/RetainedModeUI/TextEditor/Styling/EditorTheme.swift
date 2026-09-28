import simd

/// How an underline under a stretch of text is drawn.
public enum UnderlineStyle: Hashable, Sendable {
  case single
  case thick
  /// A wavy line, as under a misspelling or a compiler error.
  case squiggle
}

/// How one kind of token looks. Fields left nil keep the editor's base look. Only the font
/// fields — weight, italic, size — change how a line is shaped; the rest are drawn over it.
public struct SpanStyle: Hashable, Sendable {
  public var foreground: float4?
  public var background: float4?
  public var weight: TextFont.Weight?
  public var italic: Bool?
  /// Multiplies the base font's size: a markdown heading is larger.
  public var sizeScale: Float
  public var underline: UnderlineStyle?
  public var underlineColor: float4?
  public var strikethrough: Bool

  public init(
    foreground: float4? = nil, background: float4? = nil, weight: TextFont.Weight? = nil, italic: Bool? = nil,
    sizeScale: Float = 1, underline: UnderlineStyle? = nil, underlineColor: float4? = nil, strikethrough: Bool = false
  ) {
    self.foreground = foreground
    self.background = background
    self.weight = weight
    self.italic = italic
    self.sizeScale = sizeScale
    self.underline = underline
    self.underlineColor = underlineColor
    self.strikethrough = strikethrough
  }

  /// Whether this changes the shape of the text, and not only its colours.
  var affectsShape: Bool {
    self.weight != nil || self.italic != nil || self.sizeScale != 1 || self.underline == .single
      || self.underline == .thick || self.strikethrough
  }
}

/// An editor's look: its colours, the style of each token kind, and its spacing.
public struct EditorTheme: Hashable, Sendable {
  public var background: float4
  public var foreground: float4
  public var caret: float4
  public var selection: float4
  /// The selection while the editor does not have focus.
  public var inactiveSelection: float4
  public var currentLine: float4?
  public var gutterBackground: float4
  public var gutterForeground: float4
  public var gutterCurrentLine: float4
  public var gutterSeparator: float4?
  /// Under the input method's text while it is composed.
  public var markedText: float4
  /// The current search match's box, and the others' fill.
  public var searchMatch: float4
  public var currentSearchMatch: float4
  /// Behind a bracket beside the caret and its partner.
  public var bracketMatch: float4
  public var diagnosticColors: [float4]
  /// Extra space below every line on screen.
  public var lineSpacing: Float
  /// Every line this tall, whatever the font's own height: in place of `lineSpacing` when set.
  public var lineHeight: Float? = nil
  /// The line number gutter is at least this wide.
  public var minGutterWidth: Float = 0
  /// Between the text and the edges of the editor.
  public var textInset: float2
  /// The font when nothing around the editor sets one.
  public var font: TextFont

  /// Indexed by token raw value.
  private var styles: [SpanStyle?]

  public init(
    background: float4, foreground: float4, caret: float4, selection: float4, inactiveSelection: float4,
    currentLine: float4?, gutterBackground: float4, gutterForeground: float4, gutterCurrentLine: float4,
    gutterSeparator: float4?, markedText: float4, searchMatch: float4, currentSearchMatch: float4,
    diagnosticColors: [float4], lineSpacing: Float = 3, textInset: float2 = float2(6, 4),
    font: TextFont = .system(size: 13, design: .monospaced), styles: [TextToken: SpanStyle] = [:],
    bracketMatch: float4 = float4(0.5, 0.5, 0.55, 0.28)
  ) {
    self.bracketMatch = bracketMatch
    self.background = background
    self.foreground = foreground
    self.caret = caret
    self.selection = selection
    self.inactiveSelection = inactiveSelection
    self.currentLine = currentLine
    self.gutterBackground = gutterBackground
    self.gutterForeground = gutterForeground
    self.gutterCurrentLine = gutterCurrentLine
    self.gutterSeparator = gutterSeparator
    self.markedText = markedText
    self.searchMatch = searchMatch
    self.currentSearchMatch = currentSearchMatch
    self.diagnosticColors = diagnosticColors
    self.lineSpacing = lineSpacing
    self.textInset = textInset
    self.font = font
    self.styles = []
    for (token, style) in styles {
      self[token] = style
    }
  }

  public subscript(_ token: TextToken) -> SpanStyle? {
    get {
      let index = Int(token.rawValue)
      return index < self.styles.count ? self.styles[index] : nil
    }
    set {
      let index = Int(token.rawValue)
      if index >= self.styles.count {
        self.styles.append(contentsOf: Array(repeating: nil, count: index + 1 - self.styles.count))
      }
      self.styles[index] = newValue
    }
  }

  /// The colour of a diagnostic's squiggle.
  func color(for severity: DiagnosticSeverity) -> float4 {
    let colors = self.diagnosticColors
    return colors.isEmpty ? self.foreground : colors[min(severity.rawValue, colors.count - 1)]
  }

  /// A copy with `style` for `token`.
  public func style(_ token: TextToken, _ style: SpanStyle?) -> EditorTheme {
    var theme = self
    theme[token] = style
    return theme
  }

  // MARK: - Presets

  private static func rgb(_ hex: UInt32, _ alpha: Float = 1) -> float4 {
    float4(hex: hex, alpha: alpha)
  }

  private static func headings(_ color: float4) -> [TextToken: SpanStyle] {
    let scales: [Float] = [1.8, 1.5, 1.3, 1.15, 1.05, 1.0]
    var styles: [TextToken: SpanStyle] = [:]
    for (level, scale) in scales.enumerated() {
      styles[.heading(level + 1)] = SpanStyle(foreground: color, weight: .bold, sizeScale: scale)
    }
    return styles
  }

  /// Xcode's default light look, near enough.
  public static let light: EditorTheme = {
    var styles: [TextToken: SpanStyle] = [
      .keyword: SpanStyle(foreground: rgb(0x9B2393), weight: .semibold),
      .type: SpanStyle(foreground: rgb(0x0B4F79)),
      .function: SpanStyle(foreground: rgb(0x326D74)),
      .string: SpanStyle(foreground: rgb(0xC41A16)),
      .number: SpanStyle(foreground: rgb(0x1C00CF)),
      .comment: SpanStyle(foreground: rgb(0x5D6C79), italic: true),
      .attribute: SpanStyle(foreground: rgb(0x815F03)),
      .directive: SpanStyle(foreground: rgb(0x643820)),
      .operatorSymbol: SpanStyle(foreground: rgb(0x262626)),
      .punctuation: SpanStyle(foreground: rgb(0x262626)),
      .variable: SpanStyle(foreground: rgb(0x3E8087)),
      .constant: SpanStyle(foreground: rgb(0x1C00CF)),
      .emphasis: SpanStyle(italic: true),
      .strong: SpanStyle(weight: .bold),
      .strongEmphasis: SpanStyle(weight: .bold, italic: true),
      .code: SpanStyle(foreground: rgb(0xC41A16), background: rgb(0x000000, 0.05)),
      .link: SpanStyle(foreground: rgb(0x0E5FD8), underline: .single),
      .markup: SpanStyle(foreground: rgb(0x8E8E93)),
      .quote: SpanStyle(foreground: rgb(0x5D6C79), italic: true),
      .listMarker: SpanStyle(foreground: rgb(0x9B2393), weight: .bold),
      .strikethrough: SpanStyle(foreground: rgb(0x8E8E93), strikethrough: true),
      .output: SpanStyle(foreground: rgb(0x262626)),
      .error: SpanStyle(foreground: rgb(0xD12F1B)),
      .prompt: SpanStyle(foreground: rgb(0x0E5FD8), weight: .bold),
      .success: SpanStyle(foreground: rgb(0x1E8A34)),
    ]
    styles.merge(headings(rgb(0x1D1D1F))) { $1 }
    return EditorTheme(
      background: rgb(0xFFFFFF), foreground: rgb(0x1D1D1F), caret: rgb(0x0A64D8),
      selection: rgb(0xB4D8FD), inactiveSelection: rgb(0xDCDCDC), currentLine: rgb(0xECF5FF),
      gutterBackground: rgb(0xF7F7F7), gutterForeground: rgb(0xA0A0A5), gutterCurrentLine: rgb(0x1D1D1F),
      gutterSeparator: rgb(0x000000, 0.08), markedText: rgb(0x1D1D1F), searchMatch: rgb(0xFFE36E, 0.6),
      currentSearchMatch: rgb(0xF5B800), diagnosticColors: [rgb(0x8E8E93), rgb(0x0E5FD8), rgb(0xE8A200), rgb(0xE0312D)],
      styles: styles
    )
  }()

  /// Xcode's default dark look, near enough.
  public static let dark: EditorTheme = {
    var styles: [TextToken: SpanStyle] = [
      .keyword: SpanStyle(foreground: rgb(0xFF7AB2), weight: .semibold),
      .type: SpanStyle(foreground: rgb(0x6BDFFF)),
      .function: SpanStyle(foreground: rgb(0x67B7A4)),
      .string: SpanStyle(foreground: rgb(0xFF8170)),
      .number: SpanStyle(foreground: rgb(0xD9C97C)),
      .comment: SpanStyle(foreground: rgb(0x7F8C98), italic: true),
      .attribute: SpanStyle(foreground: rgb(0xCC9768)),
      .directive: SpanStyle(foreground: rgb(0xFD8F3F)),
      .operatorSymbol: SpanStyle(foreground: rgb(0xDFDFE0)),
      .punctuation: SpanStyle(foreground: rgb(0xDFDFE0)),
      .variable: SpanStyle(foreground: rgb(0x4EB0CC)),
      .constant: SpanStyle(foreground: rgb(0xD9C97C)),
      .emphasis: SpanStyle(italic: true),
      .strong: SpanStyle(weight: .bold),
      .strongEmphasis: SpanStyle(weight: .bold, italic: true),
      .code: SpanStyle(foreground: rgb(0xFF8170), background: rgb(0xFFFFFF, 0.07)),
      .link: SpanStyle(foreground: rgb(0x6699FF), underline: .single),
      .markup: SpanStyle(foreground: rgb(0x7F8C98)),
      .quote: SpanStyle(foreground: rgb(0x9DA5AD), italic: true),
      .listMarker: SpanStyle(foreground: rgb(0xFF7AB2), weight: .bold),
      .strikethrough: SpanStyle(foreground: rgb(0x7F8C98), strikethrough: true),
      .output: SpanStyle(foreground: rgb(0xDFDFE0)),
      .error: SpanStyle(foreground: rgb(0xFF6B5E)),
      .prompt: SpanStyle(foreground: rgb(0x6699FF), weight: .bold),
      .success: SpanStyle(foreground: rgb(0x7DDB7D)),
    ]
    styles.merge(headings(rgb(0xF2F2F7))) { $1 }
    return EditorTheme(
      background: rgb(0x1F1F24), foreground: rgb(0xDFDFE0), caret: rgb(0xFFFFFF),
      selection: rgb(0x515B70), inactiveSelection: rgb(0x3E3E44), currentLine: rgb(0x23252B),
      gutterBackground: rgb(0x1F1F24), gutterForeground: rgb(0x747478), gutterCurrentLine: rgb(0xDFDFE0),
      gutterSeparator: rgb(0xFFFFFF, 0.08), markedText: rgb(0xDFDFE0), searchMatch: rgb(0x6E5A1E, 0.8),
      currentSearchMatch: rgb(0xB88A00), diagnosticColors: [rgb(0x8E8E93), rgb(0x6699FF), rgb(0xFFC23F), rgb(0xFF5F57)],
      styles: styles
    )
  }()
}
