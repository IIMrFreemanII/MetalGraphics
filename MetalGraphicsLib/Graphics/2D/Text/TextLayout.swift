import CoreText
import Foundation

public struct TextStyle {
  public var color: float4
  public var fontSize: Float
  /// nil uses `FontManager.shared.defaultFont`.
  public var font: SDFFont?

  public init(color: float4 = .black, fontSize: Float = 16, font: SDFFont? = nil) {
    self.color = color
    self.fontSize = fontSize
    self.font = font
  }
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
}

struct TextLine {
  /// Distance from the top of the text to this line's baseline, in points.
  var baseline: Float
  var glyphs: [PlacedGlyph] = []
}

/// Text shaped and broken into lines, ready to draw. Positions are relative to the top left
/// corner of the text, so a layout can be drawn anywhere without redoing it.
public struct TextLayout {
  public internal(set) var size = float2()
  var fontSize: Float = 0
  var lines: [TextLine] = []
}

/// Shapes `text` with CoreText (kerning, ligatures, combining marks, font fallback) and wraps it
/// at words to fit `maxSize.x`. Lines that would not fit in `maxSize.y` are dropped — all but the
/// first when `keepsFirstLine` is set.
@MainActor public func layoutText(
  _ text: String, style: TextStyle = TextStyle(), maxSize: float2? = nil, keepsFirstLine: Bool = false
) -> TextLayout {
  let maxSize = maxSize ?? float2(repeating: .greatestFiniteMagnitude)
  var layout = TextLayout(fontSize: style.fontSize)
  guard style.fontSize > 0, style.fontSize.isFinite else {
    return layout
  }

  let font = (style.font ?? FontManager.shared.defaultFont).ctFont(size: style.fontSize)
  let ascent = Float(CTFontGetAscent(font))
  let lineHeight = ascent + Float(CTFontGetDescent(font)) + Float(CTFontGetLeading(font))
  // a line whose bottom lands a hair past the limit through float error still fits
  let fitsHeight = { (height: Float) in height <= maxSize.y + 1e-3 || (keepsFirstLine && height == lineHeight) }

  let string = NSAttributedString(string: text, attributes: [.init(kCTFontAttributeName as String): font])
  let typesetter = CTTypesetterCreateWithAttributedString(string)
  let length = string.length
  let maxWidth = Double(min(maxSize.x, 1e7))

  var start = 0
  while start < length, fitsHeight(layout.size.y + lineHeight) {
    var count = CTTypesetterSuggestLineBreak(typesetter, start, maxWidth)
    if count <= 0 {
      // not even one cluster fits, so it overflows on a line of its own
      count = max(CTTypesetterSuggestClusterBreak(typesetter, start, maxWidth), 1)
    }
    let line = CTTypesetterCreateLine(typesetter, CFRange(location: start, length: count))
    start += count

    var textLine = TextLine(baseline: layout.size.y + ascent)
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
      let attributes = CTRunGetAttributes(run) as NSDictionary
      // a fallback font when `font` has no glyph for the run's characters
      let runFont = attributes[kCTFontAttributeName as String] as! CTFont
      let glyphCount = CTRunGetGlyphCount(run)
      var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
      var positions = [CGPoint](repeating: .zero, count: glyphCount)
      CTRunGetGlyphs(run, CFRange(), &glyphs)
      CTRunGetPositions(run, CFRange(), &positions)

      for i in 0..<glyphCount {
        let metrics = FontManager.shared.glyphMetrics(font: runFont, glyph: glyphs[i])
        if metrics.hasOutline {
          textLine.glyphs.append(PlacedGlyph(metrics: metrics, origin: float2(Float(positions[i].x), Float(positions[i].y))))
        }
      }
    }
    layout.lines.append(textLine)

    let width = CTLineGetTypographicBounds(line, nil, nil, nil) - CTLineGetTrailingWhitespaceWidth(line)
    layout.size.x = max(layout.size.x, min(Float(width), maxSize.x))
    layout.size.y += lineHeight
  }

  // An empty text, or one ending in a newline, still has a line to put the caret on.
  if (text.isEmpty || text.last!.isNewline), fitsHeight(layout.size.y + lineHeight) {
    layout.size.y += lineHeight
  }

  return layout
}

@MainActor public func measureText(_ text: String, style: TextStyle = TextStyle(), maxSize: float2? = nil) -> float2 {
  layoutText(text, style: style, maxSize: maxSize).size
}

/// Where a caret goes in `text` set on one line: before each character, then after the last —
/// `text.count + 1` offsets from the leading edge, in points. One CoreText line, so it costs one
/// shaping however many offsets are read. Unlike `measureText`, trailing spaces count.
@MainActor public func caretOffsets(_ text: String, style: TextStyle = TextStyle()) -> [Float] {
  var offsets: [Float] = [0]
  guard !text.isEmpty, style.fontSize > 0, style.fontSize.isFinite else { return offsets }
  offsets.reserveCapacity(text.count + 1)
  let font = (style.font ?? FontManager.shared.defaultFont).ctFont(size: style.fontSize)
  let string = NSAttributedString(string: text, attributes: [.init(kCTFontAttributeName as String): font])
  let line = CTLineCreateWithAttributedString(string)
  var utf16 = 0
  for character in text {
    utf16 += character.utf16.count
    offsets.append(Float(CTLineGetOffsetForStringIndex(line, utf16, nil)))
  }
  return offsets
}
