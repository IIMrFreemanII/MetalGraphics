import simd

/// A colour, picked in a popover: `ColorPicker("Tint", selection: $tint, supportsOpacity: true)`.
///
/// The row shows a colour well; a click on it opens swatches to pick from, and hue, saturation
/// and brightness sliders — and opacity, when `supportsOpacity` — to fine-tune. The selection is
/// a `float4`, the library's colour.
public final class ColorPicker : FormControl {
  public private(set) var selection: float4
  public let supportsOpacity: Bool
  /// Where a pick reports the new colour. `@Component` arms it with the binding's write-back.
  public var onSelectionChange: ((float4) -> Void)?

  private let label: Text
  private let well = ColorWell()
  private let wellButton: HittableView
  /// Hue, saturation and brightness, kept apart from the selection so a grey keeps its hue while
  /// the saturation slider passes through zero.
  private var hsb: float3
  private var popover: PopoverHandle?
  private var sliders: [Slider] = []
  private var swatches: [ColorSwatch] = []

  public init(_ label: String, selection: float4, supportsOpacity: Bool = true, onSelectionChange: ((float4) -> Void)? = nil) {
    self.selection = selection
    self.supportsOpacity = supportsOpacity
    self.onSelectionChange = onSelectionChange
    self.hsb = hsbFromRGB(selection)
    let label = Text(label).font(FormMetrics.font).foregroundColor(FormMetrics.labelColor)
    self.label = label
    self.well.color = selection
    let well = self.well
    let button = HittableView(onTap: nil) { well }
    self.wellButton = button
    super.init(content: HStack(spacing: FormMetrics.labelSpacing) {
      if !label.text.isEmpty {
        label
        Spacer()
      }
      button
    })
    button.onTap = { [unowned self] _ in self.open() }
  }

  /// A hand-built picker over a binding. In a `@Component` body `$state` is lowered instead.
  public convenience init(_ label: String, selection: Binding<float4>, supportsOpacity: Bool = true) {
    self.init(label, selection: selection.wrappedValue, supportsOpacity: supportsOpacity)
    self.onSelectionChange = { [unowned self] color in
      selection.wrappedValue = color
      if let context = self.context { self.setSelection(selection.wrappedValue, context) }
    }
  }

  public override func unmount(_ context: UIContext) {
    if let popover = self.popover { context.dismissPopover(popover, animated: false) }
    super.unmount(context)
  }

  // MARK: - Popover

  /// 12 hues in three shades, and a row of greys.
  private static let palette: [[float4]] = {
    let shades: [(s: Float, b: Float)] = [(0.35, 1), (0.8, 0.95), (0.9, 0.6)]
    var rows = shades.map { shade in
      (0 ..< 12).map { rgbFromHSB(float3(Float($0) / 12, shade.s, shade.b), alpha: 1) }
    }
    rows.append((0 ..< 12).map { let v = 1 - Float($0) / 11; return float4(v, v, v, 1) })
    return rows
  }()

  private func open() {
    guard !self.isDisabled, let context = self.context, self.popover?.isPresented != true else { return }
    self.swatches.removeAll()
    let grid = VStack(alignment: .leading, spacing: 4)
    grid.applyContent(Self.palette.map { colors in
      let row = HStack(spacing: 4)
      row.applyContent(colors.map { color in
        let swatch = ColorSwatch(color)
        swatch.isSelected = color == self.selection
        self.swatches.append(swatch)
        return HittableView(onTap: { [unowned self] _ in self.pick(color) }) { swatch }
      })
      return row
    })

    var channels: [(String, Float)] = [("Hue", self.hsb.x), ("Saturation", self.hsb.y), ("Brightness", self.hsb.z)]
    if self.supportsOpacity { channels.append(("Opacity", self.selection.w)) }
    self.sliders = channels.enumerated().map { index, channel in
      Slider(value: channel.1, in: 0 ... 1) { [unowned self] value in self.slide(index, Float(value)) }
    }
    let rows = VStack(alignment: .leading, spacing: 6)
    rows.applyContent(zip(channels, self.sliders).map { channel, slider in
      HStack(spacing: 8) {
        Text(channel.0).font(FormMetrics.captionFont).foregroundColor(FormMetrics.secondaryColor)
          .frame(width: 70, alignment: .leading)
        slider
      }
    })

    let content = VStack(alignment: .leading, spacing: 12) {
      grid
      rows.frame(width: 12 * ColorSwatch.size + 11 * 4)
    }
    .padding(12)
    self.popover = context.presentPopover(content, anchor: self.wellButton) { [weak self] in
      self?.popover = nil
      self?.sliders.removeAll()
      self?.swatches.removeAll()
    }
  }

  private func pick(_ color: float4) {
    var color = color
    if !self.supportsOpacity { color.w = 1 } else { color.w = self.selection.w }
    self.hsb = hsbFromRGB(color)
    self.report(color)
  }

  /// A slider moved: channel 0–2 is hue, saturation, brightness; 3 is opacity.
  private func slide(_ channel: Int, _ value: Float) {
    var alpha = self.selection.w
    if channel < 3 {
      self.hsb[channel] = value
    } else {
      alpha = value
    }
    self.report(rgbFromHSB(self.hsb, alpha: alpha))
  }

