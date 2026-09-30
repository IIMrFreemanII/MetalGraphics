import CoreGraphics
import MetalGraphicsLib

// The Storybook's window, declared once: `StorybookApp` shows it, and `StorybookTests` open the
// same one in a `HeadlessApp`.
enum StorybookScenes {
  static let main = RetainedScene(
    "Storybook", id: "storybook", kind: .single, defaultSize: CGSize(width: 1280, height: 820), chrome: .translucent
  ) { scene in
    StorybookRoot(scene: scene)
  }

  static let all = [main]

  /// What a new process starts from. For tests, before a `HeadlessApp` launches or relaunches.
  static func resetForTesting() {
    StorybookModel.shared.reset()
    StorybookDock.space = StorybookDock.makeSpace()
  }
}
