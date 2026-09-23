import simd

@MainActor open class UIElement {
  public var mounted = false

  /// True while this element plays its removal transition. Its parent still holds and lays it
  /// out, but it no longer counts as one of the parent's children, and nothing under it can be
  /// hit.
  public internal(set) var isLeaving = false

  /// Where the container that lays this element out last put it, relative to the container's
  /// own position. Nil until then, and again once unmounted. See `place(_:at:in:)`.
  internal var placement: float2? = nil

  /// How far this element is drawn from where layout put it, while it slides there. Visual
  /// only, like an effect: layout and hit-testing already see it in its new place.
  internal var slideOffset: float2 = .zero

  public init() {}
  
  /// The element's own mount behaviour. Built-in elements override this to register themselves
  /// with the context; `@Component` generates it, which is why a component must not write one (F7).
  ///
  /// To run your own code on mount, override `onMount(_:)` instead.
  open func mount(_ context: UIContext) -> Void {}
  
  /// Called just after this element mounts, before its children do.
  ///
  /// The hook to override in your own elements and components. Unlike `mount(_:)` it is never
  /// generated and never owned by the macro, so overriding it can never collide with `@Component`.
  open func onMount(_ context: UIContext) -> Void {}
  
  // Mounts this element, then its children. The one mount flow for every element kind;
  // containers only differ in what `forEachChild` visits.
  internal final func handleMount(_ context: UIContext) -> Void {
    guard !self.mounted else { return }
    self.mounted = true
    self.mount(context)
    self.onMount(context)

    self.forEachChild { $0.handleMount(context) }
  }
  
  /// The element's own unmount behaviour. The mirror of `mount(_:)`, and macro-owned in the same
  /// way. To run your own code on unmount, override `onUnmount(_:)` instead.
  open func unmount(_ context: UIContext) -> Void {}

  /// Called just before this element unmounts, before its children do.
  open func onUnmount(_ context: UIContext) -> Void {}

  internal final func handleUnmount(_ context: UIContext) -> Void {
    guard self.mounted else { return }
    self.mounted = false
    self.onUnmount(context)
    self.unmount(context)

    self.forEachChild { $0.handleUnmount(context) }

    // An unmounted element is never animated. Snapping here, rather than letting the animator
    // notice on its next tick, is what lets it hold elements without retaining them.
    context.animator.finishAll(self, context)
    // A child that was leaving would otherwise come back on remount, stuck in its removal state.
    self.dropLeaving()
    self.placement = nil
  }

  /// Forgets children that were playing a removal transition. They are already unmounted.
  internal func dropLeaving() -> Void {}

  /// The `TransitionElement` that transitions this element in and out, if any: this element, or
  /// the first one found walking down through single-child wrappers that draw nothing
  /// themselves. A drawing element or a container ends the walk, since a transition below it
  /// would only move part of what is inserted.
  var transitionOnSpine: TransitionElement? {
    var current: UIElement = self
    while true {
      if let transition = current as? TransitionElement { return transition }
      guard let single = current as? SingleChildElement, !(current is UIRenderableElement),
            let child = single.child
      else { return nil }
      current = child
    }
  }

  // Visits the current children. Leaves have none; containers override this.
  internal func forEachChild(_ body: (UIElement) -> Void) -> Void {}

  // Applies content at construction time, before the element is mounted.
  internal func applyContent(_ elements: [UIElement]) -> Void {
    assertionFailure("\(type(of: self)) does not accept content")
  }

  open func debugHierarchy(_ offset: String) -> Void {
    print(offset + "\(self)".split(separator: ".").last!)
  }
  
  open func calcSize(_ availableSize: float2) -> float2 {
    return .init()
  }
  
  open func getSize() -> float2 {
    return .init()
  }
  
  open func calcPosition(_ position: float2) -> Void {}

  /// Positions `child` at `origin`, recording where that is relative to `containerOrigin`.
  ///
  /// Containers that stack or align their children position them through this. In a layout pass
  /// caused by an animated change, a child whose place within its container moved slides there
  /// from where it was drawn, instead of jumping. Placements are relative so that a container
  /// that moves slides as one, rather than every element under it sliding on its own.
  public final func place(_ child: UIElement, at origin: float2, in containerOrigin: float2) -> Void {
    let placement = origin - containerOrigin
    if let pass = LayoutPass.current, let old = child.placement, old != placement {
      child.startSlide(by: old - placement, pass)
    }
    child.placement = placement
    child.calcPosition(origin)
  }

  private func startSlide(by delta: float2, _ pass: LayoutPass) -> Void {
    let context = pass.context
    let from = self.slideOffset + delta
    if self.slideOffset == .zero {
      // Not an effect node yet: the next render has to collect it as one.
      context.invalidate(.treeOrder)
    }
    self.slideOffset = from
    context.animator.run(
      self, .slide, from: from.packed, to: float2.zero.packed, pass.animation, context,
      restart: true, group: pass.group,
      apply: { element, value, context in
        element.slideOffset = float2(packed: value)
        context.invalidate()
      },
      completion: nil
    )
  }

  /// This element's own contribution to how it and everything under it is drawn: its slide.
  /// `EffectElement` adds its opacity, scale and offset.
  var localEffect: EffectState {
    EffectState(opacity: 1, scale: 1, translate: self.slideOffset)
  }

  /// Whether `UIContext` has to resolve an effect for this element this frame.
  var hasEffect: Bool { self.slideOffset != .zero }
}

/// The animated layout pass under way, if any. Set by `UIContext.update` only around the
/// positioning of a pass that an animated change caused, which is what `place` checks.
@MainActor
struct LayoutPass {
  static var current: LayoutPass? = nil

  unowned let context: UIContext
  let animation: UIAnimation
  let group: AnimationGroup?
}
