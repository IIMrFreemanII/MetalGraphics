import simd

/// Shows one host of a `DockSpace`: its docked panels, and the panels floating over them. Place
/// it anywhere in a window's tree; it takes all the space it is offered.
///
///     RetainedWindow("Workspace", id: "workspace") { _ in
///       DockArea(.workspace, host: "main")
///     }
///
/// Panels are dragged by their tabs, a group by its bar, a float by its grip. While dragging,
/// markers show where a drop docks: the middle of a group adds tabs to it, its edges split it,
/// the area's edges dock along the whole host. A drop anywhere else leaves it floating; out of
/// the window, it becomes a window of its own (when `DockWindows` manages the space), which
/// docks back into any window the same way.
///
/// The area builds its elements from the layout, and again when it changes: panels that move
/// within the window keep their elements, and so their state; a panel arriving from another
/// window is made anew, from its kind and its storage. Nothing runs per frame: a drag moves
/// elements here, and changes the layout once, when it is let go.
public final class DockArea : MultiChildElement {
  public let space: DockSpace
  public let hostID: String
  private(set) weak var context: UIContext?

  private let background = DockAreaBackground()
  private let docked = DockSlot()
  private let overlay = DockDropOverlay()
  /// Takes over the press of whatever picked up a drag: that element may be rebuilt elsewhere
  /// as the drag undocks it, and a press ends with the element it belongs to. Never hit.
  private let catcher = HittableView {}
  private var titleBar: DockTitleBar?

  private var tabsViews: [String: DockTabsView] = [:]
  private var splitViews: [String: DockSplitView] = [:]
  private var floatViews: [String: DockFloatView] = [:]
  private var floatOrder: [DockFloatView] = []
  private var panelViews: [String: DockPanelHost] = [:]
  /// The tab groups docked, then those of each float, bottom float first: what a drag looks
  /// for a target in, from the end.
  private var groupOrder: [(group: DockTabsView, float: DockFloatView?)] = []

  private(set) var layout = DockLayout()
  private(set) var host: DockHost
  private var builtGeneration: UInt64 = 0

  private var position: float2 = .zero
  private var size: float2 = .zero

  public init(_ space: DockSpace, host: String) {
    self.space = space
    self.hostID = host
    self.host = DockHost(id: host, root: nil)
    super.init()
    self.catcher.pressedPointerStyle = .grabActive
    self.catcher.onDrag = { [unowned self] input in self.dragMoved(input) }
    self.catcher.onPress = { [unowned self] down, input in
      if !down { self.dragEnded(input) }
    }
    self.applyContent([self.background, self.docked, self.overlay, self.catcher])
  }

  // MARK: - Mounting

  override public func mount(_ context: UIContext) {
    self.context = context
    self.space.observers.add(self, token: 0)
    self.space.register(self, host: self.hostID, window: context.scene?.handle)
    self.builtGeneration = 0
    self.reconcile(animation: nil)
  }

  override public func unmount(_ context: UIContext) {
    self.drag = .none
    if context.escapeTarget === self { context.escapeTarget = nil }
    self.space.observers.remove(self)
    self.space.unregister(self, host: self.hostID)
  }

  override public func __modelDidChange(_ token: Int, _ animated: Bool) {
    self.reconcile(animation: UITransaction.animation)
  }

  // MARK: - Building

  private var titleBarHeight: Float { self.titleBar == nil ? 0 : DockMetrics.titleBarHeight }

  /// Where the docked content and the floats' frames start, window coordinates.
  private var contentOrigin: float2 { self.position + float2(0, self.titleBarHeight) }
  private var contentSize: float2 { simd_max(self.size - float2(0, self.titleBarHeight), .zero) }

