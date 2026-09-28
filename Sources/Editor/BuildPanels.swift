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
  private static let statusFont = TextFont.system(size: 11.5)
  private static let barFont = TextFont.system(size: 12)
  private static let statusColor: float4 = .secondaryLabel
  private static let productColor: float4 = .secondaryLabel
  private static let barColor: float4 = .barOverContent
  private static let theme: EditorTheme = {
    var theme = EditorTheme.dark
    theme.currentLine = nil
    theme.lineSpacing = 2
    theme.textInset = float2(10, 8)
    theme[.output] = SpanStyle(foreground: float4(0.6, 0.6, 0.63, 1))  // design: an EditorTheme holds plain colours, and the console is always dark
    return theme
  }()

  let document = TextDocument()
  /// The log's generation shown, and how many of its chunks.
  private var generation = -1
  private var shown = 0

  @State var summary: String = "Ready"
  @State var isActive: Bool = false
  @State var product: String = ""
  /// The dot beside the summary: how the last build went.
  @State var statusColor: float4 = .tertiaryLabel

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 6) {
        Button("Build") { BuildController.shared.start(.build) }
          .buttonStyle(.bordered)
          .disabled(self.isActive)
        Button("Run") { BuildController.shared.start(.run(product: nil)) }
          .buttonStyle(.borderedProminent)
          .disabled(self.isActive)
        // The product Run starts; a click picks the next.
        Button { BuildController.shared.selectNextProduct() } label: {
          Text(self.product.isEmpty ? "No Product" : self.product)
          Image(icon: .upDown)
            .foregroundColor(Self.productColor)
        }
        .buttonStyle(.bordered)
        .disabled(self.isActive || self.product.isEmpty)
        Button("Stop") { BuildController.shared.stop() }
          .buttonStyle(.bordered)
          .disabled(!self.isActive)
        Spacer()
        Rectangle(.clear)
          .frame(width: 7, height: 7)
          .background(self.statusColor, in: .capsule)
        Text(self.summary)
          .font(Self.statusFont)
          .foregroundColor(Self.statusColor)
          .lineLimit(1)
        Button("Clear") { self.clear() }
          .buttonStyle(.borderless)
      }
      .font(Self.barFont)
      .padding(Inset(horizontal: 10))
      .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
      .background(Self.barColor)
      .overlay(alignment: .bottom) {
        Rectangle(.separator)
          .frame(height: 0.5)
      }
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
    if model.product != self.product { self.product = model.product }
    let color: float4 = switch model.state {
    case .succeeded: .success
    case .failed: .destructive
    case .stopped: .warning
    case .building, .running, .testing: .accent
    case .idle: .tertiaryLabel
    }
    if color != self.statusColor { self.statusColor = color }
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
  private static let captionColor: float4 = .secondaryLabel

  /// Its tab, which shows how many problems there are.
  let panel: DockPanel?

  init(panel: DockPanel? = nil) {
    self.panel = panel
    super.init()
  }

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
    if let panel = self.panel, panel.space.layout.panels[panel.id]?.badge != problems.count {
      panel.setBadge(problems.count)
    }
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
  let item: ProblemItem

  init(item: ProblemItem) {
    self.item = item
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    ListRow(
      self.item.diagnostic.message, subtitle: self.item.location, status: ProblemRow.status(self.item.diagnostic.severity),
      height: ListRowMetrics.twoLineHeight, spacing: 10,
      action: {
        let diagnostic = self.item.diagnostic
        IDE.openFile(diagnostic.path, line: diagnostic.line, column: diagnostic.column)
      }
    )
  }

  /// A diagnostic's severity as a row's status square.
  static func status(_ severity: CompilerDiagnostic.Severity) -> ListRowStatus {
    switch severity {
    case .error: .error
    case .warning: .warning
    default: .note
    }
  }
}
