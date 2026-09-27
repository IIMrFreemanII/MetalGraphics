import Foundation
import simd

/// The whole app, in memory: its windows, their trees and frames, what they ask of the main
/// thread, and their storage, with no `NSWindow`, no view, no display link and no real time.
/// For end-to-end tests of the app's own scenes, which run the same trees and the same frame
/// code (`RootViewRenderer.runFrame`) as the app, fed the same `InputEvent`s its views send.
///
///     let app = HeadlessApp(scenes: AppScenes.all)
///     app.launch()                                  // the first window group, as SwiftUI opens
///     let main = app.window("main")!
///     try main.tap("Form")
///     try main.type("Ada", into: "Name")
///     XCTAssertTrue(main.shows("Hello, Ada"))
///     app.relaunch { AppScenes.resetForTesting() }  // reopens every window from its storage
///
/// **Deterministic.** Every window runs on the thread that made the app (the test's), one after
/// another, in the order they opened, and nothing happens between steps: time is a fake clock
/// that only `step` moves. What a window's thread would post to another — a shared `@Model`'s
/// write, a dock area's drop — waits in that window's mailbox, and runs before its next frame;
/// what one asks of the main thread — `openWindow(id:)`, a dock window request — waits in the
/// app's, and runs at the start and end of each step. Before running a window's work, the app
/// makes the window's mailbox the thread's executor (`ThreadState.executor`), which is how a
/// model or a dock space tells windows apart; between steps, the test's code runs as the main
/// thread.
///
/// **Isolated.** `UIStorage` and dock layouts go to a private, empty `UserDefaults` suite for the
/// app's life; a relaunch keeps it, and `close()` deletes it.
///
/// One app at a time: it swaps process-wide hooks (`Windows`, `MainQueue`, `UIStorage.defaults`)
/// while it lives. Call `close()` when done; a new app closes one left open.
///
/// Not simulated: `NSEvent` translation, real threads and their races (see `WindowThreadTests`),
/// SwiftUI menus and commands (call `open(id:)`), the pasteboard a copy writes to.
@MainActor public final class HeadlessApp {
  /// The windows the app can open.
  public let scenes: [RetainedScene]
  /// The screen the windows sit on, in points from its top left.
  public let screenSize: float2
  public let pixelsPerPoint: Float

  /// Open windows, in the order they opened: the order they step in.
  public private(set) var windows: [HeadlessWindow] = []
  /// The window with the keyboard: the last opened, clicked or `makeKey`ed.
  public private(set) weak var keyWindow: HeadlessWindow?
  /// Frames stepped.
  public private(set) var frames = 0

  /// Seconds on the fake clock; starts at 0.
  public var now: Double { self.clock.now }
  let clock = HeadlessClock()
  /// The main thread's mailbox.
  let mainExecutor = WindowExecutor()
  /// Visible windows, front to back.
  private(set) var zOrder: [HeadlessWindow] = []
  var docking: [HeadlessDockWindows] = []
  /// What a window pressed by the mouse is doing: set between its `mouseDown` and `mouseUp`.
  weak var pressedWindow: HeadlessWindow?
  /// Where the pointer last was on the screen.
  var screenPointer = float2()
  var dockDrag: HeadlessDockWindows.Drag?
  /// Opens presentations' windows, while the app lives.
  private(set) var presentedWindows: HeadlessPresentedWindows?

  private let defaults: UserDefaults
  private let suiteName: String
  private var saved: Saved?
  private var isClosed = false
  /// Scene storage for the windows `relaunch` reopens, by scene, oldest first.
  private var restoring: [String: [String]] = [:]

  private static weak var live: HeadlessApp?

  /// What the app swapped out, put back by `close()`.
  private struct Saved {
    let executor: ThreadExecutor
    let defaults: UserDefaults
    let opener: (@MainActor (String) -> Void)?
    let post: @Sendable (@escaping @Sendable () -> Void) -> Void
    let presentedWindows: any PresentedWindowHost
  }

  public init(scenes: [RetainedScene], screenSize: float2 = float2(1440, 900), pixelsPerPoint: Float = 2) {
    precondition(Thread.isMainThread, "A HeadlessApp runs on the main thread, as the app's main thread does")
    Self.live?.close()
    self.scenes = scenes
    self.screenSize = screenSize
    self.pixelsPerPoint = pixelsPerPoint
    self.suiteName = "MetalGraphics.HeadlessApp.\(UUID().uuidString)"
    self.defaults = UserDefaults(suiteName: self.suiteName)!

    let state = ThreadState.current
    let mainExecutor = self.mainExecutor
    self.saved = Saved(
      executor: state.executor, defaults: UIStorage.defaults,
      opener: Windows.setOpener { [weak self] id in self?.open(id: id) },
      post: MainQueue.post,
      presentedWindows: PresentedWindows.host
    )
    state.executor = mainExecutor
    UIStorage.defaults = self.defaults
    MainQueue.post = { work in mainExecutor.post(work) }
    let presented = HeadlessPresentedWindows(app: self)
    self.presentedWindows = presented
    PresentedWindows.host = presented
    Self.live = self
  }

