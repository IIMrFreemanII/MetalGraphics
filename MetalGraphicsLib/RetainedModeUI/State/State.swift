import Combine

// A state whose reads can be recorded by `DependencyTracker`.
@MainActor
public protocol TrackableState : AnyObject {
  func observe(_ action: @escaping () -> Void) -> AnyCancellable
}

// Records which states are read (via `wrappedValue`) while a builder closure runs.
// Trackers form a stack, so nested containers only record reads of their own closure.
@MainActor
public final class DependencyTracker {
  private static var stack: [DependencyTracker] = []

  private var states: [ObjectIdentifier : TrackableState] = [:]

  static func record(_ state: TrackableState) {
    stack.last?.states[ObjectIdentifier(state)] = state
  }

  static func track<R>(_ body: () -> R) -> (R, [TrackableState]) {
    let tracker = DependencyTracker()
    stack.append(tracker)
    defer { stack.removeLast() }
    let result = body()
    return (result, Array(tracker.states.values))
  }

  // Runs `body` without recording its reads into an enclosing tracker.
  static func untracked<R>(_ body: () -> R) -> R {
    track(body).0
  }
}

@MainActor
@propertyWrapper
public final class State<T> : TrackableState {
  private var handlers: [UUID : () -> Void] = [:]

  // Untracked access; reading it inside a builder does not trigger rebuilds.
  public var value: T {
    didSet {
      self.handlers.values.forEach { $0() }
    }
  }

  // Tracked access; reading it inside a `@UIElementBuilder` closure (e.g. `if isLoggedIn`)
  // makes the owning container re-evaluate that closure when the value changes.
  public var wrappedValue: T {
    get {
      DependencyTracker.record(self)
      return self.value
    }
    set { self.value = newValue }
  }

  public var projectedValue: State<T> {
    self
  }

  public init(wrappedValue: T) {
    self.value = wrappedValue
  }

  public convenience init(_ value: T) {
    self.init(wrappedValue: value)
  }

  public func observe(_ action: @escaping () -> Void) -> AnyCancellable {
    let id = UUID()
    self.handlers[id] = action
    return AnyCancellable { [weak self] in
      MainActor.assumeIsolated {
        _ = self?.handlers.removeValue(forKey: id)
      }
    }
  }
}
