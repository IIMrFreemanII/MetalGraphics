import simd

/// A sidebar beside a detail column, as SwiftUI's two-column `NavigationSplitView`:
///
/// ```swift
/// NavigationSplitView {
///   NavigationLink("Inbox", value: Mailbox.inbox)
///   NavigationLink("Sent", value: Mailbox.sent)
///     .navigationDestination(for: Mailbox.self) { box in MailboxView(box: box) }
/// } detail: {
///   Text("Select a mailbox")
/// }
/// ```
///
/// A value link in the sidebar selects: the detail column shows the view the sidebar's
/// destinations build for it, and the link is highlighted. A view link shows its view. The
/// detail column is a `NavigationStack`, so links inside it push there, and the sidebar's
/// destinations serve those pushes too. `detail:` is what it shows while nothing is selected.
///
/// With `selection: $selected` the selection is a state's: a value link reports to
/// `onSelectionChange`, and the value comes back through `setSelection`, as the stack's path does.
/// That is also how it starts on a selection, restored from storage for instance.
public final class NavigationSplitView : NavigationHost {
  /// The selection's write-back, set for a bound split view: `@Component` arms it on mount.
  public var onSelectionChange: ((AnyHashable) -> Void)?

  private let sidebarContent: VStack
  private let detailStack: NavigationStack
  /// What `detail:` holds: shown while nothing is selected.
  private var placeholder: [UIElement]
  /// Whether value links report to `onSelectionChange` rather than select.
  private let bindsSelection: Bool

  /// The sidebar's links, while mounted.
  private var links: [ObjectIdentifier : NavigationLink] = [:]
  private var selectedValue: AnyHashable?
  private weak var selectedLink: NavigationLink?
  /// A selected value no destination takes yet.
  private var pendingSelection: AnyHashable?

  public convenience init(
    @UIElementBuilder sidebar: () -> [UIElement] = { [] }, @UIElementBuilder detail: () -> [UIElement] = { [] }
  ) {
    self.init(selection: nil, binds: false, sidebar: sidebar, detail: detail)
  }

  /// Shows `selection`, and reports a sidebar link's value to `onSelectionChange`, which
  /// `@Component` arms for `selection: $state`. Left unset, value links do nothing, as with a
  /// constant binding.
  public convenience init<V: Hashable>(
    selection: V?, @UIElementBuilder sidebar: () -> [UIElement] = { [] },
    @UIElementBuilder detail: () -> [UIElement] = { [] }
  ) {
    self.init(selection: selection.map { AnyHashable($0) }, binds: true, sidebar: sidebar, detail: detail)
  }

  /// Bound to `selection`, for trees built by hand. In a `@Component` body `$selected` is lowered
  /// at compile time instead, and this is never called.
  public convenience init<V: Hashable>(
    selection: Binding<V>, @UIElementBuilder sidebar: () -> [UIElement] = { [] },
    @UIElementBuilder detail: () -> [UIElement] = { [] }
  ) {
    self.init(selection: selection.wrappedValue, sidebar: sidebar, detail: detail)
    self.onSelectionChange = { [unowned self] value in
      guard let value = value.base as? V else { return }
      selection.wrappedValue = value
      if let context = self.context { self.setSelection(selection.wrappedValue, context) }
    }
  }

  private init(
    selection: AnyHashable?, binds: Bool, sidebar: () -> [UIElement], detail: () -> [UIElement]
  ) {
    self.bindsSelection = binds
    self.selectedValue = selection
    self.pendingSelection = selection
    self.placeholder = detail()
    self.sidebarContent = VStack(alignment: .leading, spacing: 2, content: sidebar)
    let placeholder = self.placeholder
    self.detailStack = NavigationStack { return placeholder }
    let column = Sidebar(content: self.sidebarContent)
    super.init()
    self.applyContent([NavigationSplitLayout(sidebar: column, detail: self.detailStack)])
    self.detailStack.outerHost = self
  }

  /// Converts a write-back to the selection's own type: what `@Component` arms
  /// `onSelectionChange` through. A value of another type is dropped.
  public static func adapt<T: Hashable>(_ write: @escaping (T) -> Void) -> (AnyHashable) -> Void {
    { value in
      if let value = value.base as? T { write(value) }
    }
  }

  /// The door `@Component` attaches the sidebar through.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.sidebarContent.replaceChildren(elements, context, animation: animation)
  }

  /// The door `@Component` attaches the detail placeholder through. Shown while nothing in the
  /// sidebar is selected.
  public func replaceDetail(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.placeholder = elements
    guard self.selectedLink == nil, self.selectedValue == nil else { return }
    self.detailStack.replaceChildren(elements, context, animation: animation)
  }

  /// Selects `value`, as a tap on its link would, or nothing. O(links).
  public func setSelection<V: Hashable>(_ value: V?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let value = value.map { AnyHashable($0) }
    guard value != self.selectedValue else { return }
    self.select(nil, value: value)
    self.show(value)
  }

  override func activate(_ link: NavigationLink) {
    guard self.context != nil else { return }
    if let value = link.value {
      guard value != self.selectedValue else { return }
      guard !self.bindsSelection else {
        self.onSelectionChange?(value)
        return
      }
      self.select(link, value: value)
      self.show(value)
    } else if let make = link.destination, let context = self.context {
      self.select(link, value: nil)
      self.pendingSelection = nil
      self.detailStack.showRoot([make()], context)
    }
  }

  /// Shows the view for `value`, or the placeholder for nil. Waits for a destination that takes
  /// it, or for mounting.
  private func show(_ value: AnyHashable?) {
    self.pendingSelection = value
    guard let context = self.context else { return }
    guard let value else {
      self.detailStack.showRoot(self.placeholder, context)
      return
    }
    if let view = self.makeView(for: value) {
      self.pendingSelection = nil
      self.detailStack.showRoot([view], context)
    }
  }

  /// Moves the highlight. O(links).
  private func select(_ link: NavigationLink?, value: AnyHashable?) {
    self.selectedValue = value
    self.selectedLink = link
    guard let context = self.context else { return }
    for other in self.links.values {
      other.setSelected(self.isSelected(other), context)
    }
  }

  private func isSelected(_ link: NavigationLink) -> Bool {
    if let value = link.value { return value == self.selectedValue }
    return link === self.selectedLink
  }

  override func destinationsChanged() {
    guard let value = self.pendingSelection, let context = self.context,
          let view = self.makeView(for: value)
    else { return }
    self.pendingSelection = nil
    self.detailStack.showRoot([view], context)
  }

  override func linkMounted(_ link: NavigationLink) {
    guard let context = self.context else { return }
    self.links[ObjectIdentifier(link)] = link
    link.applySidebarAppearance(context)
    link.setSelected(self.isSelected(link), context)
  }

  override func linkUnmounted(_ link: NavigationLink) {
    self.links.removeValue(forKey: ObjectIdentifier(link))
  }

  override func linkValueChanged(_ link: NavigationLink) {
    guard let context = self.context else { return }
    link.setSelected(self.isSelected(link), context)
  }
}

