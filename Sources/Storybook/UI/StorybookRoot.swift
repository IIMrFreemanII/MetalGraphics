import MetalGraphicsLib
import simd

/// The Storybook window: the stories in a sidebar, searchable; beside them the toolbar over a
/// dock area holding the canvas and the addon panels (Controls, Actions, Source, Inspector),
/// which can be tabbed, split, moved or torn out into windows of their own.
///
/// Built by hand rather than as a `@Component`: its parts are made from stories, which a body
/// cannot hold.
final class StorybookRoot : ModelWatcher {
  private let title: NavigationTitleElement

  override var watched: [String] { ["selection"] }

  init(scene: WindowScene) {
    let model = StorybookModel.shared
    model.restore(from: scene.storage, catalog: StoryRegistry.catalog())
    let search = TextField("", text: Binding(get: { model.search }, set: { model.search = $0 }), prompt: "Search")
      .leadingIcon(.magnifier)
    // The toolbar shares the detail column's bar, in the title bar's row, the story's name
    // between its items.
    let title = DockArea(StorybookDock.space, host: StorybookDock.host)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .navigationTitle(Self.title(model.selection))
    self.title = title
    super.init()
    self.child = NavigationSplitView {
      SidebarTitle("Storybook")
      search.padding(Inset(left: 4, top: 0, right: 4, bottom: 8))
      SidebarList()
    } detail: {
      title.toolbar {
        StorybookToolbarLeading()
      } trailing: {
        StorybookToolbarTrailing()
      }
    }
  }

  static func title(_ id: StoryID) -> String { "\(id.component) — \(id.story)" }

  override func update(_ token: Int, _ context: UIContext) {
    self.title.setTitle(Self.title(self.model.selection), context)
  }
}

/// The canvas and the addon panels, docked beside the sidebar. The layout is saved; each panel
/// is made afresh in the window it moves to.
enum StorybookDock {
  static let host = "main"

  /// A `var` so a test starts from a fresh one (`StorybookScenes.resetForTesting`).
  nonisolated(unsafe) static var space = StorybookDock.makeSpace()

  static func makeSpace() -> DockSpace {
    DockSpace(
      name: "storybook",
      kinds: [
        DockPanelKind("canvas", title: "Canvas", tabStyle: .document) { _ in CanvasPanel() },
        DockPanelKind("controls", title: "Controls", background: .groupedBackground) { _ in ControlsPanel() },
        DockPanelKind("actions", title: "Actions") { _ in ActionsPanel() },
        DockPanelKind("source", title: "Source") { _ in SourcePanel() },
      ]
    ) {
      var layout = DockLayout()
      let canvas = layout.addPanel(kind: "canvas", title: "Canvas")
      let controls = layout.addPanel(kind: "controls", title: "Controls")
      let actions = layout.addPanel(kind: "actions", title: "Actions")
      let source = layout.addPanel(kind: "source", title: "Source")
      layout.hosts = [
        DockHost(id: StorybookDock.host, root: .column([
          .group([canvas]),
          .group([controls, actions, source]),
        ], fractions: [0.64, 0.36])),
      ]
      return layout
    }
  }
}
