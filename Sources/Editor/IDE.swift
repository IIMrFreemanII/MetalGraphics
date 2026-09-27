import EditorCore
import Foundation
import MetalGraphicsLib

/// The editor's window: a dock area holding the navigator and a tab per open file, and what the
/// app does with them: open a folder, open a file.
///
/// Files are dock panels of kind `file`, each keeping its path in its panel storage, so tabs
/// split, float, move to windows of their own and come back after a relaunch as other panels do.
enum IDE {
  static let windowID = "ide"
  static let host = "main"
  static let fileKind = "file"
  static let navigatorKind = "navigator"
  static let welcomeKind = "welcome"
  /// Where a file panel keeps its path.
  static let pathKey = "File.path"
  /// The folder open last, reopened at launch.
  static let rootKey = "Editor.root"

  /// A `var` so a test can start from a fresh one, loaded from its own storage, as a new
  /// process would (`EditorScenes.resetForTesting`). Set only at launch.
  nonisolated(unsafe) static var space = IDE.makeSpace()

  static func makeSpace() -> DockSpace {
    DockSpace(
      name: "editor",
      kinds: [
        DockPanelKind(navigatorKind, title: "Files") { panel in NavigatorPanel(panel: panel) },
        DockPanelKind(fileKind, title: "Untitled") { panel in FileEditorPanel(panel: panel) },
        DockPanelKind(welcomeKind, title: "Welcome") { _ in WelcomePanel() },
      ]
    ) {
      var layout = DockLayout()
      let navigator = layout.addPanel(kind: navigatorKind, title: "Files")
      let welcome = layout.addPanel(kind: welcomeKind, title: "Welcome")
      layout.hosts = [
        DockHost(id: host, root: .row([.group([navigator]), .group([welcome])], fractions: [0.24, 0.76])),
      ]
      return layout
    }
  }

  // MARK: - Folders

  /// Opens the folder named on the command line (`swift run Editor ~/src/pkg`), in
  /// `EDITOR_OPEN`, or the one open last.
  static func openFolderAtLaunch(arguments: [String], environment: [String: String]) {
    let candidates = [arguments.dropFirst().first { !$0.hasPrefix("-") }, environment["EDITOR_OPEN"],
                      UIStorage.value(rootKey, default: StoredText(rawValue: "")).rawValue]
    for case let path? in candidates where !path.isEmpty {
      var isDirectory: ObjCBool = false
      let absolute = URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.path
      if FileManager.default.fileExists(atPath: absolute, isDirectory: &isDirectory), isDirectory.boolValue {
        self.openFolder(absolute)
        return
      }
    }
  }

  /// Asks for a folder, then opens it.
  static func chooseFolder() {
    Services.chooseFolder { path in IDE.openFolder(path) }
  }

  /// Shows `path`'s files in the navigator, from any thread. The scan runs in the background;
  /// the tree shows when it is done.
  static func openFolder(_ path: String) {
    let path = URL(fileURLWithPath: path).standardizedFileURL.path
    UIStorage.set(StoredText(rawValue: path), for: rootKey)
    WorkspaceModel.shared.rootPath = path
    self.rescan()
  }

  /// Reads the open folder's files again.
  static func rescan() {
    let path = WorkspaceModel.shared.rootPath
    guard !path.isEmpty else { return }
    Services.background {
      let root = WorkspaceScanner.scan(URL(fileURLWithPath: path))
      // A folder opened since wins.
      guard WorkspaceModel.shared.rootPath == path else { return }
      WorkspaceModel.shared.root = root
    }
  }

  // MARK: - Files

  /// The path a file panel shows, from what the layout keeps of it.
  static func path(of info: DockPanelInfo) -> String {
    UISceneStorage(restoring: info.storage, sharesLastUsed: false)
      .value(pathKey, default: StoredText(rawValue: "")).rawValue
  }

  /// The panel showing `path`, if one does.
  static func panel(showing path: String, in layout: DockLayout) -> String? {
    layout.panels.first { $0.value.kind == fileKind && self.path(of: $0.value) == path }?.key
  }

  /// Shows `path` in a tab, from any thread: the one it is already in, else a new one beside the
  /// other files. Returns the panel's id.
  @discardableResult
  static func openFile(_ path: String) -> String? {
    let storage = UISceneStorage(restoring: "", sharesLastUsed: false)
    storage.set(StoredText(rawValue: path), for: pathKey)
    let encoded = storage.encoded
    let title = (path as NSString).lastPathComponent
    return self.space.update { layout -> String? in
      if let existing = self.panel(showing: path, in: layout) {
        layout.select(panel: existing)
        return existing
      }
      let id = layout.addPanel(kind: fileKind, title: title)
      layout.panels[id]?.storage = encoded
      if let group = self.editorGroup(in: layout) {
        layout.place(.group([id]), at: .node(group.id, .center))
        // The welcome tab makes way for the first file.
        for panel in group.panels where layout.panels[panel]?.kind == welcomeKind {
          layout.close(panel: panel)
        }
      } else if let navigator = self.group(holding: navigatorKind, in: layout) {
        layout.place(.group([id]), at: .node(navigator.id, .right))
        self.giveEditorsRoom(&layout, navigatorGroup: navigator.id)
      } else {
        layout.place(.group([id]), at: .hostEdge(host, .center))
      }
      return id
    }
  }

  /// Where a new file goes: the docked group holding files or the welcome tab.
  private static func editorGroup(in layout: DockLayout) -> DockTabs? {
    guard let root = layout.host(host)?.root else { return nil }
    return self.groups(in: root).first { tabs in
      tabs.panels.contains { layout.panels[$0]?.kind == fileKind || layout.panels[$0]?.kind == welcomeKind }
    }
  }

  private static func group(holding kind: String, in layout: DockLayout) -> DockTabs? {
    guard let root = layout.host(host)?.root else { return nil }
    return self.groups(in: root).first { tabs in tabs.panels.contains { layout.panels[$0]?.kind == kind } }
  }

  private static func groups(in node: DockNode) -> [DockTabs] {
    switch node {
    case .tabs(let tabs): [tabs]
    case .split(let split): split.children.flatMap(groups(in:))
    }
  }

  /// A new split of the navigator and the files: the files take most of it.
  private static func giveEditorsRoom(_ layout: inout DockLayout, navigatorGroup: String) {
    guard case .split(let split)? = layout.host(host)?.root, split.axis == .horizontal, split.children.count == 2,
          split.children[0].id == navigatorGroup
    else { return }
    layout.setFractions([0.24, 0.76], of: split.id)
  }
}
