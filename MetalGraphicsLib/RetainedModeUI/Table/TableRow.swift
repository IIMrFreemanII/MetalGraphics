import simd

// The pieces a `Table` is built from. None of them is public: a table makes its own header and
// rows from its columns.

@MainActor
enum TableMetrics {
  /// Between a cell's edges and its content.
  static let cellPadding = float2(6, 3)
  /// How wide the grab area of a header divider is, centred on the column edge.
  static let handleWidth: Float = 8
  static let headerColor = float4(0.94, 0.94, 0.94, 1)
  static let dividerColor = float4(0, 0, 0, 0.12)
  static let headerFont = TextFont.system(size: 12)
  /// For the cells of a column made from a key path to text.
  static let cellFont = TextFont.system(size: 13)
}

/// One cell: its content at its ideal size, aligned in the box its row gives it — column width by
/// row height — and clipped to that box. Content wider than the column is cut rather than
/// wrapped, so every row keeps to one line of text, as in SwiftUI's table.
final class TableCell : SingleChildElement {
  let alignment: HorizontalAlignment
  private var position: float2 = .zero
  /// Set by the row once it knows how tall it is.
  var box: float2 = .zero
  private var contentSize: float2 = .zero

  init(alignment: HorizontalAlignment, content: UIElement) {
    self.alignment = alignment
    super.init()
    self.applyContent([content])
  }

  override func getSize() -> float2 {
    self.box
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.child?.measure(proposal) ?? .zero
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.contentSize = self.child?.calcSize(proposal) ?? .zero
    return self.contentSize
  }

  override func calcPosition(_ position: float2) {
    self.position = position
    guard let child = self.child else { return }
    let padding = TableMetrics.cellPadding
    let slack = simd_max(self.box - self.contentSize - padding * 2, .zero)
    let origin = position + padding + float2(slack.x * self.alignment.offset, slack.y * 0.5)
    self.place(child, at: origin, in: position)
  }

  override var clipRect: ClipRect? {
    ClipRect(position: self.position, size: self.box)
  }
}

/// A row of cells, one per column, at the widths the table's columns resolve to for the width
/// the row is offered. As tall as its tallest cell. O(columns).
final class TableCells : MultiChildElement {
  unowned let columns: TableColumnLayout
  private(set) var size: float2 = .zero

  init(_ columns: TableColumnLayout, cells: [TableCell]) {
    self.columns = columns
    super.init()
    self.applyContent(cells)
  }

  override func getSize() -> float2 {
    self.size
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.layout(proposal, commit: false)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.layout(proposal, commit: true)
    return self.size
  }

  // Each cell is sized once, at its ideal: the row's height comes from the cells, and the box
  // they are then aligned in only moves them, so nothing is measured twice.
  private func layout(_ proposal: ProposedSize, commit: Bool) -> float2 {
    self.columns.resolve(proposal.width)
    let padding = TableMetrics.cellPadding
    var height: Float = 0
    for cell in self.children {
      let size = commit ? cell.calcSize(.unspecified) : cell.measure(.unspecified)
      height = max(height, size.y)
    }
    height += padding.y * 2
    if commit {
      for (index, cell) in self.children.enumerated() where index < self.columns.count {
        unsafeDowncast(cell, to: TableCell.self).box = float2(self.columns.widths[index], height)
      }
    }
    let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? self.columns.total
    return float2(max(width, self.columns.total), height)
  }

  override func calcPosition(_ position: float2) {
    for (index, cell) in self.children.enumerated() where index < self.columns.count {
      self.place(cell, at: position + float2(self.columns.offsets[index], 0), in: position)
    }
  }
}

/// Behind a row: the selection highlight, drawn only while the row is selected. It reads the
/// selection as it draws, so selecting a row costs a render and nothing else.
final class TableRowHighlight<T: Identifiable> : Background {
  unowned let table: Table<T>
  let id: T.ID

  init(table: Table<T>, id: T.ID, content: UIElement) {
    self.table = table
    self.id = id
    super.init(table.selectionColor) { content }
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard self.table.selection.contains(self.id) else { return }
    self.color = self.table.selectionColor
    super.render(renderer, effect)
  }
}

/// A column edge in the header: a thin line, and the area around it that a drag resizes from.
final class TableColumnDivider : UIRenderableElement {
  private var position: float2 = .zero
  private var size: float2 = .zero

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  override func getSize() -> float2 {
    self.size
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    proposal.replacingUnspecified(with: float2(TableMetrics.handleWidth, 0))
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.sizeThatFits(proposal)
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.position = position
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0 else { return }
    let inset: Float = 4
    let size = float2(1, max(self.size.y - inset * 2, 0)) * effect.scale
    var color = TableMetrics.dividerColor
    color.w *= effect.opacity
    let topLeft = self.position + float2((self.size.x - 1) * 0.5, inset)
    let origin = effect.apply(to: topLeft) - renderer.size * 0.5 + size * 0.5
    renderer.draw(square: Square(position: origin, size: size, color: color))
  }
}

/// The header: a row of titles, with an area over each that sorts by its column when tapped,
/// and a divider on each column edge but the last that resizes the column when dragged.
///
/// Children, in paint and hit order: the titles row, the tap areas, then the dividers, which
/// are drawn and hit over the tap areas.
final class TableHeader : MultiChildElement {
  unowned let columns: TableColumnLayout
  let titles: TableCells
  let tapAreas: [HittableView]
  let dividers: [HittableView]
  private(set) var size: float2 = .zero

  init(_ columns: TableColumnLayout, titles: TableCells, tapAreas: [HittableView], dividers: [HittableView]) {
    self.columns = columns
    self.titles = titles
    self.tapAreas = tapAreas
    self.dividers = dividers
    super.init()
    self.applyContent([titles] + tapAreas + dividers)
  }

  override func getSize() -> float2 {
    self.size
  }

  override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.titles.measure(proposal)
  }

  override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.titles.calcSize(proposal)
    for (index, area) in self.tapAreas.enumerated() {
      _ = area.calcSize(ProposedSize(width: self.columns.widths[index], height: self.size.y))
    }
    for divider in self.dividers {
      _ = divider.calcSize(ProposedSize(width: TableMetrics.handleWidth, height: self.size.y))
    }
    return self.size
  }

  override func calcPosition(_ position: float2) {
    self.place(self.titles, at: position, in: position)
    for (index, area) in self.tapAreas.enumerated() {
      self.place(area, at: position + float2(self.columns.offsets[index], 0), in: position)
    }
    for (index, divider) in self.dividers.enumerated() {
      let edge = self.columns.offsets[index] + self.columns.widths[index]
      self.place(divider, at: position + float2(edge - TableMetrics.handleWidth * 0.5, 0), in: position)
    }
  }
}