  private func report(_ color: float4) {
    guard !self.isDisabled, let report = self.onSelectionChange, color != self.selection else { return }
    self.commit { report(color) }
  }

  // MARK: - Setters

  public func setSelection(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.selection else { return }
    self.selection = value
    // A colour from elsewhere resets the channels; one from here already set them.
    if !self.isInteracting { self.hsb = hsbFromRGB(value) }
    self.well.setColor(value, context, animation: animation)
    for swatch in self.swatches {
      swatch.setSelected(swatch.color == value || (swatch.color.xyz == value.xyz && !self.supportsOpacity), context)
    }
    let values = [self.hsb.x, self.hsb.y, self.hsb.z, value.w]
    for (slider, value) in zip(self.sliders, values) {
      slider.setValue(value, context)
    }
  }

  public func setLabel(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.label.text else { return }
    self.label.setText(value, context, animation: animation)
  }
}

/// Hue, saturation and brightness, each 0...1, of an RGB colour.
func hsbFromRGB(_ color: float4) -> float3 {
  let (r, g, b) = (color.x, color.y, color.z)
  let high = max(r, g, b)
  let low = min(r, g, b)
  let delta = high - low
  var hue: Float = 0
  if delta > 0 {
    if high == r {
      hue = (g - b) / delta
    } else if high == g {
      hue = 2 + (b - r) / delta
    } else {
      hue = 4 + (r - g) / delta
    }
    hue /= 6
    if hue < 0 { hue += 1 }
  }
  return float3(hue, high > 0 ? delta / high : 0, high)
}

func rgbFromHSB(_ hsb: float3, alpha: Float) -> float4 {
  let (h, s, v) = (hsb.x, hsb.y, hsb.z)
  let sector = (h - floor(h)) * 6
  let f = sector - floor(sector)
  let p = v * (1 - s)
  let q = v * (1 - s * f)
  let t = v * (1 - s * (1 - f))
  let rgb: float3
  switch Int(sector) % 6 {
  case 0: rgb = float3(v, t, p)
  case 1: rgb = float3(q, v, p)
  case 2: rgb = float3(p, v, t)
  case 3: rgb = float3(p, q, v)
  case 4: rgb = float3(t, p, v)
  default: rgb = float3(v, p, q)
  }
  return float4(rgb, alpha)
}

/// Drawn under a translucent colour, so its opacity shows.
@MainActor func drawCheckerboard(_ renderer: Graphics2D, origin: float2, size: float2, cell: Float, opacity: Float) {
  let columns = Int((size.x / cell).rounded(.up))
  let rows = Int((size.y / cell).rounded(.up))
  for row in 0 ..< rows {
    for column in 0 ..< columns where (row + column) % 2 == 1 {
      let min = origin + float2(Float(column), Float(row)) * cell
      let max = simd_min(min + cell, origin + size)
      renderer.draw(square: Square(position: (min + max) * 0.5, size: max - min, color: float4(0, 0, 0, 0.12 * opacity)))
    }
  }
}

/// The row's colour well: the colour on a rounded swatch, over a checkerboard when translucent.
final class ColorWell : FormGraphic {
  static let size = float2(44, 24)
  var color: float4 = .black

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    Self.size
  }

  func setColor(_ value: float4, _ context: UIContext, animation: UIAnimation?) {
    context.animator.set(self, .color, from: self.color, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: ColorWell.self).color = float4(packed: value)
      context.invalidate()
    }
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let radii = float4(repeating: 6 * scale)
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: float4(1, 1, 1, opacity))
    let inset = 3 * scale
    let inner = size - inset * 2
    if self.color.w < 1 {
      drawCheckerboard(renderer, origin: origin + inset, size: inner, cell: 5 * scale, opacity: opacity)
    }
    renderer.draw(roundedRect: origin + inset, size: inner, radii: float4(repeating: 3 * scale), color: self.color.withAlpha(opacity))
    var border = FormMetrics.strokeColor
    border.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: border, strokeWidth: scale)
  }
}

/// One colour in the picker's grid, ringed when it is the selection.
final class ColorSwatch : FormGraphic {
  static let size: Float = 16
  let color: float4
  var isSelected = false

  init(_ color: float4) {
    self.color = color
    super.init()
  }

  func setSelected(_ value: Bool, _ context: UIContext) {
    guard value != self.isSelected else { return }
    self.isSelected = value
    context.invalidate()
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    float2(repeating: Self.size)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let radii = float4(repeating: 4 * scale)
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: self.color.withAlpha(opacity))
    renderer.draw(roundedRect: origin, size: size, radii: radii, color: float4(0, 0, 0, 0.1 * opacity), strokeWidth: scale)
    if self.isSelected {
      var ring = FormMetrics.accentColor
      ring.w *= opacity
      renderer.draw(
        roundedRect: origin - 2 * scale, size: size + 4 * scale, radii: radii + 2 * scale, color: ring,
        strokeWidth: 2 * scale
      )
    }
  }
}
