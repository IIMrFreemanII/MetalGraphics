import QuartzCore
import simd

/// What a change has made stale. `UIContext.invalidate(_:)` expands it to everything that
/// follows from it, so callers only name the direct effect.
public struct Invalidation: OptionSet, Sendable {
  public let rawValue: UInt8
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  public static let render    = Invalidation(rawValue: 1 << 0)
  public static let layout    = Invalidation(rawValue: 1 << 1)
  public static let hitGrid   = Invalidation(rawValue: 1 << 2)
  /// The tree-order lists: what is drawn, and what is hit-tested, in which order.
  public static let treeOrder = Invalidation(rawValue: 1 << 3)

  public static let all: Invalidation = [.render, .layout, .hitGrid, .treeOrder]
}

@MainActor
public class UIContext {
  private var renderableViews: [ObjectIdentifier : UIRenderableElement] = [:]
  private var hittableViews: [ObjectIdentifier : any Hittable] = [:]

  /// Registered renderables in the order they are drawn: tree pre-order, so a parent is drawn
  /// before its children and an earlier sibling's whole subtree before a later sibling.
  ///
  /// `Graphics2D` stacks each draw call on top of the previous one, so this order is the z-order.
  /// Sorting the registry by a per-element depth instead left ties — a `Background` and its
  /// content shared one — to dictionary hash order, and a background could cover what it sits
  /// behind.
  private var paintOrder: [UIRenderableElement] = []

  /// Registered hittable views in the same tree pre-order, so the last one is the one drawn on
  /// top. Built by the same walk as `paintOrder`, which is what keeps what is clicked and what
  /// is seen from disagreeing.
  private var hitOrder: [any Hittable] = []

  /// Every element with an effect in the tree — each `EffectElement`, and each element that is
  /// sliding — in pre-order, so a parent always comes before its children. `effectParents[i]` is the index of the nearest effect above `effectOrder[i]`,
  /// or -1, and `paintEffects[i]` the nearest effect above `paintOrder[i]`, or -1.
  ///
  /// Indices rather than references, so resolving is one pass over a flat array per frame, each
  /// effect composed once onto its already-resolved parent, instead of each renderable walking
  /// up its own chain.
  private var effectOrder: [UIElement] = []
  private var effectParents: [Int] = []
  private var effectResolved: [EffectState] = []
  private var paintEffects: [Int] = []

  /// Every `ShadowElement` in the tree, in pre-order like `effectOrder`. `shadowParents[i]` is
  /// the nearest shadow above `shadowOrder[i]`, or -1, `shadowEffects[i]` the nearest effect at
  /// or above it, `shadowClips[i]` the nearest clip above it, or -1, and `paintShadows[i]` the
  /// nearest shadow above `paintOrder[i]`, or -1. `shadowResolved[i]` is resolved each frame,
  /// scaled by the effects above it.
  private var shadowOrder: [ShadowElement] = []
  private var shadowParents: [Int] = []
  private var shadowEffects: [Int] = []
  private var shadowClips: [Int] = []
  private var shadowResolved: [ShadowState] = []
  private var paintShadows: [Int] = []

  /// Every `BlurElement` in the tree, in pre-order like `shadowOrder`. `blurParents[i]` is the
  /// nearest blur above `blurOrder[i]`, or -1, `blurEffects[i]` the nearest effect at or above
  /// it, and `paintBlurs[i]` the nearest blur above `paintOrder[i]`, or -1. `blurResolved[i]` is
  /// resolved each frame: its standard deviation combined with every blur above it.
  private var blurOrder: [BlurElement] = []
  private var blurParents: [Int] = []
  private var blurEffects: [Int] = []
  private var blurResolved: [Float] = []
  private var paintBlurs: [Int] = []

  /// Every element that clips what is under it, in pre-order like `effectOrder`.
  /// `clipParents[i]` is the nearest clip above `clipOrder[i]`, or -1, `clipEffects[i]` the
  /// nearest effect at or above it, or -1. `paintClips` and `hitClips` are the nearest clip
  /// above each entry of `paintOrder` and `hitOrder`, or -1.
  ///
  /// Resolved each frame: `clipResolved[i]` is the rect the clip and all above it leave,
  /// `clipOwnRects[i]` and `clipRadii[i]` its own rounded rect, `clipRounded[i]` the nearest
  /// rounded clip at or above it, or -1, and `clipGPU[i]` its index in this frame's
  /// `Graphics2D` clip table, or -1 until something is drawn under it.
  private var clipOrder: [UIElement] = []
  private var clipParents: [Int] = []
  private var clipEffects: [Int] = []
  private var clipResolved: [ClipRect] = []
  private var clipOwnRects: [ClipRect] = []
  private var clipRadii: [float4] = []
  private var clipRounded: [Int] = []
  private var clipGPU: [Int32] = []
  private var paintClips: [Int] = []
  private var hitClips: [Int] = []

  /// Mounted scroll views, and those in the tree in pre-order with the clip above each, which
  /// is where the wheel is routed from.
  private var scrollViews: [ObjectIdentifier : ScrollView] = [:]
  private var scrollOrder: [ScrollView] = []
  private var scrollClips: [Int] = []

