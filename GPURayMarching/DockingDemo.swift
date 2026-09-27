import MetalGraphicsLib
import ReactiveUI
import simd

// Docking: the Workspace window holds panels in a dock area. Drag a panel by its tab, a group by
// its bar, a float by its grip:
//
// - over a group, markers show: its middle adds the panel as a tab, an edge splits the group;
//   the markers along the window's edges dock along the whole of it;
// - let go anywhere else and it floats; drag it out of the window and it is a window of its own,
//   which docks back into the workspace, or into another such window, the same way.
//
// The layout — detached windows and where they are included — is saved, and restored on the
// next launch. Each panel's own values (the notes, the outline's selection) are kept in its
// panel storage, and follow it from window to window.
enum Workspace {
  static let windowID = "workspace"

  static let space = DockSpace(
    name: "workspace",
    kinds: [
      DockPanelKind("outline", title: "Outline") { panel in OutlinePanel(panel: panel) },
      DockPanelKind("inspector", title: "Inspector") { _ in InspectorPanel() },
      DockPanelKind("console", title: "Console") { _ in ConsolePanel() },
      DockPanelKind("notes", title: "Notes") { panel in NotesPanel(panel: panel) },
    ]
  ) {
    var layout = DockLayout()
    let outline = layout.addPanel(kind: "outline", title: "Outline")
    let inspector = layout.addPanel(kind: "inspector", title: "Inspector")
    let console = layout.addPanel(kind: "console", title: "Console")
    let notes = layout.addPanel(kind: "notes", title: "Notes")
    layout.hosts = [
      DockHost(id: "main", root: .row([
        .group([outline]),
        .column([.group([notes]), .group([console])], fractions: [0.6, 0.4]),
        .group([inspector]),
      ], fractions: [0.22, 0.46, 0.32])),
    ]
    return layout
  }

  /// Opens a new panel of `kind`, floating over the workspace, each a little below the last.
  static func float(_ kind: String) {
    let count = Float(space.layout.host("main")?.floating.count ?? 0)
    let offset = 40 + (count.truncatingRemainder(dividingBy: 6)) * 28
    space.open(kind: kind, in: "main", at: DockRect(x: 80 + offset, y: offset, width: 320, height: 240))
  }
}

/// A string kept in panel storage.
struct PanelText : RawRepresentable {
  var rawValue: String
}

// MARK: - Panels

@Component
final class InspectorPanel : SingleChildElement {
  @Bindable let model: AppModel = .shared

  @UIElementBuilder var body: [UIElement] {
    Form {
      Section("Shared by every window") {
        Stepper("Count: \(self.model.count)", value: $model.count, in: 0 ... 99)
        TextField("Message", text: $model.message)
        Toggle("Highlight", isOn: $model.highlighted)
        ColorPicker("Tint", selection: $model.tint)
      }
    }
  }
}

struct LogLine : Identifiable {
  let id: Int
  let text: String
}

@Component
final class ConsolePanel : SingleChildElement {
  @Bindable let model: AppModel = .shared
  @State var lines: [LogLine] = [LogLine(id: 0, text: "Workspace ready")]
  @State var next: Int = 1

  private static let font = TextFont.system(size: 12)

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Button("Log the count") {
          self.appendLines(LogLine(id: self.next, text: "count = \(self.model.count), message = \(self.model.message)"))
          self.next += 1
        }
        Button("Clear") { self.lines = [] }
      }
      ScrollView(.vertical) {
        VList(alignment: .leading, spacing: 2, items: self.lines) { line in
          Text(line.text).font(Self.font)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

struct OutlineItem : Identifiable {
  let id: String
}

@Component
final class OutlinePanel : SingleChildElement {
  static let selectedKey = "Outline.selected"

  let panel: DockPanel
  @State var selected: String
  @State var items: [OutlineItem] = ["Camera", "Key Light", "Fill Light", "Floor", "Sphere", "Cube", "Torus"]
    .map(OutlineItem.init)

  private static let font = TextFont.system(size: 13)

  init(panel: DockPanel) {
    self.panel = panel
    self.selected = panel.storage.value(OutlinePanel.selectedKey, default: PanelText(rawValue: "Camera")).rawValue
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      Text("Selected: \(self.selected)").font(Self.font).bold()
      VList(alignment: .leading, spacing: 4, items: self.items) { item in
        Button(item.id) { self.select(item.id) }
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private func select(_ name: String) {
    self.selected = name
    self.panel.storage.set(PanelText(rawValue: name), for: OutlinePanel.selectedKey)
  }
}

@Component
final class NotesPanel : SingleChildElement {
  static let textKey = "Notes.text"

  let panel: DockPanel
  @State var text: String

  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.47, 1)

  init(panel: DockPanel) {
    self.panel = panel
    self.text = panel.storage.value(NotesPanel.textKey, default: PanelText(rawValue: "")).rawValue
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      Text("Kept with the panel: move it to another window, or quit and relaunch.")
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
      TextField("Notes", text: $text)
        .onSubmit { self.save() }
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  // Saved when the panel leaves its window — moved to another, closed, the app quitting — and
  // on Return, rather than on every key.
  override func onUnmount(_ context: UIContext) {
    self.save()
  }

  private func save() {
    self.panel.storage.set(PanelText(rawValue: self.text), for: NotesPanel.textKey)
  }
}

// MARK: - Demo page

@Component
final class DockingDemo : SingleChildElement {
  @UIElementBuilder var body: [UIElement] {
    Form {
      Section("Workspace") {
        Text("Drag panels by their tabs to dock, split, tab or float them; drag one out of the window and it becomes a window of its own, which docks back the same way.")
        Button("Open Workspace window") { openWindow(id: Workspace.windowID) }
          .buttonStyle(.borderedProminent)
      }
      Section("New floating panel") {
        HStack(spacing: 8) {
          Button("Outline") { Workspace.float("outline") }.buttonStyle(.bordered)
          Button("Inspector") { Workspace.float("inspector") }.buttonStyle(.bordered)
          Button("Console") { Workspace.float("console") }.buttonStyle(.bordered)
          Button("Notes") { Workspace.float("notes") }.buttonStyle(.bordered)
        }
      }
      Section("Detached windows") {
        HStack(spacing: 8) {
          Button("Native look") { Workspace.space.setWindowStyle(.native) }.buttonStyle(.bordered)
          Button("Custom look") { Workspace.space.setWindowStyle(.custom) }.buttonStyle(.bordered)
        }
        Text("The custom look draws its own title bar: drag it to move the window, and dock it.")
      }
      Section {
        Button("Reset layout") { Workspace.space.reset() }
      }
    }
    .frame(width: 520, height: 520)
  }
}
