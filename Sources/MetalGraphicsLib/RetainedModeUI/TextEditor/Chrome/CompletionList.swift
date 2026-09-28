import simd

/// One line of a `CompletionList`.
public struct CompletionItem : Identifiable, Hashable, Sendable {
  /// What keeps its row across updates. Give the selected one an id of its own (`"12*"`), so a
  /// selection change rebuilds just the two rows it moves between.
  public let id: String
  public let label: String
  /// Its type, at the trailing edge; "" for none.
  public let detail: String
  /// Its kind's letter: M, P, V, C, S, E, Pr (`KindBadge.color(forLetter:)`).
  public let badge: String
  public let isSelected: Bool
  /// Its place in the list: what a click reports.
  public let index: Int

  public init(id: String, label: String, detail: String = "", badge: String, isSelected: Bool = false, index: Int) {
    self.id = id
    self.label = label
    self.detail = detail
    self.badge = badge
    self.isSelected = isSelected
    self.index = index
  }
}

/// A `CompletionList`'s sizes and type.
public enum CompletionListMetrics {
  /// The list's width, less its padding.
  public static let width: Float = 420
  public static let rowHeight: Float = 26
  public static let padding: Float = 5
  public static let shape = UIShape.rect(cornerRadius: 10)
  public static let font = TextFont.system(size: 12.5, design: .monospaced)
  public static let detailFont = TextFont.system(size: 11.5)
  public static let footerFont = TextFont.system(size: 11)
  public static let footerInset = Inset(left: 8, top: 6, right: 8, bottom: 2)
  public static let shadowRadius: Float = 12
  public static let shadowY: Float = 6
}

/// The completion popup: menu glass, a row per candidate with its kind's badge, its name and its
/// type, the selected one on the accent, and under a hairline the selected one's detail. Not in
/// SwiftUI; put it over the text, where the caret is.
///
///     CompletionList(items: rows, footer: "Void") { index in accept(index) }
public final class CompletionList : SingleChildElement {
  public private(set) var items: [CompletionItem]
  public private(set) var footer: String
  /// What a click on a row reports: its `index`.
  public var onPick: ((Int) -> Void)?

  private var list: VList<CompletionItem>!
  private let column = VStack(alignment: .leading, spacing: 0)
  private let footerText: Text
  private let rule: UIElement

  public init(items: [CompletionItem], footer: String = "", onPick: ((Int) -> Void)? = nil) {
    self.items = items
    self.footer = footer
    self.onPick = onPick
    self.footerText = Text(footer)
      .font(CompletionListMetrics.footerFont)
      .foregroundColor(.secondaryLabel)
      .lineLimit(1)
    self.rule = Rectangle(.separator)
      .frame(height: 0.5)
      .padding(Inset(top: 4))
    super.init()
    self.list = VList(alignment: .leading, spacing: 0, items: items) { [unowned self] item in
      CompletionRowElement(item: item) { [unowned self] index in self.onPick?(index) }
    }
    self.column.applyContent(self.columnContent())
    self.applyContent([
      self.column
        .frame(width: CompletionListMetrics.width)
        .padding(CompletionListMetrics.padding)
        .glass(.menu, in: CompletionListMetrics.shape)
        .border(.separator, width: 0.5, in: CompletionListMetrics.shape)
        .shadow(color: .shadow, radius: CompletionListMetrics.shadowRadius, y: CompletionListMetrics.shadowY)
    ])
  }

  private func columnContent() -> [UIElement] {
    var content: [UIElement] = [self.list]
    if !self.footer.isEmpty {
      content.append(self.rule)
      content.append(self.footerText.padding(CompletionListMetrics.footerInset))
    }
    return content
  }

  /// The rows, by id: kept ones stay, as a list's.
  public func setItems(_ value: [CompletionItem], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.items else { return }
    self.items = value
    self.list.setItems(value, context, animation: animation)
  }

  /// The line under the rows; "" hides it and its hairline.
  public func setFooter(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.footer else { return }
    let shown = !self.footer.isEmpty
    self.footer = value
    if !value.isEmpty { self.footerText.setText(value, context, animation: animation) }
    if shown != !value.isEmpty {
      self.column.replaceChildren(self.columnContent(), context, animation: animation)
    }
  }
}

/// One row of a `CompletionList`: a prominent `ListRow` with the badge, the name and the type.
final class CompletionRowElement : SingleChildElement {
  let item: CompletionItem

  init(item: CompletionItem, onPick: @escaping (Int) -> Void) {
    self.item = item
    super.init()
    let index = item.index
    self.applyContent([
      ListRow(
        selected: item.isSelected, selectionStyle: .prominent, height: CompletionListMetrics.rowHeight, margin: 0, spacing: 8,
        action: { onPick(index) }
      ) {
        KindBadge(item.badge, color: KindBadge.color(forLetter: item.badge))
        Text(item.label)
          .font(CompletionListMetrics.font)
          .lineLimit(1)
        Spacer()
        Text(item.detail)
          .font(CompletionListMetrics.detailFont)
          .foregroundColor(item.isSelected ? ListRowMetrics.selectedDetailColor : ListRowMetrics.secondaryColor)
          .lineLimit(1)
      }
    ])
  }
}
