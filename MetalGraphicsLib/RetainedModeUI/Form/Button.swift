import simd

/// What a button does, which decides how it looks: a destructive one is red.
public enum ButtonRole : Sendable {
  case destructive
  case cancel
}

/// A tappable title in the accent color, dimmed while pressed: `Button("Save") { self.save() }`.
public final class Button : FormControl {
  /// What a tap runs. `@Component` arms it on mount and clears it on unmount, like `onTap`.
  public var action: (() -> Void)?
  public let role: ButtonRole?

  private let title: Text
  private let press: EffectElement

  public init(_ title: String, role: ButtonRole? = nil, action: (() -> Void)? = nil) {
    self.action = action
    self.role = role
    let color = role == .destructive ? FormMetrics.destructiveColor : FormMetrics.accentColor
    let title = Text(title).font(FormMetrics.font).foregroundColor(color)
    let press = EffectElement { title }
    self.title = title
    self.press = press
    let hit = HittableView(onTap: nil) { press }
    super.init(content: hit)
    hit.onTap = { [unowned self] _ in
      guard !self.isDisabled else { return }
      self.action?()
    }
    hit.onPress = { [unowned self] pressed, _ in
      guard let context = self.context else { return }
      self.press.setOpacity(pressed && !self.isDisabled ? 0.45 : 1, context)
    }
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.title.text else { return }
    self.title.setText(value, context, animation: animation)
  }
}
