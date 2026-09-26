import simd

/// A text's case, as SwiftUI's `Text.Case`.
public enum TextCase: Hashable, Sendable {
  case uppercase, lowercase
}

/// An underline or a strikethrough: on or off, in a colour of its own or the text's.
public struct TextDecorationStyle: Equatable, Sendable {
  public var isActive: Bool
  /// nil is the text's colour.
  public var color: float4?

  public init(isActive: Bool = true, color: float4? = nil) {
    self.isActive = isActive
    self.color = color
  }
}

/// How text is styled, as SwiftUI's environment carries it: every field optional, nil where
/// nothing set it.
///
/// Three layers make a `Text`'s style, nearest last: what the `TextStyleElement`s around it set,
/// which reaches it during layout through `current`; what the containers around it in the same
/// `@Component` body set, which the macro writes into it (`Text.inheritedStyle`); and its own
/// modifiers (`Text.style`). A field set nearer wins.
///
/// The modifiers are SwiftUI's, on a value: `TextEnvironment().font(.title).bold()`.
public struct TextEnvironment: Equatable, Sendable {
  public var font: TextFont?
  public var weight: TextFont.Weight?
  public var italic: Bool?
  public var design: TextFont.Design?
  public var monospaced: Bool?
  public var monospacedDigits: Bool?
  /// Drawn with, when nothing nearer sets a colour. A `TextStyleElement`'s reaches its texts at
  /// render time, not through layout; see `UIContext.collect`.
  public var foreground: float4?
  public var underline: TextDecorationStyle?
  public var strikethrough: TextDecorationStyle?
  public var kerning: Float?
  public var tracking: Float?
  public var baselineOffset: Float?
  /// `.some(nil)` is an explicit `lineLimit(nil)`: as many lines as fit.
  public var lineLimit: Int??
  public var alignment: TextAlignment?
  public var truncation: TextTruncationMode?
  public var lineSpacing: Float?
  public var minimumScaleFactor: Float?
  /// `.some(nil)` is an explicit `textCase(nil)`: as written.
  public var textCase: TextCase??

  public init() {}

  /// Every field `nearer` sets replaces this one's.
  public func overriding(_ nearer: TextEnvironment) -> TextEnvironment {
    var merged = self
    if let font = nearer.font { merged.font = font }
    if let weight = nearer.weight { merged.weight = weight }
    if let italic = nearer.italic { merged.italic = italic }
    if let design = nearer.design { merged.design = design }
    if let monospaced = nearer.monospaced { merged.monospaced = monospaced }
    if let monospacedDigits = nearer.monospacedDigits { merged.monospacedDigits = monospacedDigits }
    if let foreground = nearer.foreground { merged.foreground = foreground }
    if let underline = nearer.underline { merged.underline = underline }
    if let strikethrough = nearer.strikethrough { merged.strikethrough = strikethrough }
    if let kerning = nearer.kerning { merged.kerning = kerning }
    if let tracking = nearer.tracking { merged.tracking = tracking }
    if let baselineOffset = nearer.baselineOffset { merged.baselineOffset = baselineOffset }
    if let lineLimit = nearer.lineLimit { merged.lineLimit = lineLimit }
    if let alignment = nearer.alignment { merged.alignment = alignment }
    if let truncation = nearer.truncation { merged.truncation = truncation }
    if let lineSpacing = nearer.lineSpacing { merged.lineSpacing = lineSpacing }
    if let minimumScaleFactor = nearer.minimumScaleFactor { merged.minimumScaleFactor = minimumScaleFactor }
    if let textCase = nearer.textCase { merged.textCase = textCase }
    return merged
  }

  /// Fills the fields this one leaves unset from `farther`: the fields set here win.
  public func filling(_ farther: TextEnvironment) -> TextEnvironment {
    farther.overriding(self)
  }

  /// Only what can differ between the runs of one text: its font, colour, decorations and
  /// spacing. `Text + Text` keeps these per run and drops the rest.
  var runFields: TextEnvironment {
    var run = TextEnvironment()
    run.font = self.font
    run.weight = self.weight
    run.italic = self.italic
    run.design = self.design
    run.monospaced = self.monospaced
    run.monospacedDigits = self.monospacedDigits
    run.foreground = self.foreground
    run.underline = self.underline
    run.strikethrough = self.strikethrough
    run.kerning = self.kerning
    run.tracking = self.tracking
    run.baselineOffset = self.baselineOffset
    return run
  }

  var withoutForeground: TextEnvironment {
    var environment = self
    environment.foreground = nil
    return environment
  }

  // MARK: - Resolving

  /// What a text with no font set anywhere draws in.
  public static let defaultFont = TextFont.system(size: 16)

