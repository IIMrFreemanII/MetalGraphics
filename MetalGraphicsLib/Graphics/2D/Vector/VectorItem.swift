import simd

/// One shape of a `VectorCanvas`, laid out as `VectorItem` in Shaders.metal.
///
/// Everything that moves the shape as a whole — offset, rotation, scale, the canvas's own place
/// and size — is folded into one affine map from `compute2D`'s point space into the shape's
/// local units, so animating it changes this struct and nothing else. Circles, ellipses and
/// rounded boxes are evaluated analytically; a path samples a region of the dynamic SDF atlas.
struct VectorItem {
  enum Kind: UInt32 {
    /// A path's fill: `params0` its local bounds, `params1` their atlas uv.
    case bakedFill = 0
    /// A path's stroke: as a fill, but the atlas holds distance to the centerline and the
    /// position along the path, so width and trim are applied here.
    case bakedStroke = 1
    /// `params0`: center, radii.
    case ellipse = 2
    /// `params0`: center, half size. `params1`: corner radii, as `UIShape.radii` orders them.
    case roundedBox = 3
  }

  static let closedFlag: UInt32 = 1
  static let strokeFlag: UInt32 = 2

  /// `local = (dot(row0.xy, p) + row0.z, dot(row1.xy, p) + row1.z)` for a point `p` in points,
  /// window centered, y down. `row0.w` is points per local unit, `row1.w` the depth.
  var row0 = float4()
  var row1 = float4()
  var params0 = float4()
  var params1 = float4()
  var color = float4()
  /// min x, min y, max x, max y, in points: where the shape can cover anything, already
  /// clipped to its canvas.
  var clip = float4()
  /// half width, trim from, trim to, length of the path in local units.
  var stroke = float4()
  var kind: UInt32 = 0
  var flags: UInt32 = 0
  /// A shadow's blur, as a standard deviation in points; 0 for a shape drawn sharp. A baked
  /// path's distance is extended past its atlas region when it is blurred.
  var blur: Float = 0
  private var padding1: Float = 0

  var depth: Float {
    get { self.row1.w }
    set { self.row1.w = newValue }
  }

  var bounds: BoundingBox2D {
    BoundingBox2D(
      center: float2(self.clip.x + self.clip.z, self.clip.y + self.clip.w) * 0.5,
      size: float2(self.clip.z - self.clip.x, self.clip.w - self.clip.y)
    )
  }
}

/// A line or quadratic of a path to bake, in local units, laid out as `VectorSegment` in
/// VectorSDF.metal.
struct VectorSegment {
  var a = float2()
  /// The control point; unused by a line.
  var b = float2()
  var c = float2()
  /// Holds the whole segment: the bake skips it for texels already nearer to something else.
  var boxMin = float2()
  var boxMax = float2()
  /// Length along the path up to `a`, and of the segment itself.
  var start: Float = 0
  var length: Float = 0
  var isLine: UInt32 = 0
  private var padding: Float = 0

  init(line a: float2, _ c: float2, start: Float) {
    self.a = a
    self.b = a
    self.c = c
    self.boxMin = simd_min(a, c)
    self.boxMax = simd_max(a, c)
    self.start = start
    self.length = simd_distance(a, c)
    self.isLine = 1
  }

  init(quad a: float2, _ b: float2, _ c: float2, start: Float) {
    self.a = a
    self.b = b
    self.c = c
    self.boxMin = simd_min(simd_min(a, b), c)
    self.boxMax = simd_max(simd_max(a, b), c)
    self.start = start
    // Close enough for placing a trim: a polyline through 8 points of the curve.
    var length: Float = 0
    var previous = a
    for i in 1...8 {
      let t = Float(i) / 8
      let point = simd_mix(simd_mix(a, b, float2(repeating: t)), simd_mix(b, c, float2(repeating: t)), float2(repeating: t))
      length += simd_distance(previous, point)
      previous = point
    }
    self.length = length
    self.isLine = 0
  }

  func point(at t: Float) -> float2 {
    if self.isLine != 0 {
      return simd_mix(self.a, self.c, float2(repeating: t))
    }
    let t2 = float2(repeating: t)
    return simd_mix(simd_mix(self.a, self.b, t2), simd_mix(self.b, self.c, t2), t2)
  }
}
