/// A button that navigates: `NavigationLink("Settings", value: Route.settings)` pushes the page
/// the stack's `.navigationDestination(for: Route.self)` builds for it, and
/// `NavigationLink("About") { AboutView() }` pushes that view. In a split view's sidebar a value
/// link selects what the detail column shows, and is highlighted while it does.
///
/// It looks and styles like a `Button`, since it is one: `.buttonStyle`, `.disabled` and a view
/// label, `NavigationLink(value: route) { Text(route.name) }`, all work.
public final class NavigationLink : Button {
  /// The value it pushes, or nil for a link to a view.
  public private(set) var value: AnyHashable?
  /// The view it pushes, when it has no value. `@Component` arms it on mount and clears it on
  /// unmount, like a handler, so it may capture `self`.
  public var destination: (() -> UIElement)?

  /// The stack or split view it is in, found when it mounts.
  private weak var host: NavigationHost?

  init(value: AnyHashable?, destination: (() -> UIElement)?, title: Text?, label: () -> [UIElement]) {
    self.value = value
    self.destination = destination
    super.init(role: nil, action: nil, title: title, label: label)
    self.action = { [unowned self] in self.activate() }
  }

  public convenience init<V: Hashable>(_ title: String, value: V?) {
    let text = Text(title)
    self.init(value: value.map { AnyHashable($0) }, destination: nil, title: text) { [text] }
  }

  public convenience init<V: Hashable>(value: V?, @UIElementBuilder label: () -> [UIElement] = { [] }) {
    self.init(value: value.map { AnyHashable($0) }, destination: nil, title: nil, label: label)
  }

  public convenience init(_ title: String, destination: (() -> UIElement)? = nil) {
    let text = Text(title)
    self.init(value: nil, destination: destination, title: text) { [text] }
  }

  public convenience init(destination: (() -> UIElement)? = nil, @UIElementBuilder label: () -> [UIElement] = { [] }) {
    self.init(value: nil, destination: destination, title: nil, label: label)
  }

  public func setValue<V: Hashable>(_ value: V?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let value = value.map { AnyHashable($0) }
    guard value != self.value else { return }
    self.value = value
    self.host?.linkValueChanged(self)
  }

  private func activate() {
    guard !self.isDisabled else { return }
    (self.host ?? self.nearestAncestor(NavigationHost.self))?.activate(self)
  }

  public override func mount(_ context: UIContext) {
    super.mount(context)
    let host = self.nearestAncestor(NavigationHost.self)
    self.host = host
    host?.linkMounted(self)
  }

  public override func unmount(_ context: UIContext) {
    self.host?.linkUnmounted(self)
    self.host = nil
    self.face.setSelected(false, context)
    super.unmount(context)
  }

  /// How a split view's sidebar shows it: full width, in the label colour unless styled.
  func applySidebarAppearance(_ context: UIContext) {
    guard !self.face.fillsWidth else { return }
    self.face.fillsWidth = true
    if self.style == .automatic {
      self.setButtonStyle(.plain, context)
    }
    context.invalidate(.layout)
  }

  func setSelected(_ value: Bool, _ context: UIContext) {
    guard value != self.face.isSelected else { return }
    self.face.setSelected(value, context)
    self.setLabelWeight(value ? .medium : nil, context)
  }
}
