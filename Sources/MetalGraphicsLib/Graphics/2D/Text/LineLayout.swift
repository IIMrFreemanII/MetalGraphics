import CoreText
import Foundation
import simd

/// A stretch of one editor line in one style, in UTF-16 columns from the line's start.
struct LineRun: Equatable {
  var start: Int32
  var end: Int32
  var style: TextRunStyle
  var paint: TextRunPaint
  var background: float4? = nil
  var squiggle: float4? = nil
}

/// Space an attachment takes in a line: inline, one U+FFFC's worth, sitting on the baseline; or
/// a block below the line's text.
struct AttachmentReservation {
  var id: TextAttachmentID
  /// The column of its U+FFFC, for an inline one.
  var column: Int32
  var size: float2
  var isBlock: Bool
  var source: String?
}

/// Where an attachment was put in a shaped line, in line coordinates.
struct PlacedAttachment {
  var id: TextAttachmentID
  var origin: float2
  var size: float2
  var isBlock: Bool
  var source: String?
}

/// A rect of a shaped line to fill: a span's background. Line coordinates: x from the text's
/// leading edge, y from the top of the line.
struct LineRect: Equatable {
  var origin: float2
  var size: float2
  var color: float4
}

/// One line of an editor's document, shaped: broken into the fragments it takes on screen (one
/// unless it wraps), with what the caret, the pointer and the selection need of it. Everything
/// is relative to the line's top left corner.
final class LineLayout {
  /// The fragments as the lines of a text layout, drawn with `Graphics2D.draw(textLayout:)`.
  let text: TextLayout
  /// One per fragment, over the whole line's string, for caret offsets and hit tests.
  let ctLines: [CTLine]
  /// Where each fragment starts, in columns, then the line's length.
  let fragmentStarts: [Int32]
  /// Where each fragment's row starts, from the line's top, then the line's height. A row is its
  /// fragment's text and half the line spacing above and below it.
  let rowTops: [Float]
  /// The colours of each run of `text`.
  let paints: [TextRunPaint]
  let backgrounds: [LineRect]
  /// Wavy underlines: start x, end x, baseline y, colour.
  let squiggles: [(x0: Float, x1: Float, y: Float, color: float4)]
  /// The widest fragment.
  let width: Float
  /// What the line was shaped from, to tell whether a restyle changes it.
  let runs: [LineRun]
  /// Its attachments: inline ones where their U+FFFC is, blocks below the text.
  let attachments: [PlacedAttachment]
  /// The text's rows and the blocks below them.
  let height: Float
  var fragmentCount: Int { self.ctLines.count }
  var length: Int32 { self.fragmentStarts.last ?? 0 }

  init(text: TextLayout, ctLines: [CTLine], fragmentStarts: [Int32], rowTops: [Float], paints: [TextRunPaint],
       backgrounds: [LineRect], squiggles: [(x0: Float, x1: Float, y: Float, color: float4)], width: Float, runs: [LineRun],
       attachments: [PlacedAttachment] = [], height: Float? = nil) {
    self.attachments = attachments
    self.height = height ?? rowTops.last ?? 0
    self.text = text
    self.ctLines = ctLines
    self.fragmentStarts = fragmentStarts
    self.rowTops = rowTops
    self.paints = paints
    self.backgrounds = backgrounds
    self.squiggles = squiggles
    self.width = width
    self.runs = runs
  }

  /// The fragment a caret at `column` is drawn on: at a soft break, the upper one when
  /// `upstream`.
  func fragment(of column: Int32, affinity: TextAffinity) -> Int {
    let count = self.fragmentCount
    guard count > 1 else { return 0 }
    for i in 0 ..< count {
      let end = self.fragmentStarts[i + 1]
      if column < end || i == count - 1 { return i }
      if column == end && affinity == .upstream { return i }
    }
    return count - 1
  }

  /// Where a caret at `column` goes: its fragment and its x.
  func caretX(_ column: Int32, affinity: TextAffinity) -> (fragment: Int, x: Float) {
    let fragment = self.fragment(of: column, affinity: affinity)
    let x = Float(CTLineGetOffsetForStringIndex(self.ctLines[fragment], CFIndex(column), nil))
    return (fragment, x + self.text.lines[fragment].x)
  }

  /// The column nearest `x` on `fragment`, and the affinity that keeps a caret there on it.
  func column(atX x: Float, fragment: Int) -> (column: Int32, affinity: TextAffinity) {
    let fragment = fragment.clamped(to: 0 ... self.fragmentCount - 1)
    let start = self.fragmentStarts[fragment]
    let end = self.fragmentStarts[fragment + 1]
    let index = CTLineGetStringIndexForPosition(self.ctLines[fragment], CGPoint(x: Double(x - self.text.lines[fragment].x), y: 0))
    let column = index == kCFNotFound ? start : Int32(index).clamped(to: start ... end)
    // The end of a fragment that wraps is the start of the next: upstream keeps it on this one.
    return (column, fragment < self.fragmentCount - 1 && column == end ? .upstream : .downstream)
  }

