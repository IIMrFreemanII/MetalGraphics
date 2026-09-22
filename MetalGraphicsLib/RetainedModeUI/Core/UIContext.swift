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

  public private(set) var pending: Invalidation = .all
  public private(set) var hitGrid = HittableGrid2D(position: .zero, size: int2(10, 10), cellSize: 50)
  private var lastSize: float2 = .zero

  public var needsRender: Bool { self.pending.contains(.render) }

  public init() {}

  // MARK: - Invalidation

  public func invalidate(_ kinds: Invalidation = .render) -> Void {
    var kinds = kinds
    if kinds.contains(.layout) {
      kinds.formUnion([.hitGrid, .treeOrder, .render])
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

  /// Hit-tests, then lays out. Run before `render(root:_:)` each frame.
  ///
  /// Hit-testing comes first so state changes its handlers make are laid out before this frame
  /// renders; the other way round, an element mounted by `onTap` would be drawn once before it
  /// had a position.
  public func update(root: Frame, size: float2, input: Input, graphics: Graphics2D) -> Void {
    if size != self.lastSize {
      self.lastSize = size
      self.invalidate(.layout)
    }

    if input.mouseMoved || input.mousePressed {
      if self.pending.contains(.treeOrder) {
        self.rebuildTreeOrder(root)
      }
      if self.pending.contains(.hitGrid) {
        self.rebuildHitGrid(graphics)
      }
      self.hitGrid.handleEvents(input)
    }

    if self.pending.contains(.layout) {
      root.size = size
      _ = root.calcSize(size)
      root.calcPosition(.init())
      // `.hitGrid` and `.treeOrder` stay pending: `invalidate(.layout)` added them.
      self.pending.remove(.layout)
    }
  }

  /// Draws every registered renderable in paint order.
  public func render(root: UIElement, _ renderer: Graphics2D) -> Void {
    if self.pending.contains(.treeOrder) {
      self.rebuildTreeOrder(root)
    }
    self.paintOrder.forEach { $0.render(renderer) }
    self.pending.remove(.render)
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
    self.hitOrder.removeAll(keepingCapacity: true)
    self.collect(root)

    self.pending.remove(.treeOrder)
  }

  // Filtered through the registries rather than `mounted`, so only elements that chose to
  // register themselves are drawn and hit-tested.
  private func collect(_ element: UIElement) -> Void {
    if let renderable = element as? UIRenderableElement,
       self.renderableViews[ObjectIdentifier(renderable)] != nil {
      self.paintOrder.append(renderable)
    } else if let hittable = element as? HittableView,
              self.hittableViews[ObjectIdentifier(hittable)] != nil {
      self.hitOrder.append(hittable)
    }
    element.forEachChild { self.collect($0) }
  }
}
