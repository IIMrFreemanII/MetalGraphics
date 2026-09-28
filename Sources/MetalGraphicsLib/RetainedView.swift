import MetalKit
import SwiftUI

/// A window's content: a Metal layer the window's own thread runs the retained tree `root` builds
/// in. One thread and renderer per window, made once and kept for the window's life however often
/// SwiftUI rebuilds this struct.
///
/// Usually reached through `RetainedWindowGroup` or `RetainedWindow` rather than directly.
public struct RetainedView: View {
  let sceneID: String
  let chrome: WindowChrome
  let root: @Sendable (WindowScene) -> UIElement

  /// Created once per window. Holds the window's handle but publishes nothing, so a resize or a
  /// frame never re-runs this body.
  @StateObject private var host = RetainedWindowHost()
  /// This window's `UISceneStorage`, saved and restored with the window by SwiftUI.
  @SceneStorage("MetalGraphics.UISceneStorage") private var persisted = ""
  @SwiftUI.Environment(\.openWindow) private var openWindowAction

  public init(sceneID: String, chrome: WindowChrome = .standard, root: @escaping @Sendable (WindowScene) -> UIElement) {
    self.sceneID = sceneID
    self.chrome = chrome
    self.root = root
  }

  public var body: some View {
    let view = RetainedMetalView(host: self.host, sceneID: self.sceneID, chrome: self.chrome, root: self.root, persisted: self.$persisted)
    Group {
      // A translucent window's content runs under its title bar, which the tree makes room for
      // (`TitleBarInsets`).
      if self.chrome == .translucent {
        view.ignoresSafeArea()
      } else {
        view
      }
    }
    .onAppear { Windows.register(self.openWindowAction) }
  }
}

@MainActor final class RetainedWindowHost: ObservableObject {
  var handle: WindowHandle?
  /// The window's `@SceneStorage`, refreshed on every update: the binding SwiftUI hands out
  /// belongs to the body that made it.
  var persist: SwiftUI.Binding<String>?
  /// What the window's `@SceneStorage` holds, as far as this window knows: the last value it
  /// saved, or the last it restored.
  private var known = ""
  /// Counts saves and restores, so a save still waiting to be written knows when a later one
  /// replaced it.
  private var generation = 0

  init() {}

  func start(restoring persisted: String) {
    self.known = persisted
  }

  /// The window's `UISceneStorage` changed, on its thread. Written once the current view update
  /// is over: SwiftUI drops a state write made during one.
  func save(_ encoded: String) {
    self.known = encoded
    self.generation += 1
    let generation = self.generation
    DispatchQueue.main.async { [weak self] in
      guard let self, self.generation == generation else { return }
      self.persist?.wrappedValue = encoded
    }
  }

  /// The window's `@SceneStorage` as SwiftUI has it now. SwiftUI restores a window's scene
  /// storage only after its view is made, so a restored window's tree was first built from the
  /// fallback values: the restored ones are handed to the window's thread, which rebuilds from
  /// them if they differ.
  func sync(_ persisted: String) {
    guard !persisted.isEmpty, persisted != self.known else { return }
    self.known = persisted
    self.generation += 1
    self.handle?.post { $0.restoreStorage(persisted) }
  }
}

struct RetainedMetalView: NSViewRepresentable {
  let host: RetainedWindowHost
  let sceneID: String
  let chrome: WindowChrome
  let root: @Sendable (WindowScene) -> UIElement
  let persisted: SwiftUI.Binding<String>

  final class Coordinator {
    let host: RetainedWindowHost
    init(host: RetainedWindowHost) { self.host = host }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(host: self.host)
  }

  func makeNSView(context: Context) -> RetainedLayerView {
    let host = self.host
    host.persist = self.persisted
    let restoring = self.persisted.wrappedValue
    host.start(restoring: restoring)

    let (view, handle) = RetainedWindowContent.make(
      sceneID: self.sceneID, chrome: self.chrome, root: self.root, restoring: restoring,
      // On the window's thread; SwiftUI is the main thread's.
      persist: { [weak host] encoded in
        DispatchQueue.main.async { MainActor.assumeIsolated { host?.save(encoded) } }
      }
    )
    host.handle = handle
    return view
  }

  func updateNSView(_ nsView: RetainedLayerView, context: Context) {
    self.host.persist = self.persisted
    self.host.sync(self.persisted.wrappedValue)
  }

  static func dismantleNSView(_ nsView: RetainedLayerView, coordinator: Coordinator) {
    if let handle = coordinator.host.handle {
      WindowRegistry.remove(handle)
      handle.close()
    }
    coordinator.host.handle = nil
  }
}

/// A window's content view and the thread its tree runs on: what `RetainedView` shows, and what
/// `DockWindows` puts in the windows it opens itself.
@MainActor enum RetainedWindowContent {
  static func make(
    sceneID: String, chrome: WindowChrome = .standard, root: @escaping @Sendable (WindowScene) -> UIElement,
    restoring: String = "", persist: (@Sendable (String) -> Void)? = nil
  ) -> (RetainedLayerView, WindowHandle) {
    AppearanceObserver.startIfNeeded()
    let handle = WindowHandle(name: "Window \(sceneID)")
    let view = RetainedLayerView(handle: handle, chrome: chrome)
    WindowRegistry.add(handle, view: view)

    nonisolated(unsafe) let layer = view.metalLayer
    // On the window's thread; the cursor is the main thread's.
    let showPointerStyle: @Sendable (PointerStyle) -> Void = { [weak view] style in
      DispatchQueue.main.async { MainActor.assumeIsolated { view?.pointerStyle = style } }
    }
    // The input method's answers come from the view, on the main thread, from what this sends.
    let showTextInput: @Sendable (TextInputSnapshot) -> Void = { [weak view] snapshot in
      DispatchQueue.main.async { MainActor.assumeIsolated { view?.textInputChanged(snapshot) } }
    }
    handle.start(
      sceneID: sceneID, root: root, restoring: restoring, persist: persist, layer: layer,
      showPointerStyle: showPointerStyle, showTextInput: showTextInput
    )
    if chrome == .translucent {
      handle.post { $0.setBackground(.clear) }
    }
#if DEBUG
    HotReload.startIfNeeded()
#endif
    return (view, handle)
  }
}

extension WindowHandle {
  /// Makes the window's scene, its storage and its renderer, on its thread, and builds its tree:
  /// what every window does, with a view (`RetainedWindowContent`) or without (`HeadlessApp`).
  func start(
    sceneID: String, root: @escaping @Sendable (WindowScene) -> UIElement,
    restoring: String, persist: (@Sendable (String) -> Void)?,
    layer: CAMetalLayer?, showPointerStyle: @escaping @Sendable (PointerStyle) -> Void,
    showTextInput: @escaping @Sendable (TextInputSnapshot) -> Void = { _ in },
    clock: (@Sendable () -> Double)? = nil
  ) {
    nonisolated(unsafe) let layer = layer
    self.start { [self] in
      let scene = WindowScene(sceneID: sceneID, storage: UISceneStorage(restoring: restoring, persist: persist), handle: self)
      let renderer = RootViewRenderer(
        scene: scene, layer: layer, root: root, showPointerStyle: showPointerStyle, showTextInput: showTextInput
      )
      // A fake one, from before the tree is built: what it starts animates on it too.
      if let clock {
        renderer.clock = clock
        renderer.uiContext.clock = clock
      }
      return renderer
    }
  }
}
