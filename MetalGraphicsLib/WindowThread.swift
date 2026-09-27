import Foundation

/// The thread one window runs on: its frames, its input, and whatever other threads post to it
/// (a shared model's write, a rebuild after hot reload). Every element of the window's tree, its
/// `UIContext` and its `Graphics2D` belong to it, and only it touches them.
///
/// The main thread never waits for one, and one never waits for the main thread: they only post
/// to each other.
public final class WindowThread: Thread, @unchecked Sendable {
  /// How work reaches this thread. `ThreadState.current.executor` on it.
  public let executor = WindowExecutor()
  private let ended = DispatchSemaphore(value: 0)

  public init(name: String) {
    super.init()
    self.name = name
    // Layout and render recurse down the tree; a secondary thread's default 512 KB is not much.
    self.stackSize = 8 << 20
    self.qualityOfService = .userInteractive
  }

  override public func main() {
    autoreleasepool {
      ThreadState.current.executor = self.executor
      self.executor.attach(to: CFRunLoopGetCurrent())
    }
    while !self.isCancelled {
      // Returns when stopped; each turn's autoreleased objects — drawables among them — are
      // released as it ends, which a secondary thread's run loop does not do by itself.
      autoreleasepool {
        _ = CFRunLoopRunInMode(.defaultMode, 60, false)
      }
    }
    self.ended.signal()
  }

  /// Runs `work` on this thread, then stops it: after `work`, nothing posted runs.
  public func stop(after work: @escaping @Sendable () -> Void = {}) {
    self.executor.post { [self] in
      work()
      self.executor.close()
      self.cancel()
      CFRunLoopStop(CFRunLoopGetCurrent())
    }
  }

  /// Waits for the thread to end after `stop`, at most `timeout` seconds. For quitting, and for
  /// tests; never from a window's frame.
  @discardableResult
  public func waitUntilFinished(timeout: TimeInterval) -> Bool {
    self.ended.wait(timeout: .now() + timeout) == .success
  }
}

/// A window thread's mailbox. Work posted from any thread is queued and runs on the window's
/// thread from its run loop, in the order it was posted.
public final class WindowExecutor: ThreadExecutor, @unchecked Sendable {
  private let lock = NSLock()
  private var mailbox: [@Sendable () -> Void] = []
  /// Swapped with `mailbox` to drain it, so a drain allocates nothing once both have grown.
  private var draining: [@Sendable () -> Void] = []
  private var isClosed = false
  private var runLoop: CFRunLoop?
  private var source: CFRunLoopSource?
  /// Runs on the thread after each drain: what the window does when work arrived, such as
  /// resuming frames it paused while idle.
  public var didDrain: (() -> Void)?

  override public init() {}

  /// Called once, on the thread, before its run loop starts.
  fileprivate func attach(to runLoop: CFRunLoop) {
    var context = CFRunLoopSourceContext()
    context.info = Unmanaged.passUnretained(self).toOpaque()
    context.perform = { info in
      Unmanaged<WindowExecutor>.fromOpaque(info!).takeUnretainedValue().drain()
    }
    let source = CFRunLoopSourceCreate(nil, 0, &context)!
    CFRunLoopAddSource(runLoop, source, .commonModes)
    let hasWork = self.lock.withLock {
      self.runLoop = runLoop
      self.source = source
      return !self.mailbox.isEmpty
    }
    // Posted before the thread started.
    if hasWork {
      CFRunLoopSourceSignal(source)
    }
  }

  override public func post(_ work: @escaping @Sendable () -> Void) {
    let target: (CFRunLoop, CFRunLoopSource)? = self.lock.withLock {
      guard !self.isClosed else { return nil }
      self.mailbox.append(work)
      guard let runLoop = self.runLoop, let source = self.source else { return nil }
      return (runLoop, source)
    }
    guard let (runLoop, source) = target else { return }
    CFRunLoopSourceSignal(source)
    CFRunLoopWakeUp(runLoop)
  }

  private func drain() {
    self.lock.withLock {
      swap(&self.mailbox, &self.draining)
    }
    for work in self.draining {
      autoreleasepool { work() }
    }
    self.draining.removeAll(keepingCapacity: true)
    self.didDrain?()
  }

  /// Drops what is queued, and everything posted from now on.
  fileprivate func close() {
    self.lock.withLock {
      self.isClosed = true
      self.mailbox.removeAll()
    }
    if let source = self.source {
      CFRunLoopSourceInvalidate(source)
    }
  }
}

/// What the main thread holds of a window whose frames run on a `WindowThread`: a way to send
/// it input and to post work to its renderer. The renderer, its tree and its `Graphics2D` are
/// made, used and released on the window's thread; the main thread never touches them.
public final class WindowHandle: @unchecked Sendable {
  public let thread: WindowThread
  private let lock = NSLock()
  private var events: [InputEvent] = []
  private var isClosed = false
  /// The window's thread's alone: set once the renderer is made there, cleared as it closes.
  fileprivate var renderer: RootViewRenderer?
  /// Posted after an event, so a window idling with its frames paused wakes for it. Made once:
  /// sending an event allocates nothing.
  private static let wake: @Sendable () -> Void = {}

  public init(name: String) {
    self.thread = WindowThread(name: name)
  }

  /// Starts the thread and makes the renderer on it.
  public func start(_ makeRenderer: @escaping @Sendable () -> RootViewRenderer) {
    self.thread.start()
    self.thread.executor.post { [self] in
      let renderer = makeRenderer()
      self.renderer = renderer
      renderer.start(handle: self)
    }
  }

  /// Queues `event` for the window's next frame.
  public func send(_ event: InputEvent) {
    let isOpen = self.lock.withLock {
      guard !self.isClosed else { return false }
      self.events.append(event)
      return true
    }
    if isOpen {
      self.thread.executor.post(Self.wake)
    }
  }

  /// The events sent since the last call, in order, swapped with `buffer`. On the window's
  /// thread, at the start of a frame.
  func takeEvents(into buffer: inout [InputEvent]) {
    self.lock.withLock {
      swap(&self.events, &buffer)
    }
  }

  var hasEvents: Bool {
    self.lock.withLock { !self.events.isEmpty }
  }

  /// Runs `work` with the window's renderer, on its thread. Dropped once the window closed.
  public func post(_ work: @escaping @Sendable (RootViewRenderer) -> Void) {
    self.thread.executor.post { [self] in
      guard let renderer = self.renderer else { return }
      work(renderer)
    }
  }

  /// The window closed: its tree unmounts and its thread ends, after whatever was posted before.
  public func close() {
    let wasOpen = self.lock.withLock {
      defer { self.isClosed = true }
      return !self.isClosed
    }
    guard wasOpen else { return }
    self.thread.stop { [self] in
      self.renderer?.teardown()
      self.renderer = nil
    }
  }
}
