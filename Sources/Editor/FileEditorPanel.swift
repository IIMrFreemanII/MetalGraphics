import EditorCore
import Foundation
import MetalGraphicsLib
import ReactiveUI
import simd

/// One open file, in a tab: its text in an editor, and a status line under it.
///
/// ⌘S saves it. A tab showing unsaved edits reads "● name", and closing it asks first. Moved to
/// another window, the panel is made anew there; its unsaved text goes with it (`OpenFiles`),
/// its undo history does not.
@Component
final class FileEditorPanel : SingleChildElement {
  private static let statusFont = TextFont.system(size: 11)
  private static let statusColor = float4(0.42, 0.42, 0.45, 1)
  private static let errorColor = float4(0.8, 0.2, 0.15, 1)
  private static let barColor = float4(0.955, 0.955, 0.96, 1)

  let panel: DockPanel
  let file: FileBinding
  let controller = EditorController()
  let styler: (any TextStyler)?

  @State var dirty: Bool
  @State var confirmingClose: Bool = false
  @State var status: String = "Ln 1, Col 1"
  /// What went wrong reading or saving the file; "" when nothing did.
  @State var problem: String

  init(panel: DockPanel) {
    self.panel = panel
    let path = panel.storage.value(IDE.pathKey, default: StoredText(rawValue: "")).rawValue
    let file = FileBinding(path: path, unsaved: OpenFiles.shared.takeUnsaved(panel: panel.id))
    self.file = file
    self.styler = Self.styler(for: path)
    self.dirty = file.isDirty
    self.problem = file.loadError ?? ""
    super.init()
    // For Save All, while the panel lives: shown or in a tab behind another.
    OpenFiles.shared.register(file)
    file.onDirtyChange = { [unowned self] dirty in
      self.dirty = dirty
      self.showTitle()
    }
    panel.shouldClose = { [weak self] in
      guard let self, self.file.isDirty else { return true }
      self.confirmingClose = true
      return false
    }
  }

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 0) {
      TextEditor(document: self.file.document)
        .styler(self.styler)
        .lineNumbers(true)
        .editable(self.file.loadError == nil)
        .controller(self.controller)
        .onSelectionChange { selection in self.showStatus(selection) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      HStack(spacing: 12) {
        Text(self.status)
          .font(Self.statusFont)
          .foregroundColor(Self.statusColor)
        Text(self.problem)
          .font(Self.statusFont)
          .foregroundColor(Self.errorColor)
          .lineLimit(1)
        Spacer()
        Text(self.file.name)
          .font(Self.statusFont)
          .foregroundColor(Self.statusColor)
      }
      .padding(Inset(vertical: 4, horizontal: 10))
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Self.barColor)
    }
    .onKeyPress(phases: .down) { press in self.key(press) }
    .alert("Save changes to “\(self.file.name)”?", isPresented: $confirmingClose) {
      Button("Save") { self.saveAndClose() }
      Button("Don’t Save", role: .destructive) { self.discardAndClose() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Your changes will be lost if you don’t save them.")
    }
  }

  override func onMount(_ context: UIContext) {
    WorkspaceModel.shared.activeFile = self.file.path
    self.showTitle()
    // Shown, so it takes the keyboard: a file just opened, a tab picked.
    context.afterLayout { [weak self] in self?.controller.focus() }
  }

  // Leaving the window — another tab picked, the panel moved or closed, the app quitting. A
  // move makes the panel anew elsewhere, from the text kept here.
  override func onUnmount(_ context: UIContext) {
    // Still in the layout: moving, or another tab picked. Not when it was closed.
    if self.file.isDirty && self.panel.space.layout.panels[self.panel.id] != nil {
      OpenFiles.shared.keepUnsaved(self.file.document.stringWithOriginalLineEndings, panel: self.panel.id)
    }
  }

  // MARK: - Actions

  private func key(_ press: KeyPress) -> KeyPress.Result {
    guard press.modifiers.contains(.command), press.key == "s" else { return .ignored }
    if press.modifiers.contains(.option) {
      OpenFiles.shared.saveAll()
    } else {
      self.save()
    }
    return .handled
  }

  @discardableResult
  func save() -> Bool {
    do {
      try self.file.save()
      OpenFiles.shared.forgetUnsaved(panel: self.panel.id)
      self.problem = ""
      return true
    } catch {
      self.problem = "\(error)"
      return false
    }
  }

  private func saveAndClose() {
    if self.save() { self.panel.close() }
  }

  private func discardAndClose() {
    OpenFiles.shared.forgetUnsaved(panel: self.panel.id)
    self.panel.close()
  }

  /// "● name" while unsaved, written only when it flips.
  private func showTitle() {
    let title = self.file.isDirty ? "● \(self.file.name)" : self.file.name
    if self.panel.title != title { self.panel.setTitle(title) }
  }

  private func showStatus(_ selection: EditorSelection) {
    let document = self.file.document
    let (line, column) = document.position(of: selection.primary.head)
    let selected = selection.ranges.reduce(0) { $0 + $1.range.count }
    self.status = selected > 0
      ? "Ln \(line + 1), Col \(column + 1) (\(selected) selected)"
      : "Ln \(line + 1), Col \(column + 1)"
  }

  static func styler(for path: String) -> (any TextStyler)? {
    switch (path as NSString).pathExtension.lowercased() {
    case "swift": SwiftStyler()
    case "md", "markdown": MarkdownStyler()
    default: nil
    }
  }
}
