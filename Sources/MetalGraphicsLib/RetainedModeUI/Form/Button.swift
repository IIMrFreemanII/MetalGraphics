import simd

/// What a button does, which decides how it looks: a destructive one is red.
public enum ButtonRole : Sendable {
  case destructive
  case cancel
}

/// How a `Button` looks: `.buttonStyle(.borderedProminent)`. The role tints each of them red
/// when destructive.
public enum ButtonStyle : Sendable {
  /// The form's own: `borderless`.
  case automatic
  /// The label in the accent color, dimmed while pressed.
  case borderless
  /// The label as it is, in the label color, dimmed while pressed.
  case plain
  /// A light tinted bezel behind a tinted label, darker while pressed.
  case bordered
  /// A bezel filled with the tint behind a white label, darker while pressed.
  case borderedProminent

  var isBordered: Bool { self == .bordered || self == .borderedProminent }
}

/// A tappable label: `Button("Save") { self.save() }`, or any elements as the label,
/// `Button(action: self.close) { Image(…); Text("Close") }` or
/// `Button { self.save() } label: { Text("Save") }`.
///
/// The label's elements sit side by side. Every `Text` in the label, however deep, draws in the
/// style's color and follows later style changes, unless it was colored on purpose; it takes the
/// form's font unless a font was set on it or around the button.
public class Button : FormControl {
  /// What a tap runs. `@Component` arms it on mount and clears it on unmount, like `onTap`.
  public var action: (() -> Void)?
  /// Runs after `action`: set by the alert or dialog the button is in, which it dismisses.
  var presentationAction: (() -> Void)?
  public let role: ButtonRole?
  public private(set) var style: ButtonStyle = .automatic

  /// The title of `Button("Save")`; nil for a button built with a label.
  let title: Text?
  private let press: EffectElement
  let face: ButtonFace
  private let label: HStack
  /// Around the label: the style's color and the form's font, for the texts in it.
  private let labelStyle: TextStyleElement
  /// What the pointer hits: the whole button.
  private let hit: HittableView

  public convenience init(_ title: String, role: ButtonRole? = nil, action: (() -> Void)? = nil) {
    let text = Text(title)
    self.init(role: role, action: action, title: text) { [text] }
  }

  public convenience init(
    role: ButtonRole? = nil, action: (() -> Void)? = nil, @UIElementBuilder label: () -> [UIElement] = { [] }
  ) {
    self.init(role: role, action: action, title: nil, label: label)
  }

  init(role: ButtonRole?, action: (() -> Void)?, title: Text?, label: () -> [UIElement]) {
    self.action = action
    self.role = role
    self.title = title
    let stack = HStack(spacing: 6)
    self.label = stack
    let labelStyle = TextStyleElement(
      overrides: TextEnvironment().foregroundColor(Self.labelColor(.automatic, role)),
      defaults: TextEnvironment().font(FormMetrics.font)
    ) { stack }
    self.labelStyle = labelStyle
    let face = ButtonFace(role: role) { labelStyle }
    let press = EffectElement { face }
    self.face = face
    self.press = press
    let hit = HittableView(onTap: nil) { press }
    // A pointing hand over it, as over a link.
    hit.pointerStyle = .link
    self.hit = hit
    super.init(content: hit)
    self.label.applyContent(label())
    hit.onTap = { [unowned self] _ in self.performTap() }
    hit.onHover = { [unowned self] hovered, _ in
      guard let context = self.context else { return }
      self.face.setHovered(hovered && !self.isDisabled, context)
    }
    hit.onPress = { [unowned self] pressed, _ in
      guard let context = self.context else { return }
      let pressed = pressed && !self.isDisabled
      if self.style.isBordered {
        self.face.setPressed(pressed, context)
      } else {
        self.press.setOpacity(pressed ? 0.45 : 1, context)
      }
    }
  }

  /// What a tap does: runs the action, unless disabled. Return and Escape in an alert run its
  /// buttons this way too.
  func performTap() -> Void {
    guard !self.isDisabled else { return }
    self.action?()
    self.presentationAction?()
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard let title = self.title, value != title.text else { return }
    title.setText(value, context, animation: animation)
  }

  /// The door `@Component` attaches the label through.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.label.replaceChildren(elements, context, animation: animation)
  }

  public func setButtonStyle(_ value: ButtonStyle, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.style else { return }
    self.style = value
    self.face.setStyle(value, context, animation: animation)
    self.face.setPressed(false, context)
    self.press.setOpacity(1, context)
    self.labelStyle.setForegroundColor(Self.labelColor(value, self.role), context, animation: animation)
  }

  /// Built in `style`: `.buttonStyle(.bordered)`. Sets this button's own style and returns it.
  public func buttonStyle(_ style: ButtonStyle) -> Self {
    guard style != self.style else { return self }
    self.style = style
    self.face.style = style
    self.labelStyle.overrides.foreground = Self.labelColor(style, self.role)
    return self
  }

  /// Its label's weight, over the form's: a split view's selected sidebar link is medium.
  func setLabelWeight(_ weight: TextFont.Weight?, _ context: UIContext) {
    self.labelStyle.restyleLayout(\.weight, weight, context, nil)
  }

  /// The pointer's shape over the button: a pointing hand when never set.
  public func pointerStyle(_ style: PointerStyle?) -> Self {
    self.hit.pointerStyle = style
    return self
  }

  public func setPointerStyle(_ value: PointerStyle?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.hit.setPointerStyle(value, context, animation: animation)
  }

  /// What a label's text is colored in `style`.
  private static func labelColor(_ style: ButtonStyle, _ role: ButtonRole?) -> float4 {
    switch style {
    case .borderedProminent: return .accentForeground
    case .plain, .bordered: return role == .destructive ? FormMetrics.destructiveColor : FormMetrics.labelColor
    case .automatic, .borderless: return ButtonFace.tint(role)
    }
  }
}

