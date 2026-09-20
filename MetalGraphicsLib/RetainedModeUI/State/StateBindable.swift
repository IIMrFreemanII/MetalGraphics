import Combine

// Marker protocol so `bind(_:to:)` can use `Self` in its key path type.
public protocol StateBindable : UIElement {}
extension UIElement : StateBindable {}

@MainActor
extension StateBindable {

  // Call from `init`. Sets the property from `compute` now and, while mounted, re-evaluates it
  // whenever a `State` read inside `compute` changes. Reads are tracked in isolation, so they
  // never make the surrounding builder re-run.
  public func bind<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, to compute: @escaping () -> T, layout: Bool = false) -> Void {
    let reaction = Reaction(compute) { [weak self] value, context in
      self?[keyPath: keyPath] = value
      context.invalidate(layout: layout)
    }

    self[keyPath: keyPath] = reaction.value
    self.reactions.append(reaction)
  }
}

@MainActor
public protocol AnyReaction : AnyObject {
  func activate(_ context: UIContext) -> Void
  func deactivate() -> Void
}

// The one reactive primitive: evaluates `compute`, subscribes to the states it read, and
// re-evaluates on change. Dependencies are re-tracked on every run since they can differ
// (e.g. `cond ? a : b`). Property bindings and builder content are both built on this.
@MainActor
public final class Reaction<T> : AnyReaction {
  private let compute: () -> T
  private let apply: (T, UIContext) -> Void
  private var dependencies: [TrackableState]
  private var subscriptions: [AnyCancellable] = []
  private var activatedBefore = false

  // Evaluated at init in its own tracking scope, so the reads are not recorded by an
  // enclosing tracker and an element that is built and then discarded subscribes to nothing.
  public private(set) var value: T

  public init(_ compute: @escaping () -> T, apply: @escaping (T, UIContext) -> Void) {
    self.compute = compute
    self.apply = apply
    (self.value, self.dependencies) = DependencyTracker.track(compute)
  }

  // Called on mount. On the first one the value from `init` is still current, so this only
  // subscribes; on a remount it re-evaluates to pick up changes made while unmounted.
  public func activate(_ context: UIContext) -> Void {
    if self.activatedBefore {
      self.run(context)
    } else {
      self.activatedBefore = true
      self.subscribe(context)
    }
  }

  public func deactivate() -> Void {
    self.subscriptions.forEach { $0.cancel() }
    self.subscriptions.removeAll()
  }

  private func run(_ context: UIContext) -> Void {
    (self.value, self.dependencies) = DependencyTracker.track(self.compute)

    self.subscribe(context)
    self.apply(self.value, context)
  }

  private func subscribe(_ context: UIContext) -> Void {
    self.deactivate()
    self.subscriptions = self.dependencies.map { $0.observe { [weak self] in self?.run(context) } }
  }
}
