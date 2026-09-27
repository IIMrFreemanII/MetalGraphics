import simd

// The elements a `DockArea` shows its host with: a tab group, a split, a float, a panel's
// content, a detached window's own title bar, and the drop zones shown while dragging.
//
// They are built and rebuilt only by the area's `reconcile`, and they hold nothing the layout
// does not, except what a drag moves before it commits: a split's fractions, a float's frame.

enum DockMetrics {
  static let barHeight: Float = 28
  static let titleBarHeight: Float = 28
  static let gripHeight: Float = 12
  static let gap: Float = 1
  static let sashHit: Float = 6
  static let resizeHit: Float = 6
  static let tabInset: Float = 4
  static let tabPadding: Float = 10
  static let tabSpacing: Float = 2
  static let closeSize: Float = 14
  static let tabMinWidth: Float = 48
  static let tabMaxWidth: Float = 220
  static let floatRadius: Float = 7
  static let minPane: Float = 60
  static let minFloat = float2(180, 110)
  static let markerSize: Float = 28
  static let markerSpacing: Float = 34
  static let edgeInset: Float = 10
  static let dragThreshold: Float = 4
  /// How much of a host's content a drop on its edge takes.
  static let edgeFraction: Float = 0.3

  static let gapColor = float4(0.74, 0.74, 0.76, 1)
  static let barColor = float4(0.88, 0.88, 0.9, 1)
  static let tabHoverColor = float4(0.93, 0.93, 0.95, 1)
  static let tabSelectedColor = float4(1, 1, 1, 1)
  static let contentColor = float4(1, 1, 1, 1)
  static let titleBarColor = float4(0.84, 0.84, 0.86, 1)
  static let borderColor = float4(0, 0, 0, 0.18)
  static let shadowColor = float4(0, 0, 0, 0.28)
  static let glyphColor = float4(0.35, 0.35, 0.38, 1)
  static let accent = FormMetrics.accentColor
  static let font = FormMetrics.captionFont
  static let animation = UIAnimation.easeOut(0.16)
}

/// Draws a rect in window coordinates: the `draw` calls take window centred ones.
private func centred(_ position: float2, _ renderer: Graphics2D) -> float2 {
  position - renderer.size * 0.5
}

// MARK: - Slot

/// Holds zero or one child and gives it all its space, less `topInset` at the top.
final class DockSlot : MultiChildElement {
  var topInset: Float = 0
  private var size: float2 = .zero

  override func getSize() -> float2 { self.size }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = proposal.replacingUnspecified(with: .zero)
    let inner = simd_max(self.size - float2(0, self.topInset), .zero)
    for child in self.children where !child.isLeaving {
      _ = child.calcSize(ProposedSize(inner))
    }
    return self.size
  }

  override func calcPosition(_ position: float2) {
    for child in self.children where !child.isLeaving {
      self.place(child, at: position + float2(0, self.topInset), in: position)
    }
    self.placeLeaving(in: position)
  }
}

// MARK: - Panel content

/// A panel's content, clipped to the space it is given. Kept by its area while the panel is in
/// the area's host, shown or not, so switching tabs keeps its state.
final class DockPanelHost : SingleChildElement {
  let panel: DockPanel
  private var position: float2 = .zero
  private var size: float2 = .zero

  init(panel: DockPanel, content: UIElement) {
    self.panel = panel
    super.init()
    self.applyContent([content])
  }

  override func getSize() -> float2 { self.size }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = proposal.replacingUnspecified(with: .zero)
    _ = self.child?.calcSize(ProposedSize(self.size))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.child?.calcPosition(position)
  }

  override var clipRect: ClipRect? {
    ClipRect(position: self.position, size: self.size)
  }
}

// MARK: - Tab group

/// A tab group: a bar of tabs over the shown panel. Pressing a tab shows it and picks it up;
/// pressing the bar beside the tabs picks the whole group up.
final class DockTabsView : MultiChildElement {
  let id: String
  unowned let area: DockArea
  private(set) var panels: [String] = []
  private(set) var selected: String?

  private let chrome = DockTabsChrome()
  private let barHandle: HittableView
  private var items: [String: DockTabItem] = [:]
  private var shownItems: [DockTabItem] = []
  private var content: DockPanelHost?

  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  init(id: String, area: DockArea) {
    self.id = id
    self.area = area
    self.barHandle = HittableView {}
    super.init()
    self.barHandle.onPress = { [unowned self] down, input in
      if down { self.area.pickUp(.group(self.id), input) }
    }
  }

