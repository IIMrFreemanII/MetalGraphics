import AppKit
import simd

/// A stack of pages under a bar with a back button, as SwiftUI's: the root content, and a page
/// over it for each value in the path.
///
/// ```swift
/// NavigationStack(path: $path) {
///   VList(items: self.routes) { route in NavigationLink(route.name, value: route) }
///     .navigationTitle("Routes")
///     .navigationDestination(for: Route.self) { route in RouteView(route: route) }
/// }
/// ```
///
/// Without `path:` the stack owns its path, and value links push onto it. With one, the bound
/// state is the only source of truth: a link, the back button and the back keys (Escape, ⌘[)
/// report the new path through `onPathChange`, and it comes back through `setPath`, as a form
/// control's value does. A page a `destination:` link pushes is not in the path.
///
/// Every page stays mounted, and keeps its state, while a page covers it; covered pages are
/// hidden, so a deep stack costs nothing per frame. A push or pop slides the two pages as one
/// animation, with `NavigationMetrics.transition` unless the change was made with one.
public final class NavigationStack : NavigationHost {
  /// The path's write-back, set for a bound stack: `@Component` arms it on mount.
  public var onPathChange: (([AnyHashable]) -> Void)?

  /// Whether links push onto the stack's own path rather than report to `onPathChange`.
  private let ownsPath: Bool
  /// The value of each page that has one, in order: the path.
  private var values: [AnyHashable]

  private let rootContent: VStack
  private let pages: NavigationPages
  private let bar: NavigationBar

  /// How many pages are pushed over the root.
  public var depth: Int { self.pages.entries.count - 1 }

  /// A stack that owns its path.
  public convenience init(@UIElementBuilder root: () -> [UIElement] = { [] }) {
    self.init(ownsPath: true, values: [], root: root)
  }

  /// A stack showing `path`, reporting changes to `onPathChange`, which `@Component` arms for
  /// `path: $state`. Left unset, links and the back keys do nothing, as with a constant binding.
  public convenience init<P: NavigationPathRepresentable>(path: P, @UIElementBuilder root: () -> [UIElement] = { [] }) {
    self.init(ownsPath: false, values: path.navigationElements, root: root)
  }

  /// A stack bound to `path`, for trees built by hand. In a `@Component` body `$path` is lowered
  /// at compile time instead, and this is never called.
  public convenience init<P: NavigationPathRepresentable>(path: Binding<P>, @UIElementBuilder root: () -> [UIElement] = { [] }) {
    self.init(path: path.wrappedValue, root: root)
    self.onPathChange = { [unowned self] values in
      guard let value = P(navigationElements: values) else { return }
      path.wrappedValue = value
      if let context = self.context { self.setPath(path.wrappedValue, context) }
    }
  }

  private init(ownsPath: Bool, values: [AnyHashable], root: () -> [UIElement]) {
    self.ownsPath = ownsPath
    self.values = values
    self.rootContent = VStack(spacing: 0, content: root)
    self.bar = NavigationBar()
    self.pages = NavigationPages()
    let column = NavigationColumn(pages: self.pages, bar: self.bar)
    let keys = KeyPressElement(phases: [.down], action: nil) { column }
    super.init()
    self.applyContent([keys])

    let root = NavigationEntry(value: nil, view: self.rootContent, stack: self)
    var entries = [root]
    for value in values {
      entries.append(NavigationEntry(value: value, view: nil, stack: self))
    }
    self.pages.setEntries(entries, animation: nil, nil)

    self.bar.back.action = { [unowned self] in self.goBack() }
    keys.action = { [unowned self] press in self.handleKey(press) }
  }

  /// Converts a write-back to the path's own type: what `@Component` arms `onPathChange`
  /// through. A path with a value of another type than the bound array's is dropped.
  public static func adapt<P: NavigationPathRepresentable>(_ write: @escaping (P) -> Void) -> ([AnyHashable]) -> Void {
    { values in
      if let path = P(navigationElements: values) { write(path) }
    }
  }

  // MARK: - Doors

