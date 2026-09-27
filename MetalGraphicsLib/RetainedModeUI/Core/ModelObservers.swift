import Foundation
import Synchronization

/// The components reading one property of a `@Model`, in every window. `@Model` gives each
/// tracked property one of these, and one more for reads it cannot pin to a property (a computed
/// property, a method call).
///
/// A component subscribes on mount and unsubscribes on unmount, with a token naming which of its
/// update methods the property feeds. A write calls `__modelDidChange(token, _:)` on each, which
/// runs that component's generated setters against its own window's `UIContext`, so each window
/// invalidates only what the property feeds there, and draws it on its next frame.
///
/// Each window runs on a thread of its own, so the readers are kept per window, in lists only
/// that window's thread touches. A write updates the writer's own window right away; every other
/// window with readers gets one message posted to its thread, carrying the writer's animation,
/// and updates its readers there on its next turn. Writes made before that message runs are one
/// delivery: the readers read the model's current values, and the last write's animation wins.
///
/// Mount and unmount are the only times it allocates, and only to grow; a write walks the lists
/// and posts at most one message per other window.
public final class ModelObservers: @unchecked Sendable {
  /// One window's readers. `entries` and `compactAt` are its thread's alone; other threads only
  /// flag it as pending and hand it an animation.
  private final class Window: @unchecked Sendable {
    struct Entry {
      // Weak so a window whose tree is freed without unmounting cannot keep it alive, or crash.
      weak var element: UIElement?
      let token: Int
    }

    let executor: ThreadExecutor
    var entries: [Entry] = []
    /// When `add` next drops entries whose element was freed without unmounting. Doubles each
    /// time, so compaction stays amortized O(1) per add.
    var compactAt = 16
    /// Set while a delivery is posted and has not started: later writes ride along.
    let isPending = Atomic<Bool>(false)
    /// The animation of the last write the pending delivery carries.
    let animation = Mutex<UIAnimation?>(nil)

    init(executor: ThreadExecutor) {
      self.executor = executor
    }

    func run() {
      guard !self.entries.isEmpty else { return }
      // A reader may mount or unmount others as it updates (a branch swap), which edits this
      // list. Iterating a copy keeps that legal: the copy is a retain until the list is edited.
      // One that unmounts mid-walk is still called and finds no context; one that mounts built
      // from the current value already.
      let snapshot = self.entries
      for entry in snapshot {
        entry.element?.__modelDidChange(entry.token, true)
      }
    }

    /// From another thread: has this window's thread update its readers.
    func schedule(_ animation: UIAnimation?) {
      self.animation.withLock { $0 = animation }
      guard !self.isPending.exchange(true, ordering: .acquiringAndReleasing) else { return }
      self.executor.post { [self] in
        // Cleared before the readers run, so a write they race with posts again rather than
        // being taken for delivered.
        self.isPending.store(false, ordering: .releasing)
        let animation = self.animation.withLock { $0 }
        withAnimation(animation) { self.run() }
      }
    }
  }

  /// Guards `windows` itself; each window's list is its own thread's.
  private let lock = NSLock()
  private var windows: [Window] = []

  public init() {}

  /// The current thread's list, made when first needed.
  private func ownWindow(creating: Bool) -> Window? {
    let executor = ThreadState.current.executor
    return self.lock.withLock {
      if let window = self.windows.first(where: { $0.executor === executor }) {
        return window
      }
      guard creating else { return nil }
      let window = Window(executor: executor)
      self.windows.append(window)
      return window
    }
  }

  /// Subscribes `element`, on its window's thread.
  public func add(_ element: UIElement, token: Int) {
    guard let window = self.ownWindow(creating: true) else { return }
    if window.entries.count >= window.compactAt {
      window.entries.removeAll { $0.element == nil }
      window.compactAt = Swift.max(16, window.entries.count * 2)
    }
    window.entries.append(Window.Entry(element: element, token: token))
  }

  /// Every subscription of `element`, on its window's thread: a component can read several
  /// properties that share this list.
  public func remove(_ element: UIElement) {
    guard let window = self.ownWindow(creating: false) else { return }
    window.entries.removeAll { $0.element === element || $0.element == nil }
    if window.entries.isEmpty {
      // A delivery still posted to it finds nothing to run.
      self.lock.withLock { self.windows.removeAll { $0 === window } }
    }
  }

  /// Notifies this property's readers, then `other`'s: the model's list for reads of any
  /// property.
  public func notify(also other: ModelObservers) {
    let state = ThreadState.current
    self.notifyOwn(from: state.executor, animation: state.transactionAnimation)
    other.notifyOwn(from: state.executor, animation: state.transactionAnimation)
  }

  /// Notifies this list's readers alone: for a shared object that keeps one list, such as a
  /// `DockSpace`.
  public func notify() {
    let state = ThreadState.current
    self.notifyOwn(from: state.executor, animation: state.transactionAnimation)
  }

  private func notifyOwn(from executor: ThreadExecutor, animation: UIAnimation?) {
    let windows = self.lock.withLock { self.windows }
    for window in windows {
      if window.executor === executor {
        window.run()
      } else {
        window.schedule(animation)
      }
    }
  }

  /// Live subscriptions in every window. For tests, which run every window on one thread.
  var count: Int {
    self.lock.withLock { self.windows }.reduce(0) { total, window in
      total + window.entries.count { $0.element != nil }
    }
  }

  /// Whether a write changed the value. Used by `@Model`'s setters so writing the same value
  /// again touches no window; a type that is not `Equatable` always counts as changed.
  @inline(__always)
  public static func changed<T: Equatable>(_ old: T, _ new: T) -> Bool {
    old != new
  }

  @inline(__always)
  public static func changed<T>(_ old: T, _ new: T) -> Bool {
    true
  }
}

/// The lock `@Model` puts around a model's tracked storage: each window reads and writes the
/// model from its own thread. Recursive, so a `_modify` body can read the model it modifies.
/// A model's readers are notified after it is released.
public final class ModelLock: @unchecked Sendable {
  private let mutex: UnsafeMutablePointer<pthread_mutex_t>

  public init() {
    self.mutex = .allocate(capacity: 1)
    var attributes = pthread_mutexattr_t()
    pthread_mutexattr_init(&attributes)
    pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE)
    pthread_mutex_init(self.mutex, &attributes)
    pthread_mutexattr_destroy(&attributes)
  }

  deinit {
    pthread_mutex_destroy(self.mutex)
    self.mutex.deallocate()
  }

  @inline(__always)
  public func lock() {
    pthread_mutex_lock(self.mutex)
  }

  @inline(__always)
  public func unlock() {
    pthread_mutex_unlock(self.mutex)
  }
}

/// What `@Bindable let model: M` declares as `$model`: `$model.count` is a `Binding` to the
/// property. A `@Component` body never evaluates it — the macro lowers the spelling — so this
/// only runs when written outside a body, e.g. passed to a hand-built control.
@dynamicMemberLookup public struct ModelBindings<Model: AnyObject> {
  private let model: Model

  public init(_ model: Model) {
    self.model = model
  }

  public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Model, Value>) -> Binding<Value> {
    Binding(unowned: self.model, keyPath)
  }
}
