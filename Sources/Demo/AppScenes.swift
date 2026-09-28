import CoreGraphics
import MetalGraphicsLib

// The app's windows, declared once: `DemoApp` shows them as SwiftUI scenes, and the
// end-to-end tests (`DemoTests`) open the same ones in a `HeadlessApp`.
enum AppScenes {
  /// First, so it opens at launch, and File ▸ New Window (⌘N) opens another.
  static let demos = RetainedScene("Demos", id: "main", defaultSize: CGSize(width: 1000, height: 760), chrome: .translucent) { scene in
    Demos(scene: scene)
  }

  static let sharedState = RetainedScene(
    "Shared State", id: SharedStateWindow.id, kind: .single, defaultSize: CGSize(width: 420, height: 320),
    chrome: .translucent
  ) { _ in
    SharedStateWindow()
  }

  static let workspace = RetainedScene(
    "Workspace", id: Workspace.windowID, kind: .single, defaultSize: CGSize(width: 1000, height: 640),
    chrome: .translucent
  ) { _ in
    DockArea(Workspace.space, host: "main")
  }

  static let all = [demos, sharedState, workspace]

  /// What a new process starts from: the shared model's first values, and a workspace loaded
  /// afresh from storage. For tests, before a `HeadlessApp` launches or relaunches.
  static func resetForTesting() {
    AppModel.shared.reset()
    Workspace.space = Workspace.makeSpace()
  }
}