  /// The door `@Component` attaches the root content through.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.rootContent.replaceChildren(elements, context, animation: animation)
  }

  /// Shows `path`: pops the pages past the longest prefix it shares with the current path, and
  /// pushes the rest. O(depth); nothing happens, and nothing is allocated, when it is the same.
  public func setPath<P: NavigationPathRepresentable>(_ value: P, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard !value.matchesNavigationElements(self.values) else { return }
    self.show(values: value.navigationElements, animation: animation)
  }

  /// Replaces the root content and drops every pushed page, at once: what a split view does
  /// when its sidebar selection changes.
  func showRoot(_ elements: [UIElement], _ context: UIContext) {
    if self.depth > 0 {
      self.values.removeAll()
      self.pages.setEntries([self.pages.entries[0]], animation: nil, self.mountedContext)
      self.refreshBar()
    }
    self.rootContent.replaceChildren(elements, context)
  }

  // MARK: - Navigating

  override func activate(_ link: NavigationLink) {
    guard self.mountedContext != nil else { return }
    if let value = link.value {
      guard !self.ownsPath else {
        self.show(values: self.values + [value], animation: nil)
        return
      }
      self.onPathChange?(self.values + [value])
    } else if let make = link.destination {
      var entries = self.pages.entries
      entries.append(NavigationEntry(value: nil, view: make(), stack: self))
      self.pages.setEntries(entries, animation: self.animation(nil), self.mountedContext)
      self.refreshBar()
    }
  }

  /// Pops the top page: the back button, Escape and ⌘[.
  public func goBack() {
    guard self.depth > 0, self.mountedContext != nil, let top = self.pages.entries.last else { return }
    if top.value == nil || self.ownsPath {
      if top.value != nil { self.values.removeLast() }
      self.pages.setEntries(Array(self.pages.entries.dropLast()), animation: self.animation(nil), self.mountedContext)
      self.refreshBar()
    } else {
      self.onPathChange?(Array(self.values.dropLast()))
    }
  }

  private func handleKey(_ press: KeyPress) -> KeyPress.Result {
    guard self.depth > 0, let context = self.context, !context.isDragging else { return .ignored }
    let modifiers = press.modifiers.intersection([.command, .option, .control, .shift])
    let escape = press.key == .escape && modifiers.isEmpty
    let bracket = modifiers == .command && (press.key == "[" || press.keyCode == .openBracket)
    guard escape || bracket else { return .ignored }
    self.goBack()
    return .handled
  }

  /// Makes the pages match `values`: keeps those up to the first that differs, with any page a
  /// view link pushed over them, and pushes one page per value after it.
  private func show(values new: [AnyHashable], animation: UIAnimation?) {
    let old = self.values
    var common = 0
    while common < old.count, common < new.count, old[common] == new[common] {
      common += 1
    }
    guard common < old.count || common < new.count else { return }

    var entries = self.pages.entries
    if common < old.count {
      // The page holding the first value that differs, and everything over it, goes.
      var seen = 0
      if let cut = entries.firstIndex(where: { entry in
        guard entry.value != nil else { return false }
        defer { seen += 1 }
        return seen == common
      }) {
        entries.removeSubrange(cut...)
      }
    }
    for value in new[common...] {
      entries.append(NavigationEntry(value: value, view: self.makeView(for: value), stack: self))
    }
    self.values = new
    self.pages.setEntries(entries, animation: self.animation(animation), self.mountedContext)
    self.refreshBar()
  }

  /// A mounted stack always animates a push or pop, as SwiftUI does: with the change's own
  /// animation, else the default.
  private func animation(_ given: UIAnimation?) -> UIAnimation? {
    guard self.mountedContext != nil else { return nil }
    return given ?? UITransaction.animation ?? NavigationMetrics.transition
  }

  private var mountedContext: UIContext? {
    self.mounted ? self.context : nil
  }

  // MARK: - Destinations

  public override func mount(_ context: UIContext) {
    super.mount(context)
    self.resolvePending()
    self.refreshBar()
  }

  override func destinationsChanged() {
    self.resolvePending()
  }

  /// Gives each page still waiting for a destination its view, if one takes its value now. By
  /// index: a view mounted here may register destinations of its own.
  private func resolvePending() {
    var index = 1
    while index < self.pages.entries.count {
      let entry = self.pages.entries[index]
      if !entry.isResolved, let value = entry.value, let view = self.makeView(for: value) {
        entry.resolve(view, self.mountedContext)
      }
      index += 1
    }
  }

  // MARK: - Bar

  func titleChanged(_ entry: NavigationEntry) {
    let entries = self.pages.entries
    guard entries.last === entry || (entries.count >= 2 && entries[entries.count - 2] === entry) else { return }
    self.refreshBar()
  }

  private func refreshBar() {
    guard let context = self.context else { return }
    let entries = self.pages.entries
    let previous = entries.count >= 2 ? entries[entries.count - 2].title : nil
    self.bar.show(title: entries.last?.title ?? "", back: previous, context)
  }
}

// MARK: - Pages