/// The sidebar column: 232 wide, the sidebar tint and a hairline at its trailing edge, content
/// top-leading, inset 10. Under a translucent window's title bar it runs to the window's top,
/// with the traffic lights on it and its content below them. What `NavigationSplitView` puts its
/// sidebar in; on its own, a sidebar for a layout of an app's own.
///
///     Sidebar(title: "Demos") {
///       SidebarLink("Form", selected: true) { … }
///     }
public final class Sidebar : UIRenderableElement {
  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero
  private var titleBarPlacement = TitleBarPlacement()
  private weak var context: UIContext?

  init(content: UIElement) {
    super.init()
    self.applyContent([content])
  }

  /// A sidebar with `title` over its content, as `SidebarTitle` draws it.
  public convenience init(title: String? = nil, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    let column = VStack(alignment: .leading, spacing: 0)
    column.applyContent((title.map { [SidebarTitle($0) as UIElement] } ?? []) + content())
    self.init(content: column)
  }

  public override func mount(_ context: UIContext) {
    self.context = context
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    self.context = nil
    context.unregisterRenderableView(self)
  }

  public override func getSize() -> float2 {
    self.size
  }

  /// Above the content: the title bar's row when it is over the sidebar.
  private var topInset: Float {
    self.titleBarPlacement.atTop && TitleBarInsets.current.top > 0
      ? TitleBarInsets.unifiedBarHeight : NavigationMetrics.sidebarVerticalInset
  }

  private func contentProposal(_ height: Float?) -> ProposedSize {
    let inset = NavigationMetrics.sidebarInset
    let vertical = self.topInset + NavigationMetrics.sidebarVerticalInset
    return ProposedSize(width: NavigationMetrics.sidebarWidth - 2 * inset, height: height.map { max($0 - vertical, 0) })
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let height = proposal.height.flatMap { $0.isFinite ? $0 : nil }
    let content = self.child?.measure(self.contentProposal(height)) ?? .zero
    let vertical = self.topInset + NavigationMetrics.sidebarVerticalInset
    return float2(NavigationMetrics.sidebarWidth, height ?? content.y + vertical)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    _ = self.child?.calcSize(self.contentProposal(self.size.y))
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
    self.titleBarPlacement.settle(position.y, self.context)
    let top = self.topInset
    if top > NavigationMetrics.sidebarVerticalInset {
      TitleBarInsets.addDragRegion(float4(position.x, position.y, self.size.x, top))
    }
    self.child?.calcPosition(position + float2(NavigationMetrics.sidebarInset, top))
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let size = self.size * effect.scale
    let origin = effect.apply(to: self.position) - renderer.size * 0.5
    var color = NavigationMetrics.sidebarColor
    color.w *= effect.opacity
    renderer.draw(square: Square(position: origin + size * 0.5, size: size, color: color))
    var line = NavigationMetrics.separatorColor
    line.w *= effect.opacity
    renderer.draw(square: Square(position: origin + float2(size.x - 0.25, size.y * 0.5), size: float2(0.5, size.y), color: line))
  }
}

/// The sidebar at its width, the detail column in the rest.
final class NavigationSplitLayout : UIElement {
  private let sidebar: Sidebar
  private let detail: NavigationStack
  private(set) var size: float2 = .zero

  init(sidebar: Sidebar, detail: NavigationStack) {
    self.sidebar = sidebar
    self.detail = detail
    super.init()
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    body(self.sidebar)
    body(self.detail)
  }

  override func getSize() -> float2 {
    self.size
  }

  private func detailProposal(_ proposal: ProposedSize) -> ProposedSize {
    ProposedSize(width: proposal.width.map { max($0 - NavigationMetrics.sidebarWidth, 0) }, height: proposal.height)
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let sidebar = self.sidebar.measure(proposal)
    let detail = self.detail.measure(self.detailProposal(proposal))
    return NavigationEntry.fill(proposal, float2(sidebar.x + detail.x, max(sidebar.y, detail.y)))
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    _ = self.sidebar.calcSize(ProposedSize(width: NavigationMetrics.sidebarWidth, height: self.size.y))
    _ = self.detail.calcSize(ProposedSize(width: max(self.size.x - NavigationMetrics.sidebarWidth, 0), height: self.size.y))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.sidebar.calcPosition(position)
    self.detail.calcPosition(position + float2(NavigationMetrics.sidebarWidth, 0))
  }
}
