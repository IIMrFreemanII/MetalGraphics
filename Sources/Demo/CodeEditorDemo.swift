import MetalGraphicsLib
import ReactiveUI
import simd

// A code editor: Swift highlighted as it is typed, line numbers, soft wrap, search, and
// diagnostics underlined where they are. The document is edited in place — the editor holds a
// `TextDocument` rather than a string — so "Load 100k lines" stays as quick to type in as the
// sample. What the status line shows comes from `onSelectionChange`.
@Component
final class CodeEditorDemo : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor = float4(0.45, 0.45, 0.47, 1)

  let document = TextDocument(CodeEditorDemo.sample)

  @State var wrap: Bool = false
  @State var numbers: Bool = true
  @State var dark: Bool = false
  @State var query: String = ""
  @State var diagnostics: [TextDiagnostic] = []
  @State var status: String = "Ln 1, Col 1"

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 16) {
        Toggle("Wrap", isOn: $wrap)
        Toggle("Line numbers", isOn: $numbers)
        Toggle("Dark", isOn: $dark)
        TextField("Find", text: $query, prompt: "Search")
      }
      HStack(spacing: 12) {
        Button("Mark TODOs") { self.markTodos() }
        Button("Load 100k lines") { self.loadLarge() }
        Button("Reset") { self.reset() }
      }
      TextEditor(document: self.document)
        .styler(SwiftStyler())
        .lineWrapping(self.wrap ? .soft : .none)
        .lineNumbers(self.numbers)
        .editorTheme(self.dark ? .dark : .light)
        .searchQuery(self.query)
        .diagnostics(self.diagnostics)
        .onSelectionChange { selection in self.showStatus(selection) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      Text(self.status)
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
    }
  }

  private func showStatus(_ selection: EditorSelection) {
    let head = selection.primary.head
    let (line, column) = self.document.position(of: head)
    let selected = selection.ranges.reduce(0) { $0 + $1.range.count }
    let lines = "\(self.document.lineCount) lines"
    self.status = selected > 0
      ? "Ln \(line + 1), Col \(column + 1) — \(selected) selected — \(lines)"
      : "Ln \(line + 1), Col \(column + 1) — \(lines)"
  }

  /// Every "TODO" gets a warning, every "fatalError" an error.
  private func markTodos() {
    var found: [TextDiagnostic] = []
    for (word, severity) in [("TODO", DiagnosticSeverity.warning), ("fatalError", .error)] {
      let units = Array(word.utf16)
      for line in 0 ..< self.document.lineCount {
        let range = self.document.lineRange(line)
        let text = Array(self.document.lineText(line).utf16)
        guard text.count >= units.count else { continue }
        for i in 0 ... text.count - units.count where Array(text[i ..< i + units.count]) == units {
          found.append(TextDiagnostic(range.lowerBound + i ..< range.lowerBound + i + units.count, severity))
        }
      }
    }
    self.diagnostics = found
  }

  private func loadLarge() {
    let block = CodeEditorDemo.sample + "\n"
    let lines = block.utf16.reduce(0) { $0 + ($1 == 0x0A ? 1 : 0) }
    self.document.setText(String(repeating: block, count: 100_000 / lines + 1))
    self.diagnostics = []
  }

  private func reset() {
    self.document.setText(CodeEditorDemo.sample)
    self.diagnostics = []
  }

  static let sample = """
  import Foundation

  /// A point on a plane, and the distance between two.
  struct Point: Hashable, Sendable {
    var x: Double
    var y: Double

    func distance(to other: Point) -> Double {
      let dx = other.x - x, dy = other.y - y
      return (dx * dx + dy * dy).squareRoot()
    }
  }

  /* Shapes know their area.
     /* Comments nest. */
     Still a comment. */
  protocol Shape {
    var area: Double { get }
  }

  @MainActor
  final class Canvas {
    private(set) var shapes: [any Shape] = []
    var title = "Untitled"

    func add(_ shape: some Shape) {
      shapes.append(shape)
      print("Added shape #\\(shapes.count) with area \\(shape.area)")
    }

    func largest() -> (any Shape)? {
      // TODO: keep them sorted instead.
      shapes.max { $0.area < $1.area }
    }

    func clear() {
      guard !shapes.isEmpty else { fatalError("nothing to clear") }
      shapes.removeAll(keepingCapacity: true)
    }
  }

  let summary = #"Raw "strings" keep \\n as written"#
  let bits = 0b1010_0101, hex = 0xFF, big = 1_000_000.5e-3
  """
}