  /// Mounted focusable elements and key handlers, and those in the tree in pre-order, which is
  /// the order Tab moves focus in. `focusClips[i]` is the clip above `focusOrder[i]`, or -1, and
  /// `focusKeys[i]` the nearest key handler at or above it, or -1. `keyParents[i]` is the nearest
  /// key handler above `keyOrder[i]`, or -1, and `keyNeedsFocus[i]` whether it belongs to a
  /// focusable element — is inside one, or wraps one with nothing but single-child elements in
  /// between, as `.focusable().onKeyPress` does. A press walks up from the focused element
  /// through these indices, so no element needs a parent pointer.
  private var focusables: [ObjectIdentifier : FocusableElement] = [:]
  private var keyHandlers: [ObjectIdentifier : KeyPressElement] = [:]
  private var focusOrder: [FocusableElement] = []
  private var focusClips: [Int] = []
  private var focusKeys: [Int] = []
  private var keyOrder: [KeyPressElement] = []
  private var keyParents: [Int] = []
  private var keyNeedsFocus: [Bool] = []

  /// The element key presses go to first. See `dispatchKeys(_:)`.
  public private(set) var focused: FocusableElement? = nil

  /// Popovers on screen, bottom first: roots of their own, laid out after the app's tree and
  /// collected after it, so they draw and hit above everything, outside every clip. Empty almost
  /// always, and then they cost nothing. See `presentPopover`.
  var overlays: [PopoverLayer] = []

  /// Mounted drop destinations, and those in the tree in pre-order with the clip above each,
  /// which is where a drag looks for its target. See `routeDrop`.
  private var dropTargets: [ObjectIdentifier : DropDestinationBase] = [:]
  private var dropOrder: [DropDestinationBase] = []
  private var dropClips: [Int] = []

  /// The drag in progress, if any. See `beginDrag`.
  private(set) var drag: DragSession? = nil
  /// The element whose drawing follows the pointer during the drag, found in `collect` by
  /// identity, which is cheaper than reading the session's weak reference per element.
  private var ghostID: ObjectIdentifier? = nil

  /// Drives every running animation, once per frame from `update`.
  public let animator = Animator()

  public private(set) var pending: Invalidation = .all

  /// The animation of the latest animated change that invalidated layout since the last pass,
  /// and the `withAnimation` groups those changes belong to, held open until the pass has
  /// started its slides. See `UIElement.place(_:at:in:)`.
  private var layoutAnimation: UIAnimation? = nil
  private var layoutGroups: [AnimationGroup] = []
  public private(set) var hitGrid = HittableGrid2D(position: .zero, size: int2(10, 10), cellSize: 50)
  private var lastSize: float2 = .zero
  private var afterLayoutWork: [() -> Void] = []

  public var needsRender: Bool { self.pending.contains(.render) }

  /// The time animations start and advance by. Tests swap it for a fake clock so frames can be
  /// stepped deterministically; `update` reads it once per frame when no `time` is passed.
  public var clock: () -> Double = CACurrentMediaTime

  public init() {}

  // MARK: - Invalidation

  /// `animation` is for discrete changes that move other elements: inserting, removing or
  /// reordering children, or a new text or alignment. Elements the next layout pass moves within
  /// their container then slide to their new place with it. Writes from a running animation never
  /// pass one — they already move a little every frame.
  public func invalidate(_ kinds: Invalidation = .render, animation: UIAnimation?) -> Void {
    if let animation, kinds.contains(.layout) {
      self.layoutAnimation = animation
      if let group = UITransaction.group, !self.layoutGroups.contains(where: { $0 === group }) {
        self.animator.hold(group)
        self.layoutGroups.append(group)
      }
    }
    self.invalidate(kinds)
  }

  public func invalidate(_ kinds: Invalidation = .render) -> Void {
    var kinds = kinds
    // Not `.treeOrder`: layout moves things but never reorders them, and an animated size would
    // otherwise re-walk the whole tree every frame. What changes the order — mounting, and
    // replacing, inserting or removing children — says so itself.
    if kinds.contains(.layout) {
      kinds.formUnion([.hitGrid, .render])
    }
    if kinds.contains(.treeOrder) {
      // The grid stores views in hit order, so a new order means a new grid.
      kinds.formUnion([.hitGrid, .render])
    }
    self.pending.formUnion(kinds)
  }

  // MARK: - Registration

  public func registerRenderableView(_ view: UIRenderableElement) -> Void {
    self.renderableViews[ObjectIdentifier(view)] = view
    self.invalidate(.treeOrder)
  }

  public func unregisterRenderableView(_ view: UIRenderableElement) -> Void {
    self.renderableViews.removeValue(forKey: ObjectIdentifier(view))
    self.invalidate(.treeOrder)
  }

  public func registerHittableView(_ view: any Hittable) -> Void {
    self.hittableViews[ObjectIdentifier(view)] = view
    self.invalidate(.treeOrder)
  }

  public func unregisterHittableView(_ view: any Hittable) -> Void {
    self.hittableViews.removeValue(forKey: ObjectIdentifier(view))
    self.invalidate(.treeOrder)
  }

  func registerScrollView(_ view: ScrollView) -> Void {
    self.scrollViews[ObjectIdentifier(view)] = view
    self.invalidate(.treeOrder)
  }

  func unregisterScrollView(_ view: ScrollView) -> Void {
    self.scrollViews.removeValue(forKey: ObjectIdentifier(view))
    self.invalidate(.treeOrder)
  }

