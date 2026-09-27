import EditorCore
import Foundation
import MetalGraphicsLib
import ReactiveUI
import simd

/// What builds and runs print, with the buttons that start and stop them. Standard error is
/// dimmed, its lines that mention an error red. It keeps to the end as output arrives, unless scrolled up.
///
/// The text is this window's document, fed from the shared `BuildLog`: each update appends the
/// chunks it has not shown, so a long build costs what it adds, not what it holds. A new build
/// starts it over.
@Component
final class ConsolePanel : SingleChildElement {
  private static let font = TextFont.system(size: 12, design: .monospaced)
  private static let statusFont = TextFont.system(size: 12)
  private static let statusColor = float4(0.42, 0.42, 0.45, 1)
  private static let barColor = float4(0.955, 0.955, 0.96, 1)
  private static let theme: EditorTheme = {
    var theme = EditorTheme.dark
    theme.currentLine = nil
    theme.lineSpacing = 2
    theme.textInset = float2(10, 8)
    theme[.output] = SpanStyle(foreground: float4(0.6, 0.6, 0.63, 1))
    return theme
  }()

  let document = TextDocument()
  /// The log's generation shown, and how many of its chunks.
  private var generation = -1
  private var shown = 0

  @State var summary: String = "Ready"
  @State var isActive: Bool = false
  @State var productTitle: String = "Run"

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        Button("Build") { BuildController.shared.start(.build) }
          .disabled(self.isActive)
        Button(self.productTitle) { BuildController.shared.start(.run(product: nil)) }
          .disabled(self.isActive)
        Button("Product ▾") { BuildController.shared.selectNextProduct() }
          .disabled(self.isActive)
        Button("Stop") { BuildController.shared.stop() }
          .disabled(!self.isActive)
        Text(self.summary)
          .font(Self.statusFont)
          .foregroundColor(Self.statusColor)
          .lineLimit(1)
        Spacer()
        Button("Clear") { self.clear() }
      }
      .padding(Inset(vertical: 5, horizontal: 10))
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Self.barColor)
      TextEditor(document: self.document)
        .editorTheme(Self.theme)
        .editable(false)
        .followsTail(true)
        .font(Self.font)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  override func onMount(_ context: UIContext) {
    let model = BuildModel.shared
    for name in ["logVersion", "state", "summary", "product"] {
      model.__observers(named: name).add(self, token: 0)
    }
    self.update()
  }

  override func onUnmount(_ context: UIContext) {
    BuildModel.shared.__observers(named: "logVersion").remove(self)
    BuildModel.shared.__observers(named: "state").remove(self)
    BuildModel.shared.__observers(named: "summary").remove(self)
    BuildModel.shared.__observers(named: "product").remove(self)
  }

  override func __modelDidChange(_ token: Int, _ animated: Bool) {
    self.update()
  }

  private func update() {
    let model = BuildModel.shared
    let summary = model.summary.isEmpty ? "Ready" : model.summary
    if summary != self.summary { self.summary = summary }
    let active = model.state.isActive
    if active != self.isActive { self.isActive = active }
    let title = model.product.isEmpty ? "Run" : "Run \(model.product)"
    if title != self.productTitle { self.productTitle = title }
    self.pull()
  }

  /// Appends what the log has that this console has not shown.
  private func pull() {
    let log = BuildController.shared.log
    let generation = log.generation
    if generation != self.generation {
      self.generation = generation
      self.shown = 0
      self.document.setText("")
    }
    let (chunks, next) = log.chunks(from: self.shown)
    self.shown = next
    for chunk in chunks {
      guard chunk.isError else {
        self.document.append(chunk.text)
        continue
      }
      // SwiftPM prints its progress on standard error too: only what reads as an error is red,
      // the rest is dimmed.
      for line in chunk.text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
        let text = line.offset > 0 ? "\n" + line.element : String(line.element)
        guard !text.isEmpty else { continue }
        let isError = line.element.localizedCaseInsensitiveContains("error")
        self.document.append(text, token: isError ? .error : .output)
      }
    }
  }

  private func clear() {
    self.document.setText("")
  }
}

