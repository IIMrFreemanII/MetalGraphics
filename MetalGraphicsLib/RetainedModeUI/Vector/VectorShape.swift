import simd

/// A shape drawn by a `VectorCanvas`, in the canvas's own units, y down.
///
/// Every attribute is a presented value, animated through the setters in
/// UIElement+ReactiveSetters.swift. Moving, turning, scaling, recoloring, fading, stroking and
/// trimming a shape never re-bakes anything: they only change the one `VectorItem` it draws as.
/// Circles, ellipses and rounded rectangles are evaluated analytically, so changing their
/// geometry is free as well; only a `Path` whose outline changes is baked again.
///
/// Shapes are drawn in the order they are written, each above the ones before it, and hit in
/// the reverse order — each exactly inside its own outline.
open class VectorShape: UIElement, Hittable {
  public enum Style {
    case fill
    case stroke
  }

  public internal(set) var style: Style = .fill
  public internal(set) var color: float4 = .black
  public internal(set) var lineWidth: Float = 1
  /// The part of a stroke drawn, as fractions of its length. Fills are never trimmed.
  public internal(set) var trim = float2(0, 1)
  /// Degrees, clockwise on screen, about `rotationAnchor` — the shape's center when nil.
  public internal(set) var rotation: Float = 0
  public internal(set) var rotationAnchor: float2? = nil
  /// About `scaleAnchor` — the shape's center when nil. A stroke scales with it.
  public internal(set) var scale: Float = 1
  public internal(set) var scaleAnchor: float2? = nil
  public internal(set) var offset: float2 = .zero
  public internal(set) var opacity: Float = 1

  // MARK: Hittable

  public var onTap: ((Input) -> Void)?
  public var onHover: ((Bool, Input) -> Void)?
  public var onPress: ((Bool, Input) -> Void)?
  public var onDrag: ((Input) -> Void)? { nil }
  public var isHovered = false
  public var isPressed = false
  /// The canvas's laid-out rect: the grid files every shape of a canvas under all of it, and
  /// `hitTest` narrows it down to the outline.
  public internal(set) var hitPosition: float2 = .zero
  public internal(set) var hitSize: float2 = .zero

  /// Maps a window point to local units, and where the shape was drawn, as of the last frame.
  private struct HitTransform {
    var linear: float2x2
    var translation: float2
    var clipMin: float2
    var clipMax: float2
  }
  private var hitTransform: HitTransform? = nil

  public override init() {
    super.init()
  }

  public override func mount(_ context: UIContext) {
    context.registerHittableView(self)
  }

  public override func unmount(_ context: UIContext) {
    self.isHovered = false
    self.isPressed = false
    self.hitTransform = nil
    context.unregisterHittableView(self)
  }

  public func hitTest(_ point: float2) -> Bool {
    guard let hit = self.hitTransform,
          point.x >= hit.clipMin.x, point.y >= hit.clipMin.y,
          point.x <= hit.clipMax.x, point.y <= hit.clipMax.y
    else { return false }
    return self.contains(hit.linear * point + hit.translation)
  }

  // MARK: - Subclass hooks

  /// Called before anything else each frame it is drawn, with how many points and pixels one
  /// local unit covers. False when there is nothing to draw.
  func prepare(pointsPerUnit: Float, pixelsPerUnit: Float) -> Bool { true }

  /// Holds the outline, not the stroke around it.
  var localBounds: (min: float2, max: float2)? { nil }

  /// Sets `kind`, `params0`, `params1`, `stroke.w` (the outline's length) and the closed flag.
  func describe(_ item: inout VectorItem) {}

  /// Signed distance to the outline, negative inside, and the position along it (0...1) of the
  /// nearest point when `along` is asked for.
  func distance(to point: float2, along: Bool) -> (distance: Float, along: Float) {
    (.greatestFiniteMagnitude, 0)
  }

  var isClosed: Bool { true }

  /// Whether a local point is inside what is drawn: the fill, or the trimmed stroke.
  func contains(_ point: float2) -> Bool {
    switch self.style {
    case .fill:
      return self.distance(to: point, along: false).distance <= 0
    case .stroke:
      let trimmed = self.trim.x > 0 || self.trim.y < 1
      let nearest = self.distance(to: point, along: trimmed)
      return VectorMath.trimmedStroke(
        abs(nearest.distance), nearest.along, halfWidth: self.lineWidth * 0.5,
        trim: self.trim, length: self.length, closed: self.isClosed
      ) <= 0
    }
  }