  func registerFocusable(_ view: FocusableElement) -> Void {
    self.focusables[ObjectIdentifier(view)] = view
    self.invalidate(.treeOrder)
  }

  // Focus goes silently, as a hover does in `HittableGrid2D`: calling into a component
  // mid-teardown is what that guards against.
  func unregisterFocusable(_ view: FocusableElement) -> Void {
    self.focusables.removeValue(forKey: ObjectIdentifier(view))
    if self.focused === view {
      self.focused = nil
    }
    self.invalidate(.treeOrder)
  }

  func registerDropTarget(_ view: DropDestinationBase) -> Void {
    self.dropTargets[ObjectIdentifier(view)] = view
    self.invalidate(.treeOrder)
  }

  func unregisterDropTarget(_ view: DropDestinationBase) -> Void {
    self.dropTargets.removeValue(forKey: ObjectIdentifier(view))
    if self.drag?.target === view {
      self.drag?.target = nil
    }
    self.invalidate(.treeOrder)
  }

  func registerKeyHandler(_ view: KeyPressElement) -> Void {
    self.keyHandlers[ObjectIdentifier(view)] = view
    self.invalidate(.treeOrder)
  }

  func unregisterKeyHandler(_ view: KeyPressElement) -> Void {
    self.keyHandlers.removeValue(forKey: ObjectIdentifier(view))
    self.invalidate(.treeOrder)
  }

  // MARK: - Frame

  /// Hit-tests, advances animations, then lays out. Run before `render(root:_:)` each frame.
  ///
  /// Hit-testing comes first so state changes its handlers make are laid out before this frame
  /// renders; the other way round, an element mounted by `onTap` would be drawn once before it
  /// had a position. Animations advance in between, so one a handler just started is laid out
  /// at its first step in the same frame.
  public func update(
    root: Frame, size: float2, input: Input, graphics: Graphics2D, time: Double? = nil
  ) -> Void {
    let time = time ?? self.clock()
    if size != self.lastSize {
      self.lastSize = size
      self.invalidate(.layout)
    }

    if input.scrollDelta != .zero {
      // Scrolling under a popover would leave it pointing at nothing.
      if let top = self.overlays.last, !top.cardContains(input.mousePosition) {
        self.dismissAllPopovers()
      }
      if self.pending.contains(.treeOrder) {
        self.rebuildTreeOrder(root)
      }
      self.routeScroll(input)
    }

    // `mouseDown`/`mouseUp` too: a click whose down and up both land between two frames is no
    // longer pressed by the time this runs, and would otherwise be missed.
    if input.mouseMoved || input.mousePressed || input.mouseDown || input.mouseUp {
      if self.pending.contains(.treeOrder) {
        self.rebuildTreeOrder(root)
      }
      if self.pending.contains(.hitGrid) {
        self.rebuildHitGrid(graphics)
      }
      // Before the tap handlers, so one that reads `focused` sees what this click focused.
      if input.leftMouseDown, !self.focusables.isEmpty {
        self.routeFocus(input)
      }
      self.hitGrid.handleEvents(input)
    }

    // After the click, so a click and the typing after it that land in one frame go together.
    if !input.keyPresses.isEmpty {
      // Escape cancels a drag, and still goes on to whatever handles it.
      if self.drag != nil, input.keyPresses.contains(where: { $0.key == .escape && $0.phase == .down }) {
        self.cancelDrag()
      }
      if self.pending.contains(.treeOrder) {
        self.rebuildTreeOrder(root)
      }
      self.dispatchKeys(input)
    }

    self.animator.tick(time, self)
    if !self.animator.isIdle {
      // A delayed animation writes nothing yet, but the frame after it must still be drawn.
      self.invalidate(.render)
    }

    if self.pending.contains(.layout) {
      root.size = size
      // A new pass: sizes measured in the last one may be stale.
      LayoutPass.generation &+= 1
      _ = root.calcSize(ProposedSize(size))
      if let animation = self.layoutAnimation {
        LayoutPass.current = LayoutPass(context: self, animation: animation, group: self.layoutGroups.last)
      }
      root.calcPosition(.init())
      LayoutPass.current = nil
      // After the tree: a popover is placed by its anchor, which that pass just placed.
      for overlay in self.overlays {
        _ = overlay.calcSize(ProposedSize(size))
        overlay.calcPosition(.zero)
      }
      // At its ideal size, wherever the pointer is: it is moved there by its effect.
      if let preview = self.drag?.preview {
        _ = preview.calcSize(.unspecified)
        preview.calcPosition(.zero)
      }
      self.layoutAnimation = nil
      if !self.layoutGroups.isEmpty {
        // After the slides joined the group, so an animation-free pass cannot end it early.
        self.layoutGroups.forEach { self.animator.release($0) }
        self.layoutGroups.removeAll()
      }
      // `.hitGrid` stays pending: `invalidate(.layout)` added it.
      self.pending.remove(.layout)
    }

    // Last, so what it changes is laid out on the next frame rather than inside this one.
    if !self.afterLayoutWork.isEmpty {
      let work = self.afterLayoutWork
      self.afterLayoutWork.removeAll(keepingCapacity: true)
      work.forEach { $0() }
    }
  }

  /// Work that reads the layout and may change state, such as `.onGeometryChange`'s action. It
  /// runs at the end of this frame's `update`.
  public func afterLayout(_ work: @escaping () -> Void) -> Void {
    self.afterLayoutWork.append(work)
  }

