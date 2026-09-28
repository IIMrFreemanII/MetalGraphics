import simd

/// How a selected `ListRow` is marked.
public enum ListRowSelectionStyle: Sendable {
  /// A tinted highlight, the label as it is but medium weight: a sidebar, a file tree, an outline.
  case standard
  /// Filled with the accent, the label in the accent's foreground: completion, quick open, a menu.
  case prominent
}

/// A problem's severity, as the square a `ListRow` shows before its content.
public enum ListRowStatus: Sendable, Hashable {
  case error
  case warning
  case note

  /// Its colour: destructive, warning, info.
  public var color: float4 {
    switch self {
    case .error: .destructive
    case .warning: .warning
    case .note: .info
    }
  }
}

/// A `ListRow`'s sizes and type for its label, subtitle, detail and status.
public enum ListRowMetrics {
  /// The label over a subtitle; alone, a label takes the font around the row.
  public static let titleFont = TextFont.system(size: 13)
  public static let subtitleFont = TextFont.system(size: 11)
  public static let detailFont = TextFont.system(size: 11.5)
  public static let secondaryColor: float4 = .secondaryLabel
  /// The detail of a selected prominent row, on the accent.
  public static let selectedDetailColor: float4 = .role(.accentForeground, alpha: 0.85)
  /// The status square's side and corner radius.
  public static let statusSide: Float = 8
  public static let statusShape = UIShape.rect(cornerRadius: 2)
  /// Between a label and its subtitle.
  public static let lineSpacing: Float = 1
  /// A two-line row, as the Problems list's.
  public static let twoLineHeight: Float = 38
}

/// One row of a sidebar, tree, outline or list, as the design system draws them: a fixed
/// height, inset from the sides, a rounded highlight while hovered and while selected, the label
/// medium weight when selected. Not in SwiftUI.
///
///     ListRow(selected: self.isActive, indent: depth * 14, action: { self.open() }) {
///       Image(icon: .document).foregroundColor(.hue(.orange))
///       Text(name)
///     }
///
/// The content sits side by side, vertically centred, and takes the row's width: put a `Spacer`
/// in it to push something to the trailing edge. Hover is tracked by the row itself and only
/// redraws.
///
/// Or give it a label, with a subtitle under it, a detail at the trailing edge and a status
/// square before it; the content then goes between the status and the label (a badge, an icon):
///
///     ListRow(message, subtitle: "Sources/App/main.swift:2:1", status: .warning, height: 38, spacing: 10)
public final class ListRow : SingleChildElement {
  /// What a tap runs. `@Component` arms it on mount and clears it on unmount, like `onTap`.
  public var action: (() -> Void)?
  public private(set) var isSelected: Bool
  public let selectionStyle: ListRowSelectionStyle

  /// The label, or nil for a row of content only.
  public private(set) var label: String?
  public private(set) var subtitle: String?
  public private(set) var detail: String?
  public private(set) var status: ListRowStatus?

  private let face: ListRowFace
  private let labelStyle: TextStyleElement
  private let stack: HStack
  private let hit: HittableView
  private weak var context: UIContext?
  /// With a label: the content given, which goes between the status and the label.
  private var accessories: [UIElement] = []
  private var statusMark: Background?
  private var titleText: Text?
  private var subtitleText: Text?
  private var detailText: Text?

  public init(
    selected: Bool = false, selectionStyle: ListRowSelectionStyle = .standard,
    height: Float = 24, margin: Float = 8, indent: Float = 0, spacing: Float = 6,
    action: (() -> Void)? = nil, @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.action = action
    self.isSelected = selected
    self.selectionStyle = selectionStyle
    let stack = HStack(spacing: spacing)
    self.stack = stack
    let labelStyle = TextStyleElement(overrides: Self.labelOverrides(selected, selectionStyle)) { stack }
    self.labelStyle = labelStyle
    let face = ListRowFace(height: height, margin: margin, indent: indent) { labelStyle }
    face.isSelected = selected
    face.selectionStyle = selectionStyle
    self.face = face
    let hit = HittableView(onTap: nil) { face }
    self.hit = hit
    super.init()
    self.applyContent([hit])
    stack.applyContent(content())
    hit.onTap = { [unowned self] _ in self.action?() }
    hit.onHover = { [unowned self] hovered, _ in
      guard let context = self.context else { return }
      self.face.setHovered(hovered, context)
    }
  }

  /// A row with a label: `subtitle` under it in the secondary colour, `detail` at the trailing
  /// edge, `status` as a square before everything. `content` goes between the status and the
  /// label. As with the other init, a lone trailing closure is the `action`: write `content:`
  /// when there is no action.
  public convenience init(
    _ label: String, subtitle: String? = nil, detail: String? = nil, status: ListRowStatus? = nil,
    selected: Bool = false, selectionStyle: ListRowSelectionStyle = .standard,
    height: Float = 24, margin: Float = 8, indent: Float = 0, spacing: Float = 6,
    action: (() -> Void)? = nil, @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.init(
      selected: selected, selectionStyle: selectionStyle, height: height, margin: margin, indent: indent,
      spacing: spacing, action: action
    )
    self.label = label
    self.subtitle = subtitle
    self.detail = detail
    self.status = status
    self.accessories = content()
    self.stack.applyContent(self.labelledContent())
  }

