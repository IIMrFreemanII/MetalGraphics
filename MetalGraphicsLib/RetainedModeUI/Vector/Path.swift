import simd

/// An outline of lines and curves: from SVG path data, from a builder closure run once, or from
/// one run again whenever the value it is given changes.
///
/// A path's distance field is baked into a tile of the dynamic atlas, and baked again only when
/// its outline changes — a morph, a new value, or growing so much on screen that it needs more
/// resolution. Stroke width and trim are applied when drawing, so animating them costs nothing.
public final class Path: VectorShape {
  private enum Source {
    /// Between two command lists, `morphProgress` of the way.
    case commands
    /// Run with `value` whenever it changes.
    case builder((inout PathBuilder, float4) -> Void)
  }

  private var source: Source
  public private(set) var d: String? = nil
  private var from: [SVGPathCommand] = []
  private var to: [SVGPathCommand] = []
  var morphProgress: Float = 1
  /// What a builder path is built from. Its unused lanes are zero.
  var value: float4 = .zero

  /// Set when the outline changes; the next draw rebuilds it and bakes.
  var outlineChanged = true
  private var geometry = VectorGeometry([], closing: true, tolerance: 1)
  private var geometryStyle: Style? = nil
  private var slot: SDFSlot? = nil
  private var region: BakedRegion? = nil
  /// The resolution asked for at the last bake, in texels per local unit.
  private var bakedTexelsPerUnit: Float = 0
  /// How far around the outline the last stroke bake reaches, in local units.
  private var bakedHalfWidth: Float = 0

  /// A path from SVG path data (`M`, `L`, `C`, `A`, `Z` and the rest), in canvas units. An
  /// animated change of `d` morphs when both have the same commands in the same order.
  public init(d: String) {
    self.source = .commands
    self.d = d
    self.to = SVGPathData.parse(d)
    self.from = self.to
    super.init()
  }

  /// A path built once by `build`.
  public init(_ build: (inout PathBuilder) -> Void) {
    var builder = PathBuilder()
    build(&builder)
    self.source = .commands
    self.to = builder.commands
    self.from = self.to
    super.init()
  }

  /// A path `build` makes from `value`, and makes again each frame `value` animates.
  public init(_ value: Float, _ build: @escaping (inout PathBuilder, Float) -> Void) {
    self.source = .builder { builder, value in build(&builder, value.x) }
    self.value = float4(value, 0, 0, 0)
    super.init()
  }

  public init(_ value: float2, _ build: @escaping (inout PathBuilder, float2) -> Void) {
    self.source = .builder { builder, value in build(&builder, float2(value.x, value.y)) }
    self.value = float4(value.x, value.y, 0, 0)
    super.init()
  }

  public init(_ value: float4, _ build: @escaping (inout PathBuilder, float4) -> Void) {
    self.source = .builder(build)
    self.value = value
    super.init()
  }

  public override func unmount(_ context: UIContext) {
    super.unmount(context)
    if let slot = self.slot {
      VectorBaker.shared.free(slot)
      self.slot = nil
      self.region = nil
    }
  }

  // MARK: - Outline

  /// The commands as presented this frame.
  var presentedCommands: [SVGPathCommand] {
    switch self.source {
    case .commands:
      return self.morphProgress >= 1
        ? self.to
        : PathMorph.interpolate(self.from, self.to, Double(self.morphProgress))
    case .builder(let build):
      var builder = PathBuilder()
      build(&builder, self.value)
      return builder.commands
    }
  }

  /// A new `d`: morphs to it with an animation when it has the same commands as what is shown,
  /// and snaps otherwise.
  func morph(to d: String, _ context: UIContext, animation: UIAnimation?) {
    guard d != self.d else { return }
    self.d = d
    let target = SVGPathData.parse(d)
    let current = self.presentedCommands
    self.source = .commands

    if let animation, PathMorph.compatible(current, target) {
      self.from = current
      self.to = target
      self.morphProgress = 0
      context.animator.run(
        self, .morph, from: Float(0).packed, to: Float(1).packed, animation, context, restart: true,
        apply: { element, value, context in
          let path = unsafeDowncast(element, to: Path.self)
          path.morphProgress = value.x
          path.outlineChanged = true
          context.invalidate()
        },
        completion: nil
      )
    } else {
      context.animator.cancel(self, .morph)
      self.from = target
      self.to = target
      self.morphProgress = 1
    }
    self.outlineChanged = true
    context.invalidate()
  }

  // MARK: - Drawing

  override func prepare(pointsPerUnit: Float, pixelsPerUnit: Float) -> Bool {
    // A little over one texel per pixel, in steps of √2, so a path growing or shrinking on
    // screen re-bakes only when it crosses a step.
    let wanted = min(max(pixelsPerUnit * 1.1, 1e-3), 1e4)
    let texelsPerUnit = Float(pow(2, (log2(wanted) * 2).rounded(.up) / 2))

    let resolutionChanged = self.region != nil
      && (texelsPerUnit > self.bakedTexelsPerUnit || texelsPerUnit < self.bakedTexelsPerUnit * 0.5)
    if self.outlineChanged || self.geometryStyle != self.style || resolutionChanged {
      // fills close their subpaths, strokes leave them as they are
      self.geometry = VectorGeometry(
        self.presentedCommands, closing: self.style == .fill, tolerance: 0.25 / texelsPerUnit
      )
      self.geometryStyle = self.style
      self.region = nil
      self.outlineChanged = false
    }
    guard !self.geometry.isEmpty else { return false }

    let halfWidth = self.style == .stroke ? self.lineWidth * 0.5 : 0
    if self.region == nil || halfWidth > self.bakedHalfWidth {
      // Room for the stroke to grow a little without baking again.
      let reach = self.style == .stroke ? halfWidth * 1.25 : 0
      self.region = VectorBaker.shared.bake(
        self.geometry.segments,
        mode: self.style == .stroke ? .stroke : .fillNonZero,
        totalLength: self.geometry.totalLength,
        boundsMin: self.geometry.boundsMin - reach, boundsMax: self.geometry.boundsMax + reach,
        texelsPerUnit: texelsPerUnit, slot: &self.slot
      )
      self.bakedTexelsPerUnit = texelsPerUnit
      self.bakedHalfWidth = reach
    }
    return self.region != nil
  }

  override var localBounds: (min: float2, max: float2)? {
    self.geometry.isEmpty ? nil : (self.geometry.boundsMin, self.geometry.boundsMax)
  }

  override func describe(_ item: inout VectorItem) {
    guard let region = self.region else { return }
    item.kind = (self.style == .stroke ? VectorItem.Kind.bakedStroke : .bakedFill).rawValue
    item.params0 = float4(region.boundsMin.x, region.boundsMin.y, region.boundsMax.x, region.boundsMax.y)
    item.params1 = float4(region.uvMin.x, region.uvMin.y, region.uvMax.x, region.uvMax.y)
    item.stroke.w = self.geometry.totalLength
    if self.geometry.isClosed {
      item.flags |= VectorItem.closedFlag
    }
  }

  override var length: Float { self.geometry.totalLength }

  override var isClosed: Bool { self.geometry.isClosed }

  override func distance(to point: float2, along: Bool) -> (distance: Float, along: Float) {
    let nearest = self.geometry.nearest(to: point)
    let distance = nearest.distanceSquared.squareRoot()
    if self.style == .fill, self.geometry.winding(at: point) != 0 {
      return (-distance, nearest.along)
    }
    return (distance, nearest.along)
  }
}
