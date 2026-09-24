import QuartzCore
import simd

/// Which property of an element an animation drives. Together with the element's identity it
/// keys a running animation: a second animation of the same property retargets the first.
///
/// A small enum rather than a key path, because the lookup sits on every animatable setter and
/// hashing a key path walks its components.
public enum AnimatedProperty: UInt8, Sendable {
  case color
  case size
  case inset
  case spacing
  case opacity
  case offset
  /// A `TransitionElement`'s progress between two effect states.
  case transition
  /// An element's slide from where layout last put it, towards where it puts it now.
  case slide
  /// A `KeyframeElement`'s clock.
  case keyframes
  /// A `Text`'s presented font size.
  case fontSize
  /// Vector shape geometry and style.
  case center
  case radius
  case origin
  case cornerRadius
  case lineWidth
  case trimFrom
  case trimTo
  case rotation
  case scale
  /// A `Path`'s progress between two outlines.
  case morph
  /// The value a `Path` builds its outline from.
  case pathValue
}

/// Drives every running animation, once per frame, from `UIContext.update`.
///
/// Nothing here is generic. Values are packed into `SIMD4<Float>`, running animations are one
/// concrete struct in a flat array, and each frame is a linear pass over it: sample the curve,
/// hand the value to the element's own setter. The setter is what invalidates layout or render,
/// exactly as a non-animated write would.
///
/// The element's property is the *presented* value and `@State` is the model, so a retarget
/// mid-flight simply starts from wherever the element is now.
@MainActor
public final class Animator {
  struct Key: Hashable {
    let element: ObjectIdentifier
    let property: AnimatedProperty
  }

  /// Writes a packed value into the element. Always a closure literal that captures nothing,
  /// so storing one allocates nothing.
  public typealias Apply = (UIElement, SIMD4<Float>, UIContext) -> Void

  struct Running {
    /// Safe without retain traffic: an element is only animated while mounted, and unmounting
    /// cancels its animations, so an entry never outlives its element. The one exception, an
    /// element still mounting, is held by `retained` until its first tick.
    unowned(unsafe) let element: UIElement
    /// Set only while the element was not yet mounted when the animation started.
    var retained: UIElement?
    let key: Key
    let animation: UIAnimation
    let from: SIMD4<Float>
    let to: SIMD4<Float>
    let initialVelocity: SIMD4<Float>
    var start: Double
    let apply: Apply
    let completion: (() -> Void)?
    /// The `withAnimation` completion group this animation belongs to, if any.
    let group: AnimationGroup?

    /// The last value written and when, for the velocity a retargeted spring starts with.
    var last: SIMD4<Float>
    var lastTime: Double
    var velocity: SIMD4<Float> = .zero
  }

  private var running: [Running] = []
  private var index: [Key: Int] = [:]
  /// `withAnimation` completions whose groups are over, run at the end of the next tick.
  private var pendingCompletions: [() -> Void] = []

  public init() {}

  /// True when nothing is animating. Checked before any hashing on every setter's fast path.
  public var isIdle: Bool { self.running.isEmpty && self.pendingCompletions.isEmpty }

  // MARK: - Writing

  /// The single door every animatable setter goes through.
  ///
  /// With an animation, starts or retargets one — unless it is already heading to `value`, which
  /// is what makes the redundant writes of a multi-state expression harmless. Without one, writes
  /// straight through, cancelling any animation heading elsewhere; an animation already heading
  /// to `value` is left to finish, so an unrelated state's write does not make it jump.
  public func set<V: UIAnimatable>(
    _ element: UIElement, _ property: AnimatedProperty,
    from current: V, to value: V, _ animation: UIAnimation?, _ context: UIContext,
    apply: @escaping Apply
  ) {
    let target = value.packed

    guard let animation else {
      if !self.running.isEmpty, let i = self.index[Key(element: ObjectIdentifier(element), property: property)] {
        if self.running[i].to == target { return }
        self.remove(at: i)
      }
      apply(element, target, context)
      return
    }

    self.run(
      element, property, from: current.packed, to: target, animation, context,
      restart: false, apply: apply, completion: nil
    )
  }

