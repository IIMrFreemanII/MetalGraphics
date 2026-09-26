import CoreText
import Foundation

public struct TextStyle {
  public var color: float4
  public var fontSize: Float
  /// nil is the system font.
  public var font: SDFFont?

  public init(color: float4 = .black, fontSize: Float = 16, font: SDFFont? = nil) {
    self.color = color
    self.fontSize = fontSize
    self.font = font
  }

  var textFont: TextFont { TextFont(font: self.font, size: self.fontSize) }
}

/// How the lines of a text line up with one another, as SwiftUI's `multilineTextAlignment`.
public enum TextAlignment: Hashable, Sendable {
  case leading, center, trailing

  var factor: Float {
    switch self {
    case .leading: 0
    case .center: 0.5
    case .trailing: 1
    }
  }
}

/// Where a text that does not fit loses characters to an ellipsis.
public enum TextTruncationMode: Hashable, Sendable {
  case head, tail, middle
}

/// One glyph quad, laid out in the same memory as `Glyph` in Shaders.metal.
struct Glyph {
  /// Top left corner, y down.
  var position = float2()
  var size = float2()
  /// Region of the SDF atlas.
  var uvMin = float2()
  var uvMax = float2()
  var color = float4(0, 0, 0, 1)
  var depth = Float()
  /// Scales an em distance from the atlas to points.
  var fontSize = Float()
  /// A shadow's blur, as a standard deviation in points; 0 for a glyph drawn sharp.
  var blur = Float()

  var bounds: BoundingBox2D {
    // A blurred glyph reaches past its quad; `compute2D` extends its distance field there.
    BoundingBox2D(center: self.position + self.size * 0.5, size: self.size + 2 * self.blur * ShadowState.reach)
  }
}

struct PlacedGlyph {
  var metrics: GlyphMetrics
  /// Glyph origin relative to the start of its line's baseline, in points, y up.
  var origin: float2
  /// The point size of the font it was shaped in: what its em metrics scale by.
  var emSize: Float
  /// Index of the run it belongs to, for its colour.
  var run: UInt16
}

/// An underline or a strikethrough under part of one line.
struct TextDecorationSegment {
  /// Top left, relative to the line's leading edge and the top of the text, y down.
  var origin: float2
  var size: float2
  var run: UInt16
  var isStrikethrough: Bool
}

struct TextLine {
  /// Distance from the top of the text to the top of this line, in points.
  var top: Float
  /// Distance from the top of the text to this line's baseline, in points.
  var baseline: Float
  /// How far the line is indented to align it, from the text's leading edge.
  var x: Float = 0
  /// Without trailing whitespace.
  var width: Float = 0
  var glyphs: [PlacedGlyph] = []
  var decorations: [TextDecorationSegment] = []
}

/// Text shaped and broken into lines, ready to draw. Positions are relative to the top left
/// corner of the text, so a layout can be drawn anywhere without redoing it.
public struct TextLayout {
  public internal(set) var size = float2()
  /// Some of the text did not fit and was cut, at an ellipsis.
  public internal(set) var isTruncated = false
  /// What the fonts were shrunk by to fit, by `minimumScaleFactor`; 1 when they were not.
  public internal(set) var fontScale: Float = 1
  var lines: [TextLine] = []
}

/// A stretch of text in one style, shaped as part of a paragraph.
struct TextRunInput: Equatable {
  var string: String
  var style: TextRunStyle
}

/// What shapes a run. Colours are not part of it: they change what is drawn, never the layout.
struct TextRunStyle: Equatable {
  var font: TextFont
  var kerning: Float = 0
  var tracking: Float = 0
  var baselineOffset: Float = 0
  var underline = false
  var strikethrough = false
}

/// How a paragraph breaks into lines and lines up.
struct TextParagraph: Equatable {
  /// nil for as many as fit.
  var lineLimit: Int? = nil
  var alignment: TextAlignment = .leading
  var truncation: TextTruncationMode = .tail
  var lineSpacing: Float = 0
  var minimumScaleFactor: Float = 1
}

/// Shapes `text` with CoreText (kerning, ligatures, combining marks, font fallback) and wraps it
/// at words to fit `maxSize.x`. Lines that would not fit in `maxSize.y` are dropped — all but the
/// first when `keepsFirstLine` is set.
@MainActor public func layoutText(
  _ text: String, style: TextStyle = TextStyle(), maxSize: float2? = nil, keepsFirstLine: Bool = false
) -> TextLayout {
  layoutText(
    runs: [TextRunInput(string: text, style: TextRunStyle(font: style.textFont))], paragraph: TextParagraph(),
    maxSize: maxSize, keepsFirstLine: keepsFirstLine
  )
}