/// One page of a stack: its root content, or the view pushed for one value or link. Fills the
/// page area with an opaque background, so the page it covers does not show through, and
/// centres its view in it.
final class NavigationEntry : UIRenderableElement {
  /// The path value it shows; nil for the root and for a page a `destination:` link pushed.
  let value: AnyHashable?
  /// False while its value waits for a destination to be registered. It shows nothing then.
  private(set) var isResolved: Bool
  private weak var stack: NavigationStack?
  private weak var titleSource: NavigationTitleElement?
  /// What it is drawn on, when a `NavigationBackgroundElement` in it says.
  var background: float4?

  /// How far it is drawn from where it was laid out, along x, while it slides in or out.
  var slide: Float = 0
  /// True during a push or pop that moves it, while it has an effect to resolve.
  var inTransition = false

  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero
  private var contentSize: float2 = .zero

  init(value: AnyHashable?, view: UIElement?, stack: NavigationStack) {
    self.value = value
    self.isResolved = view != nil
    self.stack = stack
    super.init()
    self.applyContent([view ?? EmptyElement()])
  }

  var title: String { self.titleSource?.title ?? "" }

  func resolve(_ view: UIElement, _ context: UIContext?) {
    self.isResolved = true
    if let context {
      self.setChild(view, context)
    } else {
      self.child = view
    }
  }

  func adoptTitle(_ source: NavigationTitleElement) {
    self.titleSource = source
    self.stack?.titleChanged(self)
  }

  func dropTitle(_ source: NavigationTitleElement) {
    guard self.titleSource === source else { return }
    self.titleSource = nil
    self.stack?.titleChanged(self)
  }

  func titleChanged(_ source: NavigationTitleElement) {
    guard self.titleSource === source else { return }
    self.stack?.titleChanged(self)
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 {
    self.size
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    Self.fill(proposal, self.child?.measure(proposal) ?? .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.contentSize = self.child?.calcSize(proposal) ?? .zero
    self.size = Self.fill(proposal, self.contentSize)
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.child?.calcPosition(position + (self.size - self.contentSize) * 0.5)
  }

  /// The proposal where it is finite, the content's size elsewhere.
  static func fill(_ proposal: ProposedSize, _ content: float2) -> float2 {
    float2(
      proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? content.x,
      proposal.height.flatMap { $0.isFinite ? $0 : nil } ?? content.y
    )
  }

  override var localEffect: EffectState {
    EffectState(opacity: 1, scale: 1, translate: float2(self.slide, 0) + self.slideOffset)
  }

  override var hasEffect: Bool { self.inTransition || self.slideOffset != .zero }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let size = self.size * effect.scale
    var color = renderer.resolve(self.background ?? NavigationMetrics.contentBackground)
    color.w *= effect.opacity
    let center = effect.apply(to: self.position) - renderer.size * 0.5 + size * 0.5
    renderer.draw(square: Square(position: center, size: size, color: color))
  }
}

/// The pages of a stack, and the slide between two of them.
///
/// Only the top page is laid out and drawn, and during a push or pop the page it slides over or
/// uncovers. The others stay mounted but hidden, so `UIContext.collect` skips them whole. A
/// push or pop is one animator entry driving both pages' slide, which only redraws: no layout
/// and no tree-order rebuild per frame.
final class NavigationPages : UIElement {
  /// The stack, root first. Never empty once built.
  private(set) var entries: [NavigationEntry] = []
  /// The page a pop or a replacing push removed, drawn until it has slid away.
  private var leaving: NavigationEntry?

  private struct Transition {
    unowned let incoming: NavigationEntry
    unowned let outgoing: NavigationEntry
    let isPush: Bool
  }
  private var transition: Transition?

  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero

