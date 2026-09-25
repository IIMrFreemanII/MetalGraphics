import simd

/// A group of rows in a `Form`, on a rounded card, with a separator between rows and an optional
/// header above and footer below: `Section("Account", footer: "Shown to others.") { … }`, or
/// with views, `Section { … } header: { Text("Account") } footer: { … }`.
///
/// Each child is one row. Rows fill the card's width, less the row inset, so a control's label
/// sits at the leading edge and the control at the trailing one; each is centred vertically in a
/// row at least `FormMetrics.rowMinHeight` tall. A header or footer `Text` left in the default
/// font takes the caption style.
///
/// `children` are the rows only, so `@Component`'s `replaceChildren`, branch swaps and row
/// transitions work on them as on a stack's. The card, header and footer are elements of its
/// own, visited before and after the rows.
public final class Section : MultiChildElement {
  private let card = SectionCard()
  private let header = CaptionSlot()
  private let footer = CaptionSlot()

  private var size: float2 = .zero
  /// Each live row's height, committed by `calcSize` for `calcPosition`.
  private var rowHeights: [Float] = []

  public init(_ header: String = "", footer: String = "", @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()
    self.header.caption.text = header
    self.footer.caption.text = footer
    self.applyContent(content())
  }

  public convenience init(
    @UIElementBuilder content: () -> [UIElement], @UIElementBuilder header: () -> [UIElement],
    @UIElementBuilder footer: () -> [UIElement] = { [] }
  ) {
    self.init(content: content)
    self.header.setViews(header(), nil, animation: nil)
    self.footer.setViews(footer(), nil, animation: nil)
  }

  public convenience init(
    _ header: String = "", @UIElementBuilder content: () -> [UIElement], @UIElementBuilder footer: () -> [UIElement]
  ) {
    self.init(header, content: content)
    self.footer.setViews(footer(), nil, animation: nil)
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "Section(header: \"\(self.header.caption.text)\", rows: \(self.liveChildrenCount))")
    for child in self.children {
      child.debugHierarchy(offset + "  ")
    }
  }

  // The card first, so it is drawn under the rows.
  override func forEachChild(_ body: (UIElement) -> Void) {
    body(self.card)
    body(self.header)
    self.children.forEach(body)
    body(self.footer)
  }

  override func forEachChildInPaintOrder(_ body: (UIElement) -> Void) {
    self.forEachChild(body)
  }

  // MARK: - Setters and doors

  public func setHeader(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.header.setCaption(value, context, animation: animation)
  }

  public func setFooter(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.footer.setCaption(value, context, animation: animation)
  }

  /// The door `@Component` attaches `header: { … }` through. Empty goes back to the string.
  public func replaceHeader(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.header.setViews(elements, context, animation: animation)
  }

  /// The door `@Component` attaches `footer: { … }` through.
  public func replaceFooter(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.footer.setViews(elements, context, animation: animation)
  }

  // MARK: - Layout

  private static var inset: Inset { FormMetrics.rowInset }

  /// A header's or footer's height with its gap to the card, or 0 when it shows nothing.
  private func captionHeight(_ slot: CaptionSlot, _ size: float2) -> Float {
    slot.isEmpty ? 0 : size.y + FormMetrics.captionGap
  }

  /// What rows are offered: the card's width less the row inset, and their ideal height.
  private func rowProposal(_ width: Float) -> ProposedSize {
    ProposedSize(width: max(width - Self.inset.left - Self.inset.right, 0), height: nil)
  }

  /// Its rows' widest ideal width, inset; what it takes when offered no width.
  private func idealWidth() -> Float {
    var width = self.header.isEmpty ? 0 : self.header.measure(.unspecified).x
    for child in self.children where !child.isLeaving {
      width = max(width, child.measure(.unspecified).x)
    }
    return width + Self.inset.left + Self.inset.right
  }

  private func width(for proposal: ProposedSize) -> Float {
    guard let width = proposal.width, width.isFinite else { return self.idealWidth() }
    return width
  }

  // Fills the width it is offered; as tall as its rows and captions.
  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let width = self.width(for: proposal)
    let rows = self.rowProposal(width)
    var height = self.captionHeight(self.header, self.header.measure(rows))
    for child in self.children where !child.isLeaving {
      height += RowLayout.height(child.measure(rows).y, Self.inset)
    }
    height += self.captionHeight(self.footer, self.footer.measure(rows))
    return float2(width, height)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    let width = self.width(for: proposal)
    let rows = self.rowProposal(width)
    var height = self.captionHeight(self.header, self.header.calcSize(rows))
    self.rowHeights.removeAll(keepingCapacity: true)
    for child in self.children where !child.isLeaving {
      let row = RowLayout.height(child.calcSize(rows).y, Self.inset)
      self.rowHeights.append(row)
      height += row
    }
    height += self.captionHeight(self.footer, self.footer.calcSize(rows))
    self.size = float2(width, height)
    return self.size
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcPosition(_ position: float2) {
    let leading = position.x + Self.inset.left
    var y = position.y

    self.place(self.header, at: float2(leading, y), in: position)
    y += self.captionHeight(self.header, self.header.getSize())

    let cardTop = y
    y = RowLayout.place(self, rows: self.children, heights: self.rowHeights, inset: Self.inset,
                        leading: leading, top: y, in: position, separators: &self.card.separators)
    self.card.position = float2(position.x, cardTop)
    self.card.size = float2(self.size.x, y - cardTop)

    if !self.footer.isEmpty {
      y += FormMetrics.captionGap
    }
    self.place(self.footer, at: float2(leading, y), in: position)

    self.placeLeaving(in: position)
  }
}

