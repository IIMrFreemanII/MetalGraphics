import EditorCore
import Foundation
import MetalGraphicsLib
import ReactiveUI
import simd

/// The open folder's files, as a tree: a click on a folder opens or closes it, on a file opens
/// it in a tab. Which folders are open is kept in the panel's storage.
///
/// Rows are built lazily, only those in view, from the flattened tree (`FileNode.rows`), which
/// is made again when the folder is scanned or a folder opens or closes: O(rows shown), not per
/// frame.
@Component
final class NavigatorPanel : SingleChildElement {
  static let expandedKey = "Navigator.expanded"
  private static let titleFont = TextFont.system(size: 12, weight: .semibold)
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.47, 1)

  let panel: DockPanel
  /// Which folders show their contents, by path.
  private var expanded: Set<String>

  @State var rows: [FileTreeRow] = []
  @State var title: String = "No Folder"
  @State var hasFolder: Bool = false

  init(panel: DockPanel) {
    self.panel = panel
    let stored = panel.storage.value(Self.expandedKey, default: StoredText(rawValue: "")).rawValue
    self.expanded = Set(stored.split(separator: "\n").map(String.init))
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 6) {
        Text(self.title)
          .font(Self.titleFont)
          .lineLimit(1)
        Spacer()
        Button("Open…") { IDE.chooseFolder() }
          .buttonStyle(.bordered)
      }
      .padding(Inset(vertical: 6, horizontal: 10))
      if self.hasFolder {
        ScrollView(.vertical) {
          LazyVStack(alignment: .leading, spacing: 0, items: self.rows) { [weak self] row in
            FileRowView(row: row) { tapped in self?.tap(tapped) }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Text("Open a folder to see its files: a Swift package, say.")
          .font(Self.captionFont)
          .foregroundColor(Self.captionColor)
          .padding(10)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  // The tree is the shared model's, and this panel's rows are made from it: subscribed by hand,
  // since rows are a list's `@State`, which a body cannot compute from a model.
  override func onMount(_ context: UIContext) {
    WorkspaceModel.shared.__observers(named: "root").add(self, token: 0)
    self.refreshRows()
  }

  override func onUnmount(_ context: UIContext) {
    WorkspaceModel.shared.__observers(named: "root").remove(self)
  }

  override func __modelDidChange(_ token: Int, _ animated: Bool) {
    self.refreshRows()
  }

  // MARK: - Actions

  private func tap(_ row: FileTreeRow) {
    if row.isDirectory {
      if row.isExpanded {
        self.expanded.remove(row.path)
      } else {
        self.expanded.insert(row.path)
      }
      self.panel.storage.set(StoredText(rawValue: self.expanded.sorted().joined(separator: "\n")), for: Self.expandedKey)
      self.refreshRows()
    } else {
      IDE.openFile(row.path)
    }
  }

  private func refreshRows() {
    let model = WorkspaceModel.shared
    guard let root = model.root else {
      let path = model.rootPath
      self.hasFolder = false
      self.title = path.isEmpty ? "No Folder" : (path as NSString).lastPathComponent
      if !self.rows.isEmpty { self.rows = [] }
      return
    }
    self.title = root.name
    self.hasFolder = true
    let rows = root.rows(expanded: self.expanded)
    if rows != self.rows { self.rows = rows }
  }
}

/// One file or folder in the navigator: indented by its depth, a disclosure for a folder, and
/// marked when its file is the one being edited.
@Component
final class FileRowView : SingleChildElement {
  private static let font = TextFont.system(size: 12)
  private static let chevronFont = TextFont.system(size: 9)
  private static let textColor = float4(0.13, 0.13, 0.15, 1)
  private static let folderColor = float4(0.35, 0.45, 0.62, 1)
  private static let hoverColor = float4(0, 0, 0, 0.05)
  private static let activeColor = float4(0.0, 0.48, 1.0, 0.16)
  private static let clearColor = float4(0, 0, 0, 0)
  private static let indent: Float = 14

  let row: FileTreeRow
  let onTap: (FileTreeRow) -> Void
  @Bindable let workspace: WorkspaceModel = .shared
  @State var hovered: Bool = false

  init(row: FileTreeRow, onTap: @escaping (FileTreeRow) -> Void) {
    self.row = row
    self.onTap = onTap
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    HStack(spacing: 4) {
      Text(self.row.isDirectory ? (self.row.isExpanded ? "▼" : "▶") : "")
        .font(Self.chevronFont)
        .foregroundColor(Self.folderColor)
        .frame(width: 10)
      Text(self.row.name)
        .font(Self.font)
        .foregroundColor(self.row.isDirectory ? Self.folderColor : Self.textColor)
        .lineLimit(1)
      Spacer()
    }
    .padding(Inset(left: 8 + Float(self.row.depth) * Self.indent, top: 3, right: 8, bottom: 3))
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(self.workspace.activeFile == self.row.path ? Self.activeColor : (self.hovered ? Self.hoverColor : Self.clearColor))
    .onHover { hovered, _ in self.hovered = hovered }
    .onTap { _ in self.onTap(self.row) }
  }
}