  var rect: ClipRect { ClipRect(position: self.position, size: self.size) }

  /// The bar's rect, window coordinates.
  var barRect: ClipRect { ClipRect(position: self.position, size: float2(self.size.x, DockMetrics.barHeight)) }

  /// Where the tab of `panel` starts, window coordinates.
  func tabOrigin(_ panel: String) -> float2? {
    self.items[panel].map(\.position)
  }

  /// Brings the group up to `tabs`, showing `content`; returns the children it should have.
  func update(_ tabs: DockTabs, titles: [String: DockPanelInfo], content: DockPanelHost?, _ context: UIContext) -> [UIElement] {
    self.panels = tabs.panels
    self.selected = tabs.shown
    self.content = content
    var shown: [DockTabItem] = []
    for panel in tabs.panels {
      let item = self.items[panel] ?? DockTabItem(panel: panel, group: self)
      self.items[panel] = item
      item.setTitle(titles[panel]?.title ?? "", context)
      item.isSelected = panel == tabs.shown
      shown.append(item)
    }
    // Forgotten here, and unmounted by the reconcile that no longer lists them.
    let keep = Set(tabs.panels)
    self.items = self.items.filter { keep.contains($0.key) }
    self.shownItems = shown
    self.chrome.group = self
    var children: [UIElement] = [self.chrome, self.barHandle]
    children += shown
    if let content { children.append(content) }
    return children
  }

  // MARK: Layout

  override func getSize() -> float2 { self.size }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = proposal.replacingUnspecified(with: .zero)
    let barHeight = DockMetrics.barHeight
    _ = self.chrome.calcSize(ProposedSize(self.size))
    _ = self.barHandle.calcSize(ProposedSize(width: self.size.x, height: barHeight))

    // Each tab at its title's width, all of them shrunk alike when they do not fit.
    let ideal = self.shownItems.map { $0.idealWidth() }
    let spacing = DockMetrics.tabSpacing * Float(max(self.shownItems.count - 1, 0))
    let available = self.size.x - DockMetrics.tabInset * 2 - spacing
    let total = ideal.reduce(0, +)
    let scale = total > available && total > 0 ? max(available, 0) / total : 1
    for (item, width) in zip(self.shownItems, ideal) {
      _ = item.calcSize(ProposedSize(width: max(width * scale, min(DockMetrics.tabMinWidth, width)), height: barHeight - 4))
    }
    _ = self.content?.calcSize(ProposedSize(width: self.size.x, height: max(self.size.y - barHeight, 0)))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.chrome.calcPosition(position)
    self.barHandle.calcPosition(position)
    var x = position.x + DockMetrics.tabInset
    for item in self.shownItems {
      self.place(item, at: float2(x, position.y + 4), in: position)
      x += item.getSize().x + DockMetrics.tabSpacing
    }
    if let content {
      content.calcPosition(position + float2(0, DockMetrics.barHeight))
    }
    self.placeLeaving(in: position)
  }
}

/// One tab: its title, and a close button that shows when it is selected or hovered.
final class DockTabItem : MultiChildElement {
  let panel: String
  unowned let group: DockTabsView
  private let fill = DockTabFill()
  private let title: Text
  private let press: HittableView
  private let close: HittableView
  private var titleString = ""

  var isSelected = false {
    didSet { if oldValue != self.isSelected { self.fill.isSelected = self.isSelected } }
  }

  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  init(panel: String, group: DockTabsView) {
    self.panel = panel
    self.group = group
    self.title = Text("").font(DockMetrics.font).foregroundColor(FormMetrics.labelColor).lineLimit(1)
    self.press = HittableView {}
    self.close = HittableView {}
    super.init()
    self.fill.item = self
    self.press.onPress = { [unowned self] down, input in
      if down { self.group.area.pickUp(.panel(self.panel, group: self.group.id), input) }
    }
    self.press.onHover = { [unowned self] hovered, _ in
      self.fill.isHovered = hovered
      self.group.area.context?.invalidate(.render)
    }
    // A tap goes to the topmost view that takes taps, and a press to the topmost that takes
    // presses: this takes both, so closing does not also pick the tab up.
    self.close.onPress = { _, _ in }
    self.close.onTap = { [unowned self] _ in self.group.area.closePanel(self.panel) }
    self.close.onHover = { [unowned self] hovered, _ in
      self.fill.isCloseHovered = hovered
      self.group.area.context?.invalidate(.render)
    }
    self.applyContent([self.fill, self.title, self.press, self.close])
  }

