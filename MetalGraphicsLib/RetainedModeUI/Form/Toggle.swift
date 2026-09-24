import simd

/// A switch with a label: `Toggle("Wi-Fi", isOn: $wifi)`. A click anywhere on the row flips it,
/// and the knob slides.
public final class Toggle : FormControl {
  public private(set) var isOn: Bool
  /// Where a flip is reported. `@Component` arms it with the binding's write-back.
  public var onIsOnChange: ((Bool) -> Void)?

  private let label: Text
  private let knob = ToggleSwitch()

  /// What `@Component` builds: the value, and the change reported apart.
  public init(_ label: String, isOn: Bool, onIsOnChange: ((Bool) -> Void)? = nil) {
    self.isOn = isOn
    self.onIsOnChange = onIsOnChange
    let label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    self.label = label
    self.knob.progress = isOn ? 1 : 0
    let knob = self.knob
    let row = HittableView(onTap: nil) {
      HStack(spacing: FormMetrics.labelSpacing) {
        label
        Spacer()
        knob
      }
    }
    super.init(content: row)
    row.onTap = { [unowned self] _ in self.flip() }
  }

  /// A hand-built toggle over a binding. In a `@Component` body `$state` is lowered instead, and
  /// this is never called.
  public convenience init(_ label: String, isOn: Binding<Bool>) {
    self.init(label, isOn: isOn.wrappedValue)
    self.onIsOnChange = { [unowned self] value in
      isOn.wrappedValue = value
      if let context = self.context { self.setIsOn(isOn.wrappedValue, context) }
    }
  }

  private func flip() {
    guard !self.isDisabled, let report = self.onIsOnChange else { return }
    let value = !self.isOn
    self.commit { report(value) }
  }

  public func setIsOn(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.isOn else { return }
    self.isOn = value
    self.knob.setProgress(value ? 1 : 0, context, animation: self.animation(animation))
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }
}

/// A capsule track and a round knob; `progress` 0 is off, 1 on.
final class ToggleSwitch : FormGraphic {
  static let trackSize = float2(38, 22)
  static let knobInset: Float = 2

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    Self.trackSize
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let t = self.progress
    var track = mix(FormMetrics.fillColor, FormMetrics.accentColor, t)
    track.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: size.y * 0.5), color: track)

    let inset = Self.knobInset * scale
    let diameter = size.y - inset * 2
    let x = origin.x + inset + (size.x - diameter - inset * 2) * t
    // A soft rim under the knob, so it reads on the light track.
    renderer.draw(
      roundedRect: float2(x, origin.y + inset) - 0.5 * scale, size: float2(repeating: diameter + scale),
      radii: float4(repeating: (diameter + scale) * 0.5), color: float4(0, 0, 0, 0.12 * opacity)
    )
    renderer.draw(
      roundedRect: float2(x, origin.y + inset), size: float2(repeating: diameter),
      radii: float4(repeating: diameter * 0.5), color: float4(1, 1, 1, opacity)
    )
  }
}
