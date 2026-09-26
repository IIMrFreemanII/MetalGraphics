import Foundation
import simd

/// Rows of `items` in named columns, as SwiftUI's `Table`, with a header that stays put while
/// the rows scroll under it.
///
/// ```swift
/// Table(items: self.people, selection: self.selection, sortOrder: self.sortOrder,
///       onSelectionChange: { self.selection = $0 },
///       onSortOrderChange: { self.sortOrder = $0; self.replacePeople(self.people.sorted(using: $0)) }) {
///   TableColumn("Name", value: \.name)
///   TableColumn("Age", value: \.age) { Text("\($0.age)") }.width(60).alignment(.trailing)
/// }
/// ```
///
/// Rows are built only near what shows, by a `LazyVStack`, and keep their elements by id, so a
/// sort reuses every row. Columns share the width the table is offered: fixed ones take their
/// width, the rest share what is left within their min and max, and dragging a divider in the
/// header sets a column's width. Content wider than its column is clipped.
///
/// With no bindings, selection and sort order go both ways by value: the table shows what it is
/// given, updates itself on a click, and reports the new value through its callback. Clicking a
/// row selects it; with command it toggles; with shift it selects the range from the last row
/// clicked. Clicking the title of a column made from a key path sorts by it, and again reverses.
public final class Table<T: Identifiable> : SingleChildElement {
  public private(set) var selection: Set<T.ID>
  public private(set) var sortOrder: [KeyPathComparator<T>]
  public var onSelectionChange: ((Set<T.ID>) -> Void)?
  public var onSortOrderChange: (([KeyPathComparator<T>]) -> Void)?
  /// Drawn behind selected rows.
  public var selectionColor = float4(0.25, 0.5, 0.95, 0.3)

  public var items: [T] { self.rows.items }

  private let columns: [TableColumn<T>]
  private let layout: TableColumnLayout
  private var rows: LazyVStack<T>!
  private var titles: [Text] = []
  private weak var context: UIContext? = nil

  /// The row a shift-click selects from.
  private var anchor: T.ID? = nil
  private var resizeStart = float2.zero

  private var position: float2 = .zero
  private var size: float2 = .zero

  public init(
    items: [T], selection: Set<T.ID> = [], sortOrder: [KeyPathComparator<T>] = [],
    onSelectionChange: ((Set<T.ID>) -> Void)? = nil,
    onSortOrderChange: (([KeyPathComparator<T>]) -> Void)? = nil,
    @TableColumnBuilder<T> columns: () -> [TableColumn<T>]
  ) {
    self.selection = selection
    self.sortOrder = sortOrder
    self.onSelectionChange = onSelectionChange
    self.onSortOrderChange = onSortOrderChange
    self.columns = columns()
    self.layout = TableColumnLayout(specs: self.columns.map(\.width))
    super.init()

    // Rows capture the table unowned: it holds them, through the stack.
    self.rows = LazyVStack(alignment: .leading, spacing: 0, items: items) { [unowned self] item in
      self.makeRow(item)
    }
    let header = self.makeHeader()
    self.applyContent([
      VStack(alignment: .leading, spacing: 0) {
        Background(TableMetrics.headerColor) { header }
        Divider()
        ScrollView(.vertical) { self.rows }
      }
    ])
  }

  public override func mount(_ context: UIContext) {
    self.context = context
  }

  // MARK: - Building

  private func makeRow(_ item: T) -> UIElement {
    let cells = self.columns.map { column in
      TableCell(alignment: column.alignment, content: column.content(item))
    }
    let id = item.id
    let highlight = TableRowHighlight(table: self, id: id, content: TableCells(self.layout, cells: cells))
    return HittableView(onTap: { [unowned self] input in self.rowTapped(id, input) }) { highlight }
  }