  /// Closes every window and puts back what the app swapped out. Idempotent.
  public func close() {
    guard !self.isClosed else { return }
    // Presentations' windows go with their trees, without asking their bindings.
    for window in self.windows.reversed() where window.presentation != nil {
      window.close(quitting: true)
    }
    for window in self.windows.reversed() {
      window.close()
    }
    for docking in self.docking {
      docking.stop()
    }
    self.docking.removeAll()
    self.pumpMain()
    DockSpace.saveAllNow()
    self.isClosed = true
    if let saved = self.saved {
      ThreadState.current.executor = saved.executor
      UIStorage.defaults = saved.defaults
      Windows.setOpener(saved.opener)
      MainQueue.post = saved.post
      PresentedWindows.host = saved.presentedWindows
    }
    self.presentedWindows = nil
    self.saved = nil
    self.defaults.removePersistentDomain(forName: self.suiteName)
    if Self.live === self { Self.live = nil }
  }

  // MARK: - Windows

  /// Opens the first window group, as SwiftUI does at launch, and steps its first frame.
  @discardableResult
  public func launch() -> HeadlessWindow? {
    guard let scene = self.scenes.first(where: { $0.kind == .group }) ?? self.scenes.first else { return nil }
    let window = self.open(id: scene.id)
    self.step()
    return window
  }

  /// Opens a window of the scene declared with `id`, as `openWindow(id:)` does — or brings a
  /// `.single` one that is open to the front — and makes it key. Its first frame is the next
  /// step's.
  @discardableResult
  public func open(id: String) -> HeadlessWindow {
    guard let scene = self.scenes.first(where: { $0.id == id }) else {
      preconditionFailure("HeadlessApp.open(id: \"\(id)\"): no scene declares it; the scenes are \(self.scenes.map(\.id))")
    }
    if scene.kind == .single, let open = self.windows.first(where: { $0.sceneID == id }) {
      open.show()
      self.makeKey(open)
      return open
    }
    let restoring = self.restoring[id]?.isEmpty == false ? self.restoring[id]!.removeFirst() : ""
    let window = HeadlessWindow(
      app: self, sceneID: id, title: scene.title, size: float2(Float(scene.defaultSize.width), Float(scene.defaultSize.height)),
      origin: self.cascadeOrigin(), restoring: restoring, root: scene.root
    )
    self.add(window)
    return window
  }

  /// A window made for `root`, not one the app declared: a dock window's.
  func openWindow(
    sceneID: String, title: String, size: float2, origin: float2, visible: Bool,
    root: @escaping @Sendable (WindowScene) -> UIElement
  ) -> HeadlessWindow {
    let window = HeadlessWindow(
      app: self, sceneID: sceneID, title: title, size: size, origin: origin, restoring: "", root: root
    )
    window.isVisible = visible
    self.add(window)
    return window
  }

  /// A presentation's window, opened over the one it was presented from.
  func addPresented(_ window: HeadlessWindow) {
    self.add(window)
  }

  /// The open presentation shown last from `window`, if any.
  public func presentation(over window: HeadlessWindow) -> HeadlessWindow? {
    self.windows.last { $0.isOpen && $0.presentation?.parent === window }
  }

  /// The presentation shown over `window`, and over that, and so on: the one on top. Nil when
  /// none is.
  func topPresentation(over window: HeadlessWindow) -> HeadlessWindow? {
    var top: HeadlessWindow? = nil
    var current = window
    while let next = self.presentation(over: current) {
      top = next
      current = next
    }
    return top
  }

  private func add(_ window: HeadlessWindow) {
    self.windows.append(window)
    if window.isVisible {
      self.zOrder.insert(window, at: 0)
      self.makeKey(window)
    }
  }

  /// Where a new window goes: down and right of the last, as AppKit cascades them.
  private func cascadeOrigin() -> float2 {
    let step = Float(self.windows.count % 12) * 24
    return float2(40 + step, 40 + step)
  }

  /// The `index`th open window of scene `sceneID`, in the order they opened.
  public func window(_ sceneID: String, index: Int = 0) -> HeadlessWindow? {
    let matching = self.windows.filter { $0.sceneID == sceneID }
    return index < matching.count ? matching[index] : nil
  }

  /// Gives `window` the keyboard, and brings it to the front: the key window before it resigns,
  /// as `RetainedLayerView`'s window observers report.
  public func makeKey(_ window: HeadlessWindow) {
    self.bringToFront(window)
    guard self.keyWindow !== window else { return }
    // A popover's window goes when the keyboard moves to a window not shown over it.
    if let popover = self.keyWindow, popover.presentation?.kind == .popover, !self.isShown(window, over: popover) {
      PresentedWindows.send(.resignedKey, to: popover.handle)
    }
    self.keyWindow?.handle.send(.resignKey)
    self.keyWindow = window
    window.handle.send(.becomeKey(pointer: window.pointer))
  }

