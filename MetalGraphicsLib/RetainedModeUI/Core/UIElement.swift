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

  // Visits the current children back to front: what `UIContext` draws and hit-tests them in.
  // The order they are in, unless `.zIndex` says otherwise.
  internal func forEachChildInPaintOrder(_ body: (UIElement) -> Void) -> Void {
    self.forEachChild(body)
  }

  // Applies content at construction time, before the element is mounted.
  internal func applyContent(_ elements: [UIElement]) -> Void {
    assertionFailure("\(type(of: self)) does not accept content")
  }

  open func debugHierarchy(_ offset: String) -> Void {
    print(offset + "\(self)".split(separator: ".").last!)
  }
  
  // MARK: - Layout
  //
  // Layout is SwiftUI's: a parent proposes a size, the child answers with the size it takes,
  // and the parent places it. It happens in two passes over the tree:
  //
  // - `calcSize` commits: it is called once per element per pass, with the proposal the parent
  //   settled on, and stores what the element needs to be placed and drawn.
  // - `calcPosition` then places the element and its children at the sizes committed.
  //
  // To settle on a proposal, a parent may first `measure` a child at others, which commits
  // nothing. Stacks measure each child at its smallest and largest to share space by
  // flexibility.

  /// The size this element takes when offered `proposal`. Commits nothing, so it may be called
  /// any number of times; implementations measure their children with `measure`, never
  /// `calcSize`.
  ///
  /// Must depend only on the element's properties and its children, never on what the last
  /// `calcSize` stored: answers are reused for the rest of the layout pass.
  open func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    .zero
  }

  /// `sizeThatFits`, remembered for the rest of the layout pass.
  public final func measure(_ proposal: ProposedSize) -> float2 {
    let generation = LayoutPass.generation
    if let size = self.measureCache.lookup(proposal, generation) {
      return size
    }
    let size = self.sizeThatFits(proposal)
    self.measureCache.store(proposal, size, generation)
    return size
  }

  private var measureCache = MeasureCache()

  /// Sizes this element for `proposal`, commits the result, and returns it. Called once per
  /// layout pass, by the parent, with the proposal it settled on.
  open func calcSize(_ proposal: ProposedSize) -> float2 {
    .zero
  }

  /// The axis of the stack this element is directly in, set by the stack as it lays it out: 0
  /// horizontal, 1 vertical, nil outside one. A `Spacer` grows and a `Divider` runs by it.
  internal var stackAxis: Int? = nil

  /// Set by `.hidden()`: laid out as usual, but neither drawn nor hit, nor anything under it.
  public internal(set) var isHidden = false

  // MARK: - Layout values

  /// What layout modifiers that wrap nothing set on this element: its priority, z-index,
  /// alignment guides and grid cell options. Nil until one is set, which is almost always, so
  /// an element that sets none pays one pointer for them all.
  private var traits: LayoutTraits? = nil

  private var ensuredTraits: LayoutTraits {
    if let traits = self.traits { return traits }
    let traits = LayoutTraits()
    self.traits = traits
    return traits
  }

  /// Set by `.alignmentGuide(_:computeValue:)`, latest last; nil when never set.
  internal var ownGuides: [(key: AlignmentKey, compute: (ViewDimensions) -> Float)]? {
    get { self.traits?.guides }
    set { self.ensuredTraits.guides = newValue }
  }

  /// Where `key`'s guide lies in this element, from its top left along the guide's axis, when
  /// it is offered `proposal` and takes `size`: what the element or its content defines, else
  /// the guide's default.
  public final func alignmentValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float {
    // Nothing overrides a fraction guide until some element has an explicit one.
    if key.isFraction && !AlignmentKey.anyExplicit {
      return key.defaultValue(size)
    }
    return self.guideValue(key, proposal, size) ?? key.defaultValue(size)
  }

  /// The guide this element defines for `key` when offered `proposal` and sized `size`, or nil
  /// for the default. Its own explicit guide here; a text adds its baselines, and wrappers and
  /// containers pass on what their content defines, moved to where they put it.
  open func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    self.explicitGuide(key, size)
  }

  final func explicitGuide(_ key: AlignmentKey, _ size: float2) -> Float? {
    guard let guides = self.ownGuides else { return nil }
    for guide in guides.reversed() where guide.key == key {
      return guide.compute(ViewDimensions(size))
    }
    return nil
  }

  /// Where `child`, offered `proposal` and sized `childSize`, goes within a box of `size` so
  /// that its `alignment` guides meet the box's own: `(size - childSize) * alignment` unless a
  /// guide is not a plain fraction, or the child defines one. Negative when the child is larger.
  final func alignedOffset(
    _ child: UIElement, _ alignment: Alignment, in size: float2, _ proposal: ProposedSize, _ childSize: float2
  ) -> float2 {
    var offset = float2()
    for axis in 0..<2 {
      let key = alignment.key(axis)
      offset[axis] = key.defaultValue(size) - child.alignmentValue(key, proposal, childSize)
    }
    return offset
  }

  final func addGuide(_ key: AlignmentKey, _ compute: @escaping (ViewDimensions) -> Float) {
    AlignmentKey.anyExplicit = true
    if self.ownGuides == nil {
      self.ownGuides = []
    }
    self.ownGuides!.append((key, compute))
  }

  /// Set by `.zIndex(_:)`; nil when never set. See `zIndex`.
  internal var ownZIndex: Float? {
    get { self.traits?.zIndex }
    set { self.ensuredTraits.zIndex = newValue }
  }

  /// Where this element is drawn among its siblings: higher in front. Siblings with the same
  /// index keep their order. 0 by default; read through the wrappers around the element that set
  /// it, like `layoutPriority`.
  public var zIndex: Float {
    var current: UIElement = self
    while true {
      if let index = current.ownZIndex { return index }
      guard let single = current as? SingleChildElement, let child = single.child else { return 0 }
      current = child
    }
  }

  /// Set by `.tag(_:)`; nil when never set. See `tagValue`.
  internal var ownTag: AnyHashable? {
    get { self.traits?.tag }
    set { self.ensuredTraits.tag = newValue }
  }

  /// What a `Picker` option selects: the value `.tag(_:)` gave it, read through the wrappers
  /// around the element that set it, like `layoutPriority`. Nil when none did.
  public var tagValue: AnyHashable? {
    var current: UIElement = self
    while true {
      if let tag = current.ownTag { return tag }
      guard let single = current as? SingleChildElement, let child = single.child else { return nil }
      current = child
    }
  }

  /// Set by `.layoutPriority(_:)`; nil when never set. See `layoutPriority`.
  internal var ownLayoutPriority: Float? {
    get { self.traits?.layoutPriority }
    set { self.ensuredTraits.layoutPriority = newValue }
  }

  /// Set by the `.gridCell…` modifiers; nil when none was. See `gridCell`.
  internal var ownGridCell: GridCellOptions? {
    get { self.traits?.gridCell }
    set { self.ensuredTraits.gridCell = newValue }
  }

  /// How a `Grid` lays this element out as a cell, read through the wrappers around the
  /// element that set it; nil when nothing did.
  var gridCell: GridCellOptions? {
    var current: UIElement = self
    while true {
      if let cell = current.ownGridCell { return cell }
      guard let single = current as? SingleChildElement, let child = single.child else { return nil }
      current = child
    }
  }

  /// How early a stack gives this element its share of space: children of higher priority are
  /// sized first, and those of lower priority get only their smallest size until then. 0 by
  /// default.
  ///
  /// Read through the wrappers a modifier chain puts around the element that set it, as in
  /// SwiftUI, where `.layoutPriority(1).padding()` still gives the padded element priority 1.
  public var layoutPriority: Float {
    var current: UIElement = self
    while true {
      if let priority = current.ownLayoutPriority { return priority }
      guard let single = current as? SingleChildElement, let child = single.child else { return 0 }
      current = child
    }
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

  /// The rect everything under this element is kept inside, drawn and hit alike, or nil when it
  /// clips nothing. In layout coordinates: `UIContext` moves it with the effects above.
  var clipRect: ClipRect? { nil }

  /// How far `clipRect`'s corners are rounded, in `UIShape.radii`'s order. Drawing keeps inside
  /// the rounded rect; hit-testing, cheaper, inside `clipRect`.
  var clipCornerRadii: float4 { .zero }
}

