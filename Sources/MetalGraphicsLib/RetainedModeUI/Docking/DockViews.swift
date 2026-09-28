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

  static let gapColor: float4 = .gapTint
  static let barColor: float4 = .barTint
  static let tabHoverColor: float4 = .hover
  static let tabSelectedColor: float4 = .selectedTab
  static let contentColor: float4 = .contentBackground
  static let titleBarColor: float4 = .barTint
  static let borderColor: float4 = .separator
  static let glyphColor: float4 = .secondaryLabel
  static let accent: float4 = .accent
  static var font: TextFont { Theme.current.typography.callout }
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

/// How one of the two tab styles is laid out and drawn: see `DockTabStyle`.
struct DockTabMetrics {
  let barHeight: Float
  let pillHeight: Float
  let radius: Float
  let fontSize: Float
  /// Between the bar's ends and the tabs.
  let inset: Float
  let spacing: Float
  /// Inside a pill, before the title and after the close button.
  let padding: Float
  let closeSize: Float
  let separator: Bool

  static let panel = DockTabMetrics(
    barHeight: 30, pillHeight: 22, radius: 6, fontSize: 11.5, inset: 10, spacing: 2, padding: 10, closeSize: 14,
    separator: false
  )
  static let document = DockTabMetrics(
    barHeight: 40, pillHeight: 28, radius: 7, fontSize: 12.5, inset: 10, spacing: 4, padding: 10, closeSize: 16,
    separator: true
  )

  static func of(_ style: DockTabStyle) -> DockTabMetrics {
    style == .document ? .document : .panel
  }

  /// Between a pill's icon, title, marks and close button.
  static let gap: Float = 7
  static let iconSize = float2(12, 14)
  static let dotSize: Float = 7
  static let badgeHeight: Float = 16
}

/// A tab group: a bar of tabs over the shown panel. Pressing a tab shows it and picks it up;
/// pressing the bar beside the tabs picks the whole group up.
///
/// At a translucent window's top it shares the title bar's row: a document bar is that row,
/// its tabs clear of the traffic lights; a panel bar sits under an empty row the traffic lights
/// are on. The empty parts of the row drag the window.
final class DockTabsView : MultiChildElement {
  let id: String
  unowned let area: DockArea
  private(set) var panels: [String] = []
  private(set) var selected: String?
  /// What the shown panel's content is drawn on: its kind's `background`.
  private(set) var contentBackground: float4 = DockMetrics.contentColor
  /// The shown panel's kind's.
  private(set) var style: DockTabStyle = .panel
  var metrics: DockTabMetrics { .of(self.style) }

  private let chrome = DockTabsChrome()
  private let barHandle: HittableView
  private var items: [String: DockTabItem] = [:]
  private var shownItems: [DockTabItem] = []
  private var content: DockPanelHost?
  private var titleBarPlacement = TitleBarPlacement()

  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero
  /// Above the bar: the title bar's empty row, when a panel bar is under it.
  private(set) var rowHeight: Float = 0
  private(set) var barHeight: Float = DockTabMetrics.panel.barHeight

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
  var barRect: ClipRect {
    ClipRect(position: self.position + float2(0, self.rowHeight), size: float2(self.size.x, self.barHeight))
  }

  /// Where the tab of `panel` starts, window coordinates.
  func tabOrigin(_ panel: String) -> float2? {
    self.items[panel].map(\.position)
  }

