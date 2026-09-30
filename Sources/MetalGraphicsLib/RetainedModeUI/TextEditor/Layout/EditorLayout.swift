import CoreText
import simd

/// Where a line's tokens come from besides the ones stored with its text: a styler.
protocol LineSpanSource: AnyObject {
  /// Called before `spans`, outside any read of the text: brings what `line`'s tokens depend on
  /// up to date.
  func prepare(forLine line: Int)
  /// The tokens over `line`, whose text is `units`, sorted and not overlapping, into `spans`.
  /// Must not read the document: `units` is the line.
  func spans(forLine line: Int, units: UnsafeBufferPointer<UInt16>, into spans: inout [TextSpan])
  /// What is shown below `line`, whose text is `units`: a styler's blocks.
  func blocks(forLine line: Int, units: UnsafeBufferPointer<UInt16>, into blocks: inout [BlockDecoration])
  /// Extra runs to draw over a line — search matches, diagnostics — as backgrounds or
  /// squiggles. Called when the line is shaped.
  func decorations(forLine line: Int, lineStart: Int, length: Int, into runs: inout [LineDecoration])
}

/// A background or a wavy underline over part of a line, from a decoration source.
struct LineDecoration {
  var start: Int32
  var end: Int32
  var background: float4?
  var squiggle: float4?
}

/// Lays out an editor's document line by line, on demand: a line is shaped when it is first
/// shown or asked about, and kept, keyed by the line's id, until it changes or falls out of the
/// cache. Lines never shaped have estimated heights in the document's `LineTree`, replaced by
/// their measured ones as they are shaped.
///
/// Coordinates are the document's: x from the text's leading edge, y from the top of the first
/// line.
final class EditorLayout: TextLayoutQueries {
  private(set) var document: TextDocument
  private(set) var theme: EditorTheme
  private(set) var baseFont: TextFont
  /// The width lines wrap at; nil when they do not.
  private(set) var wrapWidth: Float?
  weak var spanSource: (any LineSpanSource)?
  /// Sizes the attachments lines reserve space for.
  weak var attachmentProvider: (any TextAttachmentProvider)?

  /// The height of the view, for page moves.
  var viewportHeight: Float = 400

  /// A row of the base font: ascent, descent and leading, and the line spacing.
  private(set) var rowHeight: Float = 16
  /// Below each line: the theme's `lineSpacing`, or what makes a line its `lineHeight`.
  private(set) var lineSpacing: Float = 3
  /// The width of a digit in the base font: an estimate of an average character.
  private(set) var averageAdvance: Float = 8

  private struct Entry {
    var layout: LineLayout
    var lastUse: UInt32
  }

  private var cache: [UInt32: Entry] = [:]
  private var use: UInt32 = 0
  static let cacheLimit = 2000
  /// Lines shaped, for tests and the profiler.
  private(set) var shapedCount = 0

  /// The widest shaped line, and the longest line in units: what a view that does not wrap
  /// scrolls across.
  private var widestMeasured: Float = 0
  private var longestLine = 0

  // Scratch, kept to allocate nothing per line once grown.
  private var spans: [TextSpan] = []
  private var decorationScratch: [LineDecoration] = []
  private var blockScratch: [BlockDecoration] = []
  private var reservations: [AttachmentReservation] = []

  init(document: TextDocument, theme: EditorTheme, font: TextFont) {
    self.document = document
    self.theme = theme
    self.baseFont = font
    self.measureBaseFont()
    self.resetHeights()
  }

  // MARK: - Configuration

  func setDocument(_ document: TextDocument) {
    self.document = document
    self.cache.removeAll()
    self.widestMeasured = 0
    self.resetHeights()
  }

  /// Returns whether anything changed; everything is then reshaped as it is shown.
  @discardableResult
  func configure(theme: EditorTheme, font: TextFont, wrapWidth: Float?) -> Bool {
    let wrapWidth = wrapWidth.map { max($0, 20) }
    guard theme != self.theme || font != self.baseFont || wrapWidth != self.wrapWidth else { return false }
    let fontChanged = font != self.baseFont || theme.lineSpacing != self.theme.lineSpacing
      || theme.lineHeight != self.theme.lineHeight
    self.theme = theme
    self.baseFont = font
    self.wrapWidth = wrapWidth
    if fontChanged { self.measureBaseFont() }
    self.cache.removeAll()
    self.widestMeasured = 0
    self.resetHeights()
    return true
  }

