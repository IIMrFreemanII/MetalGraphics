import simd

/// A line shown this frame: where it starts on screen, in document coordinates, and its layout.
struct VisibleLine {
  var line: Int
  var start: Int
  var top: Double
  var layout: LineLayout
}

/// The gutter beside the text and the scroll view with the text in it, side by side: the
/// gutter as wide as its line numbers need, the text the rest.
final class EditorBody : MultiChildElement {
  private unowned let gutterBox: UIElement
  private unowned let gutter: EditorGutterView
  private unowned let scrollView: ScrollView
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  init(gutterBox: UIElement, gutter: EditorGutterView, scrollView: ScrollView) {
    self.gutterBox = gutterBox
    self.gutter = gutter
    self.scrollView = scrollView
    super.init()
    self.applyContent([gutterBox, scrollView])
  }

  override func getSize() -> float2 { self.size }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: TextEditor.idealSize)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = proposal.replacingUnspecified(with: TextEditor.idealSize)
    let gutterWidth = min(self.gutter.width, self.size.x)
    _ = self.gutterBox.calcSize(ProposedSize(width: gutterWidth, height: self.size.y))
    _ = self.scrollView.calcSize(ProposedSize(width: self.size.x - gutterWidth, height: self.size.y))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.gutterBox.calcPosition(position)
    self.scrollView.calcPosition(position + float2(min(self.gutter.width, self.size.x), 0))
  }
}

/// The editor's text: the lines in view, their backgrounds, the selection and the caret. Sized
/// by the document's line tree, so measuring it is O(1) however long the document is; drawn from
/// the lines `prepareVisible` shaped, never more.
final class EditorContentView : UIRenderableElement {
  /// Set by the editor as it builds itself, which owns this view.
  unowned(unsafe) var editor: TextEditor! = nil
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero
  /// The lines in view, top to bottom.
  private(set) var visible: [VisibleLine] = []

  /// The first line in view, by the offset of its start, and where its top was: what keeps the
  /// view still when lines above it change height.
  var anchorOffset = 0
  private(set) var anchorTop: Double = 0

  // Reused every frame.
  private var rects: [LineRect] = []
  private var wantedAttachments: [(attachment: PlacedAttachment, origin: float2)] = []
  /// The elements of the attachments in view, drawn over the text.
  let attachments = EditorAttachmentLayer()