/// What a button's label sits on: nothing in the text styles, a rounded bezel in the bordered
/// ones. It is always there, so a style change never rebuilds the button.
final class ButtonFace : UIRenderableElement {
  static let borderedInset = Inset(vertical: 3, horizontal: 10)
  /// A split view's sidebar link: a 26 pt row.
  static let sidebarInset = Inset(vertical: 5, horizontal: 10)
  /// How far the hover highlight of a borderless button reaches past its label, which has no
  /// inset of its own.
  static let hoverOutset = float2(6, 3)
  static let cornerRadius: Float = 6

  let role: ButtonRole?
  fileprivate(set) var style: ButtonStyle = .automatic
  private(set) var isPressed = false
  private(set) var isHovered = false
  /// Marked as a split view's selected sidebar link: drawn on a highlight in any style.
  private(set) var isSelected = false
  /// Takes the whole width it is offered, as a sidebar link does, with the bordered inset.
  var fillsWidth = false
  /// With `fillsWidth`, centers the label in that width, as an alert's buttons do.
  var centersContent = false
  private var contentSize: float2 = .zero
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  init(role: ButtonRole?, @UIElementBuilder content: () -> [UIElement]) {
    self.role = role
    super.init()
    self.applyContent(content())
  }

  static func tint(_ role: ButtonRole?) -> float4 {
    role == .destructive ? FormMetrics.destructiveColor : FormMetrics.accentColor
  }

  private var inset: Inset {
    if self.style.isBordered { return Self.borderedInset }
    return self.fillsWidth ? Self.sidebarInset : Inset()
  }

  func setSelected(_ value: Bool, _ context: UIContext) {
    guard value != self.isSelected else { return }
    self.isSelected = value
    context.invalidate()
  }

  private func filled(_ size: float2, _ proposal: ProposedSize) -> float2 {
    guard self.fillsWidth, let width = proposal.width, width.isFinite else { return size }
    return float2(max(width, size.x), size.y)
  }

  func setStyle(_ value: ButtonStyle, _ context: UIContext, animation: UIAnimation?) {
    guard value != self.style else { return }
    self.style = value
    context.invalidate(.layout, animation: animation)
  }

  func setPressed(_ value: Bool, _ context: UIContext) {
    guard value != self.isPressed else { return }
    self.isPressed = value
    context.invalidate()
  }

  func setHovered(_ value: Bool, _ context: UIContext) {
    guard value != self.isHovered else { return }
    self.isHovered = value
    context.invalidate()
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    self.isPressed = false
    self.isHovered = false
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 {
    self.size
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let inset = self.inset
    return self.filled(inset.inflate(size: self.child?.measure(inset.deflate(proposal)) ?? .zero), proposal)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    let inset = self.inset
    self.contentSize = self.child?.calcSize(inset.deflate(proposal)) ?? .zero
    self.size = self.filled(inset.inflate(size: self.contentSize), proposal)
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    let inset = self.inset
    var offset = float2(inset.left, inset.top)
    if self.centersContent {
      offset.x = max(((self.size.x - self.contentSize.x) * 0.5).rounded(), inset.left)
    }
    self.child?.calcPosition(position + offset)
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    var origin = self.position
    var size = self.size
    var fill: float4
    switch self.style {
    case .borderedProminent:
      // The tint, lighter while hovered, darker while pressed.
      fill = renderer.resolve(Self.tint(self.role))
      let scale: Float = self.isPressed ? 0.82 : (self.isHovered ? 1.1 : 1)
      if scale != 1 {
        fill = float4(min(fill.x * scale, 1), min(fill.y * scale, 1), min(fill.z * scale, 1), fill.w)
      }
    case .bordered:
      fill = renderer.resolve(self.isPressed ? .fillPressed : (self.isHovered ? .fillHover : .fill))
    case .automatic, .borderless, .plain:
      if self.isSelected {
        fill = renderer.resolve(NavigationMetrics.selectionColor)
      } else if self.isHovered && (self.fillsWidth || self.style != .plain) {
        fill = renderer.resolve(.hover)
        if !self.fillsWidth {
          origin -= Self.hoverOutset
          size += Self.hoverOutset * 2
        }
      } else {
        return
      }
    }
    fill.w *= effect.opacity
    let s = effect.scale
    renderer.draw(
      roundedRect: effect.apply(to: origin) - renderer.size * 0.5, size: size * s,
      radii: float4(repeating: Self.cornerRadius * s), color: fill
    )
  }
}
