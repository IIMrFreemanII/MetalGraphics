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
  static let consoleKind = "console"
  static let problemsKind = "problems"
  static let outlineKind = "outline"
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
        DockPanelKind(navigatorKind, title: "Files", background: .sidebarTint) { panel in NavigatorPanel(panel: panel) },
        DockPanelKind(
          fileKind, title: "Untitled", tabStyle: .document,
          tabIcon: { title in (.document, FileRowView.documentColor(title)) }
        ) { panel in FileEditorPanel(panel: panel) },
        DockPanelKind(welcomeKind, title: "Welcome", tabStyle: .document) { _ in WelcomePanel() },
        DockPanelKind(consoleKind, title: "Console") { _ in ConsolePanel() },
        DockPanelKind(problemsKind, title: "Problems") { panel in ProblemsPanel(panel: panel) },
        DockPanelKind(outlineKind, title: "Outline", background: .sidebarTint) { _ in OutlinePanel() },
      ]
    ) {
      var layout = DockLayout()
      let navigator = layout.addPanel(kind: navigatorKind, title: "Files")
      let outline = layout.addPanel(kind: outlineKind, title: "Outline")
      let welcome = layout.addPanel(kind: welcomeKind, title: "Welcome")
      layout.hosts = [
        DockHost(id: host, root: .row([
          .column([.group([navigator]), .group([outline])], fractions: [0.6, 0.4]),
          .group([welcome]),
        ], fractions: [0.24, 0.76])),
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

  /// Watches the open folder. Replaced when another opens.
  nonisolated(unsafe) private static var watcher: AnyObject? = nil
  private static let watcherLock = NSLock()

  /// Shows `path`'s files in the navigator, from any thread. The scan runs in the background;
  /// the tree shows when it is done. The folder is watched from then on, and its executables
  /// looked up for ⌘R.
  static func openFolder(_ path: String) {
    let path = URL(fileURLWithPath: path).standardizedFileURL.path
    UIStorage.set(StoredText(rawValue: path), for: rootKey)
    let previous = WorkspaceModel.shared.rootPath
    WorkspaceModel.shared.rootPath = path
    if path != previous {
      self.closeFiles(outside: path)
      BuildController.shared.log.reset()
      BuildModel.shared.reset()
    }
    let watcher = Services.watchFolder(path) { changed in IDE.filesChanged(changed) }
    self.watcherLock.withLock { self.watcher = watcher }
    self.rescan()
    BuildController.shared.loadProducts(path)
  }

  /// Closes the tabs of files not in `root`, as another folder opens. Unsaved edits in them are
  /// saved first.
  private static func closeFiles(outside root: String) {
    let prefix = root + "/"
    OpenFiles.shared.saveAll()
    self.space.update { layout in
      for (id, info) in layout.panels where info.kind == fileKind && !self.path(of: info).hasPrefix(prefix) {
        layout.close(panel: id)
      }
    }
  }

  /// Files changed on disk, from any thread: the tree is read again, and open files that were
  /// not edited here show what is on disk now.
  static func filesChanged(_ paths: [String]) {
    self.rescan()
    OpenFiles.shared.reloadChangedFiles()
  }

  /// Stops watching, for tests.
  static func stopWatching() {
    self.watcherLock.withLock { self.watcher = nil }
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
      } else if self.placeBesideSideColumn(.group([id]), in: &layout) {
        // Placed.
      } else {
        layout.place(.group([id]), at: .hostEdge(host, .center))
      }
      return id
    }
  }

  /// Shows `path` in a tab, with the caret at `line`, `column` (from 1; the column in UTF-8
  /// bytes, as compilers count): a problem, from the list.
  static func openFile(_ path: String, line: Int, column: Int) {
    self.openFile(path)
    let serial = (WorkspaceModel.shared.reveal?.serial ?? 0) + 1
    WorkspaceModel.shared.reveal = RevealRequest(path: path, line: line, column: column, serial: serial)
  }

  /// Shows `path` in a tab with the caret at UTF-16 `offset`: a symbol from the outline.
  static func reveal(_ path: String, offset: Int) {
    self.openFile(path)
    let serial = (WorkspaceModel.shared.reveal?.serial ?? 0) + 1
    WorkspaceModel.shared.reveal = RevealRequest(path: path, offset: offset, serial: serial)
  }

  /// Shows `path` in a tab with the caret at `line` and UTF-16 `character`, from 0: a
  /// definition, as a language server gives it.
  static func reveal(_ path: String, line: Int, character: Int) {
    self.openFile(path)
    let serial = (WorkspaceModel.shared.reveal?.serial ?? 0) + 1
    WorkspaceModel.shared.reveal = RevealRequest(path: path, line: line + 1, character: character, serial: serial)
  }

  /// Adds the Outline to a layout saved before there was one: a tab beside the navigator, which
  /// can be dragged under it.
  static func ensureOutlinePanel() {
    self.space.update { layout in
      guard !layout.panels.values.contains(where: { $0.kind == outlineKind }),
            let navigator = self.group(holding: navigatorKind, in: layout)
      else { return }
      let outline = layout.addPanel(kind: outlineKind, title: "Outline")
      layout.place(.group([outline]), at: .node(navigator.id, .center))
      layout.select(panel: navigator.panels[0])
    }
  }

  /// Shows the console and the Problems list, docked along the bottom the first time.
  static func showBuildPanels() {
    self.space.update { layout in
      if let console = layout.panels.first(where: { $0.value.kind == consoleKind })?.key {
        layout.select(panel: console)
        return
      }
      let console = layout.addPanel(kind: consoleKind, title: "Console")
      let problems = layout.addPanel(kind: problemsKind, title: "Problems")
      layout.place(.group([console, problems], selected: console), at: .hostEdge(host, .bottom))
    }
  }

  /// Shows the Problems list.
  static func showProblems() {
    self.showBuildPanels()
    self.space.update { layout in
      if let problems = layout.panels.first(where: { $0.value.kind == problemsKind })?.key {
        layout.select(panel: problems)
      }
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

  /// Puts `files`, the first file's group, right of the side column (the navigator, and the
  /// outline under it) and above the console: when the side column shares a column with the
  /// console, what is above the console becomes a row of the side column and the files. The
  /// files take most of the width. Returns false when there is no navigator.
  private static func placeBesideSideColumn(_ files: DockNode, in layout: inout DockLayout) -> Bool {
    guard let index = layout.hosts.firstIndex(where: { $0.id == host }), let root = layout.hosts[index].root,
          let navigator = self.group(holding: navigatorKind, in: layout)
    else { return false }
    let panels = layout.panels
    func holdsBuildPanels(_ node: DockNode) -> Bool {
      node.panels.contains { [consoleKind, problemsKind].contains(panels[$0]?.kind) }
    }
    func beside(_ side: DockNode) -> DockNode {
      .row([side, files], fractions: [0.24, 0.76])
    }
    // Rebuilds the tree down to the navigator: the first node on the way without the console
    // gets the files beside it, together with its siblings above the console.
    func rebuild(_ node: DockNode) -> DockNode? {
      if !holdsBuildPanels(node) { return node.panels.contains(navigator.panels[0]) ? beside(node) : nil }
      guard case .split(let split) = node else { return nil }
      guard let at = split.children.firstIndex(where: { $0.panels.contains(navigator.panels[0]) }) else { return nil }
      let child = split.children[at]
      if holdsBuildPanels(child) {
        guard let rebuilt = rebuild(child) else { return nil }
        var children = split.children
        children[at] = rebuilt
        return split.axis == .horizontal ? .row(children, fractions: split.fractions) : .column(children, fractions: split.fractions)
      }
      guard split.axis == .vertical else {
        var children = split.children
        children[at] = beside(child)
        return .row(children, fractions: split.fractions)
      }
      // The run of siblings around the navigator's without the console.
      var low = at
      while low > 0 && !holdsBuildPanels(split.children[low - 1]) { low -= 1 }
      var high = at
      while high + 1 < split.children.count && !holdsBuildPanels(split.children[high + 1]) { high += 1 }
      let run = Array(split.children[low ... high])
      let runFractions = Array(split.fractions[low ... high])
      let share = runFractions.reduce(0, +)
      let side: DockNode = run.count == 1 ? run[0] : .column(run, fractions: runFractions.map { $0 / max(share, 0.0001) })
      var children = Array(split.children[..<low])
      var fractions = Array(split.fractions[..<low])
      children.append(beside(side))
      fractions.append(share)
      children += split.children[(high + 1)...]
      fractions += split.fractions[(high + 1)...]
      return .column(children, fractions: fractions)
    }
    guard let rebuilt = rebuild(root) else { return false }
    layout.hosts[index].root = rebuilt
    return true
  }
}
