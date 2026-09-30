import AppKit
import CoreText

/// A font, as SwiftUI's `Font`: a face, a size, and the weight, slant and digit style to draw it
/// in. Not named `Font`, which would clash with SwiftUI's in a file that imports both.
///
/// `.system` and the text styles draw in the design system's type: JetBrains Mono, bundled with
/// the library, for the default and monospaced designs, in four weights (regular, medium,
/// semibold, bold); rounded and serif are San Francisco's. `TextFont.systemFamily = .sanFrancisco`
/// makes `.system` SwiftUI's again. `.custom` is any installed family, with the nearest weight
/// the family has. A face with no italic is slanted when `italic()` asks for one.
public struct TextFont: Hashable, Sendable {
  /// What `.system` draws in.
  public enum SystemFamily: Hashable, Sendable {
    /// JetBrains Mono, with its ligatures: the design system's type, as the design canvas and
    /// the web mirror draw it.
    case jetBrainsMono
    /// San Francisco, as SwiftUI's `.system`.
    case sanFrancisco
  }

  /// What `.system` and the text styles draw in, for every window. Set it before the first
  /// window opens: text laid out already keeps its face until it is laid out again.
  nonisolated(unsafe) public static var systemFamily: SystemFamily = .jetBrainsMono {
    didSet {
      if systemFamily != oldValue { FontManager.shared.removeResolvedFaces() }
    }
  }

  public enum Weight: Hashable, Sendable, CaseIterable {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black

    var systemWeight: NSFont.Weight {
      switch self {
      case .ultraLight: .ultraLight
      case .thin: .thin
      case .light: .light
      case .regular: .regular
      case .medium: .medium
      case .semibold: .semibold
      case .bold: .bold
      case .heavy: .heavy
      case .black: .black
      }
    }

    /// `NSFontManager`'s 0–15 scale, which picks the nearest face a family has.
    var familyWeight: Int {
      switch self {
      case .ultraLight: 2
      case .thin: 3
      case .light: 4
      case .regular: 5
      case .medium: 6
      case .semibold: 8
      case .bold: 9
      case .heavy: 10
      case .black: 11
      }
    }
  }

  public enum Design: Hashable, Sendable {
    case `default`, serif, rounded, monospaced
  }

  /// SwiftUI's text styles, at the sizes and weights macOS gives them.
  public enum TextStyle: Hashable, Sendable, CaseIterable {
    case largeTitle, title, title2, title3, headline, subheadline, body, callout, footnote, caption, caption2

    var size: Float {
      switch self {
      case .largeTitle: 26
      case .title: 22
      case .title2: 17
      case .title3: 15
      case .headline, .body: 13
      case .callout: 12
      case .subheadline: 11
      case .footnote, .caption, .caption2: 10
      }
    }

    var weight: Weight {
      switch self {
      case .headline: .bold
      case .caption2: .medium
      default: .regular
      }
    }
  }

  enum Face: Hashable, Sendable {
    case system(Design)
    case custom(SDFFont)
  }

  var face: Face
  public var size: Float
  /// nil is the face's own: regular, or the text style's.
  public var weight: Weight?
  public var isItalic: Bool = false
  public var isMonospacedDigit: Bool = false

  init(face: Face, size: Float, weight: Weight? = nil) {
    self.face = face
    self.size = size
    self.weight = weight
  }

  /// A face and a size: `.custom(face, size:)`, or the system font when `font` is nil.
  public init(font: SDFFont?, size: Float) {
    self.init(face: font.map { .custom($0) } ?? .system(.default), size: size)
  }

  /// The custom face, or nil for the system font.
  public var font: SDFFont? {
    if case .custom(let font) = self.face { return font }
    return nil
  }

  public var design: Design {
    if case .system(let design) = self.face { return design }
    return .default
  }

  // MARK: - Fonts

  public static func system(size: Float, weight: Weight? = nil, design: Design = .default) -> TextFont {
    TextFont(face: .system(design), size: size, weight: weight)
  }

  public static func system(_ style: TextStyle, design: Design = .default, weight: Weight? = nil) -> TextFont {
    TextFont(face: .system(design), size: style.size, weight: weight ?? style.weight)
  }

  public static func custom(_ font: SDFFont, size: Float) -> TextFont {
    TextFont(face: .custom(font), size: size)
  }

  /// The installed family or face named `name`, e.g. "Georgia" or "Avenir Next".
  public static func custom(_ name: String, size: Float) -> TextFont {
    TextFont(face: .custom(FontManager.shared.font(named: name)), size: size)
  }

  public static let largeTitle = system(.largeTitle)
  public static let title = system(.title)
  public static let title2 = system(.title2)
  public static let title3 = system(.title3)
  public static let headline = system(.headline)
  public static let subheadline = system(.subheadline)
  public static let body = system(.body)
  public static let callout = system(.callout)
  public static let footnote = system(.footnote)
  public static let caption = system(.caption)
  public static let caption2 = system(.caption2)

  // MARK: - Modifiers

  public func weight(_ weight: Weight) -> TextFont {
    var font = self
    font.weight = weight
    return font
  }

  public func bold() -> TextFont {
    self.weight(.bold)
  }

  public func italic() -> TextFont {
    var font = self
    font.isItalic = true
    return font
  }

  /// San Francisco's monospaced design; a custom face is left as is.
  public func monospaced() -> TextFont {
    guard case .system = self.face else { return self }
    var font = self
    font.face = .system(.monospaced)
    return font
  }

  /// Digits all as wide, so numbers that change do not jiggle.
  public func monospacedDigit() -> TextFont {
    var font = self
    font.isMonospacedDigit = true
    return font
  }

  public func design(_ design: Design) -> TextFont {
    guard case .system = self.face else { return self }
    var font = self
    font.face = .system(design)
    return font
  }

  func withSize(_ size: Float) -> TextFont {
    var font = self
    font.size = size
    return font
  }
}

/// A `TextFont` made concrete: the CoreText font to shape with.
struct ResolvedFace {
  let font: CTFont
  /// Asked for italic, but the face has none: slanted when its glyphs are baked.
  let oblique: Bool
  /// The line box its lines take, when it is not the font's own. See `metrics`.
  var lineMetrics: LineMetrics? = nil

  /// How tall its lines are. JetBrains Mono as `.system` keeps San Francisco's line box, its
  /// glyphs centred in it, as the web mirror's `line-height` has it: every row, button and
  /// field keeps the height the design gives it.
  var metrics: LineMetrics {
    self.lineMetrics ?? LineMetrics(self.font)
  }
}

/// A line box: above the baseline, below it, and the gap after.
struct LineMetrics {
  var ascent: Float
  var descent: Float
  var leading: Float

  init(ascent: Float, descent: Float, leading: Float) {
    self.ascent = ascent
    self.descent = descent
    self.leading = leading
  }

  /// `font`'s own.
  init(_ font: CTFont) {
    self.init(ascent: Float(CTFontGetAscent(font)), descent: Float(CTFontGetDescent(font)), leading: Float(CTFontGetLeading(font)))
  }

  var height: Float { self.ascent + self.descent + self.leading }

  /// `font`'s glyphs centred in a box as tall as `box`, as CSS's `line-height` places them.
  init(_ font: CTFont, in box: LineMetrics) {
    let own = LineMetrics(font)
    let half = (box.height - own.ascent - own.descent) * 0.5
    self.init(ascent: own.ascent + half, descent: own.descent + half, leading: 0)
  }
}
