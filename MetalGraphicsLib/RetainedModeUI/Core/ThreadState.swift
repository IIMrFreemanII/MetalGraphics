import Foundation

/// What a layout or render pass keeps for its own duration, one per thread.
///
/// Every window runs its frame on a thread of its own (see `WindowThread`), so state that lives
/// for one pass — the text style pushed around a subtree, the viewport of the scroll views around
/// it, the animation of the writes being made — can't be a plain static: two windows would
/// overwrite each other's mid-pass. The statics that hold it (`TextScope.current`,
/// `LayoutPass.current`, `UITransaction.animation`, ...) read and write this instead.
///
/// Reaching it costs one `pthread_getspecific`: code that touches several fields in a row reads
/// `current` once.
public final class ThreadState {
  private static let key: pthread_key_t = {
    var key = pthread_key_t()
    let status = pthread_key_create(&key) { raw in
      Unmanaged<ThreadState>.fromOpaque(raw).release()
    }
    precondition(status == 0, "pthread_key_create failed: \(status)")
    return key
  }()

  /// This thread's state, made the first time a thread asks.
  public static var current: ThreadState {
    if let raw = pthread_getspecific(Self.key) {
      return Unmanaged<ThreadState>.fromOpaque(raw).takeUnretainedValue()
    }
    let state = ThreadState()
    pthread_setspecific(Self.key, Unmanaged.passRetained(state).toOpaque())
    return state
  }

  private init() {}

  /// Runs work on this thread: what another window posts to it, such as a shared model's write.
  /// A `WindowThread` sets its own; the main thread posts through the main queue.
  public internal(set) lazy var executor: ThreadExecutor =
    Thread.isMainThread ? MainThreadExecutor() : ThreadExecutor()

  // MARK: Layout

  /// See `LayoutPass.current`.
  var layoutPass: LayoutPass? = nil
  /// See `LayoutPass.generation`. Per thread: an element is only ever laid out on its window's.
  var layoutGeneration: UInt32 = 0

  // MARK: Text

  /// See `TextScope`.
  var textScope = TextEnvironment()
  var textDepth = 0
  /// The glyphs this thread has laid out, copied from `FontManager`'s shared cache.
  var glyphs: [GlyphKey: GlyphMetrics] = [:]
  /// Filled by each draw of a text whose runs differ in colour; never shrinks.
  var paintScratch: [TextRunPaint] = []

  // MARK: Scrolling

  /// See `LazyStackViewport`.
  var lazyViewport: ClipRect? = nil
  var inScrollView = false

  // MARK: Transactions

  /// See `UITransaction`.
  var transactionAnimation: UIAnimation? = nil
  var transactionGroup: AnimationGroup? = nil
}

/// Where work for one thread is posted from others: the thread a window's elements live on,
/// which only that thread may touch. `ThreadState.current.executor` is the current thread's, and
/// two executors are the same thread when they are the same object.
open class ThreadExecutor: @unchecked Sendable {
  public init() {}

  /// Runs `work` on this executor's thread, after what it is running now; never before
  /// returning. A thread without a run loop to run it on drops it.
  open func post(_ work: @escaping @Sendable () -> Void) {
    assertionFailure("posted to a thread that runs no posted work")
  }
}

/// The main thread's: work runs from the main queue.
final class MainThreadExecutor: ThreadExecutor, @unchecked Sendable {
  override func post(_ work: @escaping @Sendable () -> Void) {
    DispatchQueue.main.async(execute: work)
  }
}
