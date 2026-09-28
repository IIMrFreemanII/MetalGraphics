import EditorCore
import Foundation
import MetalGraphicsLib
import ReactiveUI
import simd
import SwiftCodeModel

/// Parses a Swift document again after each pause in typing, off the window's thread, and hands
/// back what it found: the outline and what can fold.
///
/// The text is copied on the window's thread when the pause ends (O(document), once per pause,
/// not per keystroke); the parse runs on `Services.parseQueue`; the result is posted back and
/// dropped if the text changed meanwhile, since another parse is on its way.
final class CodeModelSession: TextDocumentListener {
  let document: TextDocument
  private let executor: ThreadExecutor
  private(set) var analysis = CodeAnalysis()
  /// Told of each analysis that matches the text.
  var onAnalysis: ((CodeAnalysis) -> Void)?
  private var generation = 0

  /// On the document's window thread.
  init(document: TextDocument) {
    self.document = document
    self.executor = ThreadState.current.executor
    document.addListener(self)
    self.schedule()
  }

  func document(_ document: TextDocument, didApply changes: ChangeSet, origin: EditOrigin) {
    self.schedule()
  }

  private func schedule() {
    self.generation += 1
    let generation = self.generation
    let session = WeakSession(self)
    let executor = self.executor
    let fire: @Sendable () -> Void = { executor.post { session.session?.parse(generation) } }
    let delay = Services.parseDelay
    if delay > 0 {
      DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay, execute: fire)
    } else {
      fire()
    }
  }

  /// On the window's thread, once typing paused.
  private func parse(_ generation: Int) {
    guard generation == self.generation else { return }
    let text = self.document.string
    let revision = self.document.revision
    let session = WeakSession(self)
    let executor = self.executor
    Services.parseQueue {
      let analysis = Services.analyzeCode(text)
      executor.post { session.session?.finish(analysis, revision: revision) }
    }
  }

  private func finish(_ analysis: CodeAnalysis, revision: UInt64) {
    guard revision == self.document.revision else { return }
    self.analysis = analysis
    self.onAnalysis?(analysis)
  }
}

/// A session handed to its own thread, and read only there.
private final class WeakSession: @unchecked Sendable {
  weak var session: CodeModelSession?
  init(_ session: CodeModelSession) { self.session = session }
}

/// The outline of the file being edited, shared by every window: the file tab in front writes
/// it, the Outline panel shows it.
@Model
final class OutlineModel {
  static let shared = OutlineModel()

  var path: String = ""
  var symbols: [CodeSymbol] = []

  func reset() {
    self.path = ""
    self.symbols = []
  }
}

/// One line of the outline.
struct OutlineItem : Identifiable {
  let symbol: CodeSymbol
  let path: String

  var id: String { self.symbol.id }
}

/// The declarations of the file in front, nested by type: a click selects one in the text.
@Component
final class OutlinePanel : SingleChildElement {
  private static let captionFont = TextFont.system(size: 12)
  private static let captionColor: float4 = .secondaryLabel

  @State var items: [OutlineItem] = []
  @State var caption: String = "No file"

  @UIElementBuilder var body: [UIElement] {
    VStack(alignment: .leading, spacing: 0) {
      Text(self.caption)
        .font(Self.captionFont)
        .foregroundColor(Self.captionColor)
        .lineLimit(1)
        .padding(Inset(vertical: 6, horizontal: 10))
      ScrollView(.vertical) {
        LazyVStack(alignment: .leading, spacing: 0, items: self.items) { item in
          OutlineRow(item: item)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  override func onMount(_ context: UIContext) {
    OutlineModel.shared.__observers(named: "symbols").add(self, token: 0)
    OutlineModel.shared.__observers(named: "path").add(self, token: 0)
    self.update()
  }

  override func onUnmount(_ context: UIContext) {
    OutlineModel.shared.__observers(named: "symbols").remove(self)
    OutlineModel.shared.__observers(named: "path").remove(self)
  }

  override func __modelDidChange(_ token: Int, _ animated: Bool) {
    self.update()
  }

  private func update() {
    let model = OutlineModel.shared
    let path = model.path
    let items = model.symbols.map { OutlineItem(symbol: $0, path: path) }
    if items.map(\.id) != self.items.map(\.id) { self.items = items }
    let caption = path.isEmpty ? "No file" : (items.isEmpty ? "No symbols in \((path as NSString).lastPathComponent)"
                                                            : (path as NSString).lastPathComponent)
    if caption != self.caption { self.caption = caption }
  }
}

@Component
final class OutlineRow : SingleChildElement {
  private static let font = TextFont.system(size: 13)
  private static let markFont = TextFont.system(size: 11, weight: .semibold)
  private static let markColor: float4 = .secondaryLabel
  private static let indent: Float = 14

  let item: OutlineItem
  let badge: String
  let badgeColor: float4

  init(item: OutlineItem) {
    self.item = item
    (self.badge, self.badgeColor) = Self.badge(for: item.symbol.kind, depth: item.symbol.depth)
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    ListRow(
      indent: Float(self.item.symbol.depth) * Self.indent, spacing: 7,
      action: { IDE.reveal(self.item.path, offset: self.item.symbol.nameRange.lowerBound) }
    ) {
      KindBadge(self.badge, color: self.badgeColor)
      Text(self.item.symbol.name)
        .font(self.item.symbol.kind == .mark ? Self.markFont : Self.font)
        .foregroundColor(self.item.symbol.kind == .mark ? Self.markColor : .label)
        .lineLimit(1)
      Spacer()
    }
  }

  /// A symbol's letter and colour, from the theme's palette: a member variable is a property.
  static func badge(for kind: CodeSymbol.Kind, depth: Int = 0) -> (String, float4) {
    switch kind {
    case .class: ("C", .hue(.badgeClass))
    case .struct: ("S", .hue(.badgeStruct))
    case .enum: ("E", .hue(.badgeEnum))
    case .protocol: ("P", .hue(.indigo))
    case .actor: ("A", .hue(.badgeClass))
    case .extension: ("Ex", .hue(.gray))
    case .function, .initializer, .subscript: ("M", .hue(.badgeMethod))
    case .variable: depth > 0 ? ("P", .hue(.badgeProperty)) : ("V", .hue(.badgeVariable))
    case .enumCase: ("c", .hue(.badgeEnum))
    case .typealias: ("T", .hue(.badgeStruct))
    case .macro: ("#", .hue(.badgeMethod))
    case .mark: ("—", .hue(.gray))
    }
  }
}
