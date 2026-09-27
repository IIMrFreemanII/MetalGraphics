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
  let defaultSize: CGSize
  let root: @Sendable (WindowScene) -> UIElement

  public init(
    _ title: String, id: String, defaultSize: CGSize = RetainedScene.standardSize,
    root: @escaping @Sendable (WindowScene) -> UIElement
  ) {
    self.title = title
    self.id = id
    self.defaultSize = defaultSize
    self.root = root
  }

  /// The window group `scene` declares, as `HeadlessApp` also opens it.
  public init(_ scene: RetainedScene) {
    self.init(scene.title, id: scene.id, defaultSize: scene.defaultSize, root: scene.root)
  }

  public var body: some Scene {
    WindowGroup(self.title, id: self.id) {
      RetainedView(sceneID: self.id, root: self.root)
    }
    .defaultSize(self.defaultSize)
  }
}

/// A single window whose content is a retained tree, as SwiftUI's `Window`: opening it again
/// brings the open one to the front.
public struct RetainedWindow: Scene {
  let title: String
  let id: String
  let defaultSize: CGSize
  let root: @Sendable (WindowScene) -> UIElement

  public init(
    _ title: String, id: String, defaultSize: CGSize = RetainedScene.standardSize,
    root: @escaping @Sendable (WindowScene) -> UIElement
  ) {
    self.title = title
    self.id = id
    self.defaultSize = defaultSize
    self.root = root
  }

  /// The single window `scene` declares, as `HeadlessApp` also opens it.
  public init(_ scene: RetainedScene) {
    self.init(scene.title, id: scene.id, defaultSize: scene.defaultSize, root: scene.root)
  }

  public var body: some Scene {
    Window(self.title, id: self.id) {
      RetainedView(sceneID: self.id, root: self.root)
    }
    .defaultSize(self.defaultSize)
  }
}

/// A kind of window the app declares, apart from SwiftUI: what `RetainedWindowGroup` and
/// `RetainedWindow` show, and what `HeadlessApp` opens in memory. Declaring the app's windows
/// once, as a list of these, runs the same trees in both:
///
///     static let demos = RetainedScene("Demos", id: "main") { scene in Demos(scene: scene) }
///     // App.body:     RetainedWindowGroup(AppScenes.demos)
///     // A test:       HeadlessApp(scenes: [AppScenes.demos]).launch()
public struct RetainedScene: Sendable {
  public enum Kind: Sendable {
    /// Any number open, as `WindowGroup`.
    case group
    /// At most one open, as `Window`: opening it again brings it to the front.
    case single
  }

  /// A new window's size when nothing says otherwise.
  public static let standardSize = CGSize(width: 900, height: 600)

  public let title: String
  public let id: String
  public let kind: Kind
  /// Points.
  public let defaultSize: CGSize
  public let root: @Sendable (WindowScene) -> UIElement

  public init(
    _ title: String, id: String, kind: Kind = .group, defaultSize: CGSize = RetainedScene.standardSize,
    root: @escaping @Sendable (WindowScene) -> UIElement
  ) {
    self.title = title
    self.id = id
    self.kind = kind
    self.defaultSize = defaultSize
    self.root = root
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
  /// SwiftUI's open-window action, or `HeadlessApp`'s own while one runs.
  private static var opener: (@MainActor (String) -> Void)?

  static func register(_ action: OpenWindowAction) {
    self.opener = { action(id: $0) }
  }

  /// Replaces how windows open, returning what it was: for `HeadlessApp`, which opens them in
  /// memory, and puts back what it found when it closes.
  @discardableResult
  static func setOpener(_ opener: (@MainActor (String) -> Void)?) -> (@MainActor (String) -> Void)? {
    defer { self.opener = opener }
    return self.opener
  }

  /// Opens a window of the scene declared with `id`, or brings a single `RetainedWindow` that
  /// is already open to the front.
  public static func open(id: String) {
    guard let opener else {
#if DEBUG
      print("Windows.open(id: \"\(id)\"): no window has appeared yet to open it from")
#endif
      return
    }
    opener(id)
  }
}

/// How retained code reaches the main thread: the main queue in the app, `HeadlessApp`'s own
/// mailbox while one runs, so what a handler asks of the main thread is stepped with the rest.
enum MainQueue {
  nonisolated(unsafe) static var post: @Sendable (@escaping @Sendable () -> Void) -> Void = { work in
    DispatchQueue.main.async(execute: work)
  }
}

/// Opens a window of the scene declared with `id`, from any retained handler:
///
///     Button("Inspector") { openWindow(id: "inspector") }
///
/// Windows are opened on the main thread, and each window's handlers run on its own: the
/// window opens once the main thread gets to it, after the handler returns.
public func openWindow(id: String) {
  MainQueue.post {
    MainActor.assumeIsolated { Windows.open(id: id) }
  }
}
