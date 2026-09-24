import Foundation
import simd

/// Builds the outline of a `Path`, in its canvas's units, y down.
///
/// Angles are in degrees, from +x, and grow clockwise on screen — y points down.
public struct PathBuilder {
  private(set) var commands: [SVGPathCommand] = []
  private var current: SIMD2<Double>? = nil
  private var start = SIMD2<Double>()

  public init() {}

  init(commands: [SVGPathCommand]) {
    self.commands = commands
  }

  public mutating func move(to point: float2) {
    let p = SIMD2<Double>(point)
    self.commands.append(.move(p))
    self.current = p
    self.start = p
  }

  public mutating func addLine(to point: float2) {
    let p = SIMD2<Double>(point)
    guard self.current != nil else { return self.move(to: point) }
    self.commands.append(.line(p))
    self.current = p
  }

  /// A line through each of `points`, starting a subpath at the first when none is open.
  public mutating func addLines(_ points: [float2]) {
    for (i, point) in points.enumerated() {
      if i == 0, self.current == nil {
        self.move(to: point)
      } else {
        self.addLine(to: point)
      }
    }
  }

  public mutating func addQuadCurve(to point: float2, control: float2) {
    guard self.current != nil else { return self.move(to: point) }
    self.commands.append(.quad(SIMD2(control), SIMD2(point)))
    self.current = SIMD2(point)
  }

  public mutating func addCurve(to point: float2, control1: float2, control2: float2) {
    guard self.current != nil else { return self.move(to: point) }
    self.commands.append(.cubic(SIMD2(control1), SIMD2(control2), SIMD2(point)))
    self.current = SIMD2(point)
  }

  /// A circular arc, joined to the current point by a line, or starting a subpath when none is
  /// open. `clockwise` is on screen: angles grow.
  public mutating func addArc(
    center: float2, radius: Float, startAngle: Float, endAngle: Float, clockwise: Bool = true
  ) {
    let c = SIMD2<Double>(center)
    let r = Double(radius)
    let a0 = Double(startAngle) * .pi / 180
    var a1 = Double(endAngle) * .pi / 180
    // the sweep goes the asked way, at most one full turn
    if clockwise {
      while a1 < a0 { a1 += 2 * .pi }
      if a1 - a0 > 2 * .pi { a1 = a0 + 2 * .pi }
    } else {
      while a1 > a0 { a1 -= 2 * .pi }
      if a0 - a1 > 2 * .pi { a1 = a0 - 2 * .pi }
    }
    let first = c + r * SIMD2(cos(a0), sin(a0))
    if self.current == nil {
      self.move(to: float2(first))
    } else {
      self.addLine(to: float2(first))
    }
    self.commands += Self.arc(center: c, radius: r, from: a0, to: a1)
    self.current = c + r * SIMD2(cos(a1), sin(a1))
  }

  public mutating func addEllipse(center: float2, radii: float2) {
    self.commands += SVGPathData.ellipse(center: SIMD2(center), radii: SIMD2(radii))
    self.current = nil
  }

  public mutating func addEllipse(origin: float2, size: float2) {
    self.addEllipse(center: origin + size * 0.5, radii: size * 0.5)
  }

  public mutating func addRect(origin: float2, size: float2, cornerRadius: Float = 0) {
    self.commands += Self.roundedRect(origin: SIMD2(origin), size: SIMD2(size), radius: Double(cornerRadius))
    self.current = nil
  }

  public mutating func closeSubpath() {
    guard self.current != nil else { return }
    self.commands.append(.close)
    self.current = nil
  }

  // MARK: - Shapes