  /// The stack's children with a label: status, accessories, the label (over its subtitle), a
  /// spacer, the detail. Makes the parts it does not have yet.
  private func labelledContent() -> [UIElement] {
    var children: [UIElement] = []
    if let status = self.status {
      let mark = self.statusMark ?? Rectangle(.clear)
        .frame(width: ListRowMetrics.statusSide, height: ListRowMetrics.statusSide)
        .background(status.color, in: ListRowMetrics.statusShape)
      self.statusMark = mark
      children.append(mark)
    }
    children.append(contentsOf: self.accessories)
    let title = self.titleText ?? Text(self.label ?? "").lineLimit(1)
    self.titleText = title
    if let subtitle = self.subtitle {
      let second = self.subtitleText ?? Text(subtitle)
        .font(ListRowMetrics.subtitleFont)
        .foregroundColor(ListRowMetrics.secondaryColor)
        .lineLimit(1)
      self.subtitleText = second
      _ = title.font(ListRowMetrics.titleFont)
      children.append(VStack(alignment: .leading, spacing: ListRowMetrics.lineSpacing) { title; second })
    } else {
      children.append(title)
    }
    children.append(Spacer())
    if let detail = self.detail {
      let text = self.detailText ?? Text(detail)
        .font(ListRowMetrics.detailFont)
        .foregroundColor(self.detailColor)
        .lineLimit(1)
      self.detailText = text
      children.append(text)
    }
    return children
  }

  private var detailColor: float4 {
    self.isSelected && self.selectionStyle == .prominent ? ListRowMetrics.selectedDetailColor : ListRowMetrics.secondaryColor
  }

  /// Lays the labelled parts out anew, after one came or went: made afresh, as a title moves in
  /// and out of its subtitle's stack. Once per such change, never per frame.
  private func relayoutParts(_ context: UIContext, _ animation: UIAnimation?) {
    self.statusMark = nil
    self.titleText = nil
    self.subtitleText = nil
    self.detailText = nil
    self.stack.replaceChildren(self.labelledContent(), context, animation: animation)
  }

  /// The label, for a row made with one.
  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label else { return }
    self.label = value
    self.titleText?.setText(value, context, animation: animation)
  }

  /// A second line under the label, or nil for none.
  public func setSubtitle(_ value: String?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.subtitle, self.label != nil else { return }
    let had = self.subtitle != nil
    self.subtitle = value
    if let value, had {
      self.subtitleText?.setText(value, context, animation: animation)
    } else {
      self.relayoutParts(context, animation)
    }
  }

  /// What shows at the trailing edge, or nil for nothing.
  public func setDetail(_ value: String?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.detail, self.label != nil else { return }
    let had = self.detail != nil
    self.detail = value
    if let value, had {
      self.detailText?.setText(value, context, animation: animation)
    } else {
      self.relayoutParts(context, animation)
    }
  }

  /// The square before the content, or nil for none.
  public func setStatus(_ value: ListRowStatus?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.status, self.label != nil else { return }
    let had = self.status != nil
    self.status = value
    if let value, had, let mark = self.statusMark {
      mark.setColor(value.color, context)
    } else {
      self.relayoutParts(context, animation)
    }
  }

  private static func labelOverrides(_ selected: Bool, _ style: ListRowSelectionStyle) -> TextEnvironment {
    guard selected else { return TextEnvironment() }
    switch style {
    case .standard: return TextEnvironment().fontWeight(.medium)
    case .prominent: return TextEnvironment().foregroundColor(.accentForeground)
    }
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func unmount(_ context: UIContext) {
    self.context = nil
  }

  /// Marks it selected or not. Standard rows change weight, so lay out again; prominent ones
  /// only redraw.
  public func setSelected(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.isSelected else { return }
    self.isSelected = value
    self.face.setSelected(value, context)
    switch self.selectionStyle {
    case .standard:
      self.labelStyle.restyleLayout(\.weight, value ? .medium : nil, context, animation)
    case .prominent:
      self.labelStyle.setForegroundColor(value ? .accentForeground : nil, context)
      self.detailText?.setForegroundColor(self.detailColor, context)
    }
  }

  /// The door `@Component` attaches the content through: with a label, the accessories.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    if self.label != nil {
      self.accessories = elements
      self.relayoutParts(context, animation)
    } else {
      self.stack.replaceChildren(elements, context, animation: animation)
    }
  }

  /// The pointer's shape over the row: the arrow unless set.
  public func pointerStyle(_ style: PointerStyle?) -> Self {
    self.hit.pointerStyle = style
    return self
  }
}