  /// Starts an animation of `property` from `from` to `to`.
  ///
  /// `restart` replaces a running one even when it heads to the same target; a transition needs
  /// that, since its progress always runs 0 → 1 while the states it moves between change.
  /// `completion` runs once the value arrives, never when the animation is cancelled or
  /// replaced. `group` defaults to the enclosing `withAnimation`'s.
  ///
  /// An element that is not mounted yet — one a component's `onMount` animates, before its
  /// children have mounted — is held until the first tick. It starts then if it has mounted,
  /// and snaps otherwise.
  func run(
    _ element: UIElement, _ property: AnimatedProperty,
    from: SIMD4<Float>, to: SIMD4<Float>, _ animation: UIAnimation, _ context: UIContext,
    restart: Bool, group: AnimationGroup? = UITransaction.group,
    apply: @escaping Apply, completion: (() -> Void)?
  ) {
    let key = Key(element: ObjectIdentifier(element), property: property)
    let existing = self.index[key]

    if let existing, !restart, self.running[existing].to == to { return }
    if existing == nil, from == to {
      apply(element, to, context)
      completion?()
      return
    }

    let now = CACurrentMediaTime()
    group?.retain()
    let entry = Running(
      element: element, retained: element.mounted ? nil : element,
      key: key, animation: animation,
      from: from, to: to,
      initialVelocity: existing.map { self.running[$0].velocity } ?? .zero,
      start: now, apply: apply, completion: completion, group: group,
      last: from, lastTime: now
    )

    if let existing {
      self.release(self.running[existing])
      self.running[existing] = entry
    } else {
      self.index[key] = self.running.count
      self.running.append(entry)
    }
  }

  // MARK: - Cancelling

  public func cancel(_ element: UIElement, _ property: AnimatedProperty) {
    guard !self.running.isEmpty,
          let i = self.index[Key(element: ObjectIdentifier(element), property: property)]
    else { return }
    self.remove(at: i)
  }

  /// Snaps every animation of `element` to its target and drops it. Called on unmount, which is
  /// what makes the `unowned(unsafe)` reference in `Running` safe.
  func finishAll(_ element: UIElement, _ context: UIContext) {
    guard !self.running.isEmpty else { return }
    let id = ObjectIdentifier(element)

    var i = 0
    while i < self.running.count {
      if self.running[i].key.element == id {
        let entry = self.running[i]
        self.remove(at: i)
        entry.apply(entry.element, entry.to, context)
      } else {
        i += 1
      }
    }
  }

  // MARK: - Frame

  /// Advances every animation to `now`. Completions run after the pass, since they change the
  /// tree and may start new animations.
  func tick(_ now: Double, _ context: UIContext) {
    guard !self.isIdle else { return }

    var completions: [() -> Void] = []
    var i = 0
    while i < self.running.count {
      var entry = self.running[i]

      if entry.retained != nil {
        entry.retained = nil
        self.running[i].retained = nil
        if entry.element.mounted {
          entry.start = now
          entry.lastTime = now
        }
      }

      guard entry.element.mounted else {
        self.remove(at: i)
        entry.apply(entry.element, entry.to, context)
        continue
      }

      let sample = entry.animation.sample(
        from: entry.from, to: entry.to, velocity: entry.initialVelocity,
        elapsed: Float(now - entry.start)
      )
      entry.apply(entry.element, sample.value, context)

      if sample.done {
        self.remove(at: i)
        if let completion = entry.completion { completions.append(completion) }
        continue
      }

      let dt = Float(now - entry.lastTime)
      if dt > 0 {
        entry.velocity = (sample.value - entry.last) / dt
      }
      entry.last = sample.value
      entry.lastTime = now
      self.running[i] = entry
      i += 1
    }

    completions.forEach { $0() }

    // Group completions last: an entry's own completion (a finished removal unmounting its
    // element) can end more animations, and so more groups.
    while !self.pendingCompletions.isEmpty {
      let pending = self.pendingCompletions
      self.pendingCompletions.removeAll()
      pending.forEach { $0() }
    }
  }

  // MARK: - Groups

  /// Holds `group` open without an animation: a layout pass that will start slides for it.
  func hold(_ group: AnimationGroup) {
    group.retain()
  }

  func release(_ group: AnimationGroup) {
    group.release { self.pendingCompletions.append($0) }
  }

  private func release(_ entry: Running) {
    if let group = entry.group { self.release(group) }
  }

  /// Swap-remove, so dropping an entry is O(1) whatever its position.
  private func remove(at i: Int) {
    self.release(self.running[i])
    let key = self.running[i].key
    let last = self.running.count - 1
    if i != last {
      self.running[i] = self.running[last]
      self.index[self.running[i].key] = i
    }
    self.running.removeLast()
    self.index.removeValue(forKey: key)
  }
}