/// Shapes `runs` as one paragraph and breaks it into lines that fit `maxSize`.
///
/// Lines stop at `paragraph.lineLimit`, or at the last that fits the height; if text is left, the
/// last line kept ends in an ellipsis (or starts with, or has one in the middle, by
/// `paragraph.truncation`). Then, if `minimumScaleFactor` allows it, the fonts shrink until it
/// all fits, or as far as allowed.
@MainActor func layoutText(
  runs: [TextRunInput], paragraph: TextParagraph, maxSize: float2?, keepsFirstLine: Bool
) -> TextLayout {
  let maxSize = maxSize ?? float2(repeating: .greatestFiniteMagnitude)
  let layout = shapeParagraph(runs, paragraph, maxSize, keepsFirstLine, scale: 1)
  let minimum = min(max(paragraph.minimumScaleFactor, 0.01), 1)
  guard layout.isTruncated, minimum < 1 else { return layout }

  // At most seven more shapings, and only for text that does not fit: the smallest allowed
  // first, then a bisection between it and full size.
  var fitting = shapeParagraph(runs, paragraph, maxSize, keepsFirstLine, scale: minimum)
  guard !fitting.isTruncated else { return fitting }
  var low = minimum
  var high: Float = 1
  for _ in 0..<6 {
    let scale = (low + high) * 0.5
    let attempt = shapeParagraph(runs, paragraph, maxSize, keepsFirstLine, scale: scale)
    if attempt.isTruncated {
      high = scale
    } else {
      low = scale
      fitting = attempt
    }
  }
  return fitting
}

@MainActor public func measureText(_ text: String, style: TextStyle = TextStyle(), maxSize: float2? = nil) -> float2 {
  layoutText(text, style: style, maxSize: maxSize).size
}

/// Where a caret goes in `text` set on one line: before each character, then after the last —
/// `text.count + 1` offsets from the leading edge, in points. One CoreText line, so it costs one
/// shaping however many offsets are read. Unlike `measureText`, trailing spaces count.
@MainActor public func caretOffsets(_ text: String, font: TextFont) -> [Float] {
  var offsets: [Float] = [0]
  guard !text.isEmpty, font.size > 0, font.size.isFinite else { return offsets }
  offsets.reserveCapacity(text.count + 1)
  let ctFont = FontManager.shared.face(for: font).font
  let string = NSAttributedString(string: text, attributes: [.init(kCTFontAttributeName as String): ctFont])
  let line = CTLineCreateWithAttributedString(string)
  var utf16 = 0
  for character in text {
    utf16 += character.utf16.count
    offsets.append(Float(CTLineGetOffsetForStringIndex(line, utf16, nil)))
  }
  return offsets
}

@MainActor public func caretOffsets(_ text: String, style: TextStyle = TextStyle()) -> [Float] {
  caretOffsets(text, font: style.textFont)
}

// MARK: - Shaping

/// Which run a stretch of the attributed string came from, as an `NSNumber`.
private let runAttribute = NSAttributedString.Key("MetalGraphics.run")

/// Font sizes land on quarter points when shrunk, so a bisection reuses faces between texts.
private func scaledSize(_ size: Float, _ scale: Float) -> Float {
  scale == 1 ? size : (size * scale * 4).rounded(.down) / 4
}

