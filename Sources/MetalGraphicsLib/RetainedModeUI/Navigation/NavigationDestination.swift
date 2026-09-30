/// Registers a view factory for one type of value with the navigation host it is in. Made by
/// `.navigationDestination(for:destination:)`. Draws nothing and takes its content's layout.
public class NavigationDestinationBase : SingleChildElement {
  weak var host: NavigationHost?

  var isArmed: Bool { false }

  func accepts(_ value: AnyHashable) -> Bool { false }

  func makeView(_ value: AnyHashable) -> UIElement? { nil }

  public override func mount(_ context: UIContext) {
    // Written on the stack itself, `NavigationStack { … }.navigationDestination(…)`, the host is
    // under it rather than above.
    let host = self.hostOnSpine ?? self.nearestAncestor(NavigationHost.self)
    self.host = host
    host?.register(self)
  }

  public override func unmount(_ context: UIContext) {
    self.host?.unregister(self)
    self.host = nil
  }

  private var hostOnSpine: NavigationHost? {
    var current = self.child
    while let element = current {
      if let host = element as? NavigationHost { return host }
      guard let single = element as? SingleChildElement else { return nil }
      current = single.child
    }
    return nil
  }
}

public final class NavigationDestinationElement<D: Hashable> : NavigationDestinationBase {
  /// Builds the page for a value. `@Component` arms it on mount and clears it on unmount, like a
  /// handler, so it may capture `self`.
  public var destination: ((D) -> UIElement)? {
    didSet {
      if self.destination != nil, self.mounted {
        self.host?.destinationArmed(self)
      }
    }
  }

  public init(for type: D.Type, destination: ((D) -> UIElement)?, @UIElementBuilder content: () -> [UIElement]) {
    self.destination = destination
    super.init()
    self.applyContent(content())
  }

  override var isArmed: Bool { self.destination != nil }

  override func accepts(_ value: AnyHashable) -> Bool {
    value.base is D
  }

  override func makeView(_ value: AnyHashable) -> UIElement? {
    guard let destination = self.destination, let value = value.base as? D else { return nil }
    return destination(value)
  }
}

/// Gives the page it is in its title, shown in the stack's bar and on the back button of the
/// page pushed over it. Made by `.navigationTitle(_:)`. Draws nothing.
public final class NavigationTitleElement : SingleChildElement {
  public private(set) var title: String
  private weak var entry: NavigationEntry?

  public init(_ title: String, @UIElementBuilder content: () -> [UIElement]) {
    self.title = title
    super.init()
    self.applyContent(content())
  }

  public func setTitle(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.title else { return }
    self.title = value
    self.entry?.titleChanged(self)
  }

  public override func mount(_ context: UIContext) {
    let entry = self.nearestAncestor(NavigationEntry.self)
    self.entry = entry
    entry?.adoptTitle(self)
  }

  public override func unmount(_ context: UIContext) {
    self.entry?.dropTitle(self)
    self.entry = nil
  }
}

/// Gives the page it is in items in the stack's bar, beside its title: `leading` after the back
/// button, `trailing` at the trailing edge, as SwiftUI's `.toolbar`. Made by `.toolbar(leading:
/// trailing:)`. The items are shown in the bar while the page is on top; they draw nothing here.
public final class NavigationToolbarElement : SingleChildElement {
  public let leading: [UIElement]
  public let trailing: [UIElement]
  private weak var entry: NavigationEntry?

  public init(leading: [UIElement], trailing: [UIElement], @UIElementBuilder content: () -> [UIElement]) {
    self.leading = leading
    self.trailing = trailing
    super.init()
    self.applyContent(content())
  }

  public override func mount(_ context: UIContext) {
    let entry = self.nearestAncestor(NavigationEntry.self)
    self.entry = entry
    entry?.adoptToolbar(self)
  }

  public override func unmount(_ context: UIContext) {
    self.entry?.dropToolbar(self)
    self.entry = nil
  }
}

/// Gives the page it is in its background: what the page is drawn on, edge to edge, under
/// the stack's bar. `.contentBackground` when no page element sets one. Made by
/// `.navigationBackground(_:)`. Not in SwiftUI.
public final class NavigationBackgroundElement : SingleChildElement {
  public private(set) var background: float4
  private weak var entry: NavigationEntry?

  public init(_ background: float4, @UIElementBuilder content: () -> [UIElement]) {
    self.background = background
    super.init()
    self.applyContent(content())
  }

  public func setBackground(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.background else { return }
    self.background = value
    self.entry?.background = value
    context.invalidate()
  }

  public override func mount(_ context: UIContext) {
    let entry = self.nearestAncestor(NavigationEntry.self)
    self.entry = entry
    entry?.background = self.background
  }

  public override func unmount(_ context: UIContext) {
    if self.entry?.background == self.background {
      self.entry?.background = nil
    }
    self.entry = nil
  }
}

extension UIElementWrapping where Self: UIElement {
  /// What the page this is in is drawn on: `.navigationBackground(.groupedBackground)` for a
  /// form. Not in SwiftUI.
  public func navigationBackground(_ color: float4) -> NavigationBackgroundElement {
    NavigationBackgroundElement(color) { self }
  }

  /// What a value link of type `D` inside the same navigation stack or split view pushes:
  /// `.navigationDestination(for: Route.self) { route in RouteView(route: route) }`.
  public func navigationDestination<D: Hashable>(
    for type: D.Type, destination: @escaping (D) -> UIElement
  ) -> NavigationDestinationElement<D> {
    NavigationDestinationElement(for: type, destination: destination) { self }
  }

  /// A destination with no closure yet: what `@Component` builds, before it arms the closure on
  /// mount. Values waiting for it stay pending until then, rather than resolving to a stand-in.
  public func navigationDestination<D: Hashable>(for type: D.Type) -> NavigationDestinationElement<D> {
    NavigationDestinationElement(for: type, destination: nil) { self }
  }

  /// Items in the stack's bar while the page this is in is on top: `leading` after the back
  /// button, `trailing` at the trailing edge.
  public func toolbar(
    @UIElementBuilder leading: () -> [UIElement] = { [] }, @UIElementBuilder trailing: () -> [UIElement] = { [] }
  ) -> NavigationToolbarElement {
    NavigationToolbarElement(leading: leading(), trailing: trailing()) { self }
  }

  /// The title of the page this is in, in the stack's bar.
  public func navigationTitle(_ title: String) -> NavigationTitleElement {
    NavigationTitleElement(title) { self }
  }
}