  /// Length of the outline in local units, for placing trimmed ends.
  var length: Float { 0 }

  // MARK: - Drawing

  /// Draws the shape through the canvas's map from local units to points (window centered,
  /// y down): `origin + point * unitScale`, cut to `clipMin`...`clipMax`.
  final func draw(
    _ renderer: Graphics2D, origin: float2, unitScale: Float,
    clipMin: float2, clipMax: float2, opacity: Float
  ) {
    self.hitTransform = nil
    var color = self.color
    color.w *= self.opacity * opacity
    let scale = self.scale
    guard color.w > 0, scale > 0, unitScale > 0 else { return }

    let pointsPerUnit = unitScale * scale
    guard self.prepare(pointsPerUnit: pointsPerUnit, pixelsPerUnit: pointsPerUnit * renderer.pixelsPerPoint),
          let bounds = self.localBounds
    else { return }

    // local -> canvas: scale about its anchor, turn about its anchor, then offset
    let center = (bounds.min + bounds.max) * 0.5
    let scaleAnchor = self.scaleAnchor ?? center
    let rotationAnchor = self.rotationAnchor ?? center
    let turn = float2x2(rotation: self.rotation * .pi / 180)
    let linear = turn * scale
    let translation = turn * (scaleAnchor * (1 - scale) - rotationAnchor) + rotationAnchor + self.offset
    // canvas -> points
    let toPoints = linear * unitScale
    let toPointsOffset = origin + translation * unitScale

    // where it can cover anything: its bounds, its stroke and a pixel for anti-aliasing
    let margin = (self.style == .stroke ? self.lineWidth * 0.5 : 0) + 1 / pointsPerUnit
    let lo = bounds.min - margin
    let hi = bounds.max + margin
    var coverMin = float2(repeating: .greatestFiniteMagnitude)
    var coverMax = float2(repeating: -.greatestFiniteMagnitude)
    for corner in [lo, float2(hi.x, lo.y), float2(lo.x, hi.y), hi] {
      let p = toPoints * corner + toPointsOffset
      coverMin = simd_min(coverMin, p)
      coverMax = simd_max(coverMax, p)
    }
    coverMin = simd_max(coverMin, clipMin)
    coverMax = simd_min(coverMax, clipMax)
    guard coverMin.x < coverMax.x, coverMin.y < coverMax.y else { return }

    let inverse = toPoints.inverse
    let inverseOffset = -(inverse * toPointsOffset)

    var item = VectorItem()
    item.row0 = float4(inverse[0][0], inverse[1][0], inverseOffset.x, pointsPerUnit)
    item.row1 = float4(inverse[0][1], inverse[1][1], inverseOffset.y, 0)
    item.color = color
    item.clip = float4(coverMin.x, coverMin.y, coverMax.x, coverMax.y)
    item.stroke = float4(self.style == .stroke ? self.lineWidth * 0.5 : 0, self.trim.x, self.trim.y, 0)
    item.flags = self.style == .stroke ? VectorItem.strokeFlag : 0
    self.describe(&item)
    renderer.draw(vector: item)

    // The same map from a window point, top left origin, for hit-testing until the next frame.
    let halfWindow = renderer.size * 0.5
    self.hitTransform = HitTransform(
      linear: inverse, translation: inverseOffset - inverse * halfWindow,
      clipMin: coverMin + halfWindow, clipMax: coverMax + halfWindow
    )
  }

  // MARK: - Modifiers

  /// Fills the shape with `color`. Sets this shape and returns it.
  public func fill(_ color: float4) -> Self {
    self.style = .fill
    self.color = color
    return self
  }

  /// Strokes the outline with `color`, `lineWidth` wide, with round caps and joins.
  public func stroke(_ color: float4, lineWidth: Float = 1) -> Self {
    self.style = .stroke
    self.color = color
    self.lineWidth = lineWidth
    return self
  }

  /// Draws only the part of the stroke from `from` to `to`, as fractions of its length.
  public func trim(from: Float = 0, to: Float = 1) -> Self {
    self.trim = float2(from, to)
    return self
  }

  /// Turns the shape `degrees` clockwise about `anchor`, in canvas units: its center when nil.
  public func rotationEffect(_ degrees: Float, anchor: float2? = nil) -> Self {
    self.rotation = degrees
    self.rotationAnchor = anchor
    return self
  }

  /// Scales the shape, stroke and all, about `anchor`, in canvas units: its center when nil.
  public func scaleEffect(_ scale: Float, anchor: float2? = nil) -> Self {
    self.scale = scale
    self.scaleAnchor = anchor
    return self
  }