  func bringToFront(_ window: HeadlessWindow) {
    guard window.isVisible else { return }
    self.zOrder.removeAll { $0 === window }
    self.zOrder.insert(window, at: 0)
  }

  func didHide(_ window: HeadlessWindow) {
    self.zOrder.removeAll { $0 === window }
    if self.keyWindow === window {
      window.handle.send(.resignKey)
      self.keyWindow = nil
      if let next = self.zOrder.first { self.makeKey(next) }
    }
  }

  func didClose(_ window: HeadlessWindow) {
    // The keyboard goes back to the window a presentation was shown from.
    if let parent = window.presentation?.parent, self.keyWindow === window, parent.isOpen, parent.isVisible {
      self.zOrder.removeAll { $0 === window }
      self.windows.removeAll { $0 === window }
      window.handle.send(.resignKey)
      self.keyWindow = nil
      self.makeKey(parent)
      return
    }
    self.didHide(window)
    self.windows.removeAll { $0 === window }
  }

  /// Whether `window` was presented from `base`, or from something presented from it.
  private func isShown(_ window: HeadlessWindow, over base: HeadlessWindow) -> Bool {
    var current = window.presentation?.parent
    while let presenter = current {
      if presenter === base { return true }
      current = presenter.presentation?.parent
    }
    return false
  }

  /// The visible window whose frame holds `point` (screen), front to back, skipping `except`.
  func window(at point: float2, except: HeadlessWindow? = nil) -> HeadlessWindow? {
    self.zOrder.first { $0 !== except && $0.frame.contains(point) }
  }

  // MARK: - Docking

  /// Opens and closes `space`'s detached windows from now on, as `DockWindows.manage` does in
  /// the app: tearing a panel out of a window opens one here, and dropping it back closes it.
  /// Once per space.
  public func manageDocking(_ space: DockSpace) {
    guard !self.docking.contains(where: { $0.space === space }) else { return }
    self.docking.append(HeadlessDockWindows(app: self, space: space))
  }

  // MARK: - Frames

  /// One frame of every window: advances the clock by `dt`, runs what was posted to the main
  /// thread, then each window, in the order they opened, runs what was posted to it and its
  /// frame; then the main thread's again, so a window a handler opened exists after the step.
  public func step(_ dt: Double = 1.0 / 60) {
    self.clock.now += dt
    self.frames += 1
    self.pumpMain()
    for window in self.windows where window.isOpen {
      window.runFrame()
    }
    self.pumpMain()
  }

  public func step(frames count: Int, _ dt: Double = 1.0 / 60) {
    for _ in 0 ..< count { self.step(dt) }
  }

  /// Steps `seconds` of fake time at 60 frames per second.
  public func advance(_ seconds: Double) {
    self.step(frames: max(1, Int((seconds * 60).rounded(.up))))
  }

  /// Steps until no window has anything to do — nothing animating, nothing to draw, nothing
  /// posted — and the main thread has nothing waiting. Returns the frames it took, or nil if
  /// something was still busy after `maxFrames`.
  @discardableResult
  public func settle(maxFrames: Int = 600) -> Int? {
    for i in 0 ..< maxFrames {
      if self.isIdle { return i }
      self.step()
    }
    return self.isIdle ? maxFrames : nil
  }

  public var isIdle: Bool {
    !self.mainExecutor.hasPending && self.windows.allSatisfy(\.isIdle)
  }

  /// Runs what was posted to the main thread, as the main queue would, until none is left.
  func pumpMain() {
    var turns = 0
    while self.mainExecutor.runPending() {
      turns += 1
      precondition(turns < 10_000, "The main thread's work keeps posting more")
    }
  }

  // MARK: - Relaunch

  /// Quits and relaunches the app, in memory: every window closes as the app's do at quit (their
  /// trees unmount, dock layouts save), `prepare` runs — where the app makes afresh what a new
  /// process would, such as its statics — and the windows reopen in the same order, each from
  /// its own scene storage, as SwiftUI restores them. `UIStorage` and saved dock layouts carry
  /// over; a `@Model` in memory does not, unless `prepare` leaves it.
  ///
  /// Dock spaces are no longer managed after: `prepare` calls `manageDocking` for the new ones,
  /// as the app's launch does.
  public func relaunch(prepare: () -> Void = {}) {
    let declared = Set(self.scenes.map(\.id))
    let reopen = self.windows.filter { declared.contains($0.sceneID) }
    var restoring: [String: [String]] = [:]
    for window in reopen {
      restoring[window.sceneID, default: []].append(window.persisted)
    }
    let ids = reopen.map(\.sceneID)

    for window in self.windows.reversed() {
      window.close(quitting: true)
    }
    for docking in self.docking {
      docking.stop()
    }
    self.docking.removeAll()
    self.pumpMain()
    DockSpace.saveAllNow()

    prepare()
    self.restoring = restoring
    for id in ids {
      self.open(id: id)
    }
    self.restoring.removeAll()
    self.step()
  }
}

/// The fake clock every window of a `HeadlessApp` reads.
final class HeadlessClock: @unchecked Sendable {
  var now: Double = 0
}
