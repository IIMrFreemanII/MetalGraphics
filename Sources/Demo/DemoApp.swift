import SwiftUI
import MetalGraphicsLib

@main
struct DemoApp: App {
  init() {
    // A bare executable (`swift run Demo`) starts as a background process with no Dock icon or
    // menu bar, its windows behind the frontmost app's.
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate()
    // Opens the panels' own windows while the workspace shows, where they were last time.
    DockWindows.manage(Workspace.space)
  }

  // The scenes are declared in `AppScenes`, which the end-to-end tests open too.
  var body: some Scene {
    // First, so File ▸ New Window (⌘N) opens another of these.
    RetainedWindowGroup(AppScenes.demos)
      .commands {
        CommandGroup(after: .newItem) {
          OpenSharedStateWindow()
          OpenWorkspaceWindow()
        }
      }

    RetainedWindow(AppScenes.sharedState)

    RetainedWindow(AppScenes.workspace)
  }
}

private struct OpenSharedStateWindow: View {
  @SwiftUI.Environment(\.openWindow) private var openWindow

  var body: some View {
    Button("Open Shared State Window") { self.openWindow(id: SharedStateWindow.id) }
      .keyboardShortcut("k", modifiers: [.command, .shift])
  }
}

private struct OpenWorkspaceWindow: View {
  @SwiftUI.Environment(\.openWindow) private var openWindow

  var body: some View {
    Button("Open Workspace Window") { self.openWindow(id: Workspace.windowID) }
      .keyboardShortcut("d", modifiers: [.command, .shift])
  }
}
