import MetalGraphicsLib
import SwiftUI

/// A gallery of every design-system component, as Storybook is for the web: `swift run Storybook`.
@main
struct StorybookApp: App {
  init() {
    // A bare executable starts as a background process with no Dock icon or menu bar.
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate()
    DockWindows.manage(StorybookDock.space)
  }

  var body: some Scene {
    RetainedWindow(StorybookScenes.main)
      .commands {
        StorybookCommands()
      }
  }
}