  /// Brings the elements up to the layout, if it changed since they were built.
  ///
  /// In two passes over every container: the first takes out what leaves each, the second puts
  /// in what arrives. An element moving from one container to another is so always out of the
  /// first before it goes into the second, which is what mounts it there.
  private func reconcile(animation: UIAnimation?) {
    guard let context = self.context, self.mounted else { return }
    let (layout, generation) = self.space.snapshot()
    guard generation != self.builtGeneration else { return }
    self.builtGeneration = generation
    self.layout = layout
    let host = layout.host(self.hostID) ?? DockHost(id: self.hostID, root: nil)
    self.host = host

    var plans: [(container: MultiChildElement, children: [UIElement])] = []
    var usedTabs = Set<String>()
    var usedSplits = Set<String>()
    var usedFloats = Set<String>()
    var groups: [(group: DockTabsView, float: DockFloatView?)] = []
    var hostPanels = Set<String>()

    func build(_ node: DockNode, in float: DockFloatView?) -> UIElement {
      switch node {
      case .tabs(let tabs):
        let view = self.tabsViews[tabs.id] ?? DockTabsView(id: tabs.id, area: self)
        self.tabsViews[tabs.id] = view
        usedTabs.insert(tabs.id)
        hostPanels.formUnion(tabs.panels)
        let content = tabs.shown.map { self.panelHost($0, layout) }
        plans.append((view, view.update(tabs, titles: layout.panels, content: content, context)))
        groups.append((view, float))
        return view
      case .split(let split):
        let view = self.splitViews[split.id] ?? DockSplitView(id: split.id, area: self)
        self.splitViews[split.id] = view
        usedSplits.insert(split.id)
        let nodes = split.children.map { build($0, in: float) }
        plans.append((view, view.update(split, nodes: nodes)))
        return view
      }
    }

    let root = host.root.map { build($0, in: nil) }
    plans.append((self.docked, root.map { [$0] } ?? []))

    var floats: [DockFloatView] = []
    for float in host.floating {
      let view = self.floatViews[float.id] ?? DockFloatView(id: float.id, area: self)
      self.floatViews[float.id] = view
      usedFloats.insert(float.id)
      let content = build(float.node, in: view)
      // A float being dragged keeps where the drag has it.
      plans.append((view, view.update(float, keepFrame: self.drag.movingFloat == float.id)))
      plans.append((view.slot, [content]))
      floats.append(view)
    }
    self.floatOrder = floats
    self.groupOrder = groups.filter { $0.float == nil } + groups.filter { $0.float != nil }

    if host.isDetached && layout.windowStyle == .custom {
      let bar = self.titleBar ?? DockTitleBar(area: self)
      self.titleBar = bar
      bar.setTitle(self.windowTitle, context)
    } else {
      self.titleBar = nil
    }

    var children: [UIElement] = [self.background, self.docked]
    children += floats
    if let titleBar = self.titleBar { children.append(titleBar) }
    children += [self.overlay, self.catcher]
    plans.append((self, children))

    // What is no longer shown empties, so what it held can go elsewhere.
    for (id, view) in self.tabsViews where !usedTabs.contains(id) { plans.append((view, [])) }
    for (id, view) in self.splitViews where !usedSplits.contains(id) { plans.append((view, [])) }
    for (id, view) in self.floatViews where !usedFloats.contains(id) {
      plans.append((view, []))
      plans.append((view.slot, []))
    }

    for (container, children) in plans {
      let keep = Set(children.map(ObjectIdentifier.init))
      let kept = container.children.filter { keep.contains(ObjectIdentifier($0)) }
      if kept.count != container.children.count {
        container.replaceChildren(kept, context)
      }
    }
    for (container, children) in plans where !container.children.elementsEqual(children, by: ===) {
      container.replaceChildren(children, context, animation: animation)
    }

    self.tabsViews = self.tabsViews.filter { usedTabs.contains($0.key) }
    self.splitViews = self.splitViews.filter { usedSplits.contains($0.key) }
    self.floatViews = self.floatViews.filter { usedFloats.contains($0.key) }
    self.panelViews = self.panelViews.filter { hostPanels.contains($0.key) }

    // A drag whose float is gone — docked or closed from another window — ends here.
    if let moving = self.drag.movingFloat, !usedFloats.contains(moving) {
      self.endDrag()
    }
    context.invalidate(.layout)
  }

