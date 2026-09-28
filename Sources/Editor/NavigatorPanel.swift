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
  private static let captionColor: float4 = .secondaryLabel

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
          .foregroundColor(Self.captionColor)
          .lineLimit(1)
        Spacer()
        Button("Open…") { IDE.chooseFolder() }
          .buttonStyle(.bordered)
      }
      .padding(Inset(left: 18, top: 6, right: 12, bottom: 6))
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

/// One file or folder in the navigator: indented by its depth, a disclosure chevron and a
/// folder for a folder, a document for a file, and marked when its file is the one being edited.
@Component
final class FileRowView : SingleChildElement {
  private static let font = TextFont.system(size: 13)
  private static let chevronColor: float4 = .tertiaryLabel
  private static let folderColor: float4 = .hue(.folder)
  private static let indent: Float = 14

  let row: FileTreeRow
  let onTap: (FileTreeRow) -> Void
  @Bindable let workspace: WorkspaceModel = .shared

  init(row: FileTreeRow, onTap: @escaping (FileTreeRow) -> Void) {
    self.row = row
    self.onTap = onTap
    super.init()
  }

  /// A file's document icon, tinted by its type as the design's navigator does.
  static func documentColor(_ name: String) -> float4 {
    switch (name as NSString).pathExtension.lowercased() {
    case "swift": .hue(.orange)
    case "metal", "h", "c", "m", "cpp": .hue(.teal)
    case "md", "markdown", "txt": .hue(.blue)
    default: .secondaryLabel
    }
  }

  @UIElementBuilder var body: [UIElement] {
    ListRow(
      selected: self.workspace.activeFile == self.row.path, indent: Float(self.row.depth) * Self.indent, spacing: 5,
      action: { self.onTap(self.row) }
    ) {
      if self.row.isDirectory {
        Image(icon: self.row.isExpanded ? .chevronDown : .chevronRight)
          .foregroundColor(Self.chevronColor)
        Image(icon: .folder)
          .foregroundColor(Self.folderColor)
      } else {
        Spacer(minLength: 10)
          .frame(width: 10)
        Image(icon: .document)
          .foregroundColor(Self.documentColor(self.row.name))
      }
      Text(self.row.name)
        .font(Self.font)
        .lineLimit(1)
      Spacer()
    }
  }
}