  /// Brings the group up to `tabs`, showing `content`; returns the children it should have.
  func update(_ tabs: DockTabs, titles: [String: DockPanelInfo], content: DockPanelHost?, _ context: UIContext) -> [UIElement] {
    self.panels = tabs.panels
    self.selected = tabs.shown
    self.content = content
    let shownKind = tabs.shown.flatMap { titles[$0]?.kind }.flatMap { self.area.space.kind($0) }
    let background = shownKind?.background ?? DockMetrics.contentColor
    if background != self.contentBackground {
      self.contentBackground = background
      context.invalidate()
    }
    let style = shownKind?.tabStyle ?? .panel
    if style != self.style {
      self.style = style
      context.invalidate(.layout)
    }
    var shown: [DockTabItem] = []
    for panel in tabs.panels {
      let item = self.items[panel] ?? DockTabItem(panel: panel, group: self)
      self.items[panel] = item
      let info = titles[panel]
      item.setTitle(info?.title ?? "", context)
      item.setDecoration(info, kind: info.flatMap { self.area.space.kind($0.kind) }, context)
      item.setSelected(panel == tabs.shown, context)
      item.setStyle(style, context)
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

  /// Whether it shares the title bar's row.
  private var inTitleBar: Bool {
    self.titleBarPlacement.atTop && TitleBarInsets.current.top > 0
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = proposal.replacingUnspecified(with: .zero)
    let metrics = self.metrics
    let row = TitleBarInsets.dockRowHeight
    if self.inTitleBar {
      self.rowHeight = self.style == .panel ? row : 0
      self.barHeight = self.style == .panel ? metrics.barHeight : max(metrics.barHeight, row)
    } else {
      self.rowHeight = 0
      self.barHeight = metrics.barHeight
    }
    let top = self.rowHeight + self.barHeight
    _ = self.chrome.calcSize(ProposedSize(self.size))
    _ = self.barHandle.calcSize(ProposedSize(width: self.size.x, height: self.barHeight))

    // Each tab at its title's width, all of them shrunk alike when they do not fit.
    let ideal = self.shownItems.map { $0.idealWidth() }
    let spacing = metrics.spacing * Float(max(self.shownItems.count - 1, 0))
    let available = self.size.x - metrics.inset * 2 - spacing
    let total = ideal.reduce(0, +)
    let scale = total > available && total > 0 ? max(available, 0) / total : 1
    for (item, width) in zip(self.shownItems, ideal) {
      _ = item.calcSize(ProposedSize(width: max(width * scale, min(DockMetrics.tabMinWidth, width)), height: metrics.pillHeight))
    }
    _ = self.content?.calcSize(ProposedSize(width: self.size.x, height: max(self.size.y - top, 0)))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.titleBarPlacement.settle(position.y, self.area.context)
    let metrics = self.metrics
    let barY = position.y + self.rowHeight
    self.chrome.calcPosition(position)
    self.barHandle.calcPosition(float2(position.x, barY))
    var start = metrics.inset
    if self.inTitleBar && self.style == .document {
      start = max(start, TitleBarInsets.current.leading - position.x)
    }
    var x = position.x + start
    let y = barY + ((self.barHeight - metrics.pillHeight) * 0.5).rounded()
    for item in self.shownItems {
      self.place(item, at: float2(x, y), in: position)
      x += item.getSize().x + metrics.spacing
    }
    if self.inTitleBar {
      if self.rowHeight > 0 {
        TitleBarInsets.addDragRegion(float4(position.x, position.y, self.size.x, self.rowHeight))
      } else {
        TitleBarInsets.addDragRegion(float4(position.x, barY, start, self.barHeight))
        let end = x - position.x
        TitleBarInsets.addDragRegion(float4(x, barY, self.size.x - end, self.barHeight))
      }
    }
    if let content {
      content.calcPosition(position + float2(0, self.rowHeight + self.barHeight))
    }
    self.placeLeaving(in: position)
  }
}

/// One tab: an icon, its title, marks for an unsaved document or a count, and a close button
/// that shows while the pointer is over the tab.
final class DockTabItem : MultiChildElement {
  let panel: String
  unowned let group: DockTabsView
  private let fill = DockTabFill()
  private let icon: Image
  private let title: Text
  private let badgeText: Text
  private let press: HittableView
  private let close: HittableView
  private var titleString = ""
  private var style: DockTabStyle = .panel
  private var metrics: DockTabMetrics { .of(self.style) }
  private var hasIcon = false
  private var iconKind: ThemeIcon?
  private(set) var isEdited = false
  private(set) var badge = 0

  private(set) var isSelected = false

  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  init(panel: String, group: DockTabsView) {
    self.panel = panel
    self.group = group
    self.title = Text("").font(.system(size: DockTabMetrics.panel.fontSize)).foregroundColor(.secondaryLabel).lineLimit(1)
    self.icon = Image(icon: .document)
    self.icon.isHidden = true
    self.badgeText = Text("").font(.system(size: 10, weight: .bold)).foregroundColor(.accentForeground).lineLimit(1)
    self.badgeText.isHidden = true
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
    self.applyContent([self.fill, self.icon, self.title, self.badgeText, self.press, self.close])
  }

  func setTitle(_ title: String, _ context: UIContext) {
    guard title != self.titleString else { return }
    self.titleString = title
    self.title.setText(title, context)
  }

  func setSelected(_ value: Bool, _ context: UIContext) {
    guard value != self.isSelected else { return }
    self.isSelected = value
    self.fill.isSelected = value
    self.title.setForegroundColor(value ? .label : .secondaryLabel, context)
    self.title.setFontWeight(value ? .medium : nil, context)
  }

  func setStyle(_ style: DockTabStyle, _ context: UIContext) {
    guard style != self.style else { return }
    self.style = style
    self.title.setFont(.system(size: DockTabMetrics.of(style).fontSize), context)
    self.updateIcon(context)
  }

  /// The icon, unsaved mark and count the panel set on itself.
  func setDecoration(_ info: DockPanelInfo?, kind: DockPanelKind?, _ context: UIContext) {
    let fallback = info.flatMap { info in kind?.tabIcon?(info.title) }
    let icon = info?.icon ?? fallback?.0
    if icon != self.iconKind {
      self.iconKind = icon
      if let icon { self.icon.setIcon(icon, context) }
      self.updateIcon(context)
    }
    let color = info?.icon != nil ? info?.iconColor : fallback?.1
    self.icon.setForegroundColor(color ?? .secondaryLabel, context)
    let edited = info?.isEdited ?? false
    if edited != self.isEdited {
      self.isEdited = edited
      context.invalidate(.layout)
    }
    let badge = info?.badge ?? 0
    if badge != self.badge {
      self.badge = badge
      self.badgeText.setText("\(badge)", context)
      if (badge > 0) == self.badgeText.isHidden {
        self.badgeText.isHidden = badge == 0
        context.invalidate([.layout, .treeOrder])
      }
    }
  }

  private func updateIcon(_ context: UIContext) {
    let shows = self.iconKind != nil && self.style == .document
    guard shows != self.hasIcon else { return }
    self.hasIcon = shows
    self.icon.isHidden = !shows
    context.invalidate([.layout, .treeOrder])
  }

  /// The width of what sits between the title and the close button: the unsaved dot, the count.
  private var marksWidth: Float {
    var width: Float = 0
    if self.isEdited { width += DockTabMetrics.gap + DockTabMetrics.dotSize }
    if self.badge > 0 { width += DockTabMetrics.gap + self.badgeWidth }
    return width
  }

  var badgeWidth: Float {
    max(self.badgeText.measure(.unspecified).x + 8, DockTabMetrics.badgeHeight)
  }

  private var leadingWidth: Float {
    self.metrics.padding + (self.hasIcon ? DockTabMetrics.iconSize.x + DockTabMetrics.gap : 0)
  }

  private var trailingWidth: Float {
    self.marksWidth + DockTabMetrics.gap + self.metrics.closeSize + self.metrics.padding * 0.5
  }

  func idealWidth() -> Float {
    let text = self.title.measure(.unspecified).x
    return min(text + self.leadingWidth + self.trailingWidth, DockMetrics.tabMaxWidth)
  }

  /// The close button's rect, window coordinates.
  var closeRect: ClipRect {
    let side = self.metrics.closeSize
    let origin = self.position + float2(self.size.x - self.metrics.padding * 0.5 - side, ((self.size.y - side) * 0.5).rounded())
    return ClipRect(position: origin, size: float2(side, side))
  }

  /// Where the unsaved dot and the count go, window coordinates: after the title.
  var marksOrigin: float2 {
    self.position + float2(self.leadingWidth + self.title.getSize().x, 0)
  }

  var radius: Float { self.metrics.radius }

  override func getSize() -> float2 { self.size }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: float2(self.idealWidth(), self.metrics.pillHeight))
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    _ = self.fill.calcSize(ProposedSize(self.size))
    let textWidth = max(self.size.x - self.leadingWidth - self.trailingWidth, 0)
    _ = self.title.calcSize(ProposedSize(width: textWidth, height: nil))
    _ = self.icon.calcSize(ProposedSize(DockTabMetrics.iconSize))
    _ = self.badgeText.calcSize(.unspecified)
    _ = self.press.calcSize(ProposedSize(self.size))
    _ = self.close.calcSize(ProposedSize(float2(repeating: self.metrics.closeSize)))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.fill.calcPosition(position)
    let iconSize = self.icon.getSize()
    self.icon.calcPosition(position + float2(self.metrics.padding, ((self.size.y - iconSize.y) * 0.5).rounded()))
    let textSize = self.title.getSize()
    self.title.calcPosition(position + float2(self.leadingWidth, ((self.size.y - textSize.y) * 0.5).rounded()))
    if self.badge > 0 {
      let badgeSize = self.badgeText.getSize()
      var x = self.marksOrigin.x + DockTabMetrics.gap
      if self.isEdited { x += DockTabMetrics.dotSize + DockTabMetrics.gap }
      x += ((self.badgeWidth - badgeSize.x) * 0.5).rounded()
      self.badgeText.calcPosition(float2(x, position.y + ((self.size.y - badgeSize.y) * 0.5).rounded()))
    }
    self.press.calcPosition(position)
    self.close.calcPosition(self.closeRect.min)
  }
}