  /// Forgets the shaped line with `id`: its style changed.
  func invalidate(lineID id: UInt32) {
    self.cache.removeValue(forKey: id)
  }

  func invalidateAll() {
    self.cache.removeAll()
  }

  private func measureBaseFont() {
    let face = FontManager.shared.face(for: self.baseFont)
    let font = face.font
    // The face's line box, which its lines are laid out in (`ResolvedFace.metrics`).
    let natural = face.metrics.height
    self.lineSpacing = self.theme.lineHeight.map { max($0 - natural, 0) } ?? self.theme.lineSpacing
    self.rowHeight = natural + self.lineSpacing
    var glyph = CGGlyph(0)
    var zero = UniChar(0x30)
    CTFontGetGlyphsForCharacters(font, &zero, &glyph, 1)
    var advance = CGSize.zero
    CTFontGetAdvancesForGlyphs(font, .horizontal, &glyph, &advance, 1)
    self.averageAdvance = max(Float(advance.width), 1)
    self.document.estimatedLineHeight = self.rowHeight
  }

  /// The height a line `length` units long is guessed to take before it is shaped.
  func estimatedHeight(length: Int) -> Float {
    guard let wrapWidth, length > 0 else { return self.rowHeight }
    let rows = max(1, (Float(length) * self.averageAdvance / wrapWidth).rounded(.up))
    return rows * self.rowHeight
  }

  /// Puts every line back to its estimated height. O(lines).
  private func resetHeights() {
    let lines = self.document.lines
    var longest = 0
    lines.forEach(in: 0 ..< lines.lineCount) { _, record, height, length in
      height = record.flags.contains(.hidden) ? 0 : self.estimatedHeight(length: Int(length))
      record.flags.remove(.measured)
      longest = max(longest, Int(length))
    }
    self.longestLine = longest
  }

  // MARK: - Lines

  var lineCount: Int { self.document.lineCount }
  var totalHeight: Double { self.document.lines.height }

  /// How wide the content is: the wrap width, or the widest line, measured or guessed.
  var contentWidth: Float {
    if let wrapWidth { return wrapWidth }
    return max(self.widestMeasured, Float(self.longestLine) * self.averageAdvance)
  }

  func lineTop(_ line: Int) -> Double {
    self.document.lines.top(of: line)
  }

  func line(atY y: Double) -> Int {
    self.document.lines.line(atY: y)
  }

  /// Whether `line` is folded away.
  func isHidden(_ line: Int) -> Bool {
    self.document.lines.record(of: line).flags.contains(.hidden)
  }

  /// Marks the start of a frame's use of the cache.
  func beginPass() {
    self.use &+= 1
  }

  /// `line`, shaped: from the cache, or now. Shaping stores the line's measured height.
  func layout(_ line: Int) -> LineLayout {
    let record = self.document.lines.record(of: line)
    if var entry = self.cache[record.id] {
      entry.lastUse = self.use
      self.cache[record.id] = entry
      return entry.layout
    }
    let layout = self.shape(line, spans: record.spans)
    self.cache[record.id] = Entry(layout: layout, lastUse: self.use)
    if self.cache.count > Self.cacheLimit { self.evict() }
    self.document.lines.setHeight(record.flags.contains(.hidden) ? 0 : layout.height, of: line)
    self.document.lines.updateRecord(of: line) { $0.flags.insert(.measured) }
    if self.wrapWidth == nil {
      self.widestMeasured = max(self.widestMeasured, layout.width)
    }
    return layout
  }

  /// Drops the least recently used half of the cache.
  private func evict() {
    let uses = self.cache.values.map(\.lastUse).sorted()
    let cutoff = uses[uses.count / 2]
    self.cache = self.cache.filter { $0.value.lastUse > cutoff || $0.value.lastUse == self.use }
  }

