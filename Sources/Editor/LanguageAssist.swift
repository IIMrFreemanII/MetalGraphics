import EditorCore
import Foundation
import MetalGraphicsLib
import ReactiveUI
import simd

/// One line of a completion list.
struct CompletionRow : Identifiable {
  let id: String
  let label: String
  let detail: String
  let badge: String
  let isSelected: Bool
  /// Its place in the filtered list: what a click accepts.
  let index: Int
}

/// Completion, hover and definitions for a Swift file's tab: what the language server answers,
/// turned into what the tab shows, which it is handed through `onCompletion` and `onHover`.
/// Lives on the tab's window thread; answers arrive on the server's queue and are posted here.
///
/// - A completion list opens after `.`, or once two letters of a word are typed. It asks the
///   server once, then narrows what it got as typing goes on: what starts with the word, then
///   what matches it loosely (`FuzzyMatcher`), each in the server's order. ↑ ↓ pick, Return
///   and Tab accept, Escape closes; typing past the word, or moving out of it, closes it too.
/// - A hover shows the problem under the pointer, else what the server says of the symbol.
/// - ⌘-click and ⌃⌘J go to the definition of the symbol there.
final class LanguageAssist {
  static let listWidth: Float = 400
  static let rowHeight: Float = 22
  static let visibleRows = 10

  let language: LanguageDocument
  let controller: EditorController
  private let executor: ThreadExecutor
  private var path: String { self.language.path }

  /// What the list should show, and where, in the editor's coordinates; nil hides it.
  var onCompletion: (([CompletionRow], Inset)?) -> Void = { _ in }
  /// What a tooltip should say, and where; nil hides it.
  var onHover: ((String, Inset)?) -> Void = { _ in }

  private(set) var isCompleting = false
  /// Where the word being completed starts.
  private var anchor = 0
  private var items: [LSPCompletionItem] = []
  private(set) var filtered: [LSPCompletionItem] = []
  private(set) var selected = 0
  private var request: Int? = nil
  private var serial = 0
  private var accepting = false
  private var hoverSerial = 0
  /// An edit made since the selection was last reported: acted on then, once the caret has
  /// moved with it.
  private var pendingEdit: EditOrigin? = nil

  /// On the tab's window thread.
  init(language: LanguageDocument, controller: EditorController) {
    self.language = language
    self.controller = controller
    self.executor = ThreadState.current.executor
  }

  private var document: TextDocument { self.language.document }

  /// The single caret, when there is one.
  private var caret: Int? {
    guard let selection = self.controller.editor?.state.selection, selection.isSingleCaret else { return nil }
    return selection.primary.head
  }

  // MARK: - Completion

  /// An edit was made. The caret moves with it after the document is told, so what it means
  /// for the list is worked out when the selection is reported, at the end of the frame.
  func edited(_ origin: EditOrigin) {
    guard !self.accepting else { return }
    guard origin == .user else { return self.dismiss() }
    self.pendingEdit = origin
  }

  /// The selection was reported, once a frame: after an edit, narrows the list, closes it or
  /// opens one; after a move out of the word being completed, closes it.
  func selectionChanged() {
    if let origin = self.pendingEdit {
      self.pendingEdit = nil
      self.afterEdit(origin)
      return
    }
    guard self.isCompleting || self.request != nil else { return }
    guard let caret = self.caret, caret >= self.anchor, self.isWord(self.anchor ..< caret) else { return self.dismiss() }
  }

  private func afterEdit(_ origin: EditOrigin) {
    guard let caret = self.caret else { return self.dismiss() }
    if self.isCompleting || self.request != nil {
      if caret >= self.anchor, self.isWord(self.anchor ..< caret) {
        if self.isCompleting { self.filter() }
        return
      }
      // Typed past the word: this list is over, and what was typed may start another (a ".").
      self.dismiss()
    }
    guard caret > 0 else { return }
    let before = self.document.unit(at: caret - 1)
    if before == 0x2E {  // "."
      self.ask(anchor: caret)
    } else if Self.isWordUnit(before) {
      var start = caret
      while start > 0, Self.isWordUnit(self.document.unit(at: start - 1)) { start -= 1 }
      // The word's second letter, not a number.
      let first = self.document.unit(at: start)
      if caret - start == 2, !(0x30 ... 0x39).contains(first) { self.ask(anchor: start) }
    }
  }