  private func makeHeader() -> TableHeader {
    self.titles = self.columns.indices.map { index in
      Text(self.title(index))
        .font(TableMetrics.headerFont)
        .foregroundColor(.black)
    }
    let titleCells = self.columns.indices.map { index in
      TableCell(alignment: self.columns[index].alignment, content: self.titles[index])
    }
    let tapAreas = self.columns.indices.map { index in
      HittableView(onTap: { [unowned self] _ in self.headerTapped(index) }) {}
    }
    // Every edge but the last: the last column's right edge is the table's.
    let dividers = self.columns.indices.dropLast().map { index in
      let divider = HittableView(
        // Swallows the click, so the title under it does not sort as a resize starts.
        onTap: { _ in },
        onPress: { [unowned self] down, input in
          if down { self.resizeStart = float2(input.mousePosition.x, self.layout.widths[index]) }
        },
        onDrag: { [unowned self] input in self.resize(index, input) }
      ) {
        TableColumnDivider()
      }
      divider.pointerStyle = .columnResize
      return divider
    }
    return TableHeader(self.layout, titles: TableCells(self.layout, cells: titleCells), tapAreas: tapAreas, dividers: dividers)
  }

  // MARK: - Layout

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = super.calcSize(proposal)
    return self.size
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
    super.calcPosition(position)
  }

  // Columns wider than the table, after a divider was dragged out, are cut at its edge.
  override var clipRect: ClipRect? {
    ClipRect(position: self.position, size: self.size)
  }

  // MARK: - Items

  public func setItems(_ items: [T], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.rows.setItems(items, context, animation: animation)
  }

  public func insertRow(_ item: T, at index: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.rows.insertRow(item, at: index, context, animation: animation)
  }

  public func removeRow(_ item: T, at index: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.rows.removeRow(item, at: index, context, animation: animation)
  }

  // MARK: - Selection

  public func setSelection(_ value: Set<T.ID>, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.selection else { return }
    self.selection = value
    context.invalidate(.render)
  }

  private func rowTapped(_ id: T.ID, _ input: Input) {
    var next = self.selection
    if input.commandPressed {
      if next.remove(id) == nil { next.insert(id) }
      self.anchor = id
    } else if input.shiftPressed, let anchor = self.anchor,
              let from = self.items.firstIndex(where: { $0.id == anchor }),
              let to = self.items.firstIndex(where: { $0.id == id }) {
      next = Set(self.items[min(from, to)...max(from, to)].map(\.id))
    } else {
      next = [id]
      self.anchor = id
    }
    guard next != self.selection else { return }
    self.selection = next
    self.context?.invalidate(.render)
    self.onSelectionChange?(next)
  }

  // MARK: - Sorting

  public func setSortOrder(_ value: [KeyPathComparator<T>], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.sortOrder else { return }
    self.sortOrder = value
    self.updateTitles(context)
  }

  /// Whether `a` and `b` sort by the same key, whichever way.
  private static func sameKey(_ a: KeyPathComparator<T>, _ b: KeyPathComparator<T>) -> Bool {
    var a = a
    var b = b
    a.order = .forward
    b.order = .forward
    return a == b
  }

  private func title(_ index: Int) -> String {
    let column = self.columns[index]
    guard let comparator = column.comparator, let first = self.sortOrder.first,
          Self.sameKey(first, comparator) else { return column.title }
    return column.title + (first.order == .forward ? " ▲" : " ▼")
  }

  private func updateTitles(_ context: UIContext) {
    for (index, text) in self.titles.enumerated() {
      let title = self.title(index)
      if text.text != title { text.setText(title, context) }
    }
  }

  private func headerTapped(_ index: Int) {
    guard let comparator = self.columns[index].comparator, let context = self.context else { return }
    var order = self.sortOrder
    if var first = order.first, Self.sameKey(first, comparator) {
      first.order = first.order == .forward ? .reverse : .forward
      order[0] = first
    } else {
      order.removeAll { Self.sameKey($0, comparator) }
      var leading = comparator
      leading.order = .forward
      order.insert(leading, at: 0)
    }
    self.sortOrder = order
    self.updateTitles(context)
    self.onSortOrderChange?(order)
  }

  // MARK: - Resizing

  private func resize(_ index: Int, _ input: Input) {
    let width = self.resizeStart.y + input.mousePosition.x - self.resizeStart.x
    guard self.layout.resize(index, to: width), let context = self.context else { return }
    context.invalidate(.layout)
  }
}