/// A tab's rounded background, its marks and its close cross.
final class DockTabFill : FormGraphic {
  weak var item: DockTabItem?
  var isSelected = false
  var isHovered = false
  var isCloseHovered = false

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    guard let item = self.item else { return }
    let radii = float4(repeating: item.radius * scale)
    if self.isSelected {
      // A raised pill: a shadow a point below, then the fill and a hairline.
      let shadow = renderer.theme.shadows.control
      renderer.draw(
        roundedRect: origin + float2(0, shadow.y * scale), size: size, radii: radii,
        color: shadow.color.withAlpha(opacity * 0.6)
      )
      renderer.draw(roundedRect: origin, size: size, radii: radii, color: DockMetrics.tabSelectedColor.withAlpha(opacity))
      renderer.draw(
        roundedRect: origin, size: size, radii: radii, color: DockMetrics.borderColor.withAlpha(opacity),
        strokeWidth: 0.5 * scale
      )
    } else if self.isHovered || self.isCloseHovered {
      renderer.draw(roundedRect: origin, size: size, radii: radii, color: DockMetrics.tabHoverColor.withAlpha(opacity))
    }

    // After the title: the unsaved dot and the count's capsule.
    var x = origin.x + (item.marksOrigin.x - item.position.x) * scale
    let midY = origin.y + size.y * 0.5
    if item.isEdited {
      x += DockTabMetrics.gap * scale
      let dot = DockTabMetrics.dotSize * scale
      renderer.draw(
        roundedRect: float2(x, midY - dot * 0.5), size: float2(dot, dot), radii: float4(repeating: dot * 0.5),
        color: float4.secondaryLabel.withAlpha(opacity)
      )
      x += dot
    }
    if item.badge > 0 {
      x += DockTabMetrics.gap * scale
      let height = DockTabMetrics.badgeHeight * scale
      renderer.draw(
        roundedRect: float2(x, midY - height * 0.5), size: float2(item.badgeWidth * scale, height),
        radii: float4(repeating: height * 0.5), color: float4.warning.withAlpha(opacity)
      )
    }

