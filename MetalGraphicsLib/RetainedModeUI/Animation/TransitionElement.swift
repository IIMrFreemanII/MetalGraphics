import simd

/// Plays a `UITransition` when its subtree is inserted or removed with an animation.
///
/// The parent finds it by walking down from the child it inserts or removes, through wrappers
/// that draw nothing themselves (see `UIElement.transitionOnSpine`). So
/// `.transition(.opacity).onTap { … }` still transitions although the `HittableView` is what the
/// parent holds.
///
/// Its three channels move together as one animation of a 0 → 1 progress between two states,
/// which is one animator entry and one completion for the whole transition. A removal
/// interrupted by a re-insertion simply starts a new progress from wherever the element is.
public final class TransitionElement : EffectElement {
  public let transition: UITransition

  private var fromState = TransitionState.identity
  private var toState = TransitionState.identity

  public init(_ transition: UITransition, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.transition = transition
    super.init(content: content)
  }

  private var currentState: TransitionState {
    TransitionState(opacity: self.opacity, offset: self.offset, scale: self.scale)
  }

  /// Jumps to the insertion state, then animates to identity.
  func animateIn(_ animation: UIAnimation, _ context: UIContext) {
    self.show(self.transition.insertion, context)
    self.animate(to: .identity, animation, context, completion: nil)
  }

  /// Brings back an element that was leaving, from wherever it has got to.
  func animateBack(_ animation: UIAnimation?, _ context: UIContext) {
    guard let animation else {
      context.animator.cancel(self, .transition)
      self.show(.identity, context)
      return
    }
    self.animate(to: .identity, animation, context, completion: nil)
  }

  /// Animates to the removal state; `completion` runs once it gets there.
  func animateOut(_ animation: UIAnimation, _ context: UIContext, completion: @escaping () -> Void) {
    self.animate(to: self.transition.removal, animation, context, completion: completion)
  }

  private func animate(
    to target: TransitionState, _ animation: UIAnimation, _ context: UIContext,
    completion: (() -> Void)?
  ) {
    self.fromState = self.currentState
    self.toState = target
    context.animator.run(
      self, .transition, from: Float(0).packed, to: Float(1).packed, animation, context,
      restart: true,
      apply: { element, value, context in
        unsafeDowncast(element, to: TransitionElement.self).setProgress(value.x, context)
      },
      completion: completion
    )
  }

  private func setProgress(_ progress: Float, _ context: UIContext) {
    self.show(self.fromState.mixed(with: self.toState, progress), context)
  }

  private func show(_ state: TransitionState, _ context: UIContext) {
    self.opacity = state.opacity
    self.offset = state.offset
    self.scale = state.scale
    context.invalidate()
  }
}