  /// Makes `new` the stack of pages. `new` keeps a prefix of the current pages and adds new
  /// ones after it. With a context the pages are mounted: those added mount, those removed
  /// unmount, and with an animation the old top page slides away from the new one.
  func setEntries(_ new: [NavigationEntry], animation: UIAnimation?, _ context: UIContext?) {
    let old = self.entries
    guard let context, self.mounted else {
      self.entries = new
      for (index, entry) in new.enumerated() {
        entry.isHidden = index != new.count - 1
      }
      return
    }
    self.finishTransition(context)

    let oldTop = old.last
    let newTop = new.last
    guard oldTop !== newTop else { return }

    let kept = Set(new.map(ObjectIdentifier.init))
    self.entries = new
    for entry in new where !old.contains(where: { $0 === entry }) {
      entry.isHidden = entry !== newTop
      entry.handleMount(context, in: self)
    }
    newTop?.isHidden = false
    context.invalidate([.layout, .treeOrder])

    let outgoingRemoved = oldTop.map { !kept.contains(ObjectIdentifier($0)) } ?? false
    // Pages popped from under the top one go at once; only the top one slides away.
    for entry in old where entry !== oldTop && !kept.contains(ObjectIdentifier(entry)) {
      entry.handleUnmount(context)
    }

    guard let oldTop, let newTop else { return }
    guard let animation else {
      if outgoingRemoved {
        oldTop.handleUnmount(context)
      } else {
        oldTop.isHidden = true
      }
      return
    }

    let isPush = !old.contains(where: { $0 === newTop })
    if outgoingRemoved {
      oldTop.isLeaving = true
      self.leaving = oldTop
    }
    self.transition = Transition(incoming: newTop, outgoing: oldTop, isPush: isPush)
    for entry in [newTop, oldTop] {
      entry.inTransition = true
      entry.allowsHitTesting = false
    }
    self.setProgress(0, context)
    context.animator.run(
      self, .navigation, from: Float(0).packed, to: Float(1).packed, animation, context,
      restart: true,
      apply: { element, value, context in
        unsafeDowncast(element, to: NavigationPages.self).setProgress(value.x, context)
      },
      completion: { [weak self] in
        self?.finishTransition(context)
      }
    )
  }

  private func setProgress(_ progress: Float, _ context: UIContext) {
    guard let transition = self.transition else { return }
    let width = self.size.x
    let covered = width * NavigationMetrics.parallax
    if transition.isPush {
      transition.incoming.slide = (1 - progress) * width
      transition.outgoing.slide = -progress * covered
    } else {
      transition.outgoing.slide = progress * width
      transition.incoming.slide = -(1 - progress) * covered
    }
    context.invalidate()
  }

  /// Ends the running push or pop where it was going: the old page hidden, or unmounted if it
  /// was removed. Also what an interrupting push or pop, and unmounting, do first.
  private func finishTransition(_ context: UIContext) {
    guard let transition = self.transition else { return }
    self.transition = nil
    context.animator.cancel(self, .navigation)
    let outgoing = transition.outgoing
    for entry in [transition.incoming, outgoing] {
      entry.slide = 0
      entry.inTransition = false
      entry.allowsHitTesting = true
    }
    if self.leaving === outgoing {
      self.leaving = nil
      outgoing.isLeaving = false
      outgoing.handleUnmount(context)
    } else if self.entries.last !== outgoing {
      outgoing.isHidden = true
    }
    context.invalidate([.layout, .treeOrder])
  }

  override func unmount(_ context: UIContext) {
    self.finishTransition(context)
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    self.entries.forEach(body)
    if let leaving = self.leaving { body(leaving) }
  }

  // A popped page slides away over the one it uncovers; a page a push replaces stays under the
  // one sliding in.
  override func forEachChildInPaintOrder(_ body: (UIElement) -> Void) {
    let leavingFirst = self.transition?.isPush ?? false
    if leavingFirst, let leaving = self.leaving { body(leaving) }
    self.entries.forEach(body)
    if !leavingFirst, let leaving = self.leaving { body(leaving) }
  }

  override func getSize() -> float2 {
    self.size
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    NavigationEntry.fill(proposal, self.entries.last?.measure(proposal) ?? .zero)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    let page = ProposedSize(self.size)
    self.forEachShown { _ = $0.calcSize(page) }
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    self.forEachShown { $0.calcPosition(position) }
  }

  /// The top page, and during a push or pop the other page it moves.
  private func forEachShown(_ body: (NavigationEntry) -> Void) {
    for entry in self.entries where !entry.isHidden {
      body(entry)
    }
    if let leaving = self.leaving { body(leaving) }
  }

  // Only while pages slide: at rest the top page is drawn where it is, and the clip would only
  // cost a clip resolve per frame.
  override var clipRect: ClipRect? {
    self.transition == nil ? nil : ClipRect(position: self.position, size: self.size)
  }

  override func dropLeaving() {
    self.leaving = nil
  }
}

// MARK: - Bar and layout

/// The bar over a stack's pages: the top page's title, centred, and a back button titled after
/// the page under it.
final class NavigationBar : UIRenderableElement {
  let back: Button
  let title: Text

  private(set) var position: float2 = .zero
  private(set) var size: float2 = .zero
  private var backSize: float2 = .zero
  private var titleSize: float2 = .zero
  /// Set by its column: taller in a title bar's row.
  var height: Float = NavigationMetrics.barHeight
  /// Whether it shares the title bar's row: it keeps clear of the traffic lights, and its empty
  /// parts drag the window.
  var inTitleBar = false