  func setTitle(_ title: String, _ context: UIContext) {
    guard title != self.titleString else { return }
    self.titleString = title
    self.title.setText(title, context)
  }

  func idealWidth() -> Float {
    let text = self.title.measure(.unspecified).x
    return min(text + DockMetrics.tabPadding * 2 + DockMetrics.closeSize + 4, DockMetrics.tabMaxWidth)
  }

  /// The close button's rect, window coordinates.
  var closeRect: ClipRect {
    let side = DockMetrics.closeSize
    let origin = self.position + float2(self.size.x - DockMetrics.tabPadding * 0.5 - side, (self.size.y - side) * 0.5)
    return ClipRect(position: origin, size: float2(side, side))
  }

  override func getSize() -> float2 { self.size }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: float2(self.idealWidth(), DockMetrics.barHeight - 4))
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    _ = self.fill.calcSize(ProposedSize(self.size))
    let textWidth = max(self.size.x - DockMetrics.tabPadding * 2 - DockMetrics.closeSize - 4, 0)
    _ = self.title.calcSize(ProposedSize(width: textWidth, height: nil))
    _ = self.press.calcSize(ProposedSize(self.size))
    _ = self.close.calcSize(ProposedSize(float2(repeating: DockMetrics.closeSize)))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.fill.calcPosition(position)
    let textSize = self.title.getSize()
    self.title.calcPosition(position + float2(DockMetrics.tabPadding, ((self.size.y - textSize.y) * 0.5).rounded()))
    self.press.calcPosition(position)
    self.close.calcPosition(self.closeRect.min)
  }
}

/// A tab's rounded background, and its close cross.
final class DockTabFill : FormGraphic {
  weak var item: DockTabItem?
  var isSelected = false
  var isHovered = false
  var isCloseHovered = false

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    if self.isSelected || self.isHovered {
      var color = self.isSelected ? DockMetrics.tabSelectedColor : DockMetrics.tabHoverColor
      color.w *= opacity
      renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: 5 * scale), color: color)
    }
    guard let item = self.item, self.isSelected || self.isHovered else { return }
    // The cross, in the close button's rect, moved as the tab is.
    let close = item.closeRect
    let min = origin + (close.min - item.position) * scale
    let side = (close.max.x - close.min.x) * scale
    if self.isCloseHovered {
      renderer.draw(roundedRect: min, size: float2(side, side), radii: float4(repeating: 3 * scale),
                    color: float4(0, 0, 0, 0.08 * opacity))
    }
    let inset = side * 0.3
    var color = DockMetrics.glyphColor
    color.w *= opacity
    renderer.draw(stroke: min + inset, to: min + side - inset, width: 1.2 * scale, color: color)
    renderer.draw(stroke: min + float2(side - inset, inset), to: min + float2(inset, side - inset), width: 1.2 * scale, color: color)
  }
}

/// A tab group's bar, and the background of its content.
final class DockTabsChrome : FormGraphic {
  weak var group: DockTabsView?

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let bar = DockMetrics.barHeight * scale
    var barColor = DockMetrics.barColor
    barColor.w *= opacity
    var contentColor = DockMetrics.contentColor
    contentColor.w *= opacity
    renderer.draw(roundedRect: origin, size: float2(size.x, bar), radii: .zero, color: barColor)
    renderer.draw(roundedRect: origin + float2(0, bar), size: float2(size.x, max(size.y - bar, 0)), radii: .zero, color: contentColor)
  }
}

// MARK: - Split

/// Children side by side or stacked, with a sash between each two that resizes them.
final class DockSplitView : MultiChildElement {
  let id: String
  unowned let area: DockArea
  private(set) var axis: DockAxis = .horizontal
  /// The layout's, or what a sash being dragged has made of them until it is let go.
  var fractions: [Float] = []
  private var nodes: [UIElement] = []
  private var sashes: [HittableView] = []
  private var position: float2 = .zero
  private var size: float2 = .zero
  private var dragStart: (point: Float, fractions: [Float])?