  /// Draws every registered renderable in paint order, each with the effects above it.
  public func render(root: UIElement, _ renderer: Graphics2D) -> Void {
    if self.pending.contains(.treeOrder) {
      self.rebuildTreeOrder(root)
    }

    if !self.effectOrder.isEmpty {
      self.resolveEffects()
    }
    let hasShadows = !self.shadowOrder.isEmpty
    if hasShadows {
      self.resolveShadows()
    }
    let hasBlurs = !self.blurOrder.isEmpty
    if hasBlurs {
      self.resolveBlurs()
    }
    // The shadows `renderer` draws with, as an index into `shadowOrder`, or -1 for none, and
    // the clip they were set for.
    var shadow = -1
    var shadowClip = -1
    // The blur `renderer` draws with, as an index into `blurOrder`, or -1 for none.
    var blur = -1
    if self.clipOrder.isEmpty {
      for index in self.paintOrder.indices {
        if hasShadows, self.paintShadows[index] != shadow {
          shadow = self.paintShadows[index]
          self.setShadows(shadow, clip: -1, renderer)
        }
        if hasBlurs, self.paintBlurs[index] != blur {
          blur = self.paintBlurs[index]
          renderer.setBlur(blur < 0 ? 0 : self.blurResolved[blur])
        }
        let effect = self.paintEffects[index]
        self.paintOrder[index].render(renderer, effect < 0 ? .identity : self.effectResolved[effect])
      }
    } else {
      self.resolveClips(withEffects: true)
      for index in self.clipGPU.indices {
        self.clipGPU[index] = -1
      }
      for index in self.paintOrder.indices {
        let clip = self.paintClips[index]
        if clip < 0 {
          renderer.resetClip()
        } else {
          // Nothing under an empty clip can show.
          if self.clipResolved[clip].isEmpty { continue }
          renderer.setClip(self.gpuClip(clip, renderer))
        }
        if hasShadows, self.paintShadows[index] != shadow || (shadow >= 0 && clip != shadowClip) {
          shadow = self.paintShadows[index]
          shadowClip = clip
          self.setShadows(shadow, clip: clip, renderer)
        }
        if hasBlurs, self.paintBlurs[index] != blur {
          blur = self.paintBlurs[index]
          renderer.setBlur(blur < 0 ? 0 : self.blurResolved[blur])
        }
        let effect = self.paintEffects[index]
        self.paintOrder[index].render(renderer, effect < 0 ? .identity : self.effectResolved[effect])
      }
      renderer.resetClip()
    }
    if let drag = self.drag, self.ghostID != nil, drag.ghostEnd > drag.ghostStart,
       drag.ghostEnd <= self.paintOrder.count {
      // The dragged element once more, lifted to the pointer: above everything, outside every
      // clip, and without the shadows and blurs around it.
      if shadow >= 0 {
        renderer.resetShadows()
        shadow = -1
      }
      if blur >= 0 {
        renderer.setBlur(0)
        blur = -1
      }
      renderer.resetClip()
      let lift = EffectState(opacity: DragSession.ghostOpacity, scale: 1, translate: drag.pointer - drag.start)
      for index in drag.ghostStart ..< drag.ghostEnd {
        let effect = self.paintEffects[index]
        self.paintOrder[index].render(renderer, lift.composed(with: effect < 0 ? .identity : self.effectResolved[effect]))
      }
    }
    if shadow >= 0 {
      renderer.resetShadows()
    }
    if blur >= 0 {
      renderer.setBlur(0)
    }
    self.pending.remove(.render)
  }

  // Parents come first in `blurOrder`, so each one's parent is already resolved. Gaussians in a
  // row add their variances.
  private func resolveBlurs() -> Void {
    for index in self.blurOrder.indices {
      let effect = self.blurEffects[index]
      let own = self.blurOrder[index].resolved(effect < 0 ? .identity : self.effectResolved[effect])
      let parent = self.blurParents[index]
      let above = parent < 0 ? 0 : self.blurResolved[parent]
      self.blurResolved[index] = (own * own + above * above).squareRoot()
    }
  }

  private func resolveShadows() -> Void {
    for index in self.shadowOrder.indices {
      let effect = self.shadowEffects[index]
      self.shadowResolved[index] = self.shadowOrder[index].resolved(effect < 0 ? .identity : self.effectResolved[effect])
    }
  }

  /// Hands `renderer` shadow `shadow` and every shadow above it, outermost first, or none for -1,
  /// for shapes drawn under clip `clip`.
  private func setShadows(_ shadow: Int, clip: Int, _ renderer: Graphics2D) -> Void {
    renderer.resetShadows()
    if shadow >= 0 {
      self.pushShadows(shadow, clip: clip, renderer)
    }
  }

  // Recurses once per shadow above, so only as deep as shadows are nested.
  private func pushShadows(_ shadow: Int, clip: Int, _ renderer: Graphics2D) -> Void {
    let parent = self.shadowParents[shadow]
    if parent >= 0 {
      self.pushShadows(parent, clip: clip, renderer)
    }
    var state = self.shadowResolved[shadow]
    let outer = self.shadowClips[shadow]
    if clip != outer {
      state.clip = self.shadowClip(outer: outer, inner: clip, state, renderer)
    }
    renderer.addShadow(state)
  }

