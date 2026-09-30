import MetalKit

/// A window's frame state: its input, its `UIContext` and its `Graphics2D`, sized to the view.
/// Lives on the window's thread, like everything it holds. See `RootViewRenderer`.
open class ViewRenderer: NSObject {
  public let input = Input()
  public var graphics2D: Graphics2D?
  public let uiContext: UIContext = .init()
  /// The view's size in points: what the next frame lays out in.
  public private(set) var windowSize = float2()

  /// Where `time` comes from: the wall clock, or a fake one a headless window steps by hand.
  public var clock: () -> Double = CFAbsoluteTimeGetCurrent
  private var lastTime: Double?
  public var deltaTime: Float = 0
  public var time: Float = 0

  public func updateTime() {
    let currentTime = self.clock()
    self.deltaTime = Float(currentTime - (self.lastTime ?? currentTime))
    self.time += self.deltaTime
    self.lastTime = currentTime
  }

  override public init() {
    super.init()
  }

  open func start() {}

  /// Called after InjectionNext injects edited Swift code (Debug only). The retained tree was
  /// built by the old code, so a subclass rebuilds it here for the new code to take effect.
  open func hotReload() {}

  /// The view is now `size` points.
  open func resize(to size: float2) {
    self.windowSize = size
    self.input.windowSize = size
    self.uiContext.resizeHitGrid(for: size)
    self.resizeRenderGrid(for: size)
  }

  /// The render grid covers the window: see `Graphics2D.fitGrid(to:)`. Also run once more after
  /// `start()`, when `graphics2D` first exists.
  func resizeRenderGrid(for windowSize: float2) {
    self.graphics2D?.fitGrid(to: windowSize)
  }
}

/// Every open window, weakly, by its handle: what hot reload rebuilds and what a shader reload
/// swaps pipelines in, each on the window's own thread. A window joins when its view is made and
/// leaves when it closes.
@MainActor public enum WindowRegistry {
  private struct Entry {
    weak var handle: WindowHandle?
    weak var view: RetainedLayerView?
  }

  private static var entries: [Entry] = []
  private static var observesTermination = false

  public static var live: [WindowHandle] {
    entries.compactMap(\.handle)
  }

  /// The view showing the window `handle` runs, while it is open.
  static func view(for handle: WindowHandle) -> RetainedLayerView? {
    entries.first { $0.handle === handle }?.view
  }

  public static func add(_ handle: WindowHandle, view: RetainedLayerView? = nil) {
    entries.removeAll { $0.handle == nil || $0.handle === handle }
    entries.append(Entry(handle: handle, view: view))
    if !observesTermination {
      observesTermination = true
      // Each window unmounts on its own thread, and the app waits a moment for them.
      NotificationCenter.default.addObserver(
        forName: NSApplication.willTerminateNotification, object: nil, queue: .main
      ) { _ in
        MainActor.assumeIsolated {
          // A presentation's window is closed with the window whose thread it runs on.
          let handles = WindowRegistry.live.filter { $0.parent == nil }
          handles.forEach { $0.close() }
          for handle in handles {
            handle.thread?.waitUntilFinished(timeout: 0.5)
          }
          // After the trees unmounted: panels save their last values as they go.
          DockSpace.saveAllNow()
        }
      }
    }
  }

  public static func remove(_ handle: WindowHandle) {
    entries.removeAll { $0.handle == nil || $0.handle === handle }
  }
}
