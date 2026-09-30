import simd

/// The 1 pt line between two docked panes, in the gap colour: what a `DockArea`'s splits leave
/// between panes, on its own for a spec. Fills the length it is offered. Not in SwiftUI.
public final class DockGap : UIRenderableElement {
  public let vertical: Bool
  public private(set) var position: float2 = .zero
  public private(set) var size: float2 = .zero

  /// `vertical`: a line between panes side by side.
  public init(vertical: Bool = true) {
    self.vertical = vertical
    super.init()
  }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 { self.size }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.vertical
      ? float2(DockMetrics.gap, proposal.height ?? 40)
      : float2(proposal.width ?? 40, DockMetrics.gap)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    var color = DockMetrics.gapColor
    color.w *= effect.opacity
    let drawn = self.size * effect.scale
    renderer.draw(square: Square(position: effect.apply(to: self.position) - renderer.size * 0.5 + drawn * 0.5, size: drawn, color: color))
  }
}

// MARK: - Window chrome

/// A window's close, minimise and zoom buttons: 12 pt dots 20 apart, their glyphs showing while
/// the pointer is over them, grey when `inactive`. What a custom title bar and a dock window's
/// title bar draw; the real window's are AppKit's.
public final class TrafficLights : SingleChildElement {
  public var onClose: (() -> Void)?
  public var onMinimize: (() -> Void)?
  public var onZoom: (() -> Void)?
  private let glyphs: [DockWindowButton]
  private weak var context: UIContext?

  public init(inactive: Bool = false, onClose: (() -> Void)? = nil, onMinimize: (() -> Void)? = nil, onZoom: (() -> Void)? = nil) {
    self.onClose = onClose
    self.onMinimize = onMinimize
    self.onZoom = onZoom
    self.glyphs = DockWindowButton.Kind.allCases.map { kind in
      let glyph = DockWindowButton(kind)
      glyph.isInactive = inactive
      return glyph
    }
    super.init()
    let row = HStack(spacing: 8)
    row.applyContent(self.glyphs.map { glyph in
      let button = HittableView { glyph }
      button.onHover = { [unowned self, unowned glyph] hovered, _ in
        // Hovering one shows every glyph, as macOS does.
        for other in self.glyphs { other.isHovered = hovered }
        _ = glyph
        self.context?.invalidate(.render)
      }
      button.onTap = { [unowned self] _ in
        switch glyph.kind {
        case .close: self.onClose?()
        case .minimize: self.onMinimize?()
        case .zoom: self.onZoom?()
        }
      }
      return button
    })
    self.applyContent([row])
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  public override func unmount(_ context: UIContext) {
    self.context = nil
  }

  /// Grey, as in a window that is not key.
  public func setInactive(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    for glyph in self.glyphs { glyph.isInactive = value }
    context.invalidate(.render)
  }

  /// Shows the glyphs, as when the pointer is over them: for a spec.
  public func showsGlyphs(_ value: Bool) -> Self {
    for glyph in self.glyphs { glyph.isHovered = value }
    return self
  }
}

/// A floating panel's or a dock window's own title bar: 28 tall on the bar tint, the traffic
/// lights at its leading edge and the title centred.
public final class TitleBar : SingleChildElement {
  public static let height: Float = DockMetrics.titleBarHeight
  private let title: Text

