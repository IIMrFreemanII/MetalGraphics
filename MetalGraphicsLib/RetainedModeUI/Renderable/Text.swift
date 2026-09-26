import Foundation

/// A stretch of a text in one style: a whole `Text`, or one operand of `Text + Text`.
public struct TextRun: Equatable, Sendable {
  public var string: String
  /// The run's own font, colour, decorations and spacing, over the text's.
  public var style: TextEnvironment

  public init(_ string: String, style: TextEnvironment = TextEnvironment()) {
    self.string = string
    self.style = style
  }
}

/// A paragraph of text, as SwiftUI's: wrapped at words to the width offered, in the font,
/// colour and paragraph style its own modifiers set, or else the containers around it.
///
/// `Text + Text` joins texts into one paragraph whose runs keep their own font, colour,
/// decorations and spacing.
public class Text : UIRenderableElement {
  public typealias TruncationMode = TextTruncationMode
  public typealias Case = TextCase

  /// How `Text(_:style:)` shows a date.
  public struct DateStyle: Sendable {
    let format: @Sendable (Date) -> String

    /// The long date, no time: "June 3, 2019".
    public static let date = DateStyle { $0.formatted(date: .long, time: .omitted) }
    /// The time, no date: "11:23 AM".
    public static let time = DateStyle { $0.formatted(date: .omitted, time: .shortened) }
  }

  public private(set) var runs: [TextRun] {
    didSet { self.styleDirty = true }
  }

  /// The whole text. Setting it replaces the runs with one.
  public var text: String {
    get { self.runs.count == 1 ? self.runs[0].string : self.runs.map(\.string).joined() }
    set {
      if self.runs.count == 1 {
        if self.runs[0].string != newValue { self.runs[0].string = newValue }
      } else {
        self.runs = [TextRun(newValue)]
      }
    }
  }

  /// This text's own modifiers.
  public internal(set) var style = TextEnvironment() {
    didSet { self.styleDirty = true }
  }

  /// What the containers around it in the same `@Component` body set: written by the macro,
  /// which sees them, so they need no `TextStyleElement`. Between what `TextStyleElement`s set
  /// and this text's own.
  public internal(set) var inheritedStyle = TextEnvironment() {
    didSet { self.styleDirty = true }
  }

  /// Turns a value `setText` is given into the text, for `Text(_:format:)` and
  /// `Text(_:style:)`.
  private var formatter: ((Any) -> String)? = nil

  /// What is drawn while color or size animate, nil when it is the model value itself.
  ///
  /// The resolved style is the model; these are the presentation. Text is shaped only at the
  /// model size — the one it animates to — and drawn scaled in between, so an animated size
  /// costs no shaping per frame. Its line breaks are the ones of the final size throughout.
  private var presentedColor: float4? = nil
  private var presentedFontSize: Float? = nil
  /// The colour `TextStyleElement`s gave it when last drawn: where an animation of its own
  /// colour starts from.
  private var lastForeground: float4? = nil

  public var position: SIMD2<Float> = .init()
  public var size: SIMD2<Float> = .init()
  // Picked by `calcSize` for the space layout offered, and drawn as is every frame.
  private var layout = TextLayout()
  // The last few layouts shaped, and the space each was shaped for, most recent last; emptied
  // when what is shaped changes. Shaping is the expensive part of layout. A stack measures a
  // text at its narrowest and widest before it settles on a width, and a relayout caused by
  // anything else — a sibling's animated size, say, or this text's own animated size — asks for
  // the same shapes again, so they are kept rather than reshaped.
  private var shaped: [(maxSize: float2, layout: TextLayout)] = []
  private static let shapedCapacity = 3

  /// Set when the runs or a style layer change: `resolved` is out of date.
  private var styleDirty = true
  /// The `TextScope.current` `resolved` was made under.
  private var resolvedScope = TextEnvironment()
  private var resolved = ResolvedText()
  // Filled for each draw of a text whose runs differ in colour; never shrinks.
  private static var paintScratch: [TextRunPaint] = []

  public init(_ text: String) {
    self.runs = [TextRun(text)]

    super.init()
    self.shaped.reserveCapacity(Self.shapedCapacity)
  }

  /// `text` as is. The same as `Text(_:)`, which does not localize.
  public convenience init(verbatim text: String) {
    self.init(text)
  }

  /// `value` formatted by `format`, e.g. `Text(price, format: .currency(code: "EUR"))`.
  public convenience init<F: FormatStyle>(_ value: F.FormatInput, format: F) where F.FormatOutput == String {
    self.init(format.format(value))
    self.formatter = { value in (value as? F.FormatInput).map { format.format($0) } ?? "\(value)" }
  }