  /// Moves the shape by `offset` canvas units. Unlike `UIElement.offset`, nothing wraps it.
  public func offset(_ offset: float2) -> Self {
    self.offset = offset
    return self
  }

  public func offset(x: Float = 0, y: Float = 0) -> Self {
    self.offset(float2(x, y))
  }

  public func opacity(_ opacity: Float) -> Self {
    self.opacity = opacity
    return self
  }

  /// Called on a click inside the shape's own outline — the topmost shape there.
  public func onTap(_ callback: @escaping (Input) -> Void) -> Self {
    self.onTap = callback
    return self
  }

  /// Called with true when the pointer enters the shape's own outline, false when it leaves.
  public func onHover(_ callback: @escaping (Bool, Input) -> Void) -> Self {
    self.onHover = callback
    return self
  }

  /// Called with true when the left button goes down inside the shape's outline, and with false
  /// when it comes up, wherever the pointer is by then.
  public func onPress(_ callback: @escaping (Bool, Input) -> Void) -> Self {
    self.onPress = callback
    return self
  }
}

// MARK: - Shapes

/// A circle around `center`. Analytic: every attribute animates without baking.
public final class Circle: VectorShape {
  public internal(set) var center: float2
  public internal(set) var radius: Float

  public init(center: float2, radius: Float) {
    self.center = center
    self.radius = radius
    super.init()
  }

  override var localBounds: (min: float2, max: float2)? {
    self.radius > 0 ? (self.center - self.radius, self.center + self.radius) : nil
  }

  override func describe(_ item: inout VectorItem) {
    item.kind = VectorItem.Kind.ellipse.rawValue
    item.params0 = float4(self.center.x, self.center.y, self.radius, self.radius)
    item.stroke.w = self.length
    item.flags |= VectorItem.closedFlag
  }

  override var length: Float { 2 * .pi * self.radius }

  override func distance(to point: float2, along: Bool) -> (distance: Float, along: Float) {
    let q = point - self.center
    return (simd_length(q) - self.radius, along ? VectorMath.ellipseAlong(q, float2(repeating: self.radius)) : 0)
  }
}

/// An ellipse around `center`. Analytic: every attribute animates without baking.
public final class Ellipse: VectorShape {
  public internal(set) var center: float2
  public internal(set) var radii: float2

  public init(center: float2, radii: float2) {
    self.center = center
    self.radii = radii
    super.init()
  }

  override var localBounds: (min: float2, max: float2)? {
    self.radii.x > 0 && self.radii.y > 0 ? (self.center - self.radii, self.center + self.radii) : nil
  }

  override func describe(_ item: inout VectorItem) {
    item.kind = VectorItem.Kind.ellipse.rawValue
    item.params0 = float4(self.center.x, self.center.y, self.radii.x, self.radii.y)
    item.stroke.w = self.length
    item.flags |= VectorItem.closedFlag
  }

  // Ramanujan's approximation
  override var length: Float {
    let a = self.radii.x, b = self.radii.y
    return .pi * (3 * (a + b) - ((3 * a + b) * (a + 3 * b)).squareRoot())
  }

  override func distance(to point: float2, along: Bool) -> (distance: Float, along: Float) {
    let q = point - self.center
    return (VectorMath.ellipseDistance(q, self.radii), along ? VectorMath.ellipseAlong(q, self.radii) : 0)
  }
}

/// A rectangle with its top left corner at `origin`, corners rounded by `cornerRadius`.
/// Analytic: every attribute animates without baking. Its stroke starts where the top edge
/// does and runs clockwise.
public class RoundedRectangle: VectorShape {
  public internal(set) var origin: float2
  public internal(set) var size: float2
  public internal(set) var cornerRadius: Float

  public init(origin: float2, size: float2, cornerRadius: Float = 0) {
    self.origin = origin
    self.size = size
    self.cornerRadius = cornerRadius
    super.init()
  }

  /// Clamped to half the shorter side.
  var effectiveRadius: Float {
    min(max(self.cornerRadius, 0), min(self.size.x, self.size.y) * 0.5)
  }

  override var localBounds: (min: float2, max: float2)? {
    self.size.x > 0 && self.size.y > 0 ? (self.origin, self.origin + self.size) : nil
  }