  /// The clip a shadow's copies are drawn under when clip `inner` lies between the shadow and
  /// the shape: cut, like the shadow, only by `outer`, the clip above the shadow; and shaped by
  /// `inner`'s rounded rect, moved with the shadow and blurred with it — or, unblurred, cut by it.
  /// Only the innermost clip shapes it; clips between that and `outer` do not.
  private func shadowClip(outer: Int, inner: Int, _ shadow: ShadowState, _ renderer: Graphics2D) -> Int32 {
    let own = self.clipOwnRects[inner]
    let rect = ClipRect(min: own.min + shadow.offset, max: own.max + shadow.offset)
    let roundedAbove = outer < 0 ? -1 : self.clipRounded[outer]
    let chained: Int32 = roundedAbove < 0 ? 0 : self.gpuClip(roundedAbove, renderer)
    var bounds = outer < 0 ? Self.everywhere : self.clipResolved[outer]
    if shadow.sigma <= 0 {
      bounds = bounds.intersection(rect)
    }
    return renderer.addClip(bounds: bounds, rect: rect, radii: self.clipRadii[inner], rounded: chained, blur: shadow.sigma)
  }

  private static let everywhere = ClipRect(
    min: float2(repeating: -.greatestFiniteMagnitude), max: float2(repeating: .greatestFiniteMagnitude)
  )

  // Parents come first in `effectOrder`, so each one's parent is already resolved.
  private func resolveEffects() -> Void {
    for index in self.effectOrder.indices {
      let local = self.effectOrder[index].localEffect
      let parent = self.effectParents[index]
      self.effectResolved[index] = parent < 0 ? local : self.effectResolved[parent].composed(with: local)
    }
  }

  /// Resolves every clip onto its parent's, parents first. Drawing sees clips moved by the
  /// effects above them; hit-testing, like layout, sees them where they were laid out.
  private func resolveClips(withEffects: Bool) -> Void {
    for index in self.clipOrder.indices {
      let element = self.clipOrder[index]
      let parent = self.clipParents[index]
      let roundedAbove = parent < 0 ? -1 : self.clipRounded[parent]
      guard var rect = element.clipRect else {
        self.clipResolved[index] = ClipRect(min: .zero, max: .zero)
        self.clipOwnRects[index] = ClipRect(min: .zero, max: .zero)
        self.clipRadii[index] = .zero
        self.clipRounded[index] = roundedAbove
        continue
      }
      var radii = element.clipCornerRadii
      let effect = self.clipEffects[index]
      if withEffects, effect >= 0 {
        let state = self.effectResolved[effect]
        rect = ClipRect(min: state.apply(to: rect.min), max: state.apply(to: rect.max))
        radii *= state.scale
      }
      self.clipOwnRects[index] = rect
      self.clipRadii[index] = radii
      self.clipRounded[index] = radii != .zero ? index : roundedAbove
      self.clipResolved[index] = parent < 0 ? rect : self.clipResolved[parent].intersection(rect)
    }
  }

  /// Clip `clip`'s index in the renderer's clip table, added the first time something is drawn
  /// under it this frame — after the rounded clip above it, which it chains to. Recurses once
  /// per rounded clip above, so only as deep as rounded clips are nested.
  private func gpuClip(_ clip: Int, _ renderer: Graphics2D) -> Int32 {
    let cached = self.clipGPU[clip]
    if cached >= 0 { return cached }
    let parent = self.clipParents[clip]
    let roundedAbove = parent < 0 ? -1 : self.clipRounded[parent]
    let chained: Int32 = roundedAbove < 0 ? 0 : self.gpuClip(roundedAbove, renderer)
    let index = renderer.addClip(
      bounds: self.clipResolved[clip], rect: self.clipOwnRects[clip], radii: self.clipRadii[clip], rounded: chained
    )
    self.clipGPU[clip] = index
    return index
  }

  // MARK: - Scrolling

  /// Hands the wheel to the innermost scroll view under the pointer, and what it cannot use —
  /// past its end, or along an axis it does not scroll — on to the scroll views around it.
  private func routeScroll(_ input: Input) -> Void {
    guard !self.scrollOrder.isEmpty else { return }
    self.resolveClips(withEffects: false)
    let point = input.mousePosition
    var remaining = input.scrollDelta
    // Pre-order, so walking it backwards meets a scroll view before the ones it is inside.
    for index in self.scrollOrder.indices.reversed() {
      let view = self.scrollOrder[index]
      guard view.mounted, ClipRect(position: view.position, size: view.size).contains(point) else { continue }
      let clip = self.scrollClips[index]
      if clip >= 0, !self.clipResolved[clip].contains(point) { continue }
      remaining = view.scroll(by: remaining, self)
      if remaining == .zero { break }
    }
  }

  // MARK: - Focus and keys

  /// Moves focus to `element`, or away, calling `onFocusChange` on what loses it and then on
  /// what gains it. Invalidates nothing: focus draws nothing by itself, and the state a handler
  /// writes invalidates what it has to.
  public func focus(_ element: FocusableElement?) -> Void {
    let old = self.focused
    guard old !== element else { return }
    self.focused = element
    old?.onFocusChange?(false)
    // A handler of the old one may already have moved focus elsewhere.
    if let element, self.focused === element {
      element.onFocusChange?(true)
    }
  }