  private func shape(_ line: Int, spans stored: [TextSpan]) -> LineLayout {
    self.shapedCount += 1
    let range = self.document.lineRange(line)
    // Each reads the text itself: none inside another's read.
    self.spanSource?.prepare(forLine: line)
    self.decorationScratch.removeAll(keepingCapacity: true)
    self.spanSource?.decorations(forLine: line, lineStart: range.lowerBound, length: range.count, into: &self.decorationScratch)
    // Inline attachments: the marks on U+FFFCs in the line.
    self.reservations.removeAll(keepingCapacity: true)
    let provider = self.attachmentProvider
    let maxWidth = self.wrapWidth ?? 600
    if let provider, !self.document.attachments.isEmpty {
      self.document.attachments.forEach(overlapping: range) { mark in
        guard mark.range.count == 1, range.contains(mark.range.lowerBound) else { return }
        let size = provider.size(for: mark.payload, source: nil, maxWidth: maxWidth)
        self.reservations.append(AttachmentReservation(
          id: mark.payload, column: Int32(mark.range.lowerBound - range.lowerBound), size: size, isBlock: false, source: nil
        ))
      }
    }
    return self.document.withUTF16(in: range) { units in
      self.spans.removeAll(keepingCapacity: true)
      self.spanSource?.spans(forLine: line, units: units, into: &self.spans)
      if !stored.isEmpty {
        self.spans = Self.overlay(stored, on: self.spans)
      }
      if let provider {
        self.blockScratch.removeAll(keepingCapacity: true)
        self.spanSource?.blocks(forLine: line, units: units, into: &self.blockScratch)
        for block in self.blockScratch {
          let size = provider.size(for: block.attachment, source: block.source, maxWidth: maxWidth)
          self.reservations.append(AttachmentReservation(id: block.attachment, column: 0, size: size, isBlock: true, source: block.source))
        }
      }
      let runs = self.runs(length: Int32(units.count), spans: self.spans, decorations: self.decorationScratch)
      return shapeLine(units, runs: runs, base: self.baseFont, wrapWidth: self.wrapWidth,
                       lineSpacing: self.lineSpacing, attachments: self.reservations)
    }
  }

  /// `top` laid over `bottom`: where they overlap, `top` wins.
  static func overlay(_ top: [TextSpan], on bottom: [TextSpan]) -> [TextSpan] {
    guard !bottom.isEmpty else { return top }
    var result = bottom
    for span in top {
      result = TextDocument.replacingSpans(result, span.start ..< span.end, with: span)
    }
    return result
  }

  /// Runs covering a line `length` long: the spans' styles, plain between them, split where a
  /// decoration starts or ends, and joined where neighbours look the same.
  private func runs(length: Int32, spans: [TextSpan], decorations: [LineDecoration]) -> [LineRun] {
    // Every place a run may start.
    var cuts: [Int32] = [0, length]
    for span in spans where span.end > span.start {
      cuts.append(span.start.clamped(to: 0 ... length))
      cuts.append(span.end.clamped(to: 0 ... length))
    }
    for decoration in decorations {
      cuts.append(decoration.start.clamped(to: 0 ... length))
      cuts.append(decoration.end.clamped(to: 0 ... length))
    }
    cuts.sort()
    var runs: [LineRun] = []
    var spanIndex = 0
    var previous: Int32 = -1
    for cut in cuts where cut != previous {
      defer { previous = cut }
      guard previous >= 0, cut > previous else { continue }
      let start = previous
      while spanIndex < spans.count && spans[spanIndex].end <= start { spanIndex += 1 }
      let token: TextToken = spanIndex < spans.count && spans[spanIndex].start <= start ? spans[spanIndex].token : .plain
      var run = self.run(start: start, end: cut, token: token)
      for decoration in decorations where decoration.start <= start && decoration.end >= cut {
        if let background = decoration.background { run.background = background }
        if let squiggle = decoration.squiggle { run.squiggle = squiggle }
      }
      if var last = runs.last, last.end == start, last.style == run.style, last.paint == run.paint,
         last.background == run.background, last.squiggle == run.squiggle {
        last.end = cut
        runs[runs.count - 1] = last
      } else {
        runs.append(run)
      }
    }
    if runs.isEmpty {
      runs.append(self.run(start: 0, end: length, token: .plain))
    }
    return runs
  }

  private func run(start: Int32, end: Int32, token: TextToken) -> LineRun {
    let theme = self.theme
    let style = theme[token]
    var font = self.baseFont
    if let style {
      if let weight = style.weight { font = font.weight(weight) }
      if style.italic == true { font = font.italic() }
      if style.sizeScale != 1 { font = font.withSize(font.size * style.sizeScale) }
    }
    let foreground = style?.foreground ?? theme.foreground
    let underline = style?.underline
    var runStyle = TextRunStyle(font: font)
    runStyle.underline = underline == .single || underline == .thick
    runStyle.strikethrough = style?.strikethrough ?? false
    let decoration = style?.underlineColor ?? foreground
    return LineRun(
      start: start, end: end, style: runStyle,
      paint: TextRunPaint(text: foreground, underline: decoration, strikethrough: foreground),
      background: style?.background, squiggle: underline == .squiggle ? decoration : nil
    )
  }