/// A section's header or footer: its caption string, or views in its place.
final class CaptionSlot : VStack {
  let caption = Text("").font(FormMetrics.captionFont).foregroundColor(FormMetrics.secondaryColor)
  private var hasViews = false

  init() {
    super.init(alignment: .leading, spacing: 2)
    self.applyContent([self.caption])
  }

  /// Shows nothing: no views, and an empty caption.
  var isEmpty: Bool { !self.hasViews && self.caption.text.isEmpty }

  func setCaption(_ value: String, _ context: UIContext, animation: UIAnimation?) {
    guard value != self.caption.text else { return }
    self.caption.setText(value, context, animation: animation)
  }

  func setViews(_ elements: [UIElement], _ context: UIContext?, animation: UIAnimation?) {
    for element in elements {
      // Only what was left at the defaults: a colour or font set on purpose stays.
      guard let text = element as? Text else { continue }
      if text.font.size == 16, text.font.font == nil {
        _ = text.font(FormMetrics.captionFont)
      }
      if text.color == .black {
        _ = text.foregroundColor(FormMetrics.secondaryColor)
      }
    }
    self.hasViews = !elements.isEmpty
    let shown = self.hasViews ? elements : [self.caption]
    if let context {
      self.replaceChildren(shown, context, animation: animation)
    } else {
      self.applyContent(shown)
    }
  }
}

/// How form rows are stacked: each at least `FormMetrics.rowMinHeight` tall inside its inset,
/// its content centred vertically, with a separator between one row and the next. Shared by a
/// section's card and a disclosure group's content.
@MainActor
enum RowLayout {
  static func height(_ contentHeight: Float, _ inset: Inset) -> Float {
    max(contentHeight, FormMetrics.rowMinHeight) + inset.top + inset.bottom
  }

  /// Places the live rows from `top` down, and records where each separator runs, from `top`.
  /// Returns the bottom of the last row.
  static func place(
    _ container: UIElement, rows: [UIElement], heights: [Float], inset: Inset,
    leading: Float, top: Float, in origin: float2, separatorAbove: Bool = false, separators: inout [Float]
  ) -> Float {
    separators.removeAll(keepingCapacity: true)
    var y = top
    var row = 0
    for child in rows where !child.isLeaving {
      let height = heights[row]
      if row > 0 || separatorAbove {
        separators.append(y - top)
      }
      let content = height - inset.top - inset.bottom
      container.place(child, at: float2(leading, y + inset.top + (content - child.getSize().y) * 0.5), in: origin)
      y += height
      row += 1
    }
    return y
  }