  /// Focuses the innermost focusable element under a click, or none when it hits none.
  private func routeFocus(_ input: Input) -> Void {
    self.resolveClips(withEffects: false)
    let point = input.mousePosition
    // Pre-order, so walking it backwards meets an element before the ones it is inside.
    for index in self.focusOrder.indices.reversed() {
      let element = self.focusOrder[index]
      guard element.mounted, element.isFocusable,
            ClipRect(position: element.position, size: element.size).contains(point)
      else { continue }
      let clip = self.focusClips[index]
      if clip >= 0, !self.clipResolved[clip].contains(point) { continue }
      self.focus(element)
      return
    }
    self.focus(nil)
  }

  /// Offers each press to the key handlers around the focused element, innermost first, until
  /// one handles it. With nothing focused, it goes to the handlers that belong to no focusable
  /// element (see `keyNeedsFocus`), last in the tree first. Tab and Shift-Tab that nobody handles move focus.
  private func dispatchKeys(_ input: Input) -> Void {
    for press in input.keyPresses {
      if self.offer(press) == .handled { continue }
      if press.key == .tab, press.phase != .up {
        self.moveFocus(backwards: press.modifiers.contains(.shift))
      }
    }
  }

  private func offer(_ press: KeyPress) -> KeyPress.Result {
    if let focused = self.focused {
      // Linear, but only once per key event.
      guard let index = self.focusOrder.firstIndex(where: { $0 === focused }) else { return .ignored }
      var handler = self.focusKeys[index]
      while handler >= 0 {
        let element = self.keyOrder[handler]
        if element.mounted, element.handle(press) == .handled { return .handled }
        handler = self.keyParents[handler]
      }
    } else {
      for index in self.keyOrder.indices.reversed() where !self.keyNeedsFocus[index] {
        let element = self.keyOrder[index]
        if element.mounted, element.handle(press) == .handled { return .handled }
      }
    }
    return .ignored
  }

  /// The next focusable element in tree order after the focused one, wrapping round; the first,
  /// or with `backwards` the last, when nothing is focused.
  private func moveFocus(backwards: Bool) -> Void {
    let count = self.focusOrder.count
    guard count > 0 else { return }
    let start = self.focused.flatMap { focused in self.focusOrder.firstIndex { $0 === focused } }
    let step = backwards ? count - 1 : 1
    var index = start ?? (backwards ? 0 : count - 1)
    for _ in 0..<count {
      index = (index + step) % count
      let element = self.focusOrder[index]
      if element.mounted, element.isFocusable {
        self.focus(element)
        return
      }
    }
  }

  // MARK: - Hit grid

  /// The grid covers the window in cells of a fixed size, so a new window size means a new
  /// cell count.
  public func resizeHitGrid(for windowSize: float2) -> Void {
    let newGridSize = int2(floor(windowSize / self.hitGrid.cellSize)) &+ 1
    guard newGridSize.x > 0, newGridSize.y > 0, newGridSize != self.hitGrid.cellCount else {
      return
    }

    self.hitGrid = .init(
      position: self.hitGrid.position, size: newGridSize, cellSize: self.hitGrid.cellSize
    )
    self.invalidate(.hitGrid)
  }

  // Mapped topmost first, so every cell's list comes out in hit order without a sort.
  private func rebuildHitGrid(_ renderer: Graphics2D) -> Void {
    self.hitGrid.reset()
    if !self.clipOrder.isEmpty {
      self.resolveClips(withEffects: false)
    }
    for index in self.hitOrder.indices.reversed() {
      let clip = self.hitClips[index]
      self.hitGrid.mapViewToGrid(self.hitOrder[index], clip < 0 ? nil : self.clipResolved[clip], renderer)
    }

    self.pending.remove(.hitGrid)
  }

  // MARK: - Drag and drop

  /// True while something is being dragged.
  public var isDragging: Bool { self.drag != nil }

  /// Starts a drag of `payload` by `owner`, which alone may move, end or cancel it, from the
  /// pointer at `start`. `ghost` is drawn again under the pointer, or `preview` is, mounted for
  /// the drag. A nil payload is dropped nowhere: a list reordering its own rows.
  func beginDrag(owner: UIElement, payload: Any?, ghost: UIElement?, preview: UIElement?, from start: float2) -> Void {
    if self.drag != nil {
      self.cancelDrag()
    }
    let drag = DragSession(owner: owner, payload: payload, start: start)
    self.drag = drag
    if let ghost {
      self.ghostID = ObjectIdentifier(ghost)
      // Once per drag, so `collect` finds where it sits in the paint order.
      self.invalidate(.treeOrder)
    }
    if let preview {
      let layer = DragPreviewLayer(preview)
      layer.pointer = start
      drag.preview = layer
      layer.handleMount(self)
      self.invalidate([.layout, .treeOrder])
    }
  }

  /// Moves `owner`'s drag to `point`, and with it what is drawn under the pointer and the
  /// destination it would drop on. Redraws only.
  func dragMoved(_ owner: UIElement, to point: float2) -> Void {
    guard let drag = self.drag, drag.owner === owner, drag.pointer != point else { return }
    drag.pointer = point
    drag.preview?.pointer = point
    self.routeDrop(drag)
    self.invalidate(.render)
  }