  /// The fragment whose row holds `y`, from the line's top.
  func fragment(atY y: Float) -> Int {
    for i in 0 ..< self.fragmentCount where y < self.rowTops[i + 1] {
      return i
    }
    return self.fragmentCount - 1
  }

  /// The rects that show columns `range` selected, one per fragment it reaches, in line
  /// coordinates. `throughEnd` extends the last to `extent`: the selection goes on past the
  /// line's end, over its newline.
  func selectionRects(_ range: Range<Int32>, throughEnd: Bool, extent: Float, into rects: inout [LineRect], color: float4) {
    for i in 0 ..< self.fragmentCount {
      let start = self.fragmentStarts[i]
      let end = self.fragmentStarts[i + 1]
      let isLast = i == self.fragmentCount - 1
      if range.lowerBound > end || range.upperBound < start { continue }
      // A selection starting at a soft break starts on the next fragment.
      if !isLast && range.lowerBound == end { continue }
      let low = max(range.lowerBound, start)
      let high = min(range.upperBound, end)
      // Going on past this fragment: over a soft break, or over the line's newline.
      let continues = isLast ? throughEnd : range.upperBound > end
      if low >= high && !continues { continue }
      let lineX = self.text.lines[i].x
      let x0 = Float(CTLineGetOffsetForStringIndex(self.ctLines[i], CFIndex(low), nil)) + lineX
      var x1 = Float(CTLineGetOffsetForStringIndex(self.ctLines[i], CFIndex(high), nil)) + lineX
      if continues { x1 = max(x1 + 4, extent) }
      guard x1 > x0 else { continue }
      rects.append(LineRect(origin: float2(x0, self.rowTops[i]), size: float2(x1 - x0, self.rowTops[i + 1] - self.rowTops[i]), color: color))
    }
  }
}