  /// Keys while the list shows. Returns true for those it took.
  func command(_ command: EditorCommand) -> Bool {
    guard self.isCompleting else { return false }
    switch command {
    case let .move(.visualLine, forward, false):
      self.selected = (self.selected + (forward ? 1 : -1) + self.filtered.count) % max(self.filtered.count, 1)
      self.show()
      return true
    case .insertNewline, .insertTab:
      self.accept(self.selected)
      return true
    case .cancel:
      self.dismiss()
      return true
    default:
      return false
    }
  }

  /// Types `filtered[index]` over what was typed of it, as one step to undo.
  func accept(_ index: Int) {
    guard self.filtered.indices.contains(index), let caret = self.caret, caret >= self.anchor else { return self.dismiss() }
    let item = self.filtered[index]
    self.accepting = true
    self.controller.select(self.anchor ..< caret, reveal: .none)
    self.controller.perform(.insertText(item.textToInsert))
    self.accepting = false
    self.dismiss()
    self.controller.focus()
  }

  func dismiss() {
    if let request = self.request {
      self.language.service.cancel(request)
      self.request = nil
    }
    self.serial += 1
    guard self.isCompleting else { return }
    self.isCompleting = false
    self.items = []
    self.filtered = []
    self.onCompletion(nil)
  }

  private func ask(anchor: Int) {
    guard let caret = self.caret else { return }
    self.dismiss()
    self.anchor = anchor
    self.serial += 1
    let serial = self.serial
    let assist = WeakAssist(self)
    let executor = self.executor
    self.request = self.language.service.completion(path: self.path, at: self.language.position(caret)) { items in
      executor.post { assist.assist?.received(items, serial: serial) }
    }
  }

  private func received(_ items: [LSPCompletionItem], serial: Int) {
    guard serial == self.serial else { return }
    self.request = nil
    guard let caret = self.caret, caret >= self.anchor, !items.isEmpty else { return }
    self.items = items
    self.isCompleting = true
    self.filter()
  }

  /// Narrows the list to what matches the word typed so far.
  private func filter() {
    guard let caret = self.caret else { return self.dismiss() }
    let typed = self.document.substring(self.anchor ..< caret)
    let lower = typed.lowercased()
    // What starts with the word first, then what matches it loosely; each in the server's order.
    let matched = self.items.compactMap { item -> (item: LSPCompletionItem, loose: Bool)? in
      if item.matchText.lowercased().hasPrefix(lower) { return (item, false) }
      return FuzzyMatcher.score(typed, item.matchText) != nil ? (item, true) : nil
    }
    self.filtered = matched.sorted { a, b in
      if a.loose != b.loose { return !a.loose }
      let (x, y) = (a.item.sortText ?? a.item.label, b.item.sortText ?? b.item.label)
      return x != y ? x < y : a.item.index < b.item.index
    }.prefix(100).map(\.item)
    guard !self.filtered.isEmpty else { return self.dismiss() }
    self.selected = 0
    self.show()
  }

  /// The rows around the selected one, below the word, or above it at the bottom of the view.
  private func show() {
    guard let editor = self.controller.editor, let rect = editor.caretRect(for: self.anchor) else { return }
    let start = max(0, min(self.selected - Self.visibleRows / 2, self.filtered.count - Self.visibleRows))
    let end = min(start + Self.visibleRows, self.filtered.count)
    let rows = (start ..< end).map { index in
      let item = self.filtered[index]
      return CompletionRow(
        id: "\(item.index)\(index == self.selected ? "*" : "")", label: item.label, detail: item.detail ?? "",
        badge: Self.badge(item.kind), isSelected: index == self.selected, index: index
      )
    }
    let height = Float(rows.count) * Self.rowHeight
    var y = rect.origin.y + rect.height + 2
    if y + height > editor.bounds.y && rect.origin.y - height - 2 >= 0 {
      y = rect.origin.y - height - 2
    }
    let x = max(0, min(rect.origin.x - 26, editor.bounds.x - Self.listWidth))
    self.onCompletion((rows, Inset(left: x, top: y)))
  }

  static func badge(_ kind: LSPCompletionItem.Kind?) -> String {
    switch kind {
    case .method, .function, .constructor: "M"
    case .field, .property, .variable: "V"
    case .class, .struct, .enum, .interface: "T"
    case .enumMember: "c"
    case .keyword: "K"
    case .module: "m"
    default: "·"
    }
  }

