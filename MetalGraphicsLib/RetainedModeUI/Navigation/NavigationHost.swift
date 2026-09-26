/// What navigation links and destinations inside it talk to: a `NavigationStack` or a
/// `NavigationSplitView`.
///
/// Links, destinations and titles find their host through `UIElement.parent` when they mount or
/// are tapped, never per frame. A host keeps the destinations registered inside it, and turns a
/// link's value into a view through them: its own newest first, then its outer host's, so a
/// split view's sidebar destinations serve the pages pushed in its detail column.
open class NavigationHost : SingleChildElement {
  /// Set while mounted.
  public private(set) weak var context: UIContext?
  /// The host whose destinations this one falls back on. A split view sets it on its detail
  /// stack.
  weak var outerHost: NavigationHost?

  /// In the order they registered. Few — one per `.navigationDestination` — so a lookup is a
  /// short linear scan.
  private var destinations: [NavigationDestinationBase] = []

  open override func mount(_ context: UIContext) {
    self.context = context
  }

  open override func unmount(_ context: UIContext) {
    self.context = nil
  }

  func register(_ destination: NavigationDestinationBase) {
    guard !self.destinations.contains(where: { $0 === destination }) else { return }
    self.destinations.append(destination)
    if destination.isArmed {
      self.scheduleDestinationsChanged()
    }
  }

  func unregister(_ destination: NavigationDestinationBase) {
    self.destinations.removeAll { $0 === destination }
  }

  /// A registered destination got its closure: `@Component` arms handlers after the subtree
  /// mounts on first mount, and before it on a branch swap.
  func destinationArmed(_ destination: NavigationDestinationBase) {
    self.scheduleDestinationsChanged()
  }

  /// Resolution changes the tree, which must not happen inside a layout pass: a lazy stack
  /// mounts its rows while it is laid out.
  private func scheduleDestinationsChanged() {
    guard let context = self.context else { return }
    guard context.isLayingOut else {
      self.destinationsChanged()
      return
    }
    context.afterLayout { [weak self] in
      self?.destinationsChanged()
    }
  }

  /// Something new can be resolved: values waiting for a destination may have one now.
  func destinationsChanged() {}

  /// The view for `value`, from the newest destination that takes its type, else the outer
  /// host's. Nil when none does yet.
  func makeView(for value: AnyHashable) -> UIElement? {
    for destination in self.destinations.reversed() where destination.accepts(value) {
      if let view = destination.makeView(value) { return view }
    }
    return self.outerHost?.makeView(for: value)
  }

  /// A link inside this host was tapped.
  func activate(_ link: NavigationLink) {}

  /// Only a split view keeps track of its links, to mark the selected one.
  func linkMounted(_ link: NavigationLink) {}
  func linkUnmounted(_ link: NavigationLink) {}
  func linkValueChanged(_ link: NavigationLink) {}
}