  /// The element for `panel`'s content: kept while the panel is in this host, made from its
  /// kind the first time it is shown here.
  private func panelHost(_ panel: String, _ layout: DockLayout) -> DockPanelHost {
    if let view = self.panelViews[panel] { return view }
    let info = layout.panels[panel] ?? DockPanelInfo(kind: "", title: "")
    let dockPanel = DockPanel(id: panel, kind: info.kind, space: self.space, storage: info.storage)
    let content: UIElement = self.space.kind(info.kind)?.make(dockPanel)
      ?? Text("No panel kind “\(info.kind)”").padding(12)
    let view = DockPanelHost(panel: dockPanel, content: content)
    self.panelViews[panel] = view
    return view
  }

  /// A detached window's title: the panel it shows, or how many.
  var windowTitle: String {
    self.layout.title(ofHost: self.hostID)
  }

  // MARK: - Layout

  override public func getSize() -> float2 { self.size }

  override public func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override public func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = proposal.replacingUnspecified(with: .zero)
    _ = self.background.calcSize(ProposedSize(self.size))
    _ = self.titleBar?.calcSize(ProposedSize(width: self.size.x, height: DockMetrics.titleBarHeight))
    _ = self.docked.calcSize(ProposedSize(self.contentSize))
    for float in self.floatOrder {
      _ = float.calcSize(ProposedSize(float.frame.size))
    }
    return self.size
  }

  override public func calcPosition(_ position: float2) {
    self.position = position
    self.background.calcPosition(position)
    self.titleBar?.calcPosition(position)
    self.docked.calcPosition(self.contentOrigin)
    for float in self.floatOrder {
      self.place(float, at: self.contentOrigin + float.frame.origin, in: position)
    }
    self.placeLeaving(in: position)
  }

  // MARK: - Dragging

  /// What a press picked up.
  enum Pickup {
    case panel(String, group: String)
    case group(String)
    case float(String)
    case titleBar
  }

  private enum Drag {
    case none
    /// Pressed, not yet moved far enough to be a drag.
    case pending(Pickup, start: float2)
    /// Float `id` follows the pointer, held `grab` from its top left.
    case moving(float: String, grab: float2)
    /// Float `id`'s edges `edges` (left, top, right, bottom) follow the pointer.
    case resizing(float: String, edges: float4, start: float2, frame: DockRect)
    /// The window the host is in is being dragged by the main thread, until the press ends.
    case window

    var movingFloat: String? {
      switch self {
      case .moving(let id, _), .resizing(let id, _, _, _): id
      default: nil
      }
    }
  }

  private var drag = Drag.none
  /// Where a drop would dock now.
  private var target: DockTarget?

  /// A tab, a bar, a grip or the title bar was pressed.
  func pickUp(_ pickup: Pickup, _ input: Input) {
    guard let context = self.context else { return }
    if case .panel(let panel, let group) = pickup, self.tabsViews[group]?.selected != panel {
      self.space.select(panel: panel)
    }
    self.drag = .pending(pickup, start: input.mousePosition)
    context.hitGrid.handOffPress(to: self.catcher)
    context.escapeTarget = self
  }

  private func dragMoved(_ input: Input) {
    let point = input.mousePosition
    switch self.drag {
    case .pending(let pickup, let start):
      guard simd_distance(point, start) >= DockMetrics.dragThreshold else { return }
      self.begin(pickup, at: start, input)
      if case .moving = self.drag { self.dragMoved(input) }

    case .moving(let id, let grab):
      guard let view = self.floatViews[id] else { return }
      if !input.isPointerInView, self.tearOut(view, grab: grab) { return }
      let origin = point - grab
      guard origin != view.dragOrigin, let context = self.context else { return }
      // Drawn at the pointer by an offset, laid out there once the drag commits.
      context.invalidate(view.dragOrigin == nil ? [.render, .treeOrder] : .render)
      view.dragOrigin = origin
      view.frame.origin = origin - self.contentOrigin
      self.updateTarget(at: point, excluding: view)

    default:
      break
    }
  }

  /// Turns a press into a drag: moves a float, or undocks what was picked up into one, or has
  /// the main thread drag the window when what was picked up is all the window holds.
  private func begin(_ pickup: Pickup, at start: float2, _ input: Input) {
    switch pickup {
    case .titleBar:
      self.dragWindow(input)

    case .float(let id):
      guard let view = self.floatViews[id] else { return self.endDrag() }
      if self.holdsOnly(floatID: id) { return self.dragWindow(input) }
      self.drag = .moving(float: id, grab: start - view.rect.min)

    case .group(let id):
      guard let view = self.tabsViews[id] else { return self.endDrag() }
      if let float = self.float(rootedAt: id) {
        if self.holdsOnly(floatID: float.id) { return self.dragWindow(input) }
        self.drag = .moving(float: float.id, grab: start - float.rect.min)
      } else if self.host.floating.isEmpty, self.host.root?.id == id, self.host.isDetached {
        self.dragWindow(input)
      } else {
        self.undock(.node(id), from: view, grab: start - view.position)
      }

    case .panel(let panel, let group):
      guard let view = self.tabsViews[group] else { return self.endDrag() }
      let alone = view.panels.count == 1
      if alone, let float = self.float(rootedAt: group) {
        if self.holdsOnly(floatID: float.id) { return self.dragWindow(input) }
        self.drag = .moving(float: float.id, grab: start - float.rect.min)
      } else if alone, self.host.floating.isEmpty, self.host.root?.id == group, self.host.isDetached {
        self.dragWindow(input)
      } else {
        // Held where the tab was: the new group's first tab sits at the bar's inset.
        let tab = view.tabOrigin(panel) ?? view.position
        let grab = float2(start.x - tab.x + DockMetrics.tabInset, start.y - view.position.y)
        self.undock(.panel(panel), from: view, grab: grab)
      }
    }
  }

  /// Floats `source`, picked up from `group`, under the pointer, and drags it.
  private func undock(_ source: DockSource, from group: DockTabsView, grab: float2) {
    let size = simd_clamp(group.size, DockMetrics.minFloat, simd_max(self.contentSize * 0.7, DockMetrics.minFloat))
    let grab = simd_min(grab, size - 8)
    // Where the group was: the move that follows puts it under the pointer.
    let frame = DockRect(origin: group.position - self.contentOrigin, size: size)
    guard let node = self.space.move(source, to: .float(self.hostID, frame)),
          let float = self.float(rootedAt: node)
    else { return self.endDrag() }
    self.drag = .moving(float: float.id, grab: grab)
  }

  private func dragEnded(_ input: Input) {
    switch self.drag {
    case .moving(let id, _):
      let frame = self.floatViews[id]?.frame
      let target = self.target
      self.endDrag()
      if let target, let root = self.layout.float(id)?.float.node.id {
        withAnimation(DockMetrics.animation) {
          _ = self.space.move(.node(root), to: target)
        }
      } else if let frame {
        self.space.setFrame(frame, ofFloat: id)
      }
    default:
      self.endDrag()
    }
  }

  private func endDrag() {
    self.drag = .none
    self.clearTarget()
    if self.context?.escapeTarget === self { self.context?.escapeTarget = nil }
  }

  /// Escape: a float being moved goes back to where it was; a resize to its size.
  func cancelDrag() {
    guard let id = self.drag.movingFloat else { return self.endDrag() }
    self.endDrag()
    if let view = self.floatViews[id], let float = self.layout.float(id)?.float {
      view.frame = float.frame
      view.dragOrigin = nil
      self.context?.invalidate([.layout, .treeOrder])
    }
  }

  /// The float whose tree is node `id`.
  private func float(rootedAt id: String) -> DockFloatView? {
    guard let float = self.host.floating.first(where: { $0.node.id == id }) else { return nil }
    return self.floatViews[float.id]
  }

  /// Whether float `id` is all a detached host holds: then dragging it drags the window.
  private func holdsOnly(floatID id: String) -> Bool {
    self.host.isDetached && self.host.root == nil && self.host.floating.count == 1 && self.host.floating[0].id == id
  }

  // MARK: - Windows

  /// Has the main thread drag this area's window, held where the pointer is.
  private func dragWindow(_ input: Input) {
    guard self.host.isDetached, self.space.request(.drag(host: self.hostID, grab: input.mousePosition)) else {
      return self.endDrag()
    }
    self.clearTarget()
    self.drag = .window
  }

  /// Out of the window: the float becomes a detached host, whose window the main thread opens
  /// under the pointer and drags on. False when nothing manages windows.
  private func tearOut(_ view: DockFloatView, grab: float2) -> Bool {
    guard self.space.managesWindows, let float = self.layout.float(view.id)?.float else { return false }
    let host = DockLayout.newID()
    let size = view.frame.size
    guard self.space.move(.node(float.node.id), to: .newHost(host)) != nil else { return false }
    self.space.request(.tearOut(host: host, grab: grab, size: size))
    self.clearTarget()
    self.drag = .window
    return true
  }

  func windowButton(_ kind: DockWindowButton.Kind) {
    switch kind {
    case .close: self.space.request(.close(host: self.hostID))
    case .minimize: self.space.request(.minimize(host: self.hostID))
    case .zoom: self.space.request(.zoom(host: self.hostID))
    }
  }

  func closePanel(_ panel: String) {
    withAnimation(DockMetrics.animation) {
      self.space.close(panel: panel)
    }
  }

  /// Another window's host is dragged over this area, the pointer at `point` in this window;
  /// nil when it left.
  func remoteHover(_ point: float2?) {
    if let point {
      self.updateTarget(at: point, excluding: nil)
    } else {
      self.clearTarget()
    }
  }

  /// Another window's host was let go over this area at `point`: docks it where the markers
  /// under the point say. Returns whether it docked.
  @discardableResult
  func remoteDrop(_ point: float2, source host: String) -> Bool {
    self.updateTarget(at: point, excluding: nil)
    let target = self.target
    self.clearTarget()
    guard let target else { return false }
    return withAnimation(DockMetrics.animation) {
      self.space.move(.host(host), to: target) != nil
    }
  }

  // MARK: - Resizing floats

  func resizePressed(_ id: String, _ edges: float4, _ down: Bool, _ input: Input) {
    if down {
      guard let view = self.floatViews[id] else { return }
      self.drag = .resizing(float: id, edges: edges, start: input.mousePosition, frame: view.frame)
    } else if case .resizing(let id, _, _, _) = self.drag {
      self.drag = .none
      if let frame = self.floatViews[id]?.frame {
        self.space.setFrame(frame, ofFloat: id)
      }
    }
  }

  func resizeDragged(_ input: Input) {
    guard case .resizing(let id, let edges, let start, let frame) = self.drag, let view = self.floatViews[id] else { return }
    let delta = input.mousePosition - start
    var minX = frame.x, minY = frame.y
    var maxX = frame.x + frame.width, maxY = frame.y + frame.height
    let minimum = DockMetrics.minFloat
    if edges.x > 0 { minX = min(minX + delta.x, maxX - minimum.x) }
    if edges.y > 0 { minY = min(minY + delta.y, maxY - minimum.y) }
    if edges.z > 0 { maxX = max(maxX + delta.x, minX + minimum.x) }
    if edges.w > 0 { maxY = max(maxY + delta.y, minY + minimum.y) }
    let resized = DockRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    guard resized != view.frame else { return }
    view.frame = resized
    self.context?.invalidate(.layout)
  }

  // MARK: - Targets

  private func clearTarget() {
    self.target = nil
    guard self.overlay.isShown else { return }
    self.overlay.markers.removeAll()
    self.overlay.preview = nil
    self.context?.invalidate(.render)
  }

  /// Finds what a drop at `point` would dock onto, other than float `excluded`, and shows it.
  private func updateTarget(at point: float2, excluding excluded: DockFloatView?) {
    var markers: [DockDropOverlay.Marker] = []
    var target: DockTarget?
    var preview: ClipRect?

    // The group under the pointer: in the topmost float it is over, else docked.
    // Never the excluded float's own: `overFloat` is not it, and a docked group is in none.
    let overFloat = self.floatOrder.last { $0 !== excluded && $0.rect.contains(point) }
    let group = self.groupOrder.last { entry in
      entry.float === overFloat && entry.group.rect.contains(point)
    }?.group
    if let group {
      let rect = group.rect
      let center = (rect.min + rect.max) * 0.5
      let room = simd_reduce_min(rect.max - rect.min)
      let spacing = min(DockMetrics.markerSpacing, max((room - DockMetrics.markerSize) * 0.5, 0))
      for zone in DockZone.allCases {
        let offset: float2 = switch zone {
        case .center: .zero
        case .left: float2(-spacing, 0)
        case .right: float2(spacing, 0)
        case .top: float2(0, -spacing)
        case .bottom: float2(0, spacing)
        }
        // Too small a group to split: its middle alone.
        if zone != .center && spacing < DockMetrics.markerSize { continue }
        let half = DockMetrics.markerSize * 0.5
        let marker = ClipRect(min: center + offset - half, max: center + offset + half)
        let hovered = marker.contains(point) || (zone == .center && group.barRect.contains(point))
        if hovered {
          target = .node(group.id, zone)
          preview = Self.split(rect, zone, fraction: 0.5)
        }
        markers.append(.init(rect: marker, zone: zone, isHovered: hovered))
      }
    }

    // Along the area's edges, where the pointer is not over a float.
    if overFloat == nil {
      let origin = self.contentOrigin
      let size = self.contentSize
      let half = DockMetrics.markerSize * 0.5
      let inset = DockMetrics.edgeInset + half
      let mid = origin + size * 0.5
      let edges: [(DockZone, float2)] = [
        (.left, float2(origin.x + inset, mid.y)), (.right, float2(origin.x + size.x - inset, mid.y)),
        (.top, float2(mid.x, origin.y + inset)), (.bottom, float2(mid.x, origin.y + size.y - inset)),
      ]
      let hasRoot = self.host.root != nil
      for (zone, center) in edges where hasRoot || zone == .left {
        let marker = ClipRect(min: center - half, max: center + half)
        let hovered = target == nil && marker.contains(point)
        if hovered {
          // Nothing docked: any edge fills the whole area.
          let area = ClipRect(position: origin, size: size)
          target = .hostEdge(self.hostID, hasRoot ? zone : .center)
          preview = hasRoot ? Self.split(area, zone, fraction: DockMetrics.edgeFraction) : area
        }
        markers.append(.init(rect: marker, zone: hasRoot ? zone : .center, isHovered: hovered))
      }
    }

    self.target = target
    guard markers != self.overlay.markers || preview != self.overlay.preview else { return }
    self.overlay.markers = markers
    self.overlay.preview = preview
    self.context?.invalidate(.render)
  }

  /// The part of `rect` a drop on `zone` takes.
  private static func split(_ rect: ClipRect, _ zone: DockZone, fraction: Float) -> ClipRect {
    var result = rect
    let size = rect.max - rect.min
    switch zone {
    case .center: break
    case .left: result.max.x = rect.min.x + size.x * fraction
    case .right: result.min.x = rect.max.x - size.x * fraction
    case .top: result.max.y = rect.min.y + size.y * fraction
    case .bottom: result.min.y = rect.max.y - size.y * fraction
    }
    return result
  }
}

extension DockArea : EscapeCancellable {
  func cancelOnEscape() {
    self.cancelDrag()
  }
}
