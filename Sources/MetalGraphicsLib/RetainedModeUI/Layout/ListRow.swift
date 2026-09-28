import simd

/// How a selected `ListRow` is marked.
public enum ListRowSelectionStyle: Sendable {
  /// A tinted highlight, the label as it is but medium weight: a sidebar, a file tree, an outline.
  case standard
  /// Filled with the accent, the label in the accent's foreground: completion, quick open, a menu.
  case prominent
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
public final class ListRow : SingleChildElement {
  /// What a tap runs. `@Component` arms it on mount and clears it on unmount, like `onTap`.
  public var action: (() -> Void)?
  public private(set) var isSelected: Bool
  public let selectionStyle: ListRowSelectionStyle

  private let face: ListRowFace
  private let labelStyle: TextStyleElement
  private let stack: HStack
  private let hit: HittableView
  private weak var context: UIContext?

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
    }
  }

  /// The door `@Component` attaches the content through.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.stack.replaceChildren(elements, context, animation: animation)
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
public final class KindBadge : UIRenderableElement {
  public static let side: Float = 16
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