/// An axis-aligned rect, window top left origin, y down, in points.
public struct ClipRect: Equatable, Sendable {
  public var min: float2
  public var max: float2

  public init(min: float2, max: float2) {
    self.min = min
    self.max = max
  }

  public init(position: float2, size: float2) {
    self.min = position
    self.max = position + size
  }

  public func contains(_ point: float2) -> Bool {
    point.x >= self.min.x && point.y >= self.min.y && point.x < self.max.x && point.y < self.max.y
  }

  /// Empty — `min` past `max` — when the two do not overlap.
  public func intersection(_ other: ClipRect) -> ClipRect {
    ClipRect(min: simd_max(self.min, other.min), max: simd_min(self.max, other.max))
  }

  public var isEmpty: Bool { self.max.x <= self.min.x || self.max.y <= self.min.y }
}

/// The animated layout pass under way, if any. Set by `UIContext.update` only around the
/// positioning of a pass that an animated change caused, which is what `place` checks.
@MainActor
struct LayoutPass {
  static var current: LayoutPass? = nil

  /// Which layout pass is under way, or last ran. What `measure` remembers is valid for one
  /// generation only.
  static var generation: UInt32 = 0

  unowned let context: UIContext
  let animation: UIAnimation
  let group: AnimationGroup?
}

/// The layout values of one element that modifiers set in place. See `UIElement.traits`.
@MainActor
final class LayoutTraits {
  var tag: AnyHashable? = nil
  var layoutPriority: Float? = nil
  var zIndex: Float? = nil
  var guides: [(key: AlignmentKey, compute: (ViewDimensions) -> Float)]? = nil
  var gridCell: GridCellOptions? = nil
}
