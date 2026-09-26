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
/// The label's elements sit side by side. A `Text` directly in the label, left at the default
/// color and font, takes the style's color and the form's font, and follows later style changes;
/// one colored on purpose keeps its color, and a `Text` nested deeper (in a stack inside the
/// label) is left alone.
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
  /// The label's texts this button colored, recolored when the style changes.
  private var tinted: [Text] = []

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
    let face = ButtonFace(role: role) { stack }
    let press = EffectElement { face }
    self.face = face
    self.press = press
    let hit = HittableView(onTap: nil) { press }
    super.init(content: hit)
    let elements = label()
    self.adopt(elements)
    self.label.applyContent(elements)
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
    self.adopt(elements)
    self.label.replaceChildren(elements, context, animation: animation)
  }

  public func setButtonStyle(_ value: ButtonStyle, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.style else { return }
    self.style = value
    self.face.setStyle(value, context, animation: animation)
    self.face.setPressed(false, context)
    self.press.setOpacity(1, context)
    let color = self.labelColor
    for text in self.tinted {
      text.setForegroundColor(color, context, animation: animation)
    }
  }

  /// Built in `style`: `.buttonStyle(.bordered)`. Sets this button's own style and returns it.
  public func buttonStyle(_ style: ButtonStyle) -> Self {
    guard style != self.style else { return self }
    self.style = style
    self.face.style = style
    let color = self.labelColor
    for text in self.tinted {
      _ = text.foregroundColor(color)
    }
    return self
  }

  /// What a label's text is colored in this style.
  private var labelColor: float4 {
    switch self.style {
    case .borderedProminent: return float4(1, 1, 1, 1)
    case .plain: return self.role == .destructive ? FormMetrics.destructiveColor : FormMetrics.labelColor
    case .automatic, .borderless, .bordered: return ButtonFace.tint(self.role)
    }
  }

  /// Styles the label's texts left at the defaults, and remembers them for a later style change.
  /// Texts that left the label are forgotten.
  private func adopt(_ elements: [UIElement]) {
    self.tinted.removeAll(keepingCapacity: true)
    let color = self.labelColor
    for element in elements {
      guard let text = element as? Text else { continue }
      if text.font.size == 16, text.font.font == nil {
        _ = text.font(FormMetrics.font)
      }
      // Either never colored, or colored by this button before a branch brought it back.
      if text.color == .black || self.adopted.contains(ObjectIdentifier(text)) {
        _ = text.foregroundColor(color)
        self.tinted.append(text)
      }
    }
    for text in self.tinted {
      self.adopted.insert(ObjectIdentifier(text))
    }
  }

  /// Every text this button has colored: a branch swap brings a text back already colored, and
  /// it has to be told apart from one colored on purpose.
  private var adopted: Set<ObjectIdentifier> = []
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