  init(id: String, area: DockArea) {
    self.id = id
    self.area = area
    super.init()
  }

  func update(_ split: DockSplit, nodes: [UIElement]) -> [UIElement] {
    self.axis = split.axis
    self.fractions = split.fractions
    self.nodes = nodes
    while self.sashes.count < max(nodes.count - 1, 0) {
      let index = self.sashes.count
      let sash = HittableView {}
      sash.onPress = { [unowned self] down, input in self.sashPressed(index, down, input) }
      sash.onDrag = { [unowned self] input in self.sashDragged(index, input) }
      self.sashes.append(sash)
    }
    let style: PointerStyle = split.axis == .horizontal ? .columnResize : .rowResize
    for sash in self.sashes where sash.pointerStyle != style {
      sash.pointerStyle = style
    }
    return nodes + self.sashes.prefix(max(nodes.count - 1, 0)).map { $0 as UIElement }
  }

  private var axisIndex: Int { self.axis == .horizontal ? 0 : 1 }

  /// Each child's length along the axis.
  private func lengths() -> [Float] {
    let count = self.nodes.count
    let available = max(self.size[self.axisIndex] - DockMetrics.gap * Float(max(count - 1, 0)), 0)
    var lengths = self.fractions.prefix(count).map { ($0 * available).rounded() }
    if let last = lengths.indices.last {
      lengths[last] = max(available - lengths.dropLast().reduce(0, +), 0)
    }
    return lengths
  }

  override func getSize() -> float2 { self.size }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = proposal.replacingUnspecified(with: .zero)
    let a = self.axisIndex
    for (node, length) in zip(self.nodes, self.lengths()) {
      var size = self.size
      size[a] = length
      _ = node.calcSize(ProposedSize(size))
    }
    for sash in self.sashes.prefix(max(self.nodes.count - 1, 0)) {
      var size = self.size
      size[a] = DockMetrics.sashHit
      _ = sash.calcSize(ProposedSize(size))
    }
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    let a = self.axisIndex
    var offset: Float = 0
    for (index, (node, length)) in zip(self.nodes, self.lengths()).enumerated() {
      var origin = position
      origin[a] += offset
      self.place(node, at: origin, in: position)
      offset += length
      if index < self.sashes.count, index < self.nodes.count - 1 {
        var sashOrigin = position
        sashOrigin[a] += offset + DockMetrics.gap * 0.5 - DockMetrics.sashHit * 0.5
        self.sashes[index].calcPosition(sashOrigin)
      }
      offset += DockMetrics.gap
    }
    self.placeLeaving(in: position)
  }

  // MARK: Sashes

  private func sashPressed(_ index: Int, _ down: Bool, _ input: Input) {
    if down {
      self.dragStart = (input.mousePosition[self.axisIndex], self.fractions)
    } else if self.dragStart != nil {
      self.dragStart = nil
      self.area.space.setFractions(self.fractions, of: self.id)
    }
  }

  /// Moves the sash between children `index` and `index + 1`, trading length between the two
  /// only, neither below `minPane`.
  private func sashDragged(_ index: Int, _ input: Input) {
    guard let start = self.dragStart, index + 1 < start.fractions.count else { return }
    let count = self.nodes.count
    let available = max(self.size[self.axisIndex] - DockMetrics.gap * Float(max(count - 1, 0)), 1)
    let delta = (input.mousePosition[self.axisIndex] - start.point) / available
    let pair = start.fractions[index] + start.fractions[index + 1]
    let minimum = min(DockMetrics.minPane / available, pair * 0.5)
    let first = min(max(start.fractions[index] + delta, minimum), pair - minimum)
    guard first != self.fractions[index] else { return }
    self.fractions[index] = first
    self.fractions[index + 1] = pair - first
    self.area.context?.invalidate(.layout)
  }
}

// MARK: - Float

/// A tree floating over the docked content: a card with a shadow, resized from its edges. A
/// float holding more than one group gets a grip strip on top that picks the whole float up.
final class DockFloatView : MultiChildElement {
  /// The float's, not its tree's: see `DockFloat.id`.
  let id: String
  unowned let area: DockArea
  /// In the area's content, top left origin: the layout's, or where a drag has moved it.
  var frame = DockRect(x: 0, y: 0, width: 0, height: 0)
  let slot = DockSlot()
  private let shadow: ShadowElement
  private let fill = DockFloatFill()
  private let clip: ClipElement
  private let border = DockFloatBorder()
  private let grip: HittableView
  private var handles: [(view: HittableView, edges: float4)] = []
  private var hasGrip = false
  private var position: float2 = .zero