  public init(_ title: String, inactive: Bool = false) {
    let title = Text(title).font(DockMetrics.font).foregroundColor(FormMetrics.labelColor).lineLimit(1)
    self.title = title
    super.init()
    self.applyContent([
      ZStack {
        HStack {
          TrafficLights(inactive: inactive)
          Spacer()
        }
        .padding(Inset(horizontal: 12))
        title
      }
      .frame(maxWidth: .infinity)
      .frame(height: Self.height)
      .background(DockMetrics.titleBarColor)
    ])
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.title.text else { return }
    self.title.setText(value, context, animation: animation)
  }
}

// MARK: - Floating panels and drop zones

/// A card floating over docked content: floating panel glass, radius 7, a hairline and the float
/// shadow, with a grip strip on top when `grip`, as a float of several panels has.
///
///     FloatingPanel(grip: true) { Text("Inspector").padding(12) }
public final class FloatingPanel : SingleChildElement {
  public init(grip: Bool = false, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    super.init()
    let fill = DockFloatFill()
    fill.hasGrip = grip
    let float = Theme.current.shadows.float
    let stack = VStack(alignment: .leading, spacing: 0)
    stack.applyContent(content())
    self.applyContent([
      stack
        .padding(Inset(top: grip ? DockMetrics.gripHeight : 0))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(.rect(cornerRadius: DockMetrics.floatRadius))
        .background {
          ShadowElement(color: .shadow, radius: float.radius, y: float.y) { fill }
        }
        .overlay { DockFloatBorder() }
    ])
  }
}

/// Where a dragged panel can dock: a cross of five 28 pt markers on drop marker glass, the
/// `hovered` one filled with the accent, each showing the side it docks to. What a dock area
/// shows over a tab group while a panel is dragged.
public final class DropMarkers : UIRenderableElement {
  public let zones: [DockZone]
  public private(set) var hovered: DockZone?
  private(set) var position: float2 = .zero

  public init(zones: [DockZone] = DockZone.allCases, hovered: DockZone? = nil) {
    self.zones = zones
    self.hovered = hovered
    super.init()
  }

  public func setHovered(_ value: DockZone?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.hovered else { return }
    self.hovered = value
    context.invalidate(.render)
  }

  private static var side: Float { DockMetrics.markerSize + 2 * DockMetrics.markerSpacing }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 { float2(repeating: Self.side) }
  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 { float2(repeating: Self.side) }
  public override func calcSize(_ proposal: ProposedSize) -> float2 { float2(repeating: Self.side) }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let size = DockMetrics.markerSize
    let center = self.position + float2(repeating: Self.side * 0.5)
    for zone in self.zones {
      let offset: float2 = switch zone {
      case .center: .zero
      case .left: float2(-DockMetrics.markerSpacing, 0)
      case .right: float2(DockMetrics.markerSpacing, 0)
      case .top: float2(0, -DockMetrics.markerSpacing)
      case .bottom: float2(0, DockMetrics.markerSpacing)
      }
      let origin = center + offset - size * 0.5
      let marker = DockDropOverlay.Marker(
        rect: ClipRect(min: origin, max: origin + size), zone: zone, isHovered: zone == self.hovered
      )
      DockDropOverlay.drawMarker(marker, renderer, effect)
    }
  }
}

/// Where the dragged panels would go: an accent tint over the space it is given, with a 2 pt
/// accent edge.
public final class DropPreview : UIRenderableElement {
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  public override init() {
    super.init()
  }

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 { self.size }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: float2(120, 80))
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    DockDropOverlay.drawPreview(ClipRect(position: self.position, size: self.size), renderer, effect)
  }
}

// MARK: - Tabs

/// One dock tab on its own: its icon, title, unsaved dot or count, and a close cross while the
/// pointer is over it, in the panel or the document style. What a dock area's tab bar shows.
///
///     DockTab("Greeter.swift", selected: true, style: .document, icon: .document, isEdited: true)
public final class DockTab : SingleChildElement {
  /// A click on the tab.
  public var onSelect: (() -> Void)? {
    didSet { self.armed() }
  }
  /// A click on its cross.
  public var onClose: (() -> Void)? {
    didSet { self.item.onClose = self.onClose }
  }
  private let item: DockTabItem
  private var info: DockPanelInfo
  private var selected: Bool
  private var style: DockTabStyle
  private var configured = false