  /// Ends `owner`'s drag at `point`, dropping the payload on the destination there that takes
  /// it. Returns what the destination's action returned, or false when nothing took it.
  @discardableResult
  func endDrag(_ owner: UIElement, at point: float2) -> Bool {
    guard let drag = self.drag, drag.owner === owner else { return false }
    drag.pointer = point
    self.routeDrop(drag)
    let target = drag.target
    self.finishDrag(drag)
    guard let target, target.mounted, let payload = drag.payload else { return false }
    return target.perform(payload, at: point - target.position)
  }

  /// Ends the drag without dropping anything: Escape, or its owner going away.
  func cancelDrag() -> Void {
    guard let drag = self.drag else { return }
    self.finishDrag(drag)
  }

  private func finishDrag(_ drag: DragSession) -> Void {
    self.drag = nil
    self.ghostID = nil
    if let target = drag.target {
      drag.target = nil
      target.setTargeted(false)
    }
    if let preview = drag.preview {
      drag.preview = nil
      preview.handleUnmount(self)
      self.invalidate(.treeOrder)
    }
    self.invalidate(.render)
  }

  /// Finds the innermost destination under the pointer that takes the payload, and tells the
  /// old and new ones when that changes. O(destinations), and only while dragging.
  private func routeDrop(_ drag: DragSession) -> Void {
    var found: DropDestinationBase? = nil
    if let payload = drag.payload, !self.dropOrder.isEmpty {
      self.resolveClips(withEffects: false)
      let point = drag.pointer
      // Pre-order, so walking it backwards meets a destination before the ones it is inside.
      for index in self.dropOrder.indices.reversed() {
        let target = self.dropOrder[index]
        guard target.mounted, ClipRect(position: target.position, size: target.size).contains(point) else { continue }
        let clip = self.dropClips[index]
        if clip >= 0, !self.clipResolved[clip].contains(point) { continue }
        guard target.accepts(payload) else { continue }
        found = target
        break
      }
    }
    guard found !== drag.target else { return }
    let old = drag.target
    drag.target = found
    old?.setTargeted(false)
    found?.setTargeted(true)
  }

  // MARK: - Tree order

  private func rebuildTreeOrder(_ root: UIElement) -> Void {
    self.paintOrder.removeAll(keepingCapacity: true)
    self.paintEffects.removeAll(keepingCapacity: true)
    self.paintShadows.removeAll(keepingCapacity: true)
    self.shadowOrder.removeAll(keepingCapacity: true)
    self.shadowParents.removeAll(keepingCapacity: true)
    self.shadowEffects.removeAll(keepingCapacity: true)
    self.shadowClips.removeAll(keepingCapacity: true)
    self.blurOrder.removeAll(keepingCapacity: true)
    self.blurParents.removeAll(keepingCapacity: true)
    self.blurEffects.removeAll(keepingCapacity: true)
    self.paintBlurs.removeAll(keepingCapacity: true)
    self.hitOrder.removeAll(keepingCapacity: true)
    self.effectOrder.removeAll(keepingCapacity: true)
    self.effectParents.removeAll(keepingCapacity: true)
    self.clipOrder.removeAll(keepingCapacity: true)
    self.clipParents.removeAll(keepingCapacity: true)
    self.clipEffects.removeAll(keepingCapacity: true)
    self.paintClips.removeAll(keepingCapacity: true)
    self.hitClips.removeAll(keepingCapacity: true)
    self.scrollOrder.removeAll(keepingCapacity: true)
    self.scrollClips.removeAll(keepingCapacity: true)
    self.focusOrder.removeAll(keepingCapacity: true)
    self.focusClips.removeAll(keepingCapacity: true)
    self.focusKeys.removeAll(keepingCapacity: true)
    self.keyOrder.removeAll(keepingCapacity: true)
    self.keyParents.removeAll(keepingCapacity: true)
    self.keyNeedsFocus.removeAll(keepingCapacity: true)
    self.dropOrder.removeAll(keepingCapacity: true)
    self.dropClips.removeAll(keepingCapacity: true)
    if let drag = self.drag {
      drag.ghostStart = 0
      drag.ghostEnd = 0
    }
    self.collect(root, effect: -1, clip: -1, shadow: -1, blur: -1, key: -1, spine: -1, inFocusable: false, leaving: false)
    for overlay in self.overlays {
      self.collect(overlay, effect: -1, clip: -1, shadow: -1, blur: -1, key: -1, spine: -1, inFocusable: false, leaving: false)
    }
    // Last, so it draws over the popovers too; as if leaving, so it is drawn and never hit.
    if let preview = self.drag?.preview {
      self.collect(preview, effect: -1, clip: -1, shadow: -1, blur: -1, key: -1, spine: -1, inFocusable: false, leaving: true)
    }
    self.effectResolved = Array(repeating: .identity, count: self.effectOrder.count)
    self.shadowResolved = Array(repeating: ShadowState(color: .zero, sigma: 0, offset: .zero), count: self.shadowOrder.count)
    self.blurResolved = Array(repeating: 0, count: self.blurOrder.count)
    self.clipResolved = Array(repeating: ClipRect(min: .zero, max: .zero), count: self.clipOrder.count)
    self.clipOwnRects = self.clipResolved
    self.clipRadii = Array(repeating: .zero, count: self.clipOrder.count)
    self.clipRounded = Array(repeating: -1, count: self.clipOrder.count)
    self.clipGPU = Array(repeating: -1, count: self.clipOrder.count)

    // Hidden, or on its way out: it loses focus. Not here, which may be inside `render`, where a
    // handler's invalidation would be dropped with the finished render's: at the end of `update`.
    if let focused = self.focused, !self.focusOrder.contains(where: { $0 === focused }) {
      self.afterLayout { [weak self, weak focused] in
        guard let self, let focused, self.focused === focused,
              !self.focusOrder.contains(where: { $0 === focused })
        else { return }
        self.focus(nil)
      }
    }

    self.pending.remove(.treeOrder)
  }