  /// `date` shown in `style`.
  public convenience init(_ date: Date, style: DateStyle) {
    self.init(style.format(date))
    self.formatter = { value in (value as? Date).map { style.format($0) } ?? "\(value)" }
  }

  /// Runs as they are: what `Text + Text` makes, and the `@Component` macro for it.
  public init(runs: [TextRun]) {
    self.runs = runs.isEmpty ? [TextRun("")] : runs

    super.init()
    self.shaped.reserveCapacity(Self.shapedCapacity)
  }

  /// One paragraph of `lhs`'s runs, then `rhs`'s. Each keeps its own font, colour, decorations
  /// and spacing; paragraph modifiers on either (`lineLimit`, alignment…) are dropped, as in
  /// SwiftUI, where they do not return a `Text`.
  public static func + (lhs: Text, rhs: Text) -> Text {
    Text(runs: lhs.flattenedRuns + rhs.flattenedRuns)
  }

  /// The runs with this text's own run styling folded in beneath theirs.
  var flattenedRuns: [TextRun] {
    let own = self.style.runFields
    return self.runs.map { TextRun($0.string, style: own.overriding($0.style)) }
  }

  // MARK: - Content

  /// A new string for one run: what a reactive operand of `Text + Text` in a `@Component`
  /// updates.
  public struct RunText: Sendable {
    let index: Int
    let string: String

    public init(_ index: Int, _ string: String) {
      self.index = index
      self.string = string
    }
  }

  /// A new style for one run, as a reactive `Text + Text` operand's modifiers make it.
  public struct RunStyle: Sendable {
    let index: Int
    let style: TextEnvironment

    public init(_ index: Int, _ style: TextEnvironment) {
      self.index = index
      self.style = style
    }
  }

  public func setRunText(_ value: RunText, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard self.runs.indices.contains(value.index), self.runs[value.index].string != value.string else { return }
    self.runs[value.index].string = value.string
    context.invalidate(.layout, animation: animation)
  }

  public func setRunStyle(_ value: RunStyle, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard self.runs.indices.contains(value.index), self.runs[value.index].style != value.style else { return }
    self.runs[value.index].style = value.style
    context.invalidate(.layout, animation: animation)
  }

  /// Formats `value` the way this text was made to, or describes it: a value of another type
  /// than it was made with is described.
  public func setText<V>(_ value: V, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setText(self.formatter.map { $0(value) } ?? "\(value)", context, animation: animation)
  }

  // MARK: - Style

  /// What the three style layers come to, and what that shapes. Rebuilt only when a layer or
  /// the runs change, so a measure costs one comparison of the scope.
  private struct ResolvedText {
    var inputs: [TextRunInput] = []
    var paragraph = TextParagraph()
    /// Per run: its own colour and its decorations' colours, nil for the text's colour.
    var paints: [(text: float4?, underline: float4?, strikethrough: float4?)] = []
    var hasPaints = false
    var font = TextEnvironment.defaultFont
    /// The colour the macro or this text's own modifiers set.
    var foreground: float4? = nil
  }

  /// Brings `resolved` up to date with the style layers, and drops the shaped layouts if what
  /// is shaped changed. Returns whether it did.
  @discardableResult
  private func resolveStyle(_ scope: TextEnvironment) -> Bool {
    guard self.styleDirty || scope != self.resolvedScope else { return false }
    self.styleDirty = false
    self.resolvedScope = scope

    let environment = scope.withoutForeground.overriding(self.inheritedStyle).overriding(self.style)
    var resolved = ResolvedText()
    resolved.paragraph = environment.resolvedParagraph
    resolved.font = environment.resolvedFont
    resolved.foreground = environment.foreground
    let textCase = environment.textCase ?? nil
    resolved.inputs.reserveCapacity(self.runs.count)
    resolved.paints.reserveCapacity(self.runs.count)
    for run in self.runs {
      let runEnvironment = environment.overriding(run.style)
      let string = switch textCase {
      case .uppercase: run.string.uppercased()
      case .lowercase: run.string.lowercased()
      case nil: run.string
      }
      resolved.inputs.append(TextRunInput(string: string, style: runEnvironment.resolvedRunStyle))
      let paint = (
        text: run.style.foreground, underline: runEnvironment.underline?.color,
        strikethrough: runEnvironment.strikethrough?.color
      )
      resolved.paints.append(paint)
      resolved.hasPaints = resolved.hasPaints || paint.text != nil || paint.underline != nil || paint.strikethrough != nil
    }

    let reshapes = resolved.inputs != self.resolved.inputs || resolved.paragraph != self.resolved.paragraph
    if reshapes {
      self.shaped.removeAll(keepingCapacity: true)
    }
    self.resolved = resolved
    return reshapes
  }

  /// The font the text is drawn in, all its layers resolved: as of the last layout.
  public var font: TextFont { self.resolved.font }

