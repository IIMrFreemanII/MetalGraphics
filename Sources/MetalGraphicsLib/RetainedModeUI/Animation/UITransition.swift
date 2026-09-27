import simd

/// The look of an element that is not there: what an inserted element animates in from, and
/// what a removed one animates out to.
public struct TransitionState: Equatable, Sendable {
  public var opacity: Float = 1
  public var offset: float2 = .zero
  public var scale: Float = 1

  public static let identity = TransitionState()

  public init(opacity: Float = 1, offset: float2 = .zero, scale: Float = 1) {
    self.opacity = opacity
    self.offset = offset
    self.scale = scale
  }

  func mixed(with other: TransitionState, _ t: Float) -> TransitionState {
    TransitionState(
      opacity: self.opacity + (other.opacity - self.opacity) * t,
      offset: self.offset + (other.offset - self.offset) * t,
      scale: self.scale + (other.scale - self.scale) * t
    )
  }
}

/// How an element enters and leaves, attached with `.transition(_:)`.
///
/// It only animates when the insertion or removal itself is animated — inside an
/// `.animation(_:value:)` scope that the change triggers, or inside `withAnimation`.
public struct UITransition: Sendable {
  public var insertion: TransitionState
  public var removal: TransitionState

  public init(insertion: TransitionState, removal: TransitionState) {
    self.insertion = insertion
    self.removal = removal
  }

  public static let identity = UITransition(insertion: .identity, removal: .identity)
  public static let opacity = UITransition.symmetric(TransitionState(opacity: 0))

  /// Slides in from `offset` and back out to it.
  public static func move(_ offset: float2) -> UITransition {
    .symmetric(TransitionState(offset: offset))
  }

  /// Grows in from `scale` and shrinks back to it, about the element's centre.
  public static func scale(_ scale: Float = 0.5) -> UITransition {
    .symmetric(TransitionState(scale: scale))
  }

  public static func asymmetric(insertion: UITransition, removal: UITransition) -> UITransition {
    UITransition(insertion: insertion.insertion, removal: removal.removal)
  }

  /// Both at once: opacities multiply, offsets add, scales multiply.
  public func combined(with other: UITransition) -> UITransition {
    UITransition(
      insertion: Self.combine(self.insertion, other.insertion),
      removal: Self.combine(self.removal, other.removal)
    )
  }

  private static func symmetric(_ state: TransitionState) -> UITransition {
    UITransition(insertion: state, removal: state)
  }

  private static func combine(_ a: TransitionState, _ b: TransitionState) -> TransitionState {
    TransitionState(opacity: a.opacity * b.opacity, offset: a.offset + b.offset, scale: a.scale * b.scale)
  }
}