  // Filtered through the registries rather than `mounted`, so only elements that chose to
  // register themselves are drawn and hit-tested.
  //
  // `effect` is the nearest effect above, as an index into `effectOrder`, and `clip` the
  // nearest clip, into `clipOrder`, `shadow` the nearest shadow, into `shadowOrder`, and `blur`
  // the nearest blur, into `blurOrder`, and `key` the nearest key handler, into `keyOrder`.
  // `spine` is the outermost key handler this element is reached from through single-child
  // elements only, or -1, and `inFocusable` is true under a focusable element. `leaving` is true under a child playing its
  // removal transition: still drawn, but no longer hit, focused or offered keys.
  private func collect(
    _ element: UIElement, effect: Int, clip: Int, shadow: Int, blur: Int, key: Int, spine: Int, inFocusable: Bool,
    leaving: Bool
  ) -> Void {
    // Still laid out, but nothing under it is drawn, hit or scrolled.
    guard !element.isHidden else { return }
    let isGhost = self.ghostID == ObjectIdentifier(element)
    if isGhost {
      self.drag?.ghostStart = self.paintOrder.count
    }
    defer {
      if isGhost {
        self.drag?.ghostEnd = self.paintOrder.count
      }
    }
    var effect = effect
    var clip = clip
    var shadow = shadow
    var blur = blur
    var key = key
    var spine = spine
    var inFocusable = inFocusable
    let leaving = leaving || element.isLeaving

    // Not exclusive with drawing: a sliding `Background` draws itself with its own slide.
    if element.hasEffect {
      self.effectParents.append(effect)
      effect = self.effectOrder.count
      self.effectOrder.append(element)
    }
    if let renderable = element as? UIRenderableElement,
       self.renderableViews[ObjectIdentifier(renderable)] != nil {
      self.paintOrder.append(renderable)
      self.paintEffects.append(effect)
      self.paintShadows.append(shadow)
      self.paintBlurs.append(blur)
      self.paintClips.append(clip)
    } else if !leaving, let hittable = element as? any Hittable,
              self.hittableViews[ObjectIdentifier(hittable)] != nil {
      self.hitOrder.append(hittable)
      self.hitClips.append(clip)
    }
    if !leaving, let scrollView = element as? ScrollView,
       self.scrollViews[ObjectIdentifier(scrollView)] != nil {
      self.scrollOrder.append(scrollView)
      self.scrollClips.append(clip)
    }
    // Before the focusable check: `.focusable().onKeyPress` puts the handler around the element.
    if !leaving, let handler = element as? KeyPressElement,
       self.keyHandlers[ObjectIdentifier(handler)] != nil {
      self.keyParents.append(key)
      self.keyNeedsFocus.append(inFocusable)
      key = self.keyOrder.count
      if spine < 0 {
        spine = key
      }
      self.keyOrder.append(handler)
    }
    if !leaving, !self.dropTargets.isEmpty, let target = element as? DropDestinationBase,
       self.dropTargets[ObjectIdentifier(target)] != nil {
      self.dropOrder.append(target)
      self.dropClips.append(clip)
    }
    if !leaving, let focusable = element as? FocusableElement,
       self.focusables[ObjectIdentifier(focusable)] != nil {
      self.focusOrder.append(focusable)
      self.focusClips.append(clip)
      self.focusKeys.append(key)
      // The handlers wrapped round it are its own, from the outermost on its spine down. They
      // are consecutive: nothing else sits between them in pre-order.
      if spine >= 0 {
        for handler in spine...key {
          self.keyNeedsFocus[handler] = true
        }
      }
      inFocusable = true
    }
    // After the element itself, like a clip: it shadows what is under it.
    if let shadowElement = element as? ShadowElement {
      self.shadowParents.append(shadow)
      self.shadowEffects.append(effect)
      self.shadowClips.append(clip)
      shadow = self.shadowOrder.count
      self.shadowOrder.append(shadowElement)
    }
    // After the element itself, like a shadow: it blurs what is under it.
    if let blurElement = element as? BlurElement {
      self.blurParents.append(blur)
      self.blurEffects.append(effect)
      blur = self.blurOrder.count
      self.blurOrder.append(blurElement)
    }
    // After the element itself: a clip keeps in what is under it, not the element.
    if element.clipRect != nil {
      self.clipParents.append(clip)
      self.clipEffects.append(effect)
      clip = self.clipOrder.count
      self.clipOrder.append(element)
    }
    // A container ends the spine: a handler around a stack is not any one focusable's.
    if !(element is SingleChildElement) {
      spine = -1
    }
    element.forEachChildInPaintOrder {
      self.collect(
        $0, effect: effect, clip: clip, shadow: shadow, blur: blur, key: key, spine: spine, inFocusable: inFocusable,
        leaving: leaving
      )
    }
  }
}