  private static let inset: Float = 10

  /// Where its content starts: past the traffic lights when they are over it.
  private var leading: Float {
    guard self.inTitleBar else { return Self.inset }
    return max(Self.inset, TitleBarInsets.current.leading - self.position.x)
  }

  override init() {
    self.back = Button("‹ Back")
    self.title = Text("").font(NavigationMetrics.titleFont).foregroundColor(NavigationMetrics.titleColor).lineLimit(1)
    super.init()
    self.back.isHidden = true
  }

  func show(title: String, back: String?, _ context: UIContext) {
    self.title.setText(title, context)
    if let back {
      self.back.setTitle("‹ " + (back.isEmpty ? "Back" : back), context)
    }
    let hidden = back == nil
    if hidden != self.back.isHidden {
      self.back.isHidden = hidden
      context.invalidate([.layout, .treeOrder])
    }
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    body(self.back)
    body(self.title)
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 {
    self.size
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let back = self.back.measure(.unspecified)
    let title = self.title.measure(.unspecified)
    let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? (title.x + 2 * (back.x + 2 * Self.inset))
    return float2(width, self.height)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    self.backSize = self.back.calcSize(.unspecified)
    // Centred in the bar, so it keeps clear of the back button on both sides.
    let side = self.back.isHidden ? Self.inset : self.backSize.x + 2 * Self.inset
    let room = max(self.size.x - 2 * side, 0)
    self.titleSize = self.title.calcSize(ProposedSize(width: room, height: self.size.y))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    let leading = self.leading
    self.back.calcPosition(position + float2(leading, ((self.size.y - self.backSize.y) * 0.5).rounded()))
    self.title.calcPosition(position + ((self.size - self.titleSize) * 0.5).rounded(.toNearestOrAwayFromZero))
    if self.inTitleBar {
      let start = self.back.isHidden ? 0 : leading + self.backSize.x
      TitleBarInsets.addDragRegion(float4(position.x + start, position.y, self.size.x - start, self.size.y))
    }
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let size = self.size * effect.scale
    let origin = effect.apply(to: self.position) - renderer.size * 0.5
    var color = NavigationMetrics.barColor
    color.w *= effect.opacity
    renderer.draw(square: Square(position: origin + size * 0.5, size: size, color: color))
    var line = NavigationMetrics.separatorColor
    line.w *= effect.opacity
    let lineSize = float2(size.x, 0.5)
    renderer.draw(square: Square(position: origin + float2(size.x * 0.5, size.y - 0.25), size: lineSize, color: line))
  }
}

/// The bar over the pages. Fills what it is offered; along an axis it is offered no length on,
/// it takes the top page's.
final class NavigationColumn : UIElement {
  private let pages: NavigationPages
  private let bar: NavigationBar
  private(set) var size: float2 = .zero
  private var titleBarPlacement = TitleBarPlacement()
  private weak var context: UIContext?

  override func mount(_ context: UIContext) {
    self.context = context
  }

  override func unmount(_ context: UIContext) {
    self.context = nil
  }

  /// The bar's height: the title bar's row when the column is at the window's top under one.
  private var barHeight: Float {
    self.titleBarPlacement.atTop && TitleBarInsets.current.top > 0 ? TitleBarInsets.unifiedBarHeight : NavigationMetrics.barHeight
  }

  init(pages: NavigationPages, bar: NavigationBar) {
    self.pages = pages
    self.bar = bar
    super.init()
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    body(self.pages)
    body(self.bar)
  }

  override func getSize() -> float2 {
    self.size
  }

  private func pageProposal(_ proposal: ProposedSize) -> ProposedSize {
    let barHeight = self.barHeight
    return ProposedSize(width: proposal.width, height: proposal.height.map { max($0 - barHeight, 0) })
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    let page = self.pages.measure(self.pageProposal(proposal))
    return NavigationEntry.fill(proposal, page + float2(0, self.barHeight))
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    let barHeight = self.barHeight
    self.bar.height = barHeight
    self.bar.inTitleBar = barHeight == TitleBarInsets.unifiedBarHeight
    _ = self.pages.calcSize(ProposedSize(width: self.size.x, height: max(self.size.y - barHeight, 0)))
    _ = self.bar.calcSize(ProposedSize(width: self.size.x, height: barHeight))
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.titleBarPlacement.settle(position.y, self.context)
    self.bar.calcPosition(position)
    self.pages.calcPosition(position + float2(0, self.bar.height))
  }
}
