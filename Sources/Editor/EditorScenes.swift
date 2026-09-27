import CoreGraphics
import MetalGraphicsLib

// The app's windows, declared once: `EditorApp` shows them as SwiftUI scenes, and the
// end-to-end tests (`EditorTests`) open the same ones in a `HeadlessApp`.
enum EditorScenes {
  static let ide = RetainedScene(
    "Editor", id: IDE.windowID, kind: .single, defaultSize: CGSize(width: 1180, height: 780)
  ) { _ in
    IDERoot()
  }

  static let all = [ide]

  /// What a new process starts from: no folder, and the dock layout loaded afresh from storage.
  /// For tests, before a `HeadlessApp` launches or relaunches.
  static func resetForTesting() {
    WorkspaceModel.shared.reset()
    BuildModel.shared.reset()
    BuildController.shared.log.reset()
    OpenFiles.shared.reset()
    IDE.stopWatching()
    IDE.space = IDE.makeSpace()
  }
}