  var resolvedFont: TextFont {
    var font = self.font ?? Self.defaultFont
    if let weight = self.weight { font.weight = weight }
    if let italic = self.italic { font.isItalic = italic }
    if let design = self.design { font = font.design(design) }
    if self.monospaced == true { font = font.monospaced() }
    if self.monospacedDigits == true { font.isMonospacedDigit = true }
    return font
  }

  var resolvedRunStyle: TextRunStyle {
    TextRunStyle(
      font: self.resolvedFont, kerning: self.kerning ?? 0, tracking: self.tracking ?? 0,
      baselineOffset: self.baselineOffset ?? 0,
      underline: self.underline?.isActive ?? false, strikethrough: self.strikethrough?.isActive ?? false
    )
  }

  var resolvedParagraph: TextParagraph {
    TextParagraph(
      lineLimit: self.lineLimit ?? nil, alignment: self.alignment ?? .leading, truncation: self.truncation ?? .tail,
      lineSpacing: self.lineSpacing ?? 0, minimumScaleFactor: self.minimumScaleFactor ?? 1
    )
  }

  // MARK: - Modifiers

  public func font(_ font: TextFont?) -> TextEnvironment { self.with { $0.font = font } }
  public func fontWeight(_ weight: TextFont.Weight?) -> TextEnvironment { self.with { $0.weight = weight } }
  public func fontDesign(_ design: TextFont.Design?) -> TextEnvironment { self.with { $0.design = design } }
  public func bold(_ isActive: Bool = true) -> TextEnvironment { self.with { $0.weight = isActive ? .bold : .regular } }
  public func italic(_ isActive: Bool = true) -> TextEnvironment { self.with { $0.italic = isActive } }
  public func monospaced(_ isActive: Bool = true) -> TextEnvironment { self.with { $0.monospaced = isActive } }
  public func monospacedDigit() -> TextEnvironment { self.with { $0.monospacedDigits = true } }
  public func foregroundColor(_ color: float4?) -> TextEnvironment { self.with { $0.foreground = color } }
  public func foregroundStyle(_ color: float4?) -> TextEnvironment { self.foregroundColor(color) }

  public func underline(_ isActive: Bool = true, color: float4? = nil) -> TextEnvironment {
    self.with { $0.underline = TextDecorationStyle(isActive: isActive, color: color) }
  }

  public func strikethrough(_ isActive: Bool = true, color: float4? = nil) -> TextEnvironment {
    self.with { $0.strikethrough = TextDecorationStyle(isActive: isActive, color: color) }
  }

  public func kerning(_ kerning: Float) -> TextEnvironment { self.with { $0.kerning = kerning } }
  public func tracking(_ tracking: Float) -> TextEnvironment { self.with { $0.tracking = tracking } }
  public func baselineOffset(_ offset: Float) -> TextEnvironment { self.with { $0.baselineOffset = offset } }
  public func lineLimit(_ limit: Int?) -> TextEnvironment { self.with { $0.lineLimit = .some(limit) } }
  public func multilineTextAlignment(_ alignment: TextAlignment) -> TextEnvironment { self.with { $0.alignment = alignment } }
  public func truncationMode(_ mode: TextTruncationMode) -> TextEnvironment { self.with { $0.truncation = mode } }
  public func lineSpacing(_ spacing: Float) -> TextEnvironment { self.with { $0.lineSpacing = spacing } }
  public func minimumScaleFactor(_ factor: Float) -> TextEnvironment { self.with { $0.minimumScaleFactor = factor } }
  public func textCase(_ textCase: TextCase?) -> TextEnvironment { self.with { $0.textCase = .some(textCase) } }

  private func with(_ change: (inout TextEnvironment) -> Void) -> TextEnvironment {
    var environment = self
    change(&environment)
    return environment
  }
}

/// The text style that `TextStyleElement`s around the element being laid out set. Layout is a
/// walk down the tree, so each pushes its style around its child's layout calls and pops it
/// after, and a `Text` reads it while it is measured.
///
/// Anything that lays out a subtree outside its ancestors' calls — a scroll view placing rows as
/// it scrolls, a popover, a drag preview — must capture `current` where the subtree belongs and
/// lay it out under that. `depth` is back to 0 after every pass.
@MainActor
enum TextScope {
  static var current = TextEnvironment()
  static var depth = 0

  /// Runs `body` with `environment` as the current style.
  @inline(__always)
  static func with<R>(_ environment: TextEnvironment, _ body: () -> R) -> R {
    let outer = self.current
    self.current = environment
    self.depth += 1
    defer {
      self.current = outer
      self.depth -= 1
    }
    return body()
  }
}
