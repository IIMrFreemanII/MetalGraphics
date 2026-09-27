import SwiftUI

/// A kind of window whose content is a retained tree, as SwiftUI's `WindowGroup`: any number
/// can be open, and File ▸ New Window (⌘N) opens another of the first one declared.
///
///     RetainedWindowGroup("Demos", id: "main") { scene in Demos(scene: scene) }
///
/// `root` runs once per window, and again on every hot reload with the same `WindowScene`, on
/// the window's own thread.
public struct RetainedWindowGroup: Scene {
  let title: String
  let id: String
  let root: @Sendable (WindowScene) -> UIElement

  public init(_ title: String, id: String, root: @escaping @Sendable (WindowScene) -> UIElement) {
    self.title = title
    self.id = id
    self.root = root
  }

  public var body: some Scene {
    WindowGroup(self.title, id: self.id) {
      RetainedView(sceneID: self.id, root: self.root)
    }
  }
}

/// A single window whose content is a retained tree, as SwiftUI's `Window`: opening it again
/// brings the open one to the front.
public struct RetainedWindow: Scene {
  let title: String
  let id: String
  let root: @Sendable (WindowScene) -> UIElement

  public init(_ title: String, id: String, root: @escaping @Sendable (WindowScene) -> UIElement) {
    self.title = title
    self.id = id
    self.root = root
  }

  public var body: some Scene {
    Window(self.title, id: self.id) {
      RetainedView(sceneID: self.id, root: self.root)
    }
  }
}

/// One open window, as its tree sees it. Reached as `context.scene`, or passed to the root by
/// `RetainedWindowGroup`.
public final class WindowScene {
  /// The id of the scene declaration this window was opened from: "main", "shared".
  public let sceneID: String
  /// This window, among others opened from the same declaration.
  public let id = UUID()
  /// Values this window keeps for itself across hot reloads and relaunches.
  public let storage: UISceneStorage
  /// What the main thread holds of this window: how the tree tells it which window it is in.
  /// Nil in a tree hosted without one, such as a test harness.
  public let handle: WindowHandle?

  public init(sceneID: String, storage: UISceneStorage = UISceneStorage(), handle: WindowHandle? = nil) {
    self.sceneID = sceneID
    self.storage = storage
    self.handle = handle
  }
}

/// Opening windows from retained code, which has no SwiftUI environment to read
/// `\.openWindow` from. Every `RetainedView` registers the environment's action; it is the
/// same app-wide action whichever window it came from.
@MainActor public enum Windows {
  private static var openAction: OpenWindowAction?

  static func register(_ action: OpenWindowAction) {
    self.openAction = action
  }

  /// Opens a window of the scene declared with `id`, or brings a single `RetainedWindow` that
  /// is already open to the front.
  public static func open(id: String) {
    guard let openAction else {
#if DEBUG
      print("Windows.open(id: \"\(id)\"): no window has appeared yet to open it from")
#endif
      return
    }
    openAction(id: id)
  }
}

/// Opens a window of the scene declared with `id`, from any retained handler:
///
///     Button("Inspector") { openWindow(id: "inspector") }
///
/// Windows are opened on the main thread, and each window's handlers run on its own: the
/// window opens once the main thread gets to it, after the handler returns.
public func openWindow(id: String) {
  DispatchQueue.main.async {
    Windows.open(id: id)
  }
}
