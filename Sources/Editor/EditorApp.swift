import SwiftUI
import MetalGraphicsLib

/// The Swift editor: `swift run Editor [folder]`. One window, a dock area of panels: the files
/// of the folder open, and a tab per file. See docs/Editor.md.
@main
struct EditorApp: App {
  init() {
    // `Editor ~/src/pkg` names a folder for `openFolderAtLaunch`. AppKit would otherwise take it
    // for a document to open, and open no window at launch.
    UserDefaults.standard.register(defaults: ["NSTreatUnknownArgumentsAsOpen": "NO"])
    // A bare executable starts as a background process with no Dock icon or menu bar.
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate()
    IDE.ensureOutlinePanel()
    DockWindows.manage(IDE.space)
    IDE.openFolderAtLaunch(arguments: CommandLine.arguments, environment: ProcessInfo.processInfo.environment)
  }

  var body: some Scene {
    // A window group, since SwiftUI opens one at launch, where it leaves a lone `Window` closed.
    // New Window is replaced, so there is never a second: two dock areas showing the same host
    // would each take its drags.
    RetainedWindowGroup(EditorScenes.ide)
      .commands {
        CommandGroup(replacing: .newItem) {
          // No key equivalents here: ⌘O, ⌘P, ⌘S, ⌘F and the rest are the window's own (`IDERoot`,
          // `FileEditorPanel`), which the headless tests can press. A menu's would take the key
          // before the window saw it — which is why Print, ⌘P, goes too.
          SwiftUI.Button("Open Folder…") { IDE.chooseFolder() }
        }
        CommandGroup(replacing: .printItem) {}
      }
  }
}