  // MARK: - Positions

  /// The caret at `offset`: its x, the top of its row and the row's height, in document
  /// coordinates.
  func caretRect(_ offset: Int, affinity: TextAffinity) -> (x: Float, top: Double, height: Float) {
    let (line, column) = self.document.position(of: offset)
    let layout = self.layout(line)
    let (fragment, x) = layout.caretX(Int32(column), affinity: affinity)
    let top = self.lineTop(line) + Double(layout.rowTops[fragment])
    return (x, top, layout.rowTops[fragment + 1] - layout.rowTops[fragment])
  }

  /// The offset nearest the point `x`, `y` in document coordinates, with the affinity that keeps
  /// the caret on the row the point is on.
  func offset(atX x: Float, y: Double) -> (offset: Int, affinity: TextAffinity) {
    if y < 0 { return (0, .downstream) }
    if y >= self.totalHeight { return (self.document.length, .downstream) }
    let line = self.line(atY: y)
    let layout = self.layout(line)
    let fragment = layout.fragment(atY: Float(y - self.lineTop(line)))
    let (column, affinity) = layout.column(atX: x, fragment: fragment)
    let offset = self.document.lineStart(line) + Int(column)
    return (TextBoundaries.snap(offset, in: self.document), affinity)
  }

  // MARK: - TextLayoutQueries

  func verticalMove(from offset: Int, affinity: TextAffinity, goalX: Float?, lines: Int)
    -> (offset: Int, affinity: TextAffinity, goalX: Float) {
    var (line, column) = self.document.position(of: offset)
    var layout = self.layout(line)
    var (fragment, x) = layout.caretX(Int32(column), affinity: affinity)
    let goal = goalX ?? x
    var remaining = lines
    while remaining > 0 {
      var next = line + 1
      while next < self.lineCount && self.isHidden(next) { next += 1 }
      if fragment + 1 < layout.fragmentCount {
        fragment += 1
      } else if next < self.lineCount {
        line = next
        layout = self.layout(line)
        fragment = 0
      } else {
        return (self.document.length, .downstream, goal)
      }
      remaining -= 1
    }
    while remaining < 0 {
      var previous = line - 1
      while previous >= 0 && self.isHidden(previous) { previous -= 1 }
      if fragment > 0 {
        fragment -= 1
      } else if previous >= 0 {
        line = previous
        layout = self.layout(line)
        fragment = layout.fragmentCount - 1
      } else {
        return (0, .downstream, goal)
      }
      remaining += 1
    }
    let (newColumn, newAffinity) = layout.column(atX: goal, fragment: fragment)
    column = Int(newColumn)
    let target = TextBoundaries.snap(self.document.lineStart(line) + column, in: self.document)
    return (target, newAffinity, goal)
  }

  func visualLineBoundary(of offset: Int, affinity: TextAffinity, forward: Bool) -> (offset: Int, affinity: TextAffinity) {
    let (line, column) = self.document.position(of: offset)
    let layout = self.layout(line)
    let fragment = layout.fragment(of: Int32(column), affinity: affinity)
    let start = self.document.lineStart(line)
    if forward {
      let end = Int(layout.fragmentStarts[fragment + 1])
      let isLast = fragment == layout.fragmentCount - 1
      return (start + end, isLast ? .downstream : .upstream)
    }
    return (start + Int(layout.fragmentStarts[fragment]), .downstream)
  }

  var linesPerPage: Int {
    max(1, Int(self.viewportHeight / self.rowHeight) - 1)
  }

  // MARK: - Edits

  /// Keeps the longest line up to date as lines change; it shrinks only when all heights are
  /// reset.
  func linesChanged(_ change: DocumentChange) {
    guard self.wrapWidth == nil else { return }
    let lines = self.document.lines
    for line in change.firstLine ..< min(change.firstLine + change.insertedLines, lines.lineCount) {
      self.longestLine = max(self.longestLine, lines.length(of: line))
    }
  }
}