  /// Draws hairlines across `size.x`, from `leading` in, at each of `separators` below `origin`.
  static func drawSeparators(
    _ renderer: Graphics2D, _ separators: [Float], origin: float2, size: float2, leading: Float, scale: Float, opacity: Float
  ) {
    var line = FormMetrics.separatorColor
    line.w *= opacity
    let length = size.x - leading
    guard length > 0 else { return }
    let thickness = 1 / max(renderer.pixelsPerPoint, 1)
    for y in separators {
      // origin -> centre
      renderer.draw(square: Square(
        position: origin + float2(leading + length * 0.5, y * scale),
        size: float2(length, thickness), color: line
      ))
    }
  }
}

/// A section's rounded card and the separators between its rows. Laid out by its section.
final class SectionCard : FormGraphic {
  /// Where each separator runs, from the card's top.
  var separators: [Float] = []

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    guard size.y > 0 else { return }
    var card = FormMetrics.cardColor
    card.w *= opacity
    renderer.draw(
      roundedRect: origin, size: size,
      radii: float4(repeating: FormMetrics.cardCornerRadius * scale), color: card
    )
    RowLayout.drawSeparators(
      renderer, self.separators, origin: origin, size: size,
      leading: FormMetrics.rowInset.left * scale, scale: scale, opacity: opacity
    )
  }
}

/// Rows one under another with a separator above each, as in a section but without the card or
/// the side inset: a disclosure group's content, inside a section's row. The last row leaves its
/// bottom inset to the row it is in.
final class RowStack : MultiChildElement {
  private static var inset: Inset { Inset(top: FormMetrics.rowInset.top, bottom: FormMetrics.rowInset.bottom) }

  private let lines = RowSeparators()
  private var size: float2 = .zero
  private var rowHeights: [Float] = []

  override init() {
    super.init()
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    body(self.lines)
    self.children.forEach(body)
  }

  override func forEachChildInPaintOrder(_ body: (UIElement) -> Void) {
    self.forEachChild(body)
  }

  // Each row is laid out with its full inset, but the stack stops short of the last row's
  // bottom inset: the row the stack sits in has one of its own.
  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let rows = ProposedSize(width: proposal.width, height: nil)
    var size = float2.zero
    for child in self.children where !child.isLeaving {
      let child = child.measure(rows)
      size.x = max(size.x, child.x)
      size.y += RowLayout.height(child.y, Self.inset)
    }
    return self.trimmed(size, proposal)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    let rows = ProposedSize(width: proposal.width, height: nil)
    self.rowHeights.removeAll(keepingCapacity: true)
    var size = float2.zero
    for child in self.children where !child.isLeaving {
      let childSize = child.calcSize(rows)
      let height = RowLayout.height(childSize.y, Self.inset)
      self.rowHeights.append(height)
      size.x = max(size.x, childSize.x)
      size.y += height
    }
    self.size = self.trimmed(size, proposal)
    return self.size
  }

  private func trimmed(_ size: float2, _ proposal: ProposedSize) -> float2 {
    var size = size
    if size.y > 0 { size.y -= Self.inset.bottom }
    if let width = proposal.width, width.isFinite { size.x = width }
    return size
  }

  override func getSize() -> float2 {
    self.size
  }

  override func calcPosition(_ position: float2) {
    _ = RowLayout.place(self, rows: self.children, heights: self.rowHeights, inset: Self.inset, leading: position.x,
                        top: position.y, in: position, separatorAbove: true, separators: &self.lines.separators)
    self.lines.position = position
    self.lines.size = self.size
    self.placeLeaving(in: position)
  }
}

/// A row stack's separators.
final class RowSeparators : FormGraphic {
  var separators: [Float] = []

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    RowLayout.drawSeparators(renderer, self.separators, origin: origin, size: size, leading: 0, scale: scale, opacity: opacity)
  }
}
