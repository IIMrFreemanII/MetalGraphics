import EditorCore
import Foundation
import MetalGraphicsLib
import ReactiveUI
import simd

/// ⌘L: a line to go to, or `line:column`, counted from 1.
@Component
final class GoToLineSheet : SingleChildElement {
  private static let titleFont = TextFont.system(size: 15, weight: .semibold)
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor: float4 = .secondaryLabel
  private static let errorColor: float4 = .destructive

  @Environment(\.dismiss) private var dismiss

  let lineCount: Int
  /// With the line and column, from 0.
  let onGo: (Int, Int) -> Void
  @State var text: String = ""
  @State var problem: String = ""

  init(lineCount: Int, onGo: @escaping (Int, Int) -> Void) {
    self.lineCount = lineCount
    self.onGo = onGo
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 10) {
      Text("Go to Line")
        .font(Self.titleFont)
      TextField("Line", text: $text, prompt: "1–\(self.lineCount), or line:column")
        .focused(true)
        .onSubmit { self.go() }
        .frame(width: 260)
      Text(self.problem)
        .font(Self.captionFont)
        .foregroundColor(Self.errorColor)
      HStack(spacing: 8) {
        Spacer()
        Button("Cancel", role: .cancel) { self.dismiss() }
        Button("Go") { self.go() }
          .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 320)
  }

  private func go() {
    guard let (line, column) = Self.parse(self.text), line >= 1, line <= self.lineCount else {
      self.problem = "Type a line from 1 to \(self.lineCount)."
      return
    }
    self.onGo(line - 1, max(column - 1, 0))
    self.dismiss()
  }

  /// "12" or "12:5".
  static func parse(_ text: String) -> (Int, Int)? {
    let parts = text.trimmingCharacters(in: .whitespaces).split(separator: ":", maxSplits: 1)
    guard let first = parts.first, let line = Int(first) else { return nil }
    let column = parts.count > 1 ? Int(parts[1]) ?? 1 : 1
    return (line, column)
  }
}

/// A file in the quick-open list: its name, and the folder it is in.
struct QuickOpenItem : Identifiable {
  let path: String
  let name: String
  let folder: String

  var id: String { self.path }

  init(path: String, root: String) {
    self.path = path
    let relative = TextPositions.relativePath(path, from: root)
    self.name = (relative as NSString).lastPathComponent
    self.folder = (relative as NSString).deletingLastPathComponent
  }
}

/// ⌘P: the folder's files, narrowed as a name is typed (`FuzzyMatcher`). Return opens the first.
@Component
final class QuickOpenSheet : SingleChildElement {
  static let limit = 50

  @Environment(\.dismiss) private var dismiss

  /// Every file, relative to the folder, as matched.
  private let relativePaths: [String]
  private let root: String
  @State var query: String = ""
  @State var results: [QuickOpenItem]

  override init() {
    let model = WorkspaceModel.shared
    let root = model.rootPath
    self.root = root
    self.relativePaths = (model.root?.allFiles ?? []).map { TextPositions.relativePath($0.path, from: root) }
    self.results = self.relativePaths.prefix(Self.limit).map { QuickOpenItem(path: root + "/" + $0, root: root) }
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 8) {
      TextField("Open Quickly", text: $query, prompt: "File name")
        .focused(true)
        .onEdit { text in self.filter(text) }
        .onSubmit { self.openFirst() }
        .frame(width: 460)
      ScrollView(.vertical) {
        VList(alignment: .leading, spacing: 0, items: self.results) { [weak self] item in
          QuickOpenRow(item: item) { path in self?.open(path) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(width: 460, height: 320)
    }
    .padding(16)
  }

  private func filter(_ query: String) {
    let root = self.root
    self.results = FuzzyMatcher.rank(query, self.relativePaths, limit: Self.limit)
      .map { QuickOpenItem(path: root + "/" + $0, root: root) }
  }

  private func openFirst() {
    guard let first = self.results.first else { return }
    self.open(first.path)
  }

  private func open(_ path: String) {
    IDE.openFile(path)
    self.dismiss()
  }
}

@Component
final class QuickOpenRow : SingleChildElement {
  private static let nameFont = TextFont.system(size: 13)
  private static let folderFont = TextFont.system(size: 11)
  private static let folderColor: float4 = .secondaryLabel

  let item: QuickOpenItem
  let onOpen: (String) -> Void

  init(item: QuickOpenItem, onOpen: @escaping (String) -> Void) {
    self.item = item
    self.onOpen = onOpen
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    ListRow(height: 38, margin: 0, spacing: 8, action: { self.onOpen(self.item.path) }) {
      AnimatedIcon(.document)
        .foregroundColor(FileRowView.documentColor(self.item.name))
      VStack(alignment: .leading, spacing: 1) {
        Text(self.item.name)
          .font(Self.nameFont)
          .lineLimit(1)
        Text(self.item.folder)
          .font(Self.folderFont)
          .foregroundColor(Self.folderColor)
          .lineLimit(1)
      }
      Spacer()
    }
  }
}
