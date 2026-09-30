import simd

/// A value stepped down and up with a − and a + button: `Stepper("Lives: \(self.lives)",
/// value: $lives, in: 1 ... 9)`. Each button dims at its end of the range.
///
/// Works in `Double`; the state keeps its own integer or floating-point type.
public final class Stepper : FormControl {
  public private(set) var value: Double
  public let range: ClosedRange<Double>
  public let step: Double
  /// Where a step reports the new value. `@Component` arms it with the binding's write-back,
  /// through `adapt`.
  public var onValueChange: ((Double) -> Void)?

  private let label: Text
  private let decrement = StepperGlyph(plus: false)
  private let increment = StepperGlyph(plus: true)
  /// The keys' − and +: the animated glyphs, playing as the pointer is on their key, and active
  /// (dimmed, shaking "no" when pressed) at the end of the range.
  private let decrementIcon = AnimatedIcon(.stepperMinus).foregroundColor(FormMetrics.labelColor)
  private let incrementIcon = AnimatedIcon(.stepperPlus).foregroundColor(FormMetrics.labelColor)

  init(_ label: String, value: Double, range: ClosedRange<Double>, step: Double, onValueChange: ((Double) -> Void)?) {
    self.value = value
    self.range = range
    self.step = step
    self.onValueChange = onValueChange
    let label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    self.label = label
    let (decrement, increment) = (self.decrement, self.increment)
    let (minus, plus) = (self.decrementIcon, self.incrementIcon)
    let down = HittableView(onTap: nil) { decrement.overlay { minus } }
    let up = HittableView(onTap: nil) { increment.overlay { plus } }
    super.init(content: HStack(spacing: FormMetrics.labelSpacing) {
      label
      Spacer()
      Background(FormMetrics.fillColor, in: .rect(cornerRadius: 6)) {
        // The fill shows round and between the keys, outlining them.
        HStack(spacing: 1) { down; up }.padding(1)
      }
    })
    down.onTap = { [unowned self] _ in self.advance(by: -1) }
    up.onTap = { [unowned self] _ in self.advance(by: 1) }
    self.updateEnds(nil)
  }

  public convenience init<V: BinaryInteger>(
    _ label: String, value: V, in range: ClosedRange<V>? = nil, step: V = 1,
    onValueChange: ((Double) -> Void)? = nil
  ) {
    self.init(
      label, value: Double(value),
      range: range.map { Double($0.lowerBound) ... Double($0.upperBound) } ?? -Double.infinity ... Double.infinity,
      step: Double(step), onValueChange: onValueChange
    )
  }

  public convenience init<V: BinaryFloatingPoint>(
    _ label: String, value: V, in range: ClosedRange<V>? = nil, step: V = 1,
    onValueChange: ((Double) -> Void)? = nil
  ) {
    self.init(
      label, value: Double(value),
      range: range.map { Double($0.lowerBound) ... Double($0.upperBound) } ?? -Double.infinity ... Double.infinity,
      step: Double(step), onValueChange: onValueChange
    )
  }

  /// A hand-built stepper over a binding. In a `@Component` body `$state` is lowered instead.
  public convenience init<V: BinaryInteger>(_ label: String, value: Binding<V>, in range: ClosedRange<V>? = nil, step: V = 1) {
    self.init(label, value: value.wrappedValue, in: range, step: step)
    self.onValueChange = { [unowned self] new in
      value.wrappedValue = V(new)
      if let context = self.context { self.setValue(value.wrappedValue, context) }
    }
  }

  public convenience init<V: BinaryFloatingPoint>(_ label: String, value: Binding<V>, in range: ClosedRange<V>? = nil, step: V = 1) {
    self.init(label, value: value.wrappedValue, in: range, step: step)
    self.onValueChange = { [unowned self] new in
      value.wrappedValue = V(new)
      if let context = self.context { self.setValue(value.wrappedValue, context) }
    }
  }

  /// Fit a write-back to the state's own type: what `@Component` arms `onValueChange` through.
  public static func adapt<V: BinaryInteger>(_ write: @escaping (V) -> Void) -> (Double) -> Void {
    { write(V($0)) }
  }

  public static func adapt<V: BinaryFloatingPoint>(_ write: @escaping (V) -> Void) -> (Double) -> Void {
    { write(V($0)) }
  }

  private func advance(by direction: Double) {
    guard !self.isDisabled, let report = self.onValueChange else { return }
    let value = (self.value + direction * self.step).clamped(to: self.range)
    guard value != self.value else { return }
    self.commit { report(value) }
  }

  /// Marks the key whose way is blocked: its glyph's end-of-range state.
  private func updateEnds(_ context: UIContext?) {
    Self.block(self.decrementIcon, self.value <= self.range.lowerBound, context)
    Self.block(self.incrementIcon, self.value >= self.range.upperBound, context)
  }

  private static func block(_ icon: AnimatedIcon, _ blocked: Bool, _ context: UIContext?) {
    if let context {
      icon.setActive(blocked, context)
    } else {
      icon.active = blocked
      icon.restyleAtRest()
    }
  }

  public func setValue<V: BinaryInteger>(_ value: V, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setValue(Double(value), context)
  }

  public func setValue<V: BinaryFloatingPoint>(_ value: V, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let value = Double(value)
    guard value != self.value else { return }
    self.value = value
    self.updateEnds(context)
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }
}

/// One half of a stepper: the white key a − or a + (an `AnimatedIcon` over it) sits on.
final class StepperGlyph : FormGraphic {
  static let size = float2(24, 22)
  let plus: Bool

  init(plus: Bool) {
    self.plus = plus
    super.init()
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    Self.size
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    renderer.draw(
      roundedRect: origin, size: size,
      radii: (self.plus ? float4(5, 5, 0, 0) : float4(0, 0, 5, 5)) * scale,  // trailing corners, or leading
      color: float4.controlButton.withAlpha(opacity)
    )
  }
}