/// Shapes one editor line: `units` without its newline, styled by `runs` (which cover it, in
/// order), broken at `wrapWidth` when there is one. No line is shorter than `base`.
func shapeLine(
  _ units: UnsafeBufferPointer<UInt16>, runs inputRuns: [LineRun], base: TextFont, wrapWidth: Float?, lineSpacing: Float,
  attachments: [AttachmentReservation] = []
) -> LineLayout {
  let length = units.count
  var runs = inputRuns
  if runs.isEmpty {
    runs = [LineRun(start: 0, end: Int32(length), style: TextRunStyle(font: base),
                    paint: TextRunPaint(text: .black, underline: .black, strikethrough: .black))]
  }
  let baseFace = FontManager.shared.face(for: base)
  let string = NSMutableAttributedString(
    string: length == 0 ? "" : String(utf16CodeUnits: units.baseAddress!, count: length)
  )
  var faces: [ResolvedFace] = []
  var inputs: [TextRunInput] = []
  faces.reserveCapacity(runs.count)
  inputs.reserveCapacity(runs.count)
  string.beginEditing()
  for (index, run) in runs.enumerated() {
    let face = FontManager.shared.face(for: run.style.font)
    faces.append(face)
    inputs.append(TextRunInput(string: "", style: run.style))
    let range = NSRange(location: Int(run.start), length: Int(run.end - run.start))
    guard range.length > 0, NSMaxRange(range) <= length else { continue }
    var attributes: [NSAttributedString.Key: Any] = [
      .init(kCTFontAttributeName as String): face.font,
      runAttribute: NSNumber(value: index),
    ]
    if run.style.kerning != 0 {
      attributes[.init(kCTKernAttributeName as String)] = NSNumber(value: run.style.kerning)
    }
    if run.style.tracking != 0 {
      attributes[.init(kCTTrackingAttributeName as String)] = NSNumber(value: run.style.tracking)
    }
    string.setAttributes(attributes, range: range)
  }
  // An inline attachment's U+FFFC takes the space it asks for.
  for attachment in attachments where !attachment.isBlock && Int(attachment.column) < length {
    let metrics = AttachmentMetrics(width: attachment.size.x, ascent: attachment.size.y, descent: 0)
    var callbacks = AttachmentMetrics.callbacks
    if let delegate = CTRunDelegateCreate(&callbacks, Unmanaged.passRetained(metrics).toOpaque()) {
      string.addAttribute(.init(kCTRunDelegateAttributeName as String), value: delegate,
                          range: NSRange(location: Int(attachment.column), length: 1))
    }
  }
  string.endEditing()

  let maxWidth = wrapWidth.map { max($0, 1) } ?? Float(1e7)
  let shaper = ParagraphShaper(
    runs: inputs, faces: faces, string: string, maxSize: float2(maxWidth, .greatestFiniteMagnitude), scale: 1,
    base: baseFace.font
  )
  let half = lineSpacing * 0.5
  var layout = TextLayout()
  var ctLines: [CTLine] = []
  var starts: [Int32] = []
  var rowTops: [Float] = [0]
  var width: Float = 0
  var top = half
  var start = 0
  while start < length {
    var count = CTTypesetterSuggestLineBreak(shaper.typesetter, start, Double(maxWidth))
    if count <= 0 {
      count = max(CTTypesetterSuggestClusterBreak(shaper.typesetter, start, Double(maxWidth)), 1)
    }
    let line = CTTypesetterCreateLine(shaper.typesetter, CFRange(location: start, length: count))
    let placed = shaper.place(line, top: top)
    layout.lines.append(placed.line)
    ctLines.append(line)
    starts.append(Int32(start))
    width = max(width, placed.line.width)
    rowTops.append(placed.bottom + half)
    top = placed.bottom + lineSpacing
    start += count
  }
  if ctLines.isEmpty {
    // An empty line still has a row, as tall as the base font, for the caret.
    let empty = CTLineCreateWithAttributedString(NSAttributedString(string: ""))
    layout.lines.append(TextLine(top: half, baseline: half + shaper.baseAscent))
    ctLines.append(empty)
    starts.append(0)
    rowTops.append(half + shaper.baseHeight + half)
  }
  starts.append(Int32(length))
  layout.size = float2(width, rowTops.last!)

  // Backgrounds and squiggles, per fragment each run reaches.
  var backgrounds: [LineRect] = []
  var squiggles: [(x0: Float, x1: Float, y: Float, color: float4)] = []
  for run in runs where (run.background != nil || run.squiggle != nil) && run.end > run.start {
    for i in 0 ..< ctLines.count {
      let low = max(run.start, starts[i])
      let high = min(run.end, starts[i + 1])
      guard low < high else { continue }
      let x0 = Float(CTLineGetOffsetForStringIndex(ctLines[i], CFIndex(low), nil))
      let x1 = Float(CTLineGetOffsetForStringIndex(ctLines[i], CFIndex(high), nil))
      guard x1 > x0 else { continue }
      if let color = run.background {
        backgrounds.append(LineRect(origin: float2(x0, rowTops[i]), size: float2(x1 - x0, rowTops[i + 1] - rowTops[i]), color: color))
      }
      if let color = run.squiggle {
        squiggles.append((x0, x1, layout.lines[i].baseline + 2, color))
      }
    }
  }
  // Inline attachments on their fragment's baseline; blocks stacked below the text.
  var placed: [PlacedAttachment] = []
  var height = rowTops.last!
  for attachment in attachments {
    if attachment.isBlock {
      placed.append(PlacedAttachment(id: attachment.id, origin: float2(0, height), size: attachment.size, isBlock: true,
                                     source: attachment.source))
      height += attachment.size.y + lineSpacing
    } else if Int(attachment.column) < length {
      var fragment = 0
      while fragment + 1 < ctLines.count && starts[fragment + 1] <= attachment.column { fragment += 1 }
      let x = Float(CTLineGetOffsetForStringIndex(ctLines[fragment], CFIndex(attachment.column), nil))
      let baseline = layout.lines[fragment].baseline
      placed.append(PlacedAttachment(id: attachment.id, origin: float2(x, baseline - attachment.size.y),
                                     size: attachment.size, isBlock: false, source: nil))
    }
  }
  return LineLayout(
    text: layout, ctLines: ctLines, fragmentStarts: starts, rowTops: rowTops, paints: runs.map(\.paint),
    backgrounds: backgrounds, squiggles: squiggles, width: width, runs: runs, attachments: placed, height: height
  )
}

/// What a `CTRunDelegate` reserves for an inline attachment.
private final class AttachmentMetrics {
  let width: Float
  let ascent: Float
  let descent: Float

  init(width: Float, ascent: Float, descent: Float) {
    self.width = width
    self.ascent = ascent
    self.descent = descent
  }

  static let callbacks = CTRunDelegateCallbacks(
    version: kCTRunDelegateVersion1,
    dealloc: { reference in Unmanaged<AttachmentMetrics>.fromOpaque(reference).release() },
    getAscent: { reference in CGFloat(Unmanaged<AttachmentMetrics>.fromOpaque(reference).takeUnretainedValue().ascent) },
    getDescent: { reference in CGFloat(Unmanaged<AttachmentMetrics>.fromOpaque(reference).takeUnretainedValue().descent) },
    getWidth: { reference in CGFloat(Unmanaged<AttachmentMetrics>.fromOpaque(reference).takeUnretainedValue().width) }
  )
}
