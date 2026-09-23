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
  private var hittableViews: [ObjectIdentifier : HittableView] = [:]

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
  private var hitOrder: [HittableView] = []

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

  public var needsRender: Bool { self.pending.contains(.render) }

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

  public func registerHittableView(_ view: HittableView) -> Void {
    self.hittableViews[ObjectIdentifier(view)] = view
    self.invalidate(.treeOrder)
  }

  public func unregisterHittableView(_ view: HittableView) -> Void {
    self.hittableViews.removeValue(forKey: ObjectIdentifier(view))
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
    root: Frame, size: float2, input: Input, graphics: Graphics2D, time: Double = CACurrentMediaTime()
  ) -> Void {
    if size != self.lastSize {
      self.lastSize = size
      self.invalidate(.layout)
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
      self.hitGrid.handleEvents(input)
    }

    self.animator.tick(time, self)
    if !self.animator.isIdle {
      // A delayed animation writes nothing yet, but the frame after it must still be drawn.
      self.invalidate(.render)
    }

    if self.pending.contains(.layout) {
      root.size = size
      _ = root.calcSize(size)
      if let animation = self.layoutAnimation {
        LayoutPass.current = LayoutPass(context: self, animation: animation, group: self.layoutGroups.last)
      }
      root.calcPosition(.init())
      LayoutPass.current = nil
      self.layoutAnimation = nil
      if !self.layoutGroups.isEmpty {
        // After the slides joined the group, so an animation-free pass cannot end it early.
        self.layoutGroups.forEach { self.animator.release($0) }
        self.layoutGroups.removeAll()
      }
      // `.hitGrid` stays pending: `invalidate(.layout)` added it.
      self.pending.remove(.layout)
    }
  }

  /// Draws every registered renderable in paint order, each with the effects above it.
  public func render(root: UIElement, _ renderer: Graphics2D) -> Void {
    if self.pending.contains(.treeOrder) {
      self.rebuildTreeOrder(root)
    }

    if self.effectOrder.isEmpty {
      self.paintOrder.forEach { $0.render(renderer, .identity) }
    } else {
      self.resolveEffects()
      for (renderable, effect) in zip(self.paintOrder, self.paintEffects) {
        renderable.render(renderer, effect < 0 ? .identity : self.effectResolved[effect])
      }
    }
    self.pending.remove(.render)
  }

  // Parents come first in `effectOrder`, so each one's parent is already resolved.
  private func resolveEffects() -> Void {
    for index in self.effectOrder.indices {
      let local = self.effectOrder[index].localEffect
      let parent = self.effectParents[index]
      self.effectResolved[index] = parent < 0 ? local : self.effectResolved[parent].composed(with: local)
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
    self.hitOrder.reversed().forEach { self.hitGrid.mapViewToGrid($0, renderer) }

    self.pending.remove(.hitGrid)
  }

  // MARK: - Tree order

  private func rebuildTreeOrder(_ root: UIElement) -> Void {
    self.paintOrder.removeAll(keepingCapacity: true)
    self.paintEffects.removeAll(keepingCapacity: true)
    self.hitOrder.removeAll(keepingCapacity: true)
    self.effectOrder.removeAll(keepingCapacity: true)
    self.effectParents.removeAll(keepingCapacity: true)
    self.collect(root, effect: -1, leaving: false)
    self.effectResolved = Array(repeating: .identity, count: self.effectOrder.count)

    self.pending.remove(.treeOrder)
  }

  // Filtered through the registries rather than `mounted`, so only elements that chose to
  // register themselves are drawn and hit-tested.
  //
  // `effect` is the nearest effect above, as an index into `effectOrder`. `leaving` is true
  // under a child playing its removal transition: still drawn, but no longer hit.
  private func collect(_ element: UIElement, effect: Int, leaving: Bool) -> Void {
    var effect = effect
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
    } else if !leaving, let hittable = element as? HittableView,
              self.hittableViews[ObjectIdentifier(hittable)] != nil {
      self.hitOrder.append(hittable)
    }
    element.forEachChild { self.collect($0, effect: effect, leaving: leaving) }
  }
}