  public init(
    _ title: String, selected: Bool = false, style: DockTabStyle = .panel, icon: ThemeIcon? = nil,
    iconColor: float4 = .secondaryLabel, isEdited: Bool = false, badge: Int = 0,
    onSelect: (() -> Void)? = nil, onClose: (() -> Void)? = nil
  ) {
    self.item = DockTabItem(panel: title)
    var info = DockPanelInfo(kind: "", title: title)
    info.icon = icon
    info.iconColor = iconColor
    info.isEdited = isEdited
    info.badge = badge
    self.info = info
    self.selected = selected
    self.style = style
    self.onSelect = onSelect
    self.onClose = onClose
    super.init()
    // At its title's width, as a tab group lays its tabs out when they fit.
    self.applyContent([self.item.fixedSize()])
    self.item.onClose = onClose
    self.armed()
  }

  private func armed() {
    let select = self.onSelect
    self.item.onPickUp = { _ in select?() }
  }

  // Before the tab's own parts mount, with a context to set them through.
  public override func onMount(_ context: UIContext) {
    guard !self.configured else { return }
    self.configured = true
    self.item.setTitle(self.info.title, context)
    self.item.setStyle(self.style, context)
    self.item.setDecoration(self.info, kind: nil, context)
    self.item.setSelected(self.selected, context)
  }

  public func setSelected(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.selected = value
    self.item.setSelected(value, context)
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.info.title = value
    self.item.setTitle(value, context)
  }

  public func setEdited(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.info.isEdited = value
    self.item.setDecoration(self.info, kind: nil, context)
  }

  public func setBadge(_ value: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.info.badge = value
    self.item.setDecoration(self.info, kind: nil, context)
  }
}

/// A row of dock tabs on its bar: 30 tall with 22 pt pills in the panel style, 40 with 28 pt
/// pills and a hairline under it in the document style; on the sidebar tint when `onSidebar`.
/// A dock area draws its own; this is the same bar shown in place.
public final class DockTabBar : SingleChildElement {
  /// One tab of the bar.
  public struct Tab : Sendable {
    public var title: String
    public var icon: ThemeIcon?
    public var iconColor: float4
    public var isEdited: Bool
    public var badge: Int

    public init(_ title: String, icon: ThemeIcon? = nil, iconColor: float4 = .secondaryLabel, isEdited: Bool = false, badge: Int = 0) {
      self.title = title
      self.icon = icon
      self.iconColor = iconColor
      self.isEdited = isEdited
      self.badge = badge
    }
  }

  public var onSelect: ((Int) -> Void)?
  public var onClose: ((Int) -> Void)?
  private let tabs: [DockTab]

  public init(
    tabs: [Tab], style: DockTabStyle = .panel, selection: Int = 0, onSidebar: Bool = false,
    onSelect: ((Int) -> Void)? = nil, onClose: ((Int) -> Void)? = nil
  ) {
    self.onSelect = onSelect
    self.onClose = onClose
    let metrics = DockTabMetrics.of(style)
    self.tabs = tabs.enumerated().map { index, tab in
      DockTab(
        tab.title, selected: index == selection, style: style, icon: tab.icon, iconColor: tab.iconColor,
        isEdited: tab.isEdited, badge: tab.badge
      )
    }
    super.init()
    for (index, tab) in self.tabs.enumerated() {
      tab.onSelect = { [unowned self] in self.onSelect?(index) }
      tab.onClose = { [unowned self] in self.onClose?(index) }
    }
    let row = HStack(spacing: metrics.spacing)
    row.applyContent(self.tabs + [Spacer()])
    let bar = row
      .padding(Inset(horizontal: metrics.inset))
      .frame(maxWidth: .infinity)
      .frame(height: metrics.barHeight)
      .background(onSidebar && style == .panel ? .sidebarTint : DockMetrics.barColor)
    self.applyContent([
      metrics.separator
        ? bar.overlay(alignment: .bottom) { Rectangle(DockMetrics.borderColor).frame(height: 0.5) }
        : bar
    ])
  }

  /// Selects the tab at `index`.
  public func setSelection(_ value: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    for (index, tab) in self.tabs.enumerated() { tab.setSelected(index == value, context) }
  }
}
