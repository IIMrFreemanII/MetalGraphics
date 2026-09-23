extension UIElement {
  public func padding(_ inset: Inset) -> Padding {
    Padding(inset) {
      self
    }
  }
  
  public func frame(width: Float, height: Float) -> Frame {
    Frame(.init(width, height)) {
      self
    }
  }
  
  public func background(_ color: float4) -> Background {
    Background(color) {
      self
    }
  }
  
  public func onTap(_ callback: @escaping (Input) -> Void) -> HittableView {
    HittableView(onTap: callback) {
      self
    }
  }
  
  public func onHover(_ callback: @escaping (Bool, Input) -> Void) -> HittableView {
    HittableView(onHover: callback) {
      self
    }
  }

  public func opacity(_ opacity: Float) -> EffectElement {
    EffectElement(opacity: opacity) {
      self
    }
  }

  /// Moves the drawn content by `offset`. Layout and hit-testing still see it where it was.
  public func offset(_ offset: float2) -> EffectElement {
    EffectElement(offset: offset) {
      self
    }
  }

  /// How this element enters and leaves when its insertion or removal is animated.
  public func transition(_ transition: UITransition) -> TransitionElement {
    TransitionElement(transition) {
      self
    }
  }

  /// Plays `keyframes` on this element's opacity, offset and scale each time `trigger` changes.
  /// Like an effect, it moves only what is drawn.
  public func keyframes<V: Equatable>(_ keyframes: UIKeyframes, trigger: V) -> KeyframeElement {
    KeyframeElement(keyframes, trigger: trigger) {
      self
    }
  }

  /// Animates the changes a write to the states `value` reads makes to this element — to the
  /// modifiers before this one in the chain, and to everything under it — with `animation`.
  ///
  /// A marker for `@Component`, which decides at compile time which updates animate. At runtime
  /// it adds nothing to the tree and returns the element it was called on.
  public func animation<V>(_ animation: UIAnimation?, value: V) -> Self {
    self
  }
}
