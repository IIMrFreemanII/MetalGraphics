import MetalKit

/// One window's renderer: owns the retained tree built by `root` and runs its frames, on the
/// window's own `WindowThread`. Made by `RetainedView`, once per window, on that thread.
///
/// Frames come from a display link on the thread's run loop, with the view's drawable. A window
/// with nothing to draw — nothing invalidated, nothing animating — pauses it, and anything posted
/// to the thread (an input event, a shared model's write, a resize) resumes it: an idle window
/// costs nothing, not even a wakeup per display refresh.
open class RootViewRenderer: ViewRenderer, CAMetalDisplayLinkDelegate {
  public let root = Frame(float2())
  public let scene: WindowScene
  private let makeRoot: @Sendable (WindowScene) -> UIElement
  /// The view's layer. Released on the main thread when the window closes.
  private var layer: CAMetalLayer?
  private var displayLink: CAMetalDisplayLink?
  private weak var handle: WindowHandle?
  /// Where the handle's events are swapped out to at the start of a frame; reused.
  private var events: [InputEvent] = []
  private var isOccluded = false
  /// The cursor the frame last asked for, and who shows it: the view, on the main thread.
  private var pointerStyle = PointerStyle.default
  private let showPointerStyle: @Sendable (PointerStyle) -> Void

  public init(
    scene: WindowScene, layer: CAMetalLayer,
    root: @escaping @Sendable (WindowScene) -> UIElement,
    showPointerStyle: @escaping @Sendable (PointerStyle) -> Void
  ) {
    self.scene = scene
    self.layer = layer
    self.makeRoot = root
    self.showPointerStyle = showPointerStyle
    super.init()
  }

  /// Builds the tree and starts the frames. On the window's thread, once.
  func start(handle: WindowHandle) {
    self.handle = handle
    let graphics = Graphics2D()
    graphics.profiler.label = "\(self.scene.sceneID) \(self.scene.id.uuidString.prefix(4))"
    self.graphics2D = graphics
    self.uiContext.scene = self.scene
    self.root.mounted = true
    self.scene.storage.holdsChanges = true
    self.root.setChild(self.makeRoot(self.scene), self.uiContext)
    self.scene.storage.holdsChanges = false
    self.resizeRenderGrid(for: self.windowSize)

    if let layer = self.layer {
      let link = CAMetalDisplayLink(metalLayer: layer)
      // As MTKView drew: 60 frames a second.
      link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
      link.delegate = self
      link.add(to: .current, forMode: .common)
      self.displayLink = link
    }
    handle.thread.executor.didDrain = { [weak self] in self?.resume() }
    self.start()
  }

  // New code only runs in a fresh tree; the root reopens what it stored in the scene.
  override open func hotReload() {
    self.rebuild()
  }

  /// Replaces the tree with a new one from `root`, which reads the scene's storage afresh.
  public func rebuild() {
    self.root.setChild(self.makeRoot(self.scene), self.uiContext)
    self.resume()
  }

  /// The window's `@SceneStorage` as SwiftUI restored it. SwiftUI restores a window's scene
  /// storage only after its view is made, so a restored window's tree was first built from the
  /// fallback values: when the restored ones differ, the tree is rebuilt from them, once.
  func restoreStorage(_ persisted: String) {
    guard self.scene.storage.encoded != persisted else { return }
    self.scene.storage.restore(from: persisted)
    self.rebuild()
  }

  /// The view is `size` points, `scale` pixels each.
  func resize(to size: float2, scale: Float) {
    self.resize(to: size)
    if let layer = self.layer {
      // Off the main thread a layer's changes need a transaction of their own.
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      layer.drawableSize = CGSize(width: CGFloat(size.x * scale), height: CGFloat(size.y * scale))
      CATransaction.commit()
    }
    self.resume()
  }

  /// A hidden window (minimized, fully covered, on another Space) stops drawing. Invalidations
  /// made meanwhile — a shared model written from another window — stay pending, and its first
  /// frame back draws them.
  func setOccluded(_ occluded: Bool) {
    self.isOccluded = occluded
    if occluded {
      self.displayLink?.isPaused = true
    } else {
      self.resume()
    }
  }

  private func resume() {
    guard !self.isOccluded else { return }
    self.displayLink?.isPaused = false
  }

  /// The window closed. Unmounting the tree unsubscribes it from shared models and frees the
  /// context's registries; the frames stop, and the layer goes back to the main thread.
  func teardown() {
    self.displayLink?.invalidate()
    self.displayLink = nil
    self.root.handleUnmount(self.uiContext)
    self.graphics2D = nil
    nonisolated(unsafe) let layer = self.layer
    self.layer = nil
    DispatchQueue.main.async { _ = layer }
  }

  public func metalDisplayLink(_ link: CAMetalDisplayLink, needsUpdate update: CAMetalDisplayLink.Update) {
    self.frame(drawable: update.drawable)
  }

  /// One frame: the input that arrived since the last, update, then draw if anything changed.
  func frame(drawable: CAMetalDrawable?) {
    // Nothing is laid out before the view's size arrives: at no size, a scroll view would
    // clamp its offset to content it cannot show, and keep it once the window has its size.
    guard let graphics = self.graphics2D, self.windowSize.x > 0, self.windowSize.y > 0 else {
      return
    }
    self.updateTime()
    self.handle?.takeEvents(into: &self.events)
    for event in self.events {
      self.input.apply(event)
    }
    self.events.removeAll(keepingCapacity: true)

    let profiler = graphics.profiler
    let updateStart = profiler.start()
    self.uiContext.update(root: self.root, size: self.windowSize, input: self.input, graphics: graphics)
    profiler.add(.update, since: updateStart)
    // The cursor is the main thread's: sent only when it changes.
    if self.uiContext.pointerStyle != self.pointerStyle {
      self.pointerStyle = self.uiContext.pointerStyle
      self.showPointerStyle(self.pointerStyle)
    }

    // Nothing changed since the last frame, so there is nothing new to present: the layer keeps
    // showing the last drawable. A running animation keeps `needsRender` set every frame.
    //
    // The input's per-frame state (clicks, deltas, keys) is reset at the end of every frame,
    // drawn or not, or a click would still read as pressed on every frame after it.
    //
    // The redrawn-area tint (`showDamage`) fades over a few frames after the last change, so
    // those frames are presented even though nothing changed.
    if self.uiContext.needsRender || graphics.needsDamageFrames {
      graphics.time = self.time
      graphics.context(in: FrameTarget(drawable: drawable)) { _ in
        let renderStart = profiler.start()
        self.uiContext.render(root: self.root, graphics)
        profiler.add(.uiRender, since: renderStart)
      }
    }
    self.input.endFrame()

    if self.uiContext.isIdle, !graphics.needsDamageFrames, self.handle?.hasEvents != true {
      self.displayLink?.isPaused = true
    }
  }
}