  override init() {
    super.init()
    self.child = self.attachments
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 { self.size }

  /// Where the text's top left corner is in the window.
  var textOrigin: float2 { self.position + self.editor.theme.textInset }

  private func contentSize(for proposal: ProposedSize) -> float2 {
    let editor: TextEditor = self.editor
    let inset = editor.theme.textInset
    if editor.lineWrapping == .soft {
      let width = proposal.width ?? TextEditor.idealSize.x
      editor.configureLayout(wrapWidth: width - inset.x * 2 - TextEditor.caretWidth)
      return float2(width, Float(editor.layout.totalHeight) + inset.y * 2)
    }
    editor.configureLayout(wrapWidth: nil)
    return float2(editor.layout.contentWidth + inset.x * 2 + TextEditor.caretWidth,
                  Float(editor.layout.totalHeight) + inset.y * 2)
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.contentSize(for: proposal)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.contentSize(for: proposal)
    _ = self.child?.calcSize(.unspecified)
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.attachments.calcPosition(position)
    self.prepareVisible()
  }

  /// Shapes the lines in the scroll view's viewport, and remembers the first as the anchor.
  func prepareVisible() {
    let editor: TextEditor = self.editor
    let layout = editor.layout
    let scrollView = editor.scrollView
    layout.beginPass()
    layout.viewportHeight = scrollView.size.y
    self.visible.removeAll(keepingCapacity: true)
    let inset = editor.theme.textInset
    let viewTop = Double(scrollView.position.y - self.position.y - inset.y)
    let viewBottom = viewTop + Double(scrollView.size.y)
    let document = editor.document
    let first = layout.line(atY: max(viewTop, 0))
    var top = layout.lineTop(first)
    self.anchorOffset = document.lineStart(first)
    self.anchorTop = top
    var line = first
    let count = document.lineCount
    while line < count && (top < viewBottom || line == first) {
      // Folded away: no height, nothing to show.
      if line != first && layout.isHidden(line) {
        line += 1
        continue
      }
      let lineLayout = layout.layout(line)
      self.visible.append(VisibleLine(line: line, start: document.lineStart(line), top: top, layout: lineLayout))
      top += Double(lineLayout.height)
      line += 1
    }
    self.placeAttachments()
  }

  /// Shows the elements of the attachments on the lines in view, where the lines put them.
  private func placeAttachments() {
    let editor: TextEditor = self.editor
    guard editor.attachmentProvider != nil || !self.attachments.children.isEmpty else { return }
    self.wantedAttachments.removeAll(keepingCapacity: true)
    let origin = self.textOrigin
    for visible in self.visible where !visible.layout.attachments.isEmpty {
      for attachment in visible.layout.attachments {
        self.wantedAttachments.append((attachment, origin + float2(0, Float(visible.top)) + attachment.origin))
      }
    }
    if self.attachments.show(self.wantedAttachments, provider: editor.attachmentProvider, scope: editor.textScope) {
      editor.context?.invalidate(.hitGrid)
    }
  }

  /// How far the anchor line's top moved since it was recorded: what the view scrolls by to
  /// keep what is on screen still.
  func anchorDrift() -> Double {
    let document = self.editor.document
    let line = document.line(containing: min(self.anchorOffset, document.length))
    return self.editor.layout.lineTop(line) - self.anchorTop
  }

  // MARK: - Drawing

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let editor: TextEditor = self.editor
    let theme = editor.theme
    let scale = effect.scale
    let opacity = effect.opacity
    let half = renderer.size * 0.5
    let scrollView = editor.scrollView
    let viewport = ClipRect(position: scrollView.position, size: scrollView.size)
    let origin = self.textOrigin
    let state = editor.state
    let focused = editor.isFocused

    func fill(_ min: float2, _ size: float2, _ color: float4) {
      guard size.x > 0, size.y > 0 else { return }
      var color = color
      color.w *= opacity
      let drawn = effect.apply(to: min) - half
      renderer.draw(square: Square(position: drawn + size * scale * 0.5, size: size * scale, color: color))
    }

    fill(viewport.min, viewport.max - viewport.min, theme.background)

    // The line with the caret, across the whole view.
    if let highlight = theme.currentLine, focused || state.isEditable {
      let caret = state.selection.primary
      if caret.isEmpty, let line = self.visible.first(where: { caret.head >= $0.start && caret.head <= $0.start + Int($0.layout.length) }) {
        let y = origin.y + Float(line.top)
        fill(float2(viewport.min.x, y), float2(viewport.max.x - viewport.min.x, line.layout.height), highlight)
      }
    }

    let selectionColor = focused ? theme.selection : theme.inactiveSelection
    let ranges = state.selection.ranges
    let extent = viewport.max.x - origin.x
    for visible in self.visible {
      let lineOrigin = float2(origin.x, origin.y + Float(visible.top))
      let layout = visible.layout
      for rect in layout.backgrounds {
        fill(lineOrigin + rect.origin, rect.size, rect.color)
      }
      // The selection over this line, and over its newline when it goes on past it.
      let lineEnd = visible.start + Int(layout.length)
      self.rects.removeAll(keepingCapacity: true)
      for range in ranges where !range.isEmpty && range.lowerBound <= lineEnd && range.upperBound >= visible.start {
        let low = Int32(max(range.lowerBound, visible.start) - visible.start)
        let high = Int32(min(range.upperBound, lineEnd) - visible.start)
        layout.selectionRects(low ..< max(low, high), throughEnd: range.upperBound > lineEnd, extent: extent, into: &self.rects, color: selectionColor)
      }
      for rect in self.rects {
        fill(lineOrigin + rect.origin, rect.size, rect.color)
      }
      var paints = layout.paints
      if opacity < 1 {
        for i in paints.indices {
          paints[i].text.w *= opacity
          paints[i].underline.w *= opacity
          paints[i].strikethrough.w *= opacity
        }
      }
      renderer.draw(textLayout: layout.text, at: effect.apply(to: lineOrigin) - half,
                    color: theme.foreground * float4(1, 1, 1, opacity), paints: paints, scale: scale)
      for squiggle in layout.squiggles {
        let start = effect.apply(to: lineOrigin + float2(squiggle.x0, squiggle.y)) - half
        var color = squiggle.color
        color.w *= opacity
        renderer.draw(squiggle: start, length: (squiggle.x1 - squiggle.x0) * scale, amplitude: 1.2 * scale,
                      wavelength: 4 * scale, thickness: 1 * scale, color: color)
      }
      // A fold's first line ends in a "⋯" standing for what is folded.
      if !editor.folds.isEmpty, let rect = editor.foldMarkerRect(forLine: visible.line) {
        var box = theme.foreground
        box.w = 0.12 * opacity
        let min = effect.apply(to: rect.min) - half
        renderer.draw(roundedRect: min, size: (rect.max - rect.min) * scale, radii: float4(repeating: 4 * scale), color: box)
        var dot = theme.foreground
        dot.w = 0.7 * opacity
        let center = (rect.min + rect.max) * 0.5
        for dx: Float in [-5, 0, 5] {
          renderer.draw(circle: Circle2D(position: effect.apply(to: center + float2(dx, 0)) - half, radius: 1.3 * scale, color: dot))
        }
      }
    }

    // The input method's composition, underlined.
    if let marked = state.markedRange {
      self.drawMarkedText(marked, selected: state.markedSelection, origin: origin, fill: fill)
    }

    // Carets, when focused, in the blink's on phase.
    if focused && editor.caretVisible {
      for range in ranges where range.isEmpty {
        guard let visible = self.visible.first(where: { range.head >= $0.start && range.head <= $0.start + Int($0.layout.length) })
        else { continue }
        let (fragment, x) = visible.layout.caretX(Int32(range.head - visible.start), affinity: range.affinity)
        let rows = visible.layout.rowTops
        let inset = editor.theme.lineSpacing * 0.5
        let top = origin.y + Float(visible.top) + rows[fragment] + inset * 0.5
        let height = rows[fragment + 1] - rows[fragment] - inset
        fill(float2(origin.x + x - TextEditor.caretWidth * 0.5, top), float2(TextEditor.caretWidth, height), theme.caret)
      }
    }
  }