  override func describe(_ item: inout VectorItem) {
    let center = self.origin + self.size * 0.5
    item.kind = VectorItem.Kind.roundedBox.rawValue
    item.params0 = float4(center.x, center.y, self.size.x * 0.5, self.size.y * 0.5)
    item.params1 = float4(repeating: self.effectiveRadius)
    item.stroke.w = self.length
    item.flags |= VectorItem.closedFlag
  }

  override var length: Float {
    let r = self.effectiveRadius
    return 2 * (self.size.x - 2 * r) + 2 * (self.size.y - 2 * r) + 2 * .pi * r
  }

  override func distance(to point: float2, along: Bool) -> (distance: Float, along: Float) {
    let q = point - (self.origin + self.size * 0.5)
    let half = self.size * 0.5
    let r = self.effectiveRadius
    return (
      VectorMath.roundedBoxDistance(q, half, r),
      along ? VectorMath.roundedBoxAlong(q, half, r) : 0
    )
  }
}

/// A rounded rectangle whose shorter sides are half circles.
public final class Capsule: RoundedRectangle {
  public init(origin: float2, size: float2) {
    super.init(origin: origin, size: size, cornerRadius: .greatestFiniteMagnitude)
  }
}

// MARK: - Math

/// The distances `compute2D` evaluates, for hit-testing on the CPU.
enum VectorMath {
  static func trimmedStroke(
    _ centerDistance: Float, _ along: Float, halfWidth: Float, trim: float2, length: Float, closed: Bool
  ) -> Float {
    let from = trim.x, to = trim.y
    if from <= 0 && to >= 1 { return centerDistance - halfWidth }
    if to <= from { return .greatestFiniteMagnitude }
    var past: Float = 0
    if along < from || along > to {
      if closed {
        let toFrom = along < from ? from - along : 1 - along + from
        let fromTo = along > to ? along - to : along + 1 - to
        past = min(toFrom, fromTo)
      } else {
        past = along < from ? from - along : along - to
      }
    }
    return simd_length(float2(past * length, centerDistance)) - halfWidth
  }

  /// Close to the true distance near the outline, which is all a pointer needs.
  static func ellipseDistance(_ p: float2, _ radii: float2) -> Float {
    let k0 = simd_length(p / radii)
    let k1 = simd_length(p / (radii * radii))
    guard k1 > 0 else { return -min(radii.x, radii.y) }
    return k0 * (k0 - 1) / k1
  }

  static func ellipseAlong(_ p: float2, _ radii: float2) -> Float {
    let angle = atan2(p.y / radii.y, p.x / radii.x)
    let t = angle / (2 * .pi) + 1
    return t - t.rounded(.down)
  }

  static func roundedBoxDistance(_ p: float2, _ half: float2, _ r: Float) -> Float {
    let q = simd_abs(p) - half + r
    return min(max(q.x, q.y), 0) + simd_length(simd_max(q, .zero)) - r
  }

  /// Mirrors `roundedBoxAlong` in Shaders.metal.
  static func roundedBoxAlong(_ q: float2, _ half: float2, _ r: Float) -> Float {
    let inner = simd_max(half - r, .zero)
    let width = 2 * inner.x, height = 2 * inner.y
    let arc = 0.5 * .pi * r
    let total = 2 * width + 2 * height + 4 * arc
    guard total > 0 else { return 0 }
    let k = simd_clamp(q, -inner, inner)
    var e = q - k
    if e.x == 0 && e.y == 0 {
      if half.x - abs(q.x) < half.y - abs(q.y) {
        e = float2(q.x >= 0 ? 1 : -1, 0)
      } else {
        e = float2(0, q.y >= 0 ? 1 : -1)
      }
    }
    let along: Float
    if e.x == 0 && e.y < 0 {
      along = k.x + inner.x
    } else if e.x > 0 && e.y < 0 {
      along = width + atan2(e.x, -e.y) * r
    } else if e.x > 0 && e.y == 0 {
      along = width + arc + k.y + inner.y
    } else if e.x > 0 && e.y > 0 {
      along = width + arc + height + atan2(e.y, e.x) * r
    } else if e.x == 0 && e.y > 0 {
      along = width + 2 * arc + height + inner.x - k.x
    } else if e.x < 0 && e.y > 0 {
      along = 2 * width + 2 * arc + height + atan2(-e.x, e.y) * r
    } else if e.x < 0 && e.y == 0 {
      along = 2 * width + 3 * arc + height + inner.y - k.y
    } else {
      along = 2 * width + 3 * arc + 2 * height + atan2(-e.y, -e.x) * r
    }
    return along / total
  }
}