  /// The colour the text's own modifiers or the macro set, or black. A `TextStyleElement`'s is
  /// only known when drawn.
  public var color: float4 { self.resolved.foreground ?? .black }

  private var targetColor: float4 { self.resolved.foreground ?? self.lastForeground ?? .black }
  /// The colour it is drawn in now: animating, its own, or the one around it when last drawn.
  var displayedColor: float4 { self.presentedColor ?? self.targetColor }
  private var displayedFontSize: Float { self.presentedFontSize ?? self.resolved.font.size }

  /// How much the drawn text is scaled from the layout it was shaped as.
  private var fontScale: Float {
    let size = self.resolved.font.size
    return size > 0 ? self.displayedFontSize / size : 1
  }

  /// Applies a change to this text's own style, animating color and size from what is drawn
  /// now. The one path `setFont` and `setForegroundColor` go through.
  func restyle(_ context: UIContext, _ animation: UIAnimation?, _ change: (Text) -> Void) {
    self.resolveStyle(self.resolvedScope)
    let color = self.displayedColor
    let fontSize = self.displayedFontSize
    let face = self.resolved.font.withSize(0)
    change(self)
    let reshapes = self.resolveStyle(self.resolvedScope)

    guard face == self.resolved.font.withSize(0) else {
      // One face's glyphs cannot morph into another's: snap, and let the layout change slide.
      context.animator.cancel(self, .color)
      context.animator.cancel(self, .fontSize)
      self.presentedColor = nil
      self.presentedFontSize = nil
      context.invalidate(.layout, animation: animation)
      return
    }

    // Hold what is drawn until the animator moves it; a plain write replaces it at once.
    self.presentedColor = color
    context.animator.set(self, .color, from: color, to: self.targetColor, animation, context) { element, value, context in
      let text = unsafeDowncast(element, to: Text.self)
      let color = float4(packed: value)
      text.presentedColor = color == text.targetColor ? nil : color
      context.invalidate()
    }
    let size = self.resolved.font.size
    if fontSize != size || self.presentedFontSize != nil {
      self.presentedFontSize = fontSize
      context.animator.set(self, .fontSize, from: fontSize, to: size, animation, context) { element, value, context in
        let text = unsafeDowncast(element, to: Text.self)
        text.presentedFontSize = value.x == text.resolved.font.size ? nil : value.x
        context.invalidate(.layout)
      }
    } else if reshapes {
      context.invalidate(.layout, animation: animation)
    }
  }

  /// Applies a change to this text's own style that only layout shows: decorations, spacing,
  /// paragraph. Skipped when nothing changes.
  func restyleLayout<V: Equatable>(
    _ key: WritableKeyPath<TextEnvironment, V>, _ value: V, _ context: UIContext, _ animation: UIAnimation?
  ) {
    guard self.style[keyPath: key] != value else { return }
    self.style[keyPath: key] = value
    context.invalidate(.layout, animation: animation)
  }