  private func drawMarkedText(_ marked: Range<Int>, selected: Range<Int>?, origin: float2, fill: (float2, float2, float4) -> Void) {
    let theme = self.editor.theme
    for visible in self.visible {
      let lineEnd = visible.start + Int(visible.layout.length)
      guard marked.lowerBound <= lineEnd && marked.upperBound >= visible.start else { continue }
      let layout = visible.layout
      for fragment in 0 ..< layout.fragmentCount {
        let start = visible.start + Int(layout.fragmentStarts[fragment])
        let end = visible.start + Int(layout.fragmentStarts[fragment + 1])
        let low = max(marked.lowerBound, start)
        let high = min(marked.upperBound, end)
        guard low < high else { continue }
        let x0 = layout.caretX(Int32(low - visible.start), affinity: .downstream).x
        let x1 = layout.caretX(Int32(high - visible.start), affinity: .upstream).x
        let baseline = origin.y + Float(visible.top) + layout.text.lines[fragment].baseline + 2
        fill(float2(origin.x + x0, baseline), float2(x1 - x0, 1), theme.markedText)
        // The clause being converted, thicker.
        if let selected, selected.upperBound > selected.lowerBound {
          let sLow = max(selected.lowerBound, low)
          let sHigh = min(selected.upperBound, high)
          if sLow < sHigh {
            let sx0 = layout.caretX(Int32(sLow - visible.start), affinity: .downstream).x
            let sx1 = layout.caretX(Int32(sHigh - visible.start), affinity: .upstream).x
            fill(float2(origin.x + sx0, baseline), float2(sx1 - sx0, 2), theme.markedText)
          }
        }
      }
    }
  }
}

/// The line numbers beside the text, kept level with the lines as they scroll. Numbers are made
/// from the digit glyphs, shaped once per font, so drawing one shapes nothing.
final class EditorGutterView : UIRenderableElement {
  unowned(unsafe) var editor: TextEditor! = nil
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  private var digits: [PlacedGlyph] = []
  private var digitAdvance: Float = 0
  private var digitFont: TextFont? = nil
  /// A one-line layout, refilled for each number.
  private var scratch = TextLayout()

  static let padding: Float = 10
  static let dotRadius: Float = 3
  static let dotInset: Float = 6

  override init() {
    super.init()
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 { self.size }

  /// Wide enough for the largest line number, and the fold chevrons when anything can fold;
  /// 0 when neither shows.
  var width: Float {
    let folding = self.showsFolding
    guard self.editor.showsLineNumbers || folding else { return 0 }
    self.prepareDigits()
    let count = max(self.editor.document.lineCount, 1)
    let places = max(3, String(count).count)
    let numbers = self.editor.showsLineNumbers ? Float(places) * self.digitAdvance + Self.padding * 2 : Self.padding
    return numbers + (folding ? Self.foldColumn : 0)
  }

  var showsFolding: Bool { !self.editor.foldingRanges.isEmpty || !self.editor.folds.isEmpty }

  /// Where fold chevrons are, between the numbers and the text.
  static let foldColumn: Float = 14

  /// Whether `x`, in the window, is in the chevrons' column.
  func isInFoldColumn(_ x: Float) -> Bool {
    self.showsFolding && x >= self.position.x + self.size.x - Self.foldColumn
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: float2(self.width, 0))
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = proposal.replacingUnspecified(with: float2(self.width, 0))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
  }