  /// Cubics of at most a quarter turn each, from angle `a0` to `a1` in radians.
  static func arc(center: SIMD2<Double>, radius: Double, from a0: Double, to a1: Double) -> [SVGPathCommand] {
    let delta = a1 - a0
    guard delta != 0, radius > 0 else { return [] }
    let segments = max(1, Int(ceil(abs(delta) / (.pi / 2) - 1e-9)))
    let step = delta / Double(segments)
    let k = 4.0 / 3.0 * tan(step / 4)
    var commands: [SVGPathCommand] = []
    var angle = a0
    for _ in 0 ..< segments {
      let next = angle + step
      let e0 = SIMD2(cos(angle), sin(angle))
      let e1 = SIMD2(cos(next), sin(next))
      commands.append(.cubic(
        center + radius * (e0 + k * SIMD2(-e0.y, e0.x)),
        center + radius * (e1 - k * SIMD2(-e1.y, e1.x)),
        center + radius * e1
      ))
      angle = next
    }
    return commands
  }

  /// Starts where the top edge does and runs clockwise, as the rounded box `compute2D` trims.
  static func roundedRect(origin: SIMD2<Double>, size: SIMD2<Double>, radius: Double) -> [SVGPathCommand] {
    guard size.x > 0, size.y > 0 else { return [] }
    let r = min(max(radius, 0), min(size.x, size.y) / 2)
    let x0 = origin.x, y0 = origin.y, x1 = origin.x + size.x, y1 = origin.y + size.y
    guard r > 0 else {
      return [.move(SIMD2(x0, y0)), .line(SIMD2(x1, y0)), .line(SIMD2(x1, y1)), .line(SIMD2(x0, y1)), .close]
    }
    var commands: [SVGPathCommand] = [.move(SIMD2(x0 + r, y0)), .line(SIMD2(x1 - r, y0))]
    commands += Self.arc(center: SIMD2(x1 - r, y0 + r), radius: r, from: -.pi / 2, to: 0)
    commands.append(.line(SIMD2(x1, y1 - r)))
    commands += Self.arc(center: SIMD2(x1 - r, y1 - r), radius: r, from: 0, to: .pi / 2)
    commands.append(.line(SIMD2(x0 + r, y1)))
    commands += Self.arc(center: SIMD2(x0 + r, y1 - r), radius: r, from: .pi / 2, to: .pi)
    commands.append(.line(SIMD2(x0, y0 + r)))
    commands += Self.arc(center: SIMD2(x0 + r, y0 + r), radius: r, from: .pi, to: 1.5 * .pi)
    commands.append(.close)
    return commands
  }
}

// MARK: - Morphing

enum PathMorph {
  /// Whether `a` can be interpolated into `b`: the same commands, in the same order.
  static func compatible(_ a: [SVGPathCommand], _ b: [SVGPathCommand]) -> Bool {
    guard a.count == b.count, !a.isEmpty else { return false }
    for (x, y) in zip(a, b) {
      switch (x, y) {
      case (.move, .move), (.line, .line), (.quad, .quad), (.cubic, .cubic), (.close, .close):
        continue
      default:
        return false
      }
    }
    return true
  }

  /// Each point of `a` moved `t` of the way to its counterpart in `b`. Only for compatible paths.
  static func interpolate(_ a: [SVGPathCommand], _ b: [SVGPathCommand], _ t: Double) -> [SVGPathCommand] {
    func mix(_ p: SIMD2<Double>, _ q: SIMD2<Double>) -> SIMD2<Double> { p + (q - p) * t }
    return zip(a, b).map { x, y in
      switch (x, y) {
      case (.move(let p), .move(let q)): .move(mix(p, q))
      case (.line(let p), .line(let q)): .line(mix(p, q))
      case (.quad(let c, let p), .quad(let d, let q)): .quad(mix(c, d), mix(p, q))
      case (.cubic(let c1, let c2, let p), .cubic(let d1, let d2, let q)): .cubic(mix(c1, d1), mix(c2, d2), mix(p, q))
      default: x
      }
    }
  }
}

// MARK: - Flattening

/// A path ready to bake and hit-test: lines and quadratics in local units, with their lengths.
struct VectorGeometry {
  var segments: [VectorSegment] = []
  var totalLength: Float = 0
  /// Holds every point and control point.
  var boundsMin = float2(repeating: .greatestFiniteMagnitude)
  var boundsMax = float2(repeating: -.greatestFiniteMagnitude)
  /// True when the path is one subpath, and closed: its trim wraps round where it starts.
  var isClosed = false