/// What a `ListRow`'s content sits on: its height, its inset and its highlight.
final class ListRowFace : UIRenderableElement {
  let height: Float
  let margin: Float
  let indent: Float
  var isSelected = false
  var selectionStyle: ListRowSelectionStyle = .standard
  private(set) var isHovered = false
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero
  private var contentSize: float2 = .zero

  /// From the highlight's edges to the content.
  static let padding: Float = 8

  init(height: Float, margin: Float, indent: Float, @UIElementBuilder content: () -> [UIElement]) {
    self.height = height
    self.margin = margin
    self.indent = indent
    super.init()
    self.applyContent(content())
  }

  func setSelected(_ value: Bool, _ context: UIContext) {
    guard value != self.isSelected else { return }
    self.isSelected = value
    context.invalidate()
  }

  func setHovered(_ value: Bool, _ context: UIContext) {
    guard value != self.isHovered else { return }
    self.isHovered = value
    context.invalidate()
  }

  private var leading: Float { self.margin + Self.padding + self.indent }
  private var trailing: Float { self.margin + Self.padding }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    self.isHovered = false
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 {
    self.size
  }

  private func contentProposal(_ proposal: ProposedSize) -> ProposedSize {
    ProposedSize(width: proposal.width.map { max($0 - self.leading - self.trailing, 0) }, height: self.height)
  }

  /// As wide as it is offered, or as its content when offered any width.
  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let content = self.child?.measure(self.contentProposal(proposal)) ?? .zero
    return self.fitted(content, proposal)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    var content = self.contentProposal(proposal)
    if let width = content.width, width.isFinite {
      content.width = width
    }
    self.contentSize = self.child?.calcSize(content) ?? .zero
    self.size = self.fitted(self.contentSize, proposal)
    return self.size
  }

  private func fitted(_ content: float2, _ proposal: ProposedSize) -> float2 {
    let natural = content.x + self.leading + self.trailing
    guard let width = proposal.width, width.isFinite else { return float2(natural, self.height) }
    return float2(max(width, natural), self.height)
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    let y = ((self.height - self.contentSize.y) * 0.5).rounded()
    self.child?.calcPosition(position + float2(self.leading, y))
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard self.isSelected || self.isHovered, effect.opacity > 0 else { return }
    let color: float4
    if self.isSelected {
      color = self.selectionStyle == .prominent ? .accent : .selection
    } else {
      color = .hover
    }
    let s = effect.scale
    let origin = effect.apply(to: self.position + float2(self.margin, 0)) - renderer.size * 0.5
    let size = float2(max(self.size.x - self.margin * 2, 0), self.size.y) * s
    renderer.draw(
      roundedRect: origin, size: size, radii: float4(repeating: renderer.theme.radii.md * s),
      color: renderer.resolve(color).withAlpha(effect.opacity)
    )
  }
}

/// A symbol's kind as a small coloured tile with a letter: C for a class, S a struct, M a
/// method. Not in SwiftUI.
///
///     KindBadge("S", color: .hue(.badgeStruct))
///     KindBadge("S", color: KindBadge.color(forLetter: "S"))
public final class KindBadge : UIRenderableElement {
  public static let side: Float = 16

  /// The palette hue for a kind's letter: M method, P property, V variable, C class, S struct,
  /// E (or c, a case) enum, Pr protocol; grey for anything else.
  public static func color(forLetter letter: String) -> float4 {
    switch letter {
    case "M": .hue(.badgeMethod)
    case "P": .hue(.badgeProperty)
    case "V": .hue(.badgeVariable)
    case "C": .hue(.badgeClass)
    case "S": .hue(.badgeStruct)
    case "E", "c": .hue(.badgeEnum)
    case "Pr": .hue(.indigo)
    default: .hue(.gray)
    }
  }
  public private(set) var color: float4
  private let text: Text
  private(set) var position: float2 = .zero

  public init(_ letter: String, color: float4) {
    self.color = color
    self.text = Text(letter)
      .font(.system(size: 10, weight: .bold))
      .foregroundColor(.accentForeground)
      .lineLimit(1)
    super.init()
    self.applyContent([self.text])
  }

  public func setLetter(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.text.setText(value, context, animation: animation)
  }

  public func setColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.color else { return }
    self.color = value
    context.invalidate()
  }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 {
    float2(repeating: Self.side)
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    float2(repeating: Self.side)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    _ = self.text.calcSize(ProposedSize(width: nil, height: nil))
    return float2(repeating: Self.side)
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
    let textSize = self.text.getSize()
    self.text.calcPosition(position + ((float2(repeating: Self.side) - textSize) * 0.5).rounded(.toNearestOrAwayFromZero))
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let s = effect.scale
    renderer.draw(
      roundedRect: effect.apply(to: self.position) - renderer.size * 0.5, size: float2(repeating: Self.side * s),
      radii: float4(repeating: 4 * s), color: renderer.resolve(self.color).withAlpha(effect.opacity)
    )
  }
}