  private func prepareDigits() {
    let font = self.editor.layout.baseFont.monospacedDigit()
    guard font != self.digitFont else { return }
    self.digitFont = font
    let shaped = layoutText(
      runs: [TextRunInput(string: "0123456789", style: TextRunStyle(font: font))], paragraph: TextParagraph(),
      maxSize: nil, keepsFirstLine: true
    )
    let glyphs = shaped.lines.first?.glyphs ?? []
    self.digits = glyphs.map { glyph in
      var glyph = glyph
      glyph.origin.x = 0
      return glyph
    }
    self.digitAdvance = glyphs.count > 1 ? glyphs[1].origin.x - glyphs[0].origin.x : font.size * 0.6
    self.scratch = TextLayout()
    self.scratch.lines = [TextLine(top: 0, baseline: 0)]
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0, self.size.x > 0, self.digits.count == 10 else { return }
    let editor: TextEditor = self.editor
    let theme = editor.theme
    let scale = effect.scale
    let half = renderer.size * 0.5
    let opacity = effect.opacity

    func fill(_ min: float2, _ size: float2, _ color: float4) {
      var color = color
      color.w *= opacity
      renderer.draw(square: Square(position: effect.apply(to: min) - half + size * scale * 0.5, size: size * scale, color: color))
    }
    fill(self.position, self.size, theme.gutterBackground)
    if let separator = theme.gutterSeparator {
      fill(float2(self.position.x + self.size.x - 1, self.position.y), float2(1, self.size.y), separator)
    }

    let content = editor.content
    let originY = content.textOrigin.y
    let folding = self.showsFolding
    let right = self.position.x + self.size.x - Self.padding - (folding ? Self.foldColumn : 0)
    let document = editor.document
    let caretLine = document.line(containing: editor.state.selection.primary.head)
    let diagnostics = document.diagnostics
    for visible in content.visible {
      let layout = visible.layout
      let baseline = originY + Float(visible.top) + (layout.text.lines.first?.baseline ?? 0)
      guard baseline > self.position.y - 20, baseline < self.position.y + self.size.y + 20 else { continue }
      if !diagnostics.isEmpty {
        // A dot by the number of a line with problems, in the colour of the worst.
        var worst: DiagnosticSeverity? = nil
        let lineRange = document.lineRange(visible.line)
        diagnostics.forEach(overlapping: lineRange.lowerBound ..< lineRange.upperBound + 1) { mark in
          if worst.map({ mark.payload.severity.rawValue > $0.rawValue }) ?? true { worst = mark.payload.severity }
        }
        if let worst {
          var color = theme.color(for: worst)
          color.w *= opacity
          let center = float2(self.position.x + Self.dotInset, baseline - editor.layout.baseFont.size * 0.35)
          renderer.draw(circle: Circle2D(position: effect.apply(to: center) - half, radius: Self.dotRadius * scale, color: color))
        }
      }
      // The number's digits, right to left, into the scratch line.
      var number = visible.line + 1
      var x: Float = 0
      self.scratch.lines[0].glyphs.removeAll(keepingCapacity: true)
      repeat {
        x -= self.digitAdvance
        var glyph = self.digits[number % 10]
        glyph.origin.x = x
        self.scratch.lines[0].glyphs.append(glyph)
        number /= 10
      } while number > 0
      if folding, let folded = editor.foldState(ofLine: visible.line) {
        // ⌄ over what can fold, › over what is folded.
        var color = theme.gutterForeground
        color.w *= folded ? opacity : opacity * 0.55
        let center = float2(self.position.x + self.size.x - Self.foldColumn * 0.5 - 1, baseline - editor.layout.baseFont.size * 0.35)
        let points: [float2] = folded ? [float2(-1.5, -3.5), float2(2, 0), float2(-1.5, 3.5)]
                                      : [float2(-3.5, -1.5), float2(0, 2), float2(3.5, -1.5)]
        for i in 0 ..< 2 {
          renderer.draw(stroke: effect.apply(to: center + points[i]) - half, to: effect.apply(to: center + points[i + 1]) - half,
                        width: 1.3 * scale, color: color)
        }
      }
      guard editor.showsLineNumbers else { continue }
      var color = visible.line == caretLine ? theme.gutterCurrentLine : theme.gutterForeground
      color.w *= opacity
      renderer.draw(textLayout: self.scratch, at: effect.apply(to: float2(right, baseline)) - half, color: color, scale: scale)
    }
  }
}