@MainActor private func shapeParagraph(
  _ runs: [TextRunInput], _ paragraph: TextParagraph, _ maxSize: float2, _ keepsFirstLine: Bool, scale: Float
) -> TextLayout {
  var layout = TextLayout(fontScale: scale)
  guard let first = runs.first, first.style.font.size > 0, first.style.font.size.isFinite else {
    return layout
  }

  var faces: [ResolvedFace] = []
  faces.reserveCapacity(runs.count)
  let string = NSMutableAttributedString()
  for (index, run) in runs.enumerated() {
    let face = FontManager.shared.face(for: run.style.font.withSize(scaledSize(run.style.font.size, scale)))
    faces.append(face)
    guard !run.string.isEmpty else { continue }
    var attributes: [NSAttributedString.Key: Any] = [
      .init(kCTFontAttributeName as String): face.font,
      runAttribute: NSNumber(value: index),
    ]
    if run.style.kerning != 0 {
      attributes[.init(kCTKernAttributeName as String)] = NSNumber(value: run.style.kerning * scale)
    }
    if run.style.tracking != 0 {
      attributes[.init(kCTTrackingAttributeName as String)] = NSNumber(value: run.style.tracking * scale)
    }
    string.append(NSAttributedString(string: run.string, attributes: attributes))
  }

  var shaper = ParagraphShaper(runs: runs, faces: faces, string: string, maxSize: maxSize, scale: scale)
  let lineSpacing = paragraph.lineSpacing
  let lineLimit = paragraph.lineLimit.map { max($0, 1) }
  // a line whose bottom lands a hair past the limit through float error still fits
  let fits = { (bottom: Float) in bottom <= maxSize.y + 1e-3 }

  let length = string.length
  var start = 0
  var lastStart = 0
  var bottom: Float = 0
  while start < length {
    var count = CTTypesetterSuggestLineBreak(shaper.typesetter, start, shaper.maxWidth)
    if count <= 0 {
      // not even one cluster fits, so it overflows on a line of its own
      count = max(CTTypesetterSuggestClusterBreak(shaper.typesetter, start, shaper.maxWidth), 1)
    }
    let top = layout.lines.isEmpty ? 0 : bottom + lineSpacing
    var placed = shaper.place(CTTypesetterCreateLine(shaper.typesetter, CFRange(location: start, length: count)), top: top)
    if !fits(placed.bottom), !(keepsFirstLine && layout.lines.isEmpty) {
      // The text from `start` on is dropped: the line before takes the ellipsis.
      if let last = layout.lines.indices.last {
        let truncated = shaper.place(shaper.truncatedLine(from: lastStart, paragraph.truncation), top: layout.lines[last].top)
        layout.lines[last] = truncated.line
        bottom = truncated.bottom
        layout.isTruncated = true
      }
      break
    }
    if let lineLimit, layout.lines.count + 1 >= lineLimit, start + count < length {
      placed = shaper.place(shaper.truncatedLine(from: start, paragraph.truncation), top: top)
      layout.lines.append(placed.line)
      bottom = placed.bottom
      layout.isTruncated = true
      break
    }
    layout.lines.append(placed.line)
    bottom = placed.bottom
    lastStart = start
    start += count
  }

  // An empty text, or one ending in a newline, still has a line to put the caret on.
  let text = string.string
  if !layout.isTruncated, text.isEmpty || text.last!.isNewline, lineLimit.map({ layout.lines.count < $0 }) ?? true {
    let top = layout.lines.isEmpty ? 0 : bottom + lineSpacing
    if fits(top + shaper.baseHeight) || (keepsFirstLine && layout.lines.isEmpty) {
      bottom = top + shaper.baseHeight
    }
  }

  for line in layout.lines {
    layout.size.x = max(layout.size.x, min(line.width, maxSize.x))
  }
  layout.size.y = bottom
  let factor = paragraph.alignment.factor
  if factor > 0 {
    for index in layout.lines.indices {
      layout.lines[index].x = max(layout.size.x - layout.lines[index].width, 0) * factor
    }
  }
  return layout
}

/// The state of shaping one paragraph: its string, typesetter and faces.
@MainActor private struct ParagraphShaper {
  let runs: [TextRunInput]
  let faces: [ResolvedFace]
  let string: NSAttributedString
  let typesetter: CTTypesetter
  let maxWidth: Double
  let scale: Float
  /// The first run's font: the least a line is tall, and the height of an empty one.
  let baseAscent: Float
  let baseDescent: Float
  let baseLeading: Float

  var baseHeight: Float { self.baseAscent + self.baseDescent + self.baseLeading }

  init(runs: [TextRunInput], faces: [ResolvedFace], string: NSAttributedString, maxSize: float2, scale: Float) {
    self.runs = runs
    self.faces = faces
    self.string = string
    self.typesetter = CTTypesetterCreateWithAttributedString(string)
    self.maxWidth = Double(min(maxSize.x, 1e7))
    self.scale = scale
    let base = faces[0].font
    self.baseAscent = Float(CTFontGetAscent(base))
    self.baseDescent = Float(CTFontGetDescent(base))
    self.baseLeading = Float(CTFontGetLeading(base))
  }

  /// The text from `start` to the end of its paragraph, cut to fit one line, with an ellipsis
  /// where it was cut — or at its end, if more paragraphs follow.
  func truncatedLine(from start: Int, _ mode: TextTruncationMode) -> CTLine {
    let text = self.string.string as NSString
    let paragraph = text.paragraphRange(for: NSRange(location: start, length: 0))
    var end = NSMaxRange(paragraph)
    let more = end < text.length
    while end > start, let scalar = Unicode.Scalar(text.character(at: end - 1)),
          CharacterSet.newlines.contains(scalar) {
      end -= 1
    }
    let attributes = self.string.attributes(at: max(min(end, text.length) - 1, 0), effectiveRange: nil)
    let token = NSAttributedString(string: "\u{2026}", attributes: attributes)

    let cut = NSMutableAttributedString(attributedString: self.string.attributedSubstring(from: NSRange(location: start, length: end - start)))
    if more, mode == .tail {
      cut.append(token)
    }
    let line = CTLineCreateWithAttributedString(cut)
    let type: CTLineTruncationType = switch mode {
    case .head: .start
    case .middle: .middle
    case .tail: .end
    }
    return CTLineCreateTruncatedLine(line, self.maxWidth, type, CTLineCreateWithAttributedString(token)) ?? line
  }