  init(id: String, area: DockArea) {
    self.id = id
    self.area = area
    let fill = self.fill
    self.shadow = ShadowElement(color: DockMetrics.shadowColor, radius: 12, y: 4) { fill }
    let slot = self.slot
    self.clip = ClipElement(.rect(cornerRadius: DockMetrics.floatRadius)) { slot }
    self.grip = HittableView {}
    super.init()
    self.grip.onPress = { [unowned self] down, input in
      if down { self.area.pickUp(.float(self.id), input) }
    }
    self.grip.pointerStyle = .grabIdle
    // Edges then corners, as (left, top, right, bottom) moved by the drag.
    let edges: [(float4, PointerStyle)] = [
      (float4(1, 0, 0, 0), .frameResize(position: .leading)),
      (float4(0, 1, 0, 0), .frameResize(position: .top)),
      (float4(0, 0, 1, 0), .frameResize(position: .trailing)),
      (float4(0, 0, 0, 1), .frameResize(position: .bottom)),
      (float4(1, 1, 0, 0), .frameResize(position: .topLeading)),
      (float4(0, 1, 1, 0), .frameResize(position: .topTrailing)),
      (float4(1, 0, 0, 1), .frameResize(position: .bottomLeading)),
      (float4(0, 0, 1, 1), .frameResize(position: .bottomTrailing)),
    ]
    for (mask, style) in edges {
      let handle = HittableView {}
      handle.pointerStyle = style
      handle.onPress = { [unowned self] down, input in self.area.resizePressed(self.id, mask, down, input) }
      handle.onDrag = { [unowned self] input in self.area.resizeDragged(input) }
      self.handles.append((handle, mask))
    }
  }

  /// Brings the float up to `float`; returns the children it should have.
  func update(_ float: DockFloat, keepFrame: Bool) -> [UIElement] {
    if !keepFrame {
      self.frame = float.frame
    }
    if case .split = float.node { self.hasGrip = true } else { self.hasGrip = false }
    self.slot.topInset = self.hasGrip ? DockMetrics.gripHeight : 0
    self.fill.hasGrip = self.hasGrip
    var children: [UIElement] = [self.shadow, self.clip, self.border]
    if self.hasGrip { children.append(self.grip) }
    children += self.handles.map(\.view)
    return children
  }

  var rect: ClipRect { ClipRect(position: self.position, size: self.frame.size) }

  /// Where a drag has the card, window coordinates, until the next layout puts it there: it is
  /// drawn there by an offset meanwhile, so following the pointer only redraws, and lays out
  /// nothing — the panels' content included. Hit-testing goes by the layout; nothing hits a
  /// float while it is dragged, the press being its area's.
  var dragOrigin: float2?

  override var hasEffect: Bool { self.dragOrigin != nil || super.hasEffect }

  override var localEffect: EffectState {
    var effect = super.localEffect
    if let dragOrigin {
      effect.translate += dragOrigin - self.position
    }
    return effect
  }

  override func getSize() -> float2 { self.frame.size }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 { self.frame.size }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    let size = self.frame.size
    _ = self.shadow.calcSize(ProposedSize(size))
    _ = self.clip.calcSize(ProposedSize(size))
    _ = self.border.calcSize(ProposedSize(size))
    _ = self.grip.calcSize(ProposedSize(width: size.x, height: DockMetrics.gripHeight))
    let hit = DockMetrics.resizeHit
    let corner = hit * 2
    for (handle, edges) in self.handles {
      let isCorner = edges.x + edges.y + edges.z + edges.w > 1
      let handleSize: float2 = isCorner ? float2(corner, corner)
        : edges.x + edges.z > 0 ? float2(hit, max(size.y - corner * 2, 0))
        : float2(max(size.x - corner * 2, 0), hit)
      _ = handle.calcSize(ProposedSize(handleSize))
    }
    return size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    // Laid out where the drag has it: the offset is spent.
    self.dragOrigin = nil
    let size = self.frame.size
    self.shadow.calcPosition(position)
    self.clip.calcPosition(position)
    self.border.calcPosition(position)
    self.grip.calcPosition(position)
    let hit = DockMetrics.resizeHit
    let corner = hit * 2
    for (handle, edges) in self.handles {
      let x: Float = edges.x > 0 ? -hit * 0.5 : edges.z > 0 ? size.x - (edges.y + edges.w > 0 ? corner - hit * 0.5 : hit * 0.5) : corner
      let y: Float = edges.y > 0 ? -hit * 0.5 : edges.w > 0 ? size.y - (edges.x + edges.z > 0 ? corner - hit * 0.5 : hit * 0.5) : corner
      handle.calcPosition(position + float2(x, y))
    }
  }
}

