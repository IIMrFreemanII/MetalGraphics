import simd

/// One step of a keyframe track, packed: the value to reach, how long to take, and how.
struct KeyframeSegment: Sendable {
  let target: SIMD4<Float>
  let duration: Float
  /// Never `.keyframes`: a segment is a single move.
  let curve: UIAnimation.Curve
}

/// Moves to `value` over `duration` seconds, starting from wherever the previous keyframe ended.
///
/// Used two ways: as progress in `UIAnimation.keyframes`, and as absolute values in the
/// tracks of `UIKeyframes`.
public struct UIKeyframe<V: UIAnimatable>: Sendable {
  let segment: KeyframeSegment

  private init(_ value: V, _ duration: Float, _ curve: UIAnimation.Curve) {
    self.segment = KeyframeSegment(target: value.packed, duration: max(duration, 0), curve: curve)
  }

  public static func linear(_ value: V, duration: Float) -> Self {
    Self(value, duration, .linear)
  }

  public static func easeIn(_ value: V, duration: Float) -> Self {
    Self(value, duration, .easeIn)
  }

  public static func easeOut(_ value: V, duration: Float) -> Self {
    Self(value, duration, .easeOut)
  }

  public static func easeInOut(_ value: V, duration: Float) -> Self {
    Self(value, duration, .easeInOut)
  }

  /// A spring towards `value`, cut off after `duration`: whatever is left of its motion then
  /// is snapped, so give it long enough to settle.
  public static func spring(
    _ value: V, duration: Float, response: Float = 0.5, dampingFraction: Float = 0.825
  ) -> Self {
    Self(value, duration, UIAnimation.spring(response: response, dampingFraction: dampingFraction).curve)
  }
}

/// Tracks of keyframes for `.keyframes(_:trigger:)`, one per effect channel. An empty track
/// leaves its channel alone. Each track starts from the channel's value when it is played.
///
/// ```swift
/// UIKeyframes(offset: [
///   .linear(float2(-8, 0), duration: 0.05),
///   .linear(float2(8, 0), duration: 0.1),
///   .linear(float2(-6, 0), duration: 0.1),
///   .spring(.zero, duration: 0.3),
/// ])
/// ```
public struct UIKeyframes: Sendable {
  let opacity: [KeyframeSegment]
  let offset: [KeyframeSegment]
  let scale: [KeyframeSegment]
  /// The longest track's length.
  let duration: Float

  public init(
    opacity: [UIKeyframe<Float>] = [], offset: [UIKeyframe<float2>] = [], scale: [UIKeyframe<Float>] = []
  ) {
    self.opacity = opacity.map(\.segment)
    self.offset = offset.map(\.segment)
    self.scale = scale.map(\.segment)

    let length = { (segments: [KeyframeSegment]) in segments.reduce(Float(0)) { $0 + $1.duration } }
    self.duration = max(length(self.opacity), length(self.offset), length(self.scale))
  }
}

/// Plays `UIKeyframes` on its own opacity, offset and scale whenever its trigger changes.
///
/// The whole play is one animator entry, a clock running from 0 to the tracks' length; each
/// frame samples every track at that time. It ends on the tracks' last values.
public final class KeyframeElement : EffectElement {
  public let keyframes: UIKeyframes

  private var trigger: Any
  /// The channels as they were when the play started: each track's first keyframe moves from here.
  private var startOpacity: Float = 1
  private var startOffset: float2 = .zero
  private var startScale: Float = 1

  public init<V: Equatable>(
    _ keyframes: UIKeyframes, trigger: V, @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.keyframes = keyframes
    self.trigger = trigger
    super.init(content: content)
  }

  /// Plays the keyframes if `value` differs from the last trigger. A play still running restarts
  /// from wherever it has got to.
  public func setTrigger<V: Equatable>(_ value: V, _ context: UIContext) {
    if let old = self.trigger as? V, old == value { return }
    self.trigger = value
    self.play(context)
  }

  private func play(_ context: UIContext) {
    self.startOpacity = self.opacity
    self.startOffset = self.offset
    self.startScale = self.scale

    let total = self.keyframes.duration
    context.animator.run(
      self, .keyframes, from: Float(0).packed, to: Float(total).packed, .linear(total), context,
      restart: true,
      apply: { element, value, context in
        unsafeDowncast(element, to: KeyframeElement.self).show(at: value.x, context)
      },
      completion: nil
    )
  }

  private func show(at time: Float, _ context: UIContext) {
    let tracks = self.keyframes
    if !tracks.opacity.isEmpty {
      self.opacity = UIAnimation.sample(tracks.opacity, start: self.startOpacity.packed, t: time).value.x
    }
    if !tracks.offset.isEmpty {
      self.offset = float2(packed: UIAnimation.sample(tracks.offset, start: self.startOffset.packed, t: time).value)
    }
    if !tracks.scale.isEmpty {
      self.scale = UIAnimation.sample(tracks.scale, start: self.startScale.packed, t: time).value.x
    }
    context.invalidate()
  }
}