  // MARK: - Element

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(text: \"\(text)\", position: \(position), size: \(size))")
  }

  public override func getSize() -> float2 {
    self.size
  }

  // Wraps at the width offered, and as one line when asked for its ideal size. Lines past the
  // height offered are dropped, but the first line always stays, as SwiftUI's does.
  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.resolveStyle(TextScope.current)
    return self.shape(for: proposal).size * self.fontScale
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.resolveStyle(TextScope.current)
    self.layout = self.shape(for: proposal)
    self.size = self.layout.size * self.fontScale

    return self.size
  }

  private func shape(for proposal: ProposedSize) -> TextLayout {
    let maxSize = proposal.replacingUnspecified(with: float2(repeating: .infinity))
    if let index = self.shaped.firstIndex(where: { $0.maxSize == maxSize }) {
      let entry = self.shaped[index]
      if index != self.shaped.count - 1 {
        self.shaped.remove(at: index)
        self.shaped.append(entry)
      }
      return entry.layout
    }

    let layout = layoutText(
      runs: self.resolved.inputs, paragraph: self.resolved.paragraph, maxSize: maxSize, keepsFirstLine: true
    )
    if self.shaped.count == Self.shapedCapacity {
      self.shaped.removeFirst()
    }
    self.shaped.append((maxSize, layout))
    return layout
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    if let own = self.explicitGuide(key, size) { return own }
    switch key.kind {
    case .firstTextBaseline:
      self.resolveStyle(TextScope.current)
      return self.shape(for: proposal).lines.first.map { $0.baseline * self.fontScale }
    case .lastTextBaseline:
      self.resolveStyle(TextScope.current)
      return self.shape(for: proposal).lines.last.map { $0.baseline * self.fontScale }
    default: return nil
    }
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    self.lastForeground = renderer.textForeground
    guard effect.opacity > 0 else { return }
    var color = self.displayedColor
    color.w *= effect.opacity
    // origin -> top left
    let origin = effect.apply(to: self.position) - renderer.size * 0.5
    let scale = effect.scale * self.fontScale
    guard self.resolved.hasPaints else {
      renderer.draw(textLayout: self.layout, at: origin, color: color, scale: scale)
      return
    }

    Self.paintScratch.removeAll(keepingCapacity: true)
    for paint in self.resolved.paints {
      var text = color
      if let own = paint.text {
        text = own
        text.w *= effect.opacity
      }
      var underline = text
      if let own = paint.underline {
        underline = own
        underline.w *= effect.opacity
      }
      var strikethrough = text
      if let own = paint.strikethrough {
        strikethrough = own
        strikethrough.w *= effect.opacity
      }
      Self.paintScratch.append(TextRunPaint(text: text, underline: underline, strikethrough: strikethrough))
    }
    renderer.draw(textLayout: self.layout, at: origin, color: color, paints: Self.paintScratch, scale: scale)
  }

  // MARK: - Modifiers
  //
  // Unlike most modifiers they wrap nothing: each sets this text's own style and returns it.
  // The same modifiers on any other element wrap it in a `TextStyleElement`, whose style every
  // text inside inherits.

  /// The face and size to draw in; 16pt San Francisco when never set here or around it.
  public func font(_ font: TextFont?) -> Self { self.style = self.style.font(font); return self }
  public func fontWeight(_ weight: TextFont.Weight?) -> Self { self.style = self.style.fontWeight(weight); return self }
  public func fontDesign(_ design: TextFont.Design?) -> Self { self.style = self.style.fontDesign(design); return self }
  public func bold(_ isActive: Bool = true) -> Self { self.style = self.style.bold(isActive); return self }
  public func italic(_ isActive: Bool = true) -> Self { self.style = self.style.italic(isActive); return self }
  public func monospaced(_ isActive: Bool = true) -> Self { self.style = self.style.monospaced(isActive); return self }
  public func monospacedDigit() -> Self { self.style = self.style.monospacedDigit(); return self }
  /// The color to draw in; black when never set here or around it.
  public func foregroundColor(_ color: float4) -> Self { self.style = self.style.foregroundColor(color); return self }
  public func foregroundStyle(_ color: float4) -> Self { self.foregroundColor(color) }

  public func underline(_ isActive: Bool = true, color: float4? = nil) -> Self {
    self.style = self.style.underline(isActive, color: color)
    return self
  }

  public func strikethrough(_ isActive: Bool = true, color: float4? = nil) -> Self {
    self.style = self.style.strikethrough(isActive, color: color)
    return self
  }

  /// Space added after every character, in points; ligatures are kept.
  public func kerning(_ kerning: Float) -> Self { self.style = self.style.kerning(kerning); return self }
  /// Space added between characters, in points; unlike kerning, it breaks up ligatures.
  public func tracking(_ tracking: Float) -> Self { self.style = self.style.tracking(tracking); return self }
  /// Raises the text off its baseline by `offset` points, or lowers it for a negative one.
  public func baselineOffset(_ offset: Float) -> Self { self.style = self.style.baselineOffset(offset); return self }
  /// At most `limit` lines, the last ending in an ellipsis when text is left; nil for any.
  public func lineLimit(_ limit: Int?) -> Self { self.style = self.style.lineLimit(limit); return self }
  public func multilineTextAlignment(_ alignment: TextAlignment) -> Self {
    self.style = self.style.multilineTextAlignment(alignment)
    return self
  }
  public func truncationMode(_ mode: TruncationMode) -> Self { self.style = self.style.truncationMode(mode); return self }
  /// Space between lines, in points, on top of the font's own.
  public func lineSpacing(_ spacing: Float) -> Self { self.style = self.style.lineSpacing(spacing); return self }
  /// How far the fonts may shrink, as a fraction of their size, before text is truncated.
  public func minimumScaleFactor(_ factor: Float) -> Self { self.style = self.style.minimumScaleFactor(factor); return self }
  public func textCase(_ textCase: Case?) -> Self { self.style = self.style.textCase(textCase); return self }

  /// Sets several of this text's own modifiers at once: what the macro makes of a chain of them
  /// with constant arguments. Later ones win, as in the chain.
  public func applyStyle(_ style: TextEnvironment) -> Self {
    self.style = self.style.overriding(style)
    return self
  }

  /// Fills what this text inherits from `style`, the style of a container around it that the
  /// `@Component` macro can see. Called innermost container first, so nearer ones win.
  public func inheritStyle(_ style: TextEnvironment) -> Self {
    self.inheritedStyle = self.inheritedStyle.filling(style)
    return self
  }
}
