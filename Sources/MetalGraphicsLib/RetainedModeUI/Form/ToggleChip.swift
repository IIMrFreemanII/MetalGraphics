import simd

/// A `ToggleChip`'s type, padding and shape.
public enum ToggleChipMetrics {
  public static let font = TextFont.system(size: 11.5, weight: .semibold)
  public static let inset = Inset(vertical: 3, horizontal: 8)
  public static let shape = UIShape.rect(cornerRadius: 5)
  public static let onColor: float4 = .selection
  public static let offColor: float4 = .clear
}

/// A small on/off chip: a find bar's Aa, Word and .* options. On, it sits on the selection
/// colour. Not in SwiftUI.
///
///     ToggleChip("Aa", isOn: $caseSensitive)
public final class ToggleChip : SingleChildElement {
  public private(set) var isOn: Bool
  /// Where a flip is reported. `@Component` arms it with the binding's write-back.
  public var onIsOnChange: ((Bool) -> Void)?

  private let button: Button
  private let fill: Background

  /// What `@Component` builds: the value, and the change reported apart.
  public init(_ title: String, isOn: Bool, onIsOnChange: ((Bool) -> Void)? = nil) {
    self.isOn = isOn
    self.onIsOnChange = onIsOnChange
    let button = Button(title, action: nil).buttonStyle(isOn ? .borderless : .plain)
    self.button = button
    let fill = button
      .font(ToggleChipMetrics.font)
      .padding(ToggleChipMetrics.inset)
      .background(isOn ? ToggleChipMetrics.onColor : ToggleChipMetrics.offColor, in: ToggleChipMetrics.shape)
    self.fill = fill
    super.init()
    self.applyContent([fill])
    button.action = { [unowned self] in self.onIsOnChange?(!self.isOn) }
  }

  /// A hand-built chip over a binding. In a `@Component` body `$state` is lowered instead.
  public convenience init(_ title: String, isOn: Binding<Bool>) {
    self.init(title, isOn: isOn.wrappedValue)
    self.onIsOnChange = { [unowned self] value in
      isOn.wrappedValue = value
      if let context = self.context { self.setIsOn(isOn.wrappedValue, context) }
    }
  }

  private weak var context: UIContext?

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func unmount(_ context: UIContext) {
    self.context = nil
  }

  public func setIsOn(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.isOn else { return }
    self.isOn = value
    self.button.setButtonStyle(value ? .borderless : .plain, context)
    self.fill.setColor(value ? ToggleChipMetrics.onColor : ToggleChipMetrics.offColor, context, animation: animation)
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.button.setTitle(value, context, animation: animation)
  }
}