    guard self.isHovered || self.isCloseHovered else { return }
    // The cross, in the close button's rect, moved as the tab is.
    let close = item.closeRect
    let min = origin + (close.min - item.position) * scale
    let side = (close.max.x - close.min.x) * scale
    if self.isCloseHovered {
      renderer.draw(roundedRect: min, size: float2(side, side), radii: float4(repeating: 4 * scale),
                    color: float4.hover.withAlpha(opacity))
    }
    let inset = (side - 7 * scale) * 0.5
    var color = DockMetrics.glyphColor
    color.w *= opacity
    renderer.draw(stroke: min + inset, to: min + side - inset, width: 1.3 * scale, color: color)
    renderer.draw(stroke: min + float2(side - inset, inset), to: min + float2(inset, side - inset), width: 1.3 * scale, color: color)
  }
}

/// A tab group's bar, and the background of its content.
final class DockTabsChrome : FormGraphic {
  weak var group: DockTabsView?

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let row = (self.group?.rowHeight ?? 0) * scale
    let bar = (self.group?.barHeight ?? DockTabMetrics.panel.barHeight) * scale
    var barColor = DockMetrics.barColor
    barColor.w *= opacity
    var contentColor = self.group?.contentBackground ?? DockMetrics.contentColor
    contentColor.w *= opacity
    // The title bar's row and the bar: a sidebar's own tint under a panel bar on a sidebar,
    // which is part of it; the bar tint otherwise.
    let top = row + bar
    let onSidebar = self.group?.style == .panel && self.group?.contentBackground == .sidebarTint
    let chrome = onSidebar ? contentColor : barColor
    renderer.draw(roundedRect: origin, size: float2(size.x, top), radii: .zero, color: chrome)
    renderer.draw(roundedRect: origin + float2(0, top), size: float2(size.x, max(size.y - top, 0)), radii: .zero, color: contentColor)
    if self.group?.metrics.separator == true {
      renderer.draw(
        roundedRect: origin + float2(0, top - 0.5 * scale), size: float2(size.x, 0.5 * scale), radii: .zero,
        color: DockMetrics.borderColor.withAlpha(opacity)
      )
    }
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
    let float = Theme.current.shadows.float
    self.shadow = ShadowElement(color: .shadow, radius: float.radius, y: float.y) { fill }
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

/// A float's card: the theme's floating panel glass, and a grip strip on top when it has one.
final class DockFloatFill : FormGraphic {
  var hasGrip = false

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: .zero)
  }

  override func draw(_ renderer: Graphics2D, origin: float2, size: float2, scale: Float, opacity: Float) {
    let radius = DockMetrics.floatRadius * scale
    let material = renderer.theme[.floatingPanel]
    renderer.draw(
      glass: origin, size: size, radii: float4(repeating: radius), material: material,
      sigma: material.blurRadius * ShadowState.sigmaPerRadius * scale, opacity: opacity
    )
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
    case .close: float4(1, 0.37, 0.34, 1)  // design: the macOS traffic lights
    case .minimize: float4(1, 0.74, 0.18, 1)  // design: the macOS traffic lights
    case .zoom: float4(0.16, 0.78, 0.25, 1)  // design: the macOS traffic lights
    }
    color.w *= opacity
    renderer.draw(roundedRect: origin, size: size, radii: float4(repeating: size.x * 0.5), color: color)
    guard self.isHovered else { return }
    var glyph = float4(0, 0, 0, 0.55)  // design: the macOS traffic lights
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
    let opacity = effect.opacity
    if let preview {
      let origin = centred(effect.apply(to: preview.min), renderer)
      let size = (preview.max - preview.min) * effect.scale
      let radii = float4(repeating: renderer.theme.radii.md)
      renderer.draw(roundedRect: origin, size: size, radii: radii, color: accent.withAlpha(0.18 * opacity))
      renderer.draw(roundedRect: origin, size: size, radii: radii, color: accent.withAlpha(0.7 * opacity), strokeWidth: 2)
    }
    let material = renderer.theme[.dropMarker]
    for marker in self.markers {
      let origin = centred(effect.apply(to: marker.rect.min), renderer)
      let size = (marker.rect.max - marker.rect.min) * effect.scale
      let radii = float4(repeating: renderer.theme.radii.md)
      if marker.isHovered {
        renderer.draw(roundedRect: origin, size: size, radii: radii, color: accent.withAlpha(opacity))
      } else {
        renderer.draw(
          glass: origin, size: size, radii: radii, material: material,
          sigma: material.blurRadius * ShadowState.sigmaPerRadius * effect.scale, opacity: opacity
        )
      }
      renderer.draw(roundedRect: origin, size: size, radii: radii, color: accent.withAlpha(0.9 * opacity), strokeWidth: 1.5)
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
      let color = marker.isHovered ? float4.accentForeground.withAlpha(0.9 * opacity) : accent.withAlpha(0.55 * opacity)
      renderer.draw(roundedRect: inner.min, size: inner.max - inner.min, radii: float4(repeating: 2), color: color)
    }
  }
}
