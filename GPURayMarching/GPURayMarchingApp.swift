import SwiftUI
import MetalGraphicsLib

@main
struct GPURayMarchingApp: App {
  init() {
    // Opens the panels' own windows while the workspace shows, where they were last time.
    DockWindows.manage(Workspace.space)
  }

  var body: some Scene {
    // First, so File ▸ New Window (⌘N) opens another of these.
    RetainedWindowGroup("Demos", id: "main") { scene in
      Demos(scene: scene)
    }
    .commands {
      CommandGroup(after: .newItem) {
        OpenSharedStateWindow()
        OpenWorkspaceWindow()
      }
    }

    RetainedWindow("Shared State", id: SharedStateWindow.id) { _ in
      SharedStateWindow()
    }
    .defaultSize(width: 420, height: 320)

    RetainedWindow("Workspace", id: Workspace.windowID) { _ in
      DockArea(Workspace.space, host: "main")
    }
    .defaultSize(width: 1000, height: 640)
  }
}

private struct OpenSharedStateWindow: View {
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Button("Open Shared State Window") { self.openWindow(id: SharedStateWindow.id) }
      .keyboardShortcut("k", modifiers: [.command, .shift])
  }
}

private struct OpenWorkspaceWindow: View {
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Button("Open Workspace Window") { self.openWindow(id: Workspace.windowID) }
      .keyboardShortcut("d", modifiers: [.command, .shift])
  }
}