  private func isWord(_ range: Range<Int>) -> Bool {
    self.document.withUTF16(in: range) { units in units.allSatisfy(Self.isWordUnit) }
  }

  static func isWordUnit(_ unit: UInt16) -> Bool {
    (unit >= 0x30 && unit <= 0x39) || (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A) || unit == 0x5F
      || unit >= 0x80
  }

  // MARK: - Hover

  /// The pointer rested on `offset`, at `point` in the editor; nil when it moved on.
  func hover(_ offset: Int?, at point: float2) {
    self.hoverSerial += 1
    guard let offset, !self.isCompleting else { return self.onHover(nil) }
    // A problem under the pointer says what it is.
    var message = ""
    self.document.diagnostics.forEach(overlapping: offset ..< offset + 1) { mark in
      if message.isEmpty { message = mark.payload.message }
    }
    if !message.isEmpty { return self.showHover(message, at: point) }
    let serial = self.hoverSerial
    let assist = WeakAssist(self)
    let executor = self.executor
    self.language.service.hover(path: self.path, at: self.language.position(offset)) { text in
      executor.post {
        guard let assist = assist.assist, assist.hoverSerial == serial, let text else { return }
        assist.showHover(text, at: point)
      }
    }
  }

  private func showHover(_ text: String, at point: float2) {
    let text = text.count > 800 ? String(text.prefix(800)) + "…" : text
    let width = self.controller.editor?.bounds.x ?? 600
    self.onHover((text, Inset(left: max(0, min(point.x + 4, width - 420)), top: point.y + 18)))
  }

  // MARK: - Definitions

  /// Shows where the symbol at `offset` is declared: here, or in its file.
  func goToDefinition(at offset: Int) {
    let assist = WeakAssist(self)
    let executor = self.executor
    self.language.service.definition(path: self.path, at: self.language.position(offset)) { locations in
      executor.post { assist.assist?.show(locations) }
    }
  }

  private func show(_ locations: [LSPLocation]) {
    guard let location = locations.first, let path = location.path else { return }
    let start = location.range.start
    if path == self.path {
      let offset = LanguageDocument.offset(start, in: self.document)
      self.controller.select(offset ..< offset, reveal: .center)
    } else {
      IDE.reveal(path, line: start.line, character: start.character)
    }
  }
}

/// An assist handed to its own thread, and read only there.
private final class WeakAssist: @unchecked Sendable {
  weak var assist: LanguageAssist?
  init(_ assist: LanguageAssist) { self.assist = assist }
}

/// A line of the completion list: what kind of thing, its name, and its type.
@Component
final class CompletionRowView : SingleChildElement {
  private static let font = TextFont.system(size: 12, design: .monospaced)
  private static let detailFont = TextFont.system(size: 11)
  private static let badgeFont = TextFont.system(size: 9, weight: .bold)
  private static let selectedColor = float4(0.0, 0.45, 0.95, 1)
  private static let clearColor = float4(0, 0, 0, 0)
  private static let textColor = float4(0.12, 0.12, 0.14, 1)
  private static let detailColor = float4(0.45, 0.45, 0.48, 1)
  private static let badgeColor = float4(0.35, 0.45, 0.75, 1)

  let row: CompletionRow
  let onPick: (Int) -> Void

  init(row: CompletionRow, onPick: @escaping (Int) -> Void) {
    self.row = row
    self.onPick = onPick
    super.init()
  }

  @UIElementBuilder var body: [UIElement] {
    HStack(spacing: 6) {
      Text(self.row.badge)
        .font(Self.badgeFont)
        .foregroundColor(.white)
        .frame(width: 14, height: 14)
        .background(Self.badgeColor)
      Text(self.row.label)
        .font(Self.font)
        .foregroundColor(self.row.isSelected ? .white : Self.textColor)
        .lineLimit(1)
      Spacer()
      Text(self.row.detail)
        .font(Self.detailFont)
        .foregroundColor(self.row.isSelected ? .white : Self.detailColor)
        .lineLimit(1)
    }
    .padding(Inset(vertical: 3, horizontal: 6))
    .frame(width: LanguageAssist.listWidth, height: LanguageAssist.rowHeight, alignment: .leading)
    .background(self.row.isSelected ? Self.selectedColor : Self.clearColor)
    .onTap { _ in self.onPick(self.row.index) }
  }
}
