import Combine

// An array that reports structural changes. Reading `collection` inside a builder records it
// as a dependency, like `State`; the lists subscribe to `observeChanges` for incremental updates.
@MainActor
public final class ObservableCollection<T : Identifiable> : TrackableState {
  public enum Change {
    case insert(T, Int)
    case remove(T, Int)
    case replaceAll([T])
  }

  private var handlers: [UUID : (Change) -> Void] = [:]
  private var storage: [T]

  // Untracked access, mirrors `State.value`.
  public var items: [T] {
    self.storage
  }

  // Tracked access; reading it inside a `@UIElementBuilder` closure re-runs that builder
  // when the collection changes. Assigning replaces the whole collection.
  public var collection: [T] {
    get {
      DependencyTracker.record(self)
      return self.storage
    }
    set { self.replaceAll(newValue) }
  }

  public init(_ collection: [T]) {
    self.storage = collection
  }

  public func insert(_ element: T, at index: Int) {
    let index = index.clamped(to: 0 ... self.storage.count)
    self.storage.insert(element, at: index)
    self.send(.insert(element, index))
  }

  public func append(_ element: T) {
    self.insert(element, at: self.storage.count)
  }

  public func remove(at index: Int) {
    guard self.storage.indices.contains(index) else { return }

    let removed = self.storage.remove(at: index)
    self.send(.remove(removed, index))
  }

  public func remove(with id: T.ID) {
    guard let index = self.storage.firstIndex(where: { $0.id == id }) else { return }

    self.remove(at: index)
  }

  public func replaceAll(_ elements: [T]) {
    self.storage = elements
    self.send(.replaceAll(elements))
  }

  // Any change, without the payload; this is what makes the collection a builder dependency.
  public func observe(_ action: @escaping () -> Void) -> AnyCancellable {
    self.observeChanges { _ in action() }
  }

  public func observeChanges(_ action: @escaping (Change) -> Void) -> AnyCancellable {
    let id = UUID()
    self.handlers[id] = action

    return AnyCancellable { [weak self] in
      MainActor.assumeIsolated {
        _ = self?.handlers.removeValue(forKey: id)
      }
    }
  }

  private func send(_ change: Change) {
    self.handlers.values.forEach { $0(change) }
  }
}