  var isEmpty: Bool { self.segments.isEmpty }

  /// `commands` as segments. A fill closes every subpath; a stroke only those that say so.
  /// Cubics are split into quadratics no further than `tolerance` from them.
  init(_ commands: [SVGPathCommand], closing: Bool, tolerance: Float) {
    var builder = SDFPathBuilder(closesOpenSubPaths: closing)
    for command in commands {
      switch command {
      case .move(let p): builder.move(to: float2(p))
      case .line(let p): builder.line(to: float2(p))
      case .quad(let c, let p): builder.quad(float2(c), float2(p))
      case .cubic(let c1, let c2, let p): builder.cubic(float2(c1), float2(c2), float2(p), tolerance: tolerance)
      case .close: builder.close()
      }
    }
    let (elements, subPaths) = builder.finish()

    var closedCount = 0
    for subPath in subPaths {
      var start = float2()
      var previous = float2()
      for i in Int(subPath.start) ..< Int(subPath.end) {
        let element = elements[i]
        switch element.type {
        case 0:
          start = element.point0
          previous = start
        case 1:
          self.append(VectorSegment(line: previous, element.point0, start: self.totalLength))
          previous = element.point0
        case 2:
          self.append(VectorSegment(quad: previous, element.point0, element.point1, start: self.totalLength))
          previous = element.point1
        case 4:
          closedCount += 1
          if previous != start {
            self.append(VectorSegment(line: previous, start, start: self.totalLength))
          }
          previous = start
        default:
          break
        }
      }
    }
    self.isClosed = subPaths.count == 1 && closedCount == 1
  }

  private mutating func append(_ segment: VectorSegment) {
    self.segments.append(segment)
    self.totalLength += segment.length
    self.boundsMin = simd_min(self.boundsMin, segment.boxMin)
    self.boundsMax = simd_max(self.boundsMax, segment.boxMax)
  }

  /// Nearest point of the path to `p`: squared distance, and position along the path, 0...1.
  func nearest(to p: float2) -> (distanceSquared: Float, along: Float) {
    var best = Float.greatestFiniteMagnitude
    var along: Float = 0
    for segment in self.segments {
      let outside = simd_max(simd_max(segment.boxMin - p, p - segment.boxMax), .zero)
      guard simd_length_squared(outside) < best else { continue }
      // a line exactly, a curve through 8 pieces: plenty for a pointer
      let pieces = segment.isLine != 0 ? 1 : 8
      var previous = segment.a
      for i in 1 ... pieces {
        let t1 = Float(i) / Float(pieces)
        let point = segment.point(at: t1)
        let e = point - previous
        let ee = simd_length_squared(e)
        let u = ee > 0 ? simd_clamp(simd_dot(p - previous, e) / ee, 0, 1) : 0
        let d = simd_length_squared(p - previous - e * u)
        if d < best {
          best = d
          along = segment.start + (Float(i - 1) + u) / Float(pieces) * segment.length
        }
        previous = point
      }
    }
    return (best, self.totalLength > 0 ? along / self.totalLength : 0)
  }

  /// Nonzero winding of the path around `p`, as the bake decides inside.
  func winding(at p: float2) -> Int {
    var winding = 0
    for segment in self.segments {
      guard p.y >= segment.boxMin.y, p.y <= segment.boxMax.y, segment.boxMax.x > p.x else { continue }
      let pieces = segment.isLine != 0 ? 1 : 8
      var previous = segment.a
      for i in 1 ... pieces {
        let point = segment.point(at: Float(i) / Float(pieces))
        let e = point - previous
        let w = p - previous
        let side = e.x * w.y - e.y * w.x
        if previous.y <= p.y, p.y < point.y, side > 0 {
          winding += 1
        } else if point.y <= p.y, p.y < previous.y, side < 0 {
          winding -= 1
        }
        previous = point
      }
    }
    return winding
  }
}