/// A float's card: white, and a grip strip on top when it has one.
final class DockFloatFill : FormGraphic {
  var hasGrip = false

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let radius = DockMetrics.floatRadius * scale
    var color = DockMetrics.barColor
    color.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: radius), color: color)
    guard self.hasGrip else { return }
    // Three dots in the middle of the strip, for something to take hold of.
    var dot = DockMetrics.glyphColor
    dot.w *= opacity * 0.7
    let center = origin + float2(size.x * 0.5, DockMetrics.gripHeight * 0.5 * scale)
    for i in -1 ... 1 {
      let c = center + float2(Float(i) * 6 * scale, 0)
      renderer.draw(roundedRect: c - 1.5 * scale, size: float2(repeating: 3 * scale), radii: float4(repeating: 1.5 * scale), color: dot)
    }
  }
}

final class DockFloatBorder : FormGraphic {
  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    var color = DockMetrics.borderColor
    color.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: DockMetrics.floatRadius * scale),
                  color: color, strokeWidth: 0.5 * scale)
  }
}

// MARK: - Area background

/// What shows between the panes: the gaps a split leaves, and an area with nothing docked.
final class DockAreaBackground : FormGraphic {
  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    var color = DockMetrics.gapColor
    color.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: .zero, color: color)
  }
}

// MARK: - Title bar

/// A detached window's own title bar, in the custom look: its buttons, its title, and the rest
/// of it a handle that drags the window, and docks it where it is let go.
final class DockTitleBar : MultiChildElement {
  unowned let area: DockArea
  private let fill = DockTitleFill()
  private let title: Text
  private let handle: HittableView
  private let buttons: [HittableView]
  private var titleString = ""
  private var size: float2 = .zero

  init(area: DockArea) {
    self.area = area
    self.title = Text("").font(DockMetrics.font).foregroundColor(FormMetrics.labelColor).lineLimit(1)
    self.handle = HittableView {}
    var buttons: [HittableView] = []
    for kind in DockWindowButton.Kind.allCases {
      let glyph = DockWindowButton(kind)
      let button = HittableView { glyph }
      button.onPress = { _, _ in }
      button.onHover = { [unowned glyph] hovered, _ in
        glyph.isHovered = hovered
      }
      buttons.append(button)
    }
    self.buttons = buttons
    super.init()
    self.handle.onPress = { [unowned self] down, input in
      if down { self.area.pickUp(.titleBar, input) }
    }
    for (button, kind) in zip(buttons, DockWindowButton.Kind.allCases) {
      button.onTap = { [unowned self] _ in self.area.windowButton(kind) }
      let hover = button.onHover
      button.onHover = { [unowned self] hovered, input in
        hover?(hovered, input)
        self.area.context?.invalidate(.render)
      }
    }
    self.applyContent([self.fill, self.handle, self.title] + buttons)
  }

  func setTitle(_ title: String, _ context: UIContext) {
    guard title != self.titleString else { return }
    self.titleString = title
    self.title.setText(title, context)
  }

  override func getSize() -> float2 { self.size }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    float2(proposal.width ?? 0, DockMetrics.titleBarHeight)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    _ = self.fill.calcSize(ProposedSize(self.size))
    _ = self.handle.calcSize(ProposedSize(self.size))
    _ = self.title.calcSize(ProposedSize(width: max(self.size.x - 160, 40), height: nil))
    for button in self.buttons {
      _ = button.calcSize(ProposedSize(float2(repeating: 12)))
    }
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.fill.calcPosition(position)
    self.handle.calcPosition(position)
    let titleSize = self.title.getSize()
    self.title.calcPosition(position + ((self.size - titleSize) * 0.5).rounded(.down))
    for (index, button) in self.buttons.enumerated() {
      button.calcPosition(position + float2(12 + Float(index) * 20, (self.size.y - 12) * 0.5))
    }
  }
}

