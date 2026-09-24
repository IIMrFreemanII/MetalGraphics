import simd

/// A value picked along a track by dragging its knob, or clicking where it should go:
/// `Slider("Volume", value: $volume, in: 0 ... 1)`.
///
/// Works in `Double`; the state keeps its own floating-point type, converted at the edges.
public final class Slider : FormControl {
  public private(set) var value: Double
  public let range: ClosedRange<Double>
  public let step: Double?
  /// Where a drag reports each new value. `@Component` arms it with the binding's write-back,
  /// through `adapt`.
  public var onValueChange: ((Double) -> Void)?

  private let label: Text
  private let track = SliderTrack()

  public init<V: BinaryFloatingPoint>(
    _ label: String = "", value: V, in range: ClosedRange<V> = 0 ... 1, step: V? = nil,
    onValueChange: ((Double) -> Void)? = nil
  ) {
    self.value = Double(value)
    self.range = Double(range.lowerBound) ... Double(range.upperBound)
    self.step = step.map { Double($0) }
    self.onValueChange = onValueChange
    let label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    self.label = label
    let track = self.track
    // Swallows the tap, so a click on the track reaches nothing under it.
    let hit = HittableView(onTap: { _ in }) { track }
    super.init(content: HStack(spacing: FormMetrics.labelSpacing) {
      if !label.text.isEmpty { label }
      hit
    })
    self.track.progress = self.fraction(of: self.value)
    // Pressing jumps the knob to the pointer; dragging follows it, wherever the pointer goes.
    hit.onPress = { [unowned self] down, input in
      if down { self.follow(input.mousePosition.x) }
    }
    hit.onDrag = { [unowned self] input in self.follow(input.mousePosition.x) }
  }

  /// A hand-built slider over a binding. In a `@Component` body `$state` is lowered instead.
  public convenience init<V: BinaryFloatingPoint>(
    _ label: String = "", value: Binding<V>, in range: ClosedRange<V> = 0 ... 1, step: V? = nil
  ) {
    self.init(label, value: value.wrappedValue, in: range, step: step)
    self.onValueChange = { [unowned self] new in
      value.wrappedValue = V(new)
      if let context = self.context { self.setValue(value.wrappedValue, context) }
    }
  }

  /// Fits a write-back to the state's own type: what `@Component` arms `onValueChange` through.
  public static func adapt<V: BinaryFloatingPoint>(_ write: @escaping (V) -> Void) -> (Double) -> Void {
    { write(V($0)) }
  }

  private func fraction(of value: Double) -> Float {
    let span = self.range.upperBound - self.range.lowerBound
    return span > 0 ? Float((value - self.range.lowerBound) / span).clamped(to: 0 ... 1) : 0
  }

  /// The value under the pointer, snapped to `step` and clamped; reported only when it changed.
  private func follow(_ x: Float) {
    guard !self.isDisabled, let report = self.onValueChange else { return }
    let t = Double(self.track.fraction(atX: x))
    var value = self.range.lowerBound + t * (self.range.upperBound - self.range.lowerBound)
    if let step = self.step, step > 0 {
      value = self.range.lowerBound + ((value - self.range.lowerBound) / step).rounded() * step
    }
    value = value.clamped(to: self.range)
    guard value != self.value else { return }
    // A drag follows the pointer: no easing behind it.
    report(value)
  }

  public func setValue<V: BinaryFloatingPoint>(_ value: V, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let value = Double(value)
    guard value != self.value else { return }
    self.value = value
    self.track.setProgress(self.fraction(of: value), context, animation: animation)
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }
}

/// A thin track, filled in the accent color up to a round knob at `progress`.
final class SliderTrack : FormGraphic {
  static let height: Float = 20
  static let idealWidth: Float = 180
  static let minWidth: Float = 60
  static let thickness: Float = 4
  static let knob: Float = 18

  // As wide as it is offered, down to a usable minimum.
  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    float2(max(proposal.width ?? Self.idealWidth, Self.minWidth), Self.height)
  }

  /// Where along the track `x` falls, 0 at the knob's leftmost centre, 1 at its rightmost.
  func fraction(atX x: Float) -> Float {
    let travel = self.size.x - Self.knob
    guard travel > 0 else { return 0 }
    return ((x - self.position.x - Self.knob * 0.5) / travel).clamped(to: 0 ... 1)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let knob = Self.knob * scale
    let thickness = Self.thickness * scale
    let centerY = origin.y + size.y * 0.5
    let knobX = origin.x + (size.x - knob) * self.progress

    var track = FormMetrics.fillColor
    track.w *= opacity
    let trackOrigin = float2(origin.x, centerY - thickness * 0.5)
    renderer.draw(roundedRect: trackOrigin, size: float2(size.x, thickness), radii: float4(repeating: thickness * 0.5), color: track)
    var fill = FormMetrics.accentColor
    fill.w *= opacity
    renderer.draw(
      roundedRect: trackOrigin, size: float2(knobX - origin.x + knob * 0.5, thickness),
      radii: float4(repeating: thickness * 0.5), color: fill
    )

    let knobOrigin = float2(knobX, centerY - knob * 0.5)
    renderer.draw(
      roundedRect: knobOrigin - 0.5 * scale, size: float2(repeating: knob + scale),
      radii: float4(repeating: (knob + scale) * 0.5), color: float4(0, 0, 0, 0.18 * opacity)
    )
    renderer.draw(roundedRect: knobOrigin, size: float2(repeating: knob), radii: float4(repeating: knob * 0.5), color: float4(1, 1, 1, opacity))
  }
}

/// A bar filled to how far along a task is: `ProgressView(value: self.downloaded, total: 100)`.
public final class ProgressView : FormGraphic {
  public private(set) var value: Double
  public private(set) var total: Double

  static let height: Float = 6

  public init<V: BinaryFloatingPoint>(value: V, total: V = 1) {
    self.value = Double(value)
    self.total = Double(total)
    super.init()
    self.progress = self.fraction
  }

  private var fraction: Float {
    self.total > 0 ? Float(self.value / self.total).clamped(to: 0 ... 1) : 0
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    float2(max(proposal.width ?? SliderTrack.idealWidth, SliderTrack.minWidth), Self.height)
  }

  public func setValue<V: BinaryFloatingPoint>(_ value: V, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard Double(value) != self.value else { return }
    self.value = Double(value)
    self.setProgress(self.fraction, context, animation: animation)
  }

  public func setTotal<V: BinaryFloatingPoint>(_ total: V, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard Double(total) != self.total else { return }
    self.total = Double(total)
    self.setProgress(self.fraction, context, animation: animation)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let radii = float4(repeating: size.y * 0.5)
    var track = FormMetrics.fillColor
    track.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: track)
    var fill = FormMetrics.accentColor
    fill.w *= opacity
    renderer.draw(roundedRect: origin, size: float2(size.x * self.progress, size.y), radii: radii, color: fill)
  }
}