  private func runIndex(_ run: CTRun) -> Int {
    let attributes = CTRunGetAttributes(run) as NSDictionary
    return (attributes[runAttribute] as? NSNumber)?.intValue ?? (self.runs.count - 1)
  }

  /// Lays `line` out with its top at `top`: its glyphs, decorations and width.
  func place(_ line: CTLine, top: Float) -> (line: TextLine, bottom: Float) {
    let glyphRuns = CTLineGetGlyphRuns(line) as! [CTRun]

    // Tall as its tallest run, raised or lowered by its baseline offset, and never less than
    // the first font, so a line of one font measures as that font.
    var ascent = self.baseAscent
    var descent = self.baseDescent
    var leading = self.baseLeading
    for run in glyphRuns {
      let offset = self.runs[self.runIndex(run)].style.baselineOffset * self.scale
      var runAscent: CGFloat = 0
      var runDescent: CGFloat = 0
      var runLeading: CGFloat = 0
      CTRunGetTypographicBounds(run, CFRange(), &runAscent, &runDescent, &runLeading)
      ascent = max(ascent, Float(runAscent) + offset)
      descent = max(descent, Float(runDescent) - offset)
      leading = max(leading, Float(runLeading))
    }

    let width = Float(CTLineGetTypographicBounds(line, nil, nil, nil) - CTLineGetTrailingWhitespaceWidth(line))
    var textLine = TextLine(top: top, baseline: top + ascent, width: width)
    for run in glyphRuns {
      let index = self.runIndex(run)
      let style = self.runs[index].style
      let oblique = self.faces[index].oblique
      let offset = style.baselineOffset * self.scale
      let attributes = CTRunGetAttributes(run) as NSDictionary
      // a fallback font when the run's font has no glyph for its characters
      let runFont = attributes[kCTFontAttributeName as String] as! CTFont
      let face = FontManager.shared.faceKey(for: runFont, oblique: oblique)
      let emSize = Float(CTFontGetSize(runFont))
      let glyphCount = CTRunGetGlyphCount(run)
      var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
      var positions = [CGPoint](repeating: .zero, count: glyphCount)
      CTRunGetGlyphs(run, CFRange(), &glyphs)
      CTRunGetPositions(run, CFRange(), &positions)

      for i in 0..<glyphCount {
        let metrics = FontManager.shared.glyphMetrics(face: face, font: runFont, glyph: glyphs[i], oblique: oblique)
        if metrics.hasOutline {
          textLine.glyphs.append(PlacedGlyph(
            metrics: metrics, origin: float2(Float(positions[i].x), Float(positions[i].y) + offset),
            emSize: emSize, run: UInt16(truncatingIfNeeded: index)
          ))
        }
      }

      if (style.underline || style.strikethrough), glyphCount > 0 {
        let start = Float(positions[0].x)
        let end = min(start + Float(CTRunGetTypographicBounds(run, CFRange(), nil, nil, nil)), width)
        guard end > start else { continue }
        // Measured in the run's own font, not a fallback, so a decoration runs straight across.
        let font = self.faces[index].font
        let thickness = max(Float(CTFontGetUnderlineThickness(font)), 0.5)
        if style.underline {
          let centre = textLine.baseline - (Float(CTFontGetUnderlinePosition(font)) + offset)
          Self.addDecoration(&textLine, start, end, centre, thickness, index, strike: false)
        }
        if style.strikethrough {
          let centre = textLine.baseline - (Float(CTFontGetXHeight(font)) * 0.5 + offset)
          Self.addDecoration(&textLine, start, end, centre, thickness, index, strike: true)
        }
      }
    }
    return (textLine, top + ascent + descent + leading)
  }

  /// Adds a segment, or extends the one before when it continues it: a run split by a fallback
  /// font is still one line.
  private static func addDecoration(
    _ line: inout TextLine, _ start: Float, _ end: Float, _ centre: Float, _ thickness: Float, _ run: Int, strike: Bool
  ) {
    let run = UInt16(truncatingIfNeeded: run)
    if let last = line.decorations.indices.last(where: { line.decorations[$0].isStrikethrough == strike }),
       line.decorations[last].run == run,
       abs(line.decorations[last].origin.x + line.decorations[last].size.x - start) < 0.5 {
      line.decorations[last].size.x = end - line.decorations[last].origin.x
      return
    }
    line.decorations.append(TextDecorationSegment(
      origin: float2(start, centre - thickness * 0.5), size: float2(end - start, thickness),
      run: run, isStrikethrough: strike
    ))
  }
}
