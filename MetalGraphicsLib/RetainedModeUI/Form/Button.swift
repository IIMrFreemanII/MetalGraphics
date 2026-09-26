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
public final class Button : FormControl {
  /// What a tap runs. `@Component` arms it on mount and clears it on unmount, like `onTap`.
  public var action: (() -> Void)?
  public let role: ButtonRole?
  public private(set) var style: ButtonStyle = .automatic

  /// The title of `Button("Save")`; nil for a button built with a label.
  private let title: Text?
  private let press: EffectElement
  private let face: ButtonFace
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

  private init(role: ButtonRole?, action: (() -> Void)?, title: Text?, label: () -> [UIElement]) {
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
    hit.onTap = { [unowned self] _ in
      guard !self.isDisabled else { return }
      self.action?()
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
    case .borderedProminent: return float4(1, 1, 1, 1)
    case .plain: return role == .destructive ? FormMetrics.destructiveColor : FormMetrics.labelColor
    case .automatic, .borderless, .bordered: return ButtonFace.tint(role)
    }
  }
}

/// What a button's label sits on: nothing in the text styles, a rounded bezel in the bordered
/// ones. It is always there, so a style change never rebuilds the button.
final class ButtonFace : UIRenderableElement {
  static let borderedInset = Inset(vertical: 3, horizontal: 10)
  static let cornerRadius: Float = 6

  let role: ButtonRole?
  fileprivate(set) var style: ButtonStyle = .automatic
  private(set) var isPressed = false
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
    self.style.isBordered ? Self.borderedInset : Inset()
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

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    self.isPressed = false
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 {
    self.size
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let inset = self.inset
    return inset.inflate(size: self.child?.measure(inset.deflate(proposal)) ?? .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    let inset = self.inset
    self.size = inset.inflate(size: self.child?.calcSize(inset.deflate(proposal)) ?? .zero)
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    let inset = self.inset
    self.child?.calcPosition(position + float2(inset.left, inset.top))
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard self.style.isBordered, effect.opacity > 0 else { return }
    let tint = Self.tint(self.role)
    var fill = self.style == .borderedProminent ? tint : float4(tint.x, tint.y, tint.z, 0.15)
    if self.isPressed {
      fill = float4(fill.x * 0.8, fill.y * 0.8, fill.z * 0.8, self.style == .borderedProminent ? fill.w : 0.28)
    }
    fill.w *= effect.opacity
    let s = effect.scale
    renderer.draw(
      roundedRect: effect.apply(to: self.position) - renderer.size * 0.5, size: self.size * s,
      radii: float4(repeating: Self.cornerRadius * s), color: fill
    )
  }
}