/// A problem in the list: where, and what.
struct ProblemItem : Identifiable {
  let diagnostic: CompilerDiagnostic
  let location: String

  var id: String { self.diagnostic.id }

  init(_ diagnostic: CompilerDiagnostic, root: String) {
    self.diagnostic = diagnostic
    self.location = "\(TextPositions.relativePath(diagnostic.path, from: root)):\(diagnostic.line):\(diagnostic.column)"
  }
}

/// The build's errors and warnings: a click shows the place in its file.
@Component
final class ProblemsPanel : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.47, 1)

  @State var items: [ProblemItem] = []
  @State var summary: String = "No problems"

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 0) {
      Text(self.summary)
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
        .padding(Inset(vertical: 6, horizontal: 10))
      ScrollView(.vertical) {
        VList(alignment: .leading, spacing: 0, items: self.items) { item in
          ProblemRow(item: item)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  override func onMount(_ context: UIContext) {
    BuildModel.shared.__observers(named: "problems").add(self, token: 0)
    self.update()
  }

  override func onUnmount(_ context: UIContext) {
    BuildModel.shared.__observers(named: "problems").remove(self)
  }

  override func __modelDidChange(_ token: Int, _ animated: Bool) {
    self.update()
  }

  private func update() {
    let root = WorkspaceModel.shared.rootPath
    // Errors first, then warnings, then notes; in the order printed within each.
    let problems = BuildModel.shared.problems.enumerated()
      .sorted { $0.element.severity != $1.element.severity ? $0.element.severity > $1.element.severity : $0.offset < $1.offset }
      .map { ProblemItem($0.element, root: root) }
    guard problems.map(\.id) != self.items.map(\.id) else { return }
    self.items = problems
    let errors = problems.count { $0.diagnostic.severity == .error }
    let warnings = problems.count { $0.diagnostic.severity == .warning }
    self.summary = problems.isEmpty ? "No problems"
      : [BuildController.count(errors, "error"), BuildController.count(warnings, "warning")].joined(separator: ", ")
  }
}

@Component
final class ProblemRow : SingleChildElement {
  private static let messageFont = TextFont.system(size: 12)
  private static let locationFont = TextFont.system(size: 11)
  private static let locationColor = float4(0.45, 0.45, 0.47, 1)
  private static let errorColor = float4(0.88, 0.19, 0.18, 1)
  private static let warningColor = float4(0.91, 0.64, 0.0, 1)
  private static let noteColor = float4(0.35, 0.5, 0.8, 1)
  private static let hoverColor = float4(0, 0, 0, 0.05)
  private static let clearColor = float4(0, 0, 0, 0)

  let item: ProblemItem
  @State var hovered: Bool = false

  init(item: ProblemItem) {
    self.item = item
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    HStack(alignment: .top, spacing: 8) {
      Rectangle(self.item.diagnostic.severity == .error ? Self.errorColor
                : (self.item.diagnostic.severity == .warning ? Self.warningColor : Self.noteColor))
        .frame(width: 8, height: 8)
        .padding(Inset(top: 4))
      VStack(alignment: .leading, spacing: 1) {
        Text(self.item.diagnostic.message)
          .font(Self.messageFont)
          .lineLimit(2)
        Text(self.item.location)
          .font(Self.locationFont)
          .foregroundColor(Self.locationColor)
          .lineLimit(1)
      }
      Spacer()
    }
    .padding(Inset(vertical: 4, horizontal: 10))
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(self.hovered ? Self.hoverColor : Self.clearColor)
    .onHover { hovered, _ in self.hovered = hovered }
    .onTap { _ in
      let diagnostic = self.item.diagnostic
      IDE.openFile(diagnostic.path, line: diagnostic.line, column: diagnostic.column)
    }
  }
}
