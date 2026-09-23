import Foundation
import simd

/// How a value travels from where it is to where it was set.
///
/// A plain value, cheap to copy. A spring's derived coefficients are worked out once, when it is
/// made, so sampling it every frame is a handful of flops plus one `exp`.
public struct UIAnimation: Sendable {
  enum Curve: Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    /// `omega` is the undamped angular frequency, `zeta` the damping ratio.
    case spring(omega: Float, zeta: Float)
    /// Progress keyframes: each segment's target is a progress in its `x` lane.
    case keyframes([KeyframeSegment])
  }

  let curve: Curve
  /// Seconds. A spring runs until it settles and ignores this, except when it repeats: then it is
  /// the spring's settling time, which is the length of one cycle.
  private(set) var duration: Float
  /// Seconds to hold the start value before moving.
  public private(set) var delay: Float = 0
  /// How many times the animation plays; -1 is forever.
  private(set) var cycles: Int32 = 1
  /// Every other cycle plays backwards, from the target to the start.
  private(set) var autoreverses = false

  /// A spring still moving after this long is snapped to its target. It only guards against a
  /// degenerate spring (almost no damping); any sensible one settles well before.
  private static let maxSpringDuration: Float = 10

  init(curve: Curve, duration: Float) {
    self.curve = curve
    self.duration = duration
  }

  // MARK: - Curves

  public static func linear(_ duration: Float = 0.25) -> UIAnimation {
    UIAnimation(curve: .linear, duration: duration)
  }

  public static func easeIn(_ duration: Float = 0.25) -> UIAnimation {
    UIAnimation(curve: .easeIn, duration: duration)
  }

  public static func easeOut(_ duration: Float = 0.25) -> UIAnimation {
    UIAnimation(curve: .easeOut, duration: duration)
  }

  public static func easeInOut(_ duration: Float = 0.25) -> UIAnimation {
    UIAnimation(curve: .easeInOut, duration: duration)
  }

  /// What `withAnimation` uses when no animation is named.
  public static let `default` = UIAnimation.easeInOut(0.25)

  /// A damped spring. `response` is roughly the time to reach the target, in seconds;
  /// `dampingFraction` is 1 for no overshoot, less to bounce, more to creep.
  public static func spring(response: Float = 0.5, dampingFraction: Float = 0.825) -> UIAnimation {
    let omega = 2 * Float.pi / max(response, 0.001)
    return UIAnimation(curve: .spring(omega: omega, zeta: max(dampingFraction, 0)), duration: 0)
  }

  /// A curve drawn through keyframes of *progress*: 0 is where the value starts, 1 where it was
  /// set. Values past 1 or under 0 overshoot; the last keyframe should be 1, since that is where
  /// the value ends up whatever it says.
  ///
  /// ```swift
  /// withAnimation(.keyframes([
  ///   .easeOut(1.2, duration: 0.15),
  ///   .easeInOut(0.95, duration: 0.1),
  ///   .easeInOut(1, duration: 0.1),
  /// ])) { self.size = 80 }
  /// ```
  public static func keyframes(_ frames: [UIKeyframe<Float>]) -> UIAnimation {
    let segments = frames.map(\.segment)
    return UIAnimation(curve: .keyframes(segments), duration: segments.reduce(0) { $0 + $1.duration })
  }

  public func delay(_ seconds: Float) -> UIAnimation {
    var copy = self
    copy.delay = max(seconds, 0)
    return copy
  }

  /// Plays the animation `count` times in all. With `autoreverses`, every other play runs
  /// backwards. The value ends where it was set whatever the count, so an even count that
  /// autoreverses jumps back at the end — use an odd one.
  public func repeatCount(_ count: Int, autoreverses: Bool = true) -> UIAnimation {
    self.repeating(Int32(clamping: max(count, 1)), autoreverses: autoreverses)
  }

  /// Plays the animation over and over until the value is set again or the element unmounts.
  /// Rendering never stops while it runs.
  public func repeatForever(autoreverses: Bool = true) -> UIAnimation {
    self.repeating(-1, autoreverses: autoreverses)
  }

  private func repeating(_ cycles: Int32, autoreverses: Bool) -> UIAnimation {
    var copy = self
    copy.cycles = cycles
    copy.autoreverses = autoreverses
    if case .spring(let omega, let zeta) = self.curve {
      copy.duration = Self.settlingTime(omega: omega, zeta: zeta)
    }
    return copy
  }

  /// How long a spring released from rest takes to settle, by the same test `spring` ends on.
  /// Worked out once, when a repeating spring is made.
  private static func settlingTime(omega: Float, zeta: Float) -> Float {
    let step: Float = 1.0 / 240
    var t = step
    while t < Self.maxSpringDuration {
      let sample = Self.spring(
        omega: omega, zeta: zeta, from: SIMD4(repeating: 1), to: .zero, velocity: .zero, t: t
      )
      if sample.done { return t }
      t += step
    }
    return Self.maxSpringDuration
  }

  // MARK: - Sampling

  /// The value `elapsed` seconds after the animation started, and whether it has arrived.
  ///
  /// `velocity` is the value's rate of change when the animation started. Only a spring uses it:
  /// that is what keeps a spring retargeted mid-flight moving smoothly instead of stopping dead.
  func sample(
    from: SIMD4<Float>, to: SIMD4<Float>, velocity: SIMD4<Float>, elapsed: Float
  ) -> (value: SIMD4<Float>, done: Bool) {
    let t = elapsed - self.delay
    guard t > 0 else { return (from, false) }
    guard self.cycles != 1 else {
      return self.sampleCycle(from: from, to: to, velocity: velocity, t: t, reversed: false)
    }

    guard self.duration > 0 else { return (to, true) }
    let cycle = (t / self.duration).rounded(.down)
    if self.cycles > 0, cycle >= Float(self.cycles) { return (to, true) }

    let reversed = self.autoreverses && Int(cycle) % 2 == 1
    let local = t - cycle * self.duration
    let sample = self.sampleCycle(
      from: from, to: to, velocity: cycle == 0 ? velocity : .zero, t: local, reversed: reversed
    )
    return (sample.value, false)
  }

  /// One play of the animation, `t` seconds in. A reversed play runs the same motion backwards.
  private func sampleCycle(
    from: SIMD4<Float>, to: SIMD4<Float>, velocity: SIMD4<Float>, t: Float, reversed: Bool
  ) -> (value: SIMD4<Float>, done: Bool) {
    switch self.curve {
    case .spring(let omega, let zeta):
      return reversed
        ? Self.spring(omega: omega, zeta: zeta, from: to, to: from, velocity: .zero, t: t)
        : Self.spring(omega: omega, zeta: zeta, from: from, to: to, velocity: velocity, t: t)
    case .keyframes(let segments):
      guard t < self.duration else { return (reversed ? from : to, true) }
      let progress = Self.sample(segments, start: .zero, t: reversed ? self.duration - t : t).value.x
      return (from + (to - from) * progress, false)
    default:
      guard self.duration > 0, t < self.duration else { return (reversed ? from : to, true) }
      let x = t / self.duration
      let progress = Self.ease(self.curve, reversed ? 1 - x : x)
      return (from + (to - from) * progress, false)
    }
  }

  /// Walks keyframe segments: each runs from the previous one's target (the first from `start`)
  /// to its own, over its own duration and curve. Shared by the progress curve and by value
  /// keyframes, which differ only in what the lanes mean.
  static func sample(
    _ segments: [KeyframeSegment], start: SIMD4<Float>, t: Float
  ) -> (value: SIMD4<Float>, done: Bool) {
    var from = start
    var t = t
    for segment in segments {
      if t < segment.duration {
        switch segment.curve {
        case .spring(let omega, let zeta):
          let value = Self.spring(
            omega: omega, zeta: zeta, from: from, to: segment.target, velocity: .zero, t: t
          ).value
          return (value, false)
        default:
          let progress = Self.ease(segment.curve, t / segment.duration)
          return (from + (segment.target - from) * progress, false)
        }
      }
      t -= segment.duration
      from = segment.target
    }
    return (from, true)
  }

  /// Closed-form polynomials: no per-frame Newton solve of a cubic Bézier.
  static func ease(_ curve: Curve, _ x: Float) -> Float {
    switch curve {
    case .easeIn:
      return x * x * x
    case .easeOut:
      let inverse = 1 - x
      return 1 - inverse * inverse * inverse
    case .easeInOut:
      if x < 0.5 { return 4 * x * x * x }
      let inverse = -2 * x + 2
      return 1 - inverse * inverse * inverse * 0.5
    default:
      return x
    }
  }

  /// The analytic solution of a damped oscillator, run on the displacement from the target.
  ///
  /// Alongside the value it computes an upper bound on how far any lane can still be from the
  /// target. Once that drops under a small fraction of the distance travelled, the spring is
  /// done and snaps; without that its asymptotic tail would keep the UI rendering for seconds.
  static func spring(
    omega: Float, zeta: Float,
    from: SIMD4<Float>, to: SIMD4<Float>, velocity v0: SIMD4<Float>, t: Float
  ) -> (value: SIMD4<Float>, done: Bool) {
    let x0 = from - to
    let displacement: SIMD4<Float>
    let bound: SIMD4<Float>

    if zeta < 1 {
      let omegaD = omega * (1 - zeta * zeta).squareRoot()
      let envelope = exp(-zeta * omega * t)
      let c2 = (v0 + zeta * omega * x0) / omegaD
      displacement = envelope * (x0 * cos(omegaD * t) + c2 * sin(omegaD * t))
      bound = envelope * (abs(x0) + abs(c2))
    } else if zeta == 1 {
      let envelope = exp(-omega * t)
      let c2 = v0 + omega * x0
      displacement = envelope * (x0 + c2 * t)
      bound = envelope * (abs(x0) + abs(c2) * t)
    } else {
      let root = (zeta * zeta - 1).squareRoot()
      let r1 = -omega * (zeta - root)
      let r2 = -omega * (zeta + root)
      let c1 = (v0 - r2 * x0) / (r1 - r2)
      let c2 = x0 - c1
      let e1 = exp(r1 * t)
      let e2 = exp(r2 * t)
      displacement = c1 * e1 + c2 * e2
      bound = abs(c1) * e1 + abs(c2) * e2
    }

    let range = abs(x0).max()
    let epsilon = max(1e-4, range * 5e-4)
    if bound.max() < epsilon || t >= Self.maxSpringDuration {
      return (to, true)
    }
    return (to + displacement, false)
  }
}