final class DockTitleFill : FormGraphic {
  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    var color = DockMetrics.titleBarColor
    color.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: .zero, color: color)
  }
}

/// A close, minimise or zoom button of the custom title bar: a coloured dot, with its glyph
/// when hovered.
final class DockWindowButton : FormGraphic {
  enum Kind: CaseIterable {
    case close, minimize, zoom
  }

  let kind: Kind
  var isHovered = false

  init(_ kind: Kind) {
    self.kind = kind
    super.init()
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    float2(12, 12)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    var color: float4 = switch self.kind {
    case .close: float4(1, 0.37, 0.34, 1)
    case .minimize: float4(1, 0.74, 0.18, 1)
    case .zoom: float4(0.16, 0.78, 0.25, 1)
    }
    color.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: size.x * 0.5), color: color)
    guard self.isHovered else { return }
    var glyph = float4(0, 0, 0, 0.55)
    glyph.w *= opacity
    let c = origin + size * 0.5
    let r = size.x * 0.22
    switch self.kind {
    case .close:
      renderer.draw(stroke: c - r, to: c + r, width: 1.1 * scale, color: glyph)
      renderer.draw(stroke: c + float2(r, -r), to: c + float2(-r, r), width: 1.1 * scale, color: glyph)
    case .minimize:
      renderer.draw(stroke: c - float2(r * 1.2, 0), to: c + float2(r * 1.2, 0), width: 1.1 * scale, color: glyph)
    case .zoom:
      renderer.draw(stroke: c - float2(r * 1.2, 0), to: c + float2(r * 1.2, 0), width: 1.1 * scale, color: glyph)
      renderer.draw(stroke: c - float2(0, r * 1.2), to: c + float2(0, r * 1.2), width: 1.1 * scale, color: glyph)
    }
  }
}

// MARK: - Drop zones

/// What a drag would dock onto: the zone markers of the tab group under the pointer, those
/// along the area's edges, and a tint over where the dragged panels would go. Placed by its
/// area, not by layout: it only redraws as the drag moves.
final class DockDropOverlay : UIRenderableElement {
  struct Marker: Equatable {
    var rect: ClipRect
    var zone: DockZone
    var isHovered: Bool
  }

  var markers: [Marker] = []
  var preview: ClipRect?

  var isShown: Bool { !self.markers.isEmpty || self.preview != nil }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let accent = DockMetrics.accent
    if let preview {
      let origin = centred(effect.apply(to: preview.min), renderer)
      let size = (preview.max - preview.min) * effect.scale
      renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: 4), color: float4(accent.x, accent.y, accent.z, 0.18 * effect.opacity))
      renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: 4), color: float4(accent.x, accent.y, accent.z, 0.7 * effect.opacity), strokeWidth: 2)
    }
    for marker in self.markers {
      let origin = centred(effect.apply(to: marker.rect.min), renderer)
      let size = (marker.rect.max - marker.rect.min) * effect.scale
      let radii = float4(repeating: 5)
      renderer.draw(roundedRect: origin, size: size, radii: radii,
                    color: marker.isHovered ? float4(accent.x, accent.y, accent.z, effect.opacity) : float4(1, 1, 1, 0.95 * effect.opacity))
      renderer.draw(roundedRect: origin, size: size, radii: radii, color: float4(accent.x, accent.y, accent.z, 0.9 * effect.opacity), strokeWidth: 1.5)
      // Where the panels go, drawn inside the marker: all of it for the middle, else one side.
      let inset: Float = 6
      var inner = ClipRect(min: origin + inset, max: origin + size - inset)
      let mid = (inner.min + inner.max) * 0.5
      switch marker.zone {
      case .center: break
      case .left: inner.max.x = mid.x
      case .right: inner.min.x = mid.x
      case .top: inner.max.y = mid.y
      case .bottom: inner.min.y = mid.y
      }
      let color = marker.isHovered ? float4(1, 1, 1, 0.9 * effect.opacity) : float4(accent.x, accent.y, accent.z, 0.55 * effect.opacity)
      renderer.draw(roundedRect: inner.min, size: inner.max - inner.min, radii: float4(repeating: 2), color: color)
    }
  }
}
