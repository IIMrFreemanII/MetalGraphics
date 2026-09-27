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
  private static let captionColor = float4(0.45, 0.45, 0.47, 1)

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
  private static let font = TextFont.system(size: 12)
  private static let badgeFont = TextFont.system(size: 9, weight: .bold)
  private static let markFont = TextFont.system(size: 11, weight: .semibold)
  private static let markColor = float4(0.45, 0.45, 0.47, 1)
  private static let hoverColor = float4(0, 0, 0, 0.05)
  private static let clearColor = float4(0, 0, 0, 0)
  private static let indent: Float = 12

  let item: OutlineItem
  let badge: String
  let badgeColor: float4
  @State var hovered: Bool = false

  init(item: OutlineItem) {
    self.item = item
    (self.badge, self.badgeColor) = Self.badge(for: item.symbol.kind)
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    HStack(spacing: 6) {
      Text(self.badge)
        .font(Self.badgeFont)
        .foregroundColor(.white)
        .frame(width: 14, height: 14)
        .background(self.badgeColor)
      Text(self.item.symbol.name)
        .font(self.item.symbol.kind == .mark ? Self.markFont : Self.font)
        .foregroundColor(self.item.symbol.kind == .mark ? Self.markColor : float4(0.13, 0.13, 0.15, 1))
        .lineLimit(1)
      Spacer()
    }
    .padding(Inset(left: 10 + Float(self.item.symbol.depth) * Self.indent, top: 3, right: 8, bottom: 3))
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(self.hovered ? Self.hoverColor : Self.clearColor)
    .onHover { hovered, _ in self.hovered = hovered }
    .onTap { _ in IDE.reveal(self.item.path, offset: self.item.symbol.nameRange.lowerBound) }
  }

  static func badge(for kind: CodeSymbol.Kind) -> (String, float4) {
    let type = float4(0.55, 0.36, 0.78, 1)
    let member = float4(0.2, 0.5, 0.85, 1)
    let value = float4(0.28, 0.6, 0.4, 1)
    return switch kind {
    case .class: ("C", type)
    case .struct: ("S", type)
    case .enum: ("E", type)
    case .protocol: ("P", type)
    case .actor: ("A", type)
    case .extension: ("Ex", float4(0.5, 0.5, 0.55, 1))
    case .function, .initializer, .subscript: ("M", member)
    case .variable: ("V", value)
    case .enumCase: ("c", value)
    case .typealias: ("T", type)
    case .macro: ("#", member)
    case .mark: ("—", float4(0.62, 0.62, 0.65, 1))
    }
  }
}
