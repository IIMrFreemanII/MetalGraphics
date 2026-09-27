import simd

/// How a `Grid` lays out one cell. Set by `.gridCellColumns(_:)`, `.gridColumnAlignment(_:)`,
/// `.gridCellAnchor(_:)` and `.gridCellUnsizedAxes(_:)`.
public struct GridCellOptions: Sendable {
  /// How many columns the cell spans.
  public var columns: Int = 1
  /// How every cell in the cell's column is aligned horizontally, unless it has an anchor.
  public var columnAlignment: HorizontalAlignment? = nil
  /// Where the cell sits in the space the grid gives it, overriding the column's and row's
  /// alignment.
  public var anchor: Alignment? = nil
  /// Axes along which the cell takes the size of its column or row without affecting it.
  public var unsizedAxes: Axis = .none

  public init() {}
}

/// A row of cells in a `Grid`: its first child goes in the first column, and so on.
///
/// Laid out by its grid, which is what sizes and places its cells; outside a grid it takes no
/// space.
public final class GridRow : MultiChildElement {
  /// How the row's cells are aligned vertically; nil is the grid's.
  public var alignment: VerticalAlignment?

  /// Where the grid put each live cell, relative to the row, and how large it made the row.
  var placedOffsets: [float2] = []
  var size: float2 = .zero

  public init(alignment: VerticalAlignment? = nil, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.alignment = alignment
    super.init()
    self.applyContent(content())
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func calcPosition(_ position: float2) {
    var index = 0
    for cell in self.children where !cell.isLeaving {
      let offset = index < self.placedOffsets.count ? self.placedOffsets[index] : .zero
      self.place(cell, at: position + offset, in: position)
      index += 1
    }
    self.placeLeaving(in: position)
  }
}

/// Cells in rows and columns, as SwiftUI's `Grid`. Each `GridRow` child is a row; any other
/// child is a row of its own that spans every column.
///
/// Columns are as wide as their widest cell, rows as tall as their tallest, and when the grid
/// is offered a size, columns share its width and rows its height the way a stack shares its
/// length: the least flexible first, each offered an equal share of what is left. A cell that
/// spans several columns and needs more than them widens each equally. Each cell is then offered
/// the size of its column and row, and aligned in it by its anchor, else its column's alignment
/// and its row's, else the grid's.
///
/// Checked against SwiftUI's own layout of the same grids.
public final class Grid : MultiChildElement {
  public var alignment: Alignment
  public var horizontalSpacing: Float
  public var verticalSpacing: Float

  public private(set) var size: float2 = .zero

  // The table, rebuilt for each layout: every live cell with its row, first column and span,
  // and every row with the element that holds it.
  private var cells: [UIElement] = []
  private var cellRow: [Int] = []
  private var cellColumn: [Int] = []
  private var cellSpan: [Int] = []
  private var cellInfo: [GridCellOptions] = []
  private var rows: [UIElement] = []
  private var columnCount = 0

  // Scratch for sizing tracks, reused across layouts.
  private var widths: [Float] = []
  private var heights: [Float] = []
  private var trackMin: [Float] = []
  private var trackMax: [Float] = []
  private var order: [Int] = []
  private var columnAlignments: [HorizontalAlignment?] = []

  // From the last committed layout: where each row starts, and each free row's cell.
  private var rowTops: [Float] = []
  private var freeOffsets: [float2] = []

  public init(
    alignment: Alignment = .center, horizontalSpacing: Float = 0, verticalSpacing: Float = 0,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.alignment = alignment
    self.horizontalSpacing = horizontalSpacing
    self.verticalSpacing = verticalSpacing
    super.init()
    self.applyContent(content())
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.layout(proposal, commit: false)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.size = self.layout(proposal, commit: true)
    return self.size
  }

  // MARK: - Table

  private func buildTable() {
    self.cells.removeAll(keepingCapacity: true)
    self.cellRow.removeAll(keepingCapacity: true)
    self.cellColumn.removeAll(keepingCapacity: true)
    self.cellSpan.removeAll(keepingCapacity: true)
    self.cellInfo.removeAll(keepingCapacity: true)
    self.rows.removeAll(keepingCapacity: true)
    self.columnCount = 0

    for child in self.children where !child.isLeaving {
      let row = self.rows.count
      self.rows.append(child)
      if let gridRow = child as? GridRow {
        var column = 0
        for cell in gridRow.children where !cell.isLeaving {
          let info = cell.gridCell ?? GridCellOptions()
          let span = max(info.columns, 1)
          self.cells.append(cell)
          self.cellRow.append(row)
          self.cellColumn.append(column)
          self.cellSpan.append(span)
          self.cellInfo.append(info)
          column += span
        }
        self.columnCount = max(self.columnCount, column)
      } else {
        // Spans every column; the count is only known once every row is in.
        self.cells.append(child)
        self.cellRow.append(row)
        self.cellColumn.append(0)
        self.cellSpan.append(0)
        self.cellInfo.append(child.gridCell ?? GridCellOptions())
      }
    }
    self.columnCount = max(self.columnCount, 1)
    for index in self.cellSpan.indices where self.cellSpan[index] == 0 {
      self.cellSpan[index] = self.columnCount
    }

    self.columnAlignments.removeAll(keepingCapacity: true)
    self.columnAlignments.append(contentsOf: repeatElement(nil, count: self.columnCount))
    for index in self.cells.indices where self.cellSpan[index] == 1 {
      let column = self.cellColumn[index]
      if self.columnAlignments[column] == nil, let alignment = self.cellInfo[index].columnAlignment {
        self.columnAlignments[column] = alignment
      }
    }
  }

  /// The width of the cells `column ..< column + span`, spacing between them included.
  private func spanWidth(_ column: Int, _ span: Int) -> Float {
    var width: Float = 0
    for track in column ..< min(column + span, self.widths.count) {
      width += self.widths[track]
    }
    return width + self.horizontalSpacing * Float(max(span - 1, 0))
  }

  // MARK: - Layout

  private func layout(_ proposal: ProposedSize, commit: Bool) -> float2 {
    self.buildTable()
    let rowCount = self.rows.count
    guard rowCount > 0 else {
      if commit {
        self.rowTops.removeAll(keepingCapacity: true)
        self.freeOffsets.removeAll(keepingCapacity: true)
      }
      return .zero
    }

    self.sizeColumns(proposal.width)
    self.sizeRows(proposal.height)

    var size = float2(
      self.widths.reduce(0, +) + self.horizontalSpacing * Float(self.columnCount - 1),
      self.heights.reduce(0, +) + self.verticalSpacing * Float(rowCount - 1)
    )
    size = simd_max(size, .zero)

    if commit {
      self.commitCells(width: size.x)
    }
    return size
  }

  /// Column widths into `widths`: each as wide as its widest single-column cell, sharing the
  /// width offered, then widened for cells spanning several that need more.
  private func sizeColumns(_ available: Float?) {
    let count = self.columnCount
    self.widths.removeAll(keepingCapacity: true)
    self.widths.append(contentsOf: repeatElement(0, count: count))

    // The widest a column's cells take when each is offered `width`.
    func columnWidth(_ column: Int, _ width: Float?) -> Float {
      var result: Float = 0
      for index in self.cells.indices
      where self.cellColumn[index] == column && self.cellSpan[index] == 1 && self.cellInfo[index].unsizedAxes.horizontal == 0 {
        result = max(result, self.cells[index].measure(ProposedSize(width: width, height: nil)).x)
      }
      return result
    }

    if let available {
      self.trackMin.removeAll(keepingCapacity: true)
      self.trackMax.removeAll(keepingCapacity: true)
      for column in 0..<count {
        self.trackMin.append(columnWidth(column, 0))
        self.trackMax.append(columnWidth(column, .infinity))
      }
      self.shareTracks(available - self.horizontalSpacing * Float(count - 1)) { column, share in
        self.widths[column] = columnWidth(column, share)
        return self.widths[column]
      }
    } else {
      for column in 0..<count {
        self.widths[column] = columnWidth(column, nil)
      }
    }

    // Cells spanning several columns widen them, equally, to their ideal width — as far as the
    // width offered allows.
    for index in self.cells.indices where self.cellSpan[index] > 1 && self.cellInfo[index].unsizedAxes.horizontal == 0 {
      let column = self.cellColumn[index]
      let span = min(self.cellSpan[index], count - column)
      let current = self.spanWidth(column, span)
      var needed = self.cells[index].measure(.unspecified).x
      if let available {
        let total = self.spanWidth(0, count)
        needed = min(needed, current + max(available - total, 0))
      }
      guard needed > current, span > 0 else { continue }
      let extra = (needed - current) / Float(span)
      for track in column ..< column + span {
        self.widths[track] += extra
      }
    }
  }

  /// Row heights into `heights`: each as tall as its tallest cell at its width, sharing the
  /// height offered.
  private func sizeRows(_ available: Float?) {
    let count = self.rows.count
    self.heights.removeAll(keepingCapacity: true)
    self.heights.append(contentsOf: repeatElement(0, count: count))

    func rowHeight(_ row: Int, _ height: Float?) -> Float {
      var result: Float = 0
      for index in self.cells.indices where self.cellRow[index] == row && self.cellInfo[index].unsizedAxes.vertical == 0 {
        let width = self.spanWidth(self.cellColumn[index], self.cellSpan[index])
        result = max(result, self.cells[index].measure(ProposedSize(width: width, height: height)).y)
      }
      return result
    }

    if let available {
      self.trackMin.removeAll(keepingCapacity: true)
      self.trackMax.removeAll(keepingCapacity: true)
      for row in 0..<count {
        self.trackMin.append(rowHeight(row, 0))
        self.trackMax.append(rowHeight(row, .infinity))
      }
      self.shareTracks(available - self.verticalSpacing * Float(count - 1)) { row, share in
        self.heights[row] = rowHeight(row, share)
        return self.heights[row]
      }
    } else {
      for row in 0..<count {
        self.heights[row] = rowHeight(row, nil)
      }
    }
  }

  /// Shares `available` among the tracks in `trackMin`/`trackMax` as a stack shares its length:
  /// least flexible first, each offered an equal share of what is left. `size` sizes one track
  /// for the length it is offered and returns what it took.
  private func shareTracks(_ available: Float, _ size: (Int, Float) -> Float) {
    let count = self.trackMin.count
    self.order.removeAll(keepingCapacity: true)
    self.order.append(contentsOf: 0..<count)
    self.order.sort { a, b in
      let flexA = self.trackMax[a] - self.trackMin[a]
      let flexB = self.trackMax[b] - self.trackMin[b]
      return flexA != flexB ? flexA < flexB : a < b
    }
    var remaining = available
    for (position, track) in self.order.enumerated() {
      let share = max(remaining / Float(count - position), 0)
      remaining -= size(track, share)
    }
  }

  /// Sizes every cell for good, in the box of its columns and row, and works out where it goes.
  private func commitCells(width: Float) {
    self.rowTops.removeAll(keepingCapacity: true)
    self.freeOffsets.removeAll(keepingCapacity: true)
    var top: Float = 0
    for row in self.rows.indices {
      self.rowTops.append(top)
      self.freeOffsets.append(.zero)
      (self.rows[row] as? GridRow)?.placedOffsets.removeAll(keepingCapacity: true)
      top += self.heights[row] + self.verticalSpacing
    }

    var index = 0
    while index < self.cells.count {
      let row = self.cellRow[index]
      let gridRow = self.rows[row] as? GridRow
      let rowAlignment = gridRow?.alignment ?? self.alignment.vertical
      // A row aligned on a baseline or a guide of its own lines its cells up on one line, as a
      // stack does; any other alignment places each cell in its own box.
      let rowLine = rowAlignment.key.isFraction ? nil : self.rowLine(row, rowAlignment.key)

      while index < self.cells.count && self.cellRow[index] == row {
        let cell = self.cells[index]
        let column = self.cellColumn[index]
        let box = float2(self.spanWidth(column, self.cellSpan[index]), self.heights[row])
        let proposal = ProposedSize(box)
        let cellSize = cell.calcSize(proposal)

        let horizontal = self.cellSpan[index] == 1 ? self.columnAlignments[column] : nil
        let alignment = self.cellInfo[index].anchor
          ?? Alignment(horizontal: horizontal ?? self.alignment.horizontal, vertical: rowAlignment)
        var offset = self.alignedOffset(cell, alignment, in: box, proposal, cellSize)
        if let rowLine, self.cellInfo[index].anchor == nil {
          offset.y = rowLine - cell.alignmentValue(rowAlignment.key, proposal, cellSize)
        }
        offset.x += self.spanWidth(0, column) + (column > 0 ? self.horizontalSpacing : 0)

        if let gridRow {
          gridRow.placedOffsets.append(offset)
        } else {
          self.freeOffsets[row] = offset
        }
        index += 1
      }
      gridRow?.size = float2(width, self.heights[row])
    }
  }

  /// The line a row's cells meet on for `key`: the furthest guide down among them.
  private func rowLine(_ row: Int, _ key: AlignmentKey) -> Float {
    var line: Float = 0
    for index in self.cells.indices where self.cellRow[index] == row {
      let box = float2(self.spanWidth(self.cellColumn[index], self.cellSpan[index]), self.heights[row])
      let size = self.cells[index].measure(ProposedSize(box))
      line = max(line, self.cells[index].alignmentValue(key, ProposedSize(box), size))
    }
    return line
  }

  public override func calcPosition(_ position: float2) {
    self.buildTable()
    for (row, element) in self.rows.enumerated() where row < self.rowTops.count {
      let origin = position + float2(0, self.rowTops[row])
      if element is GridRow {
        self.place(element, at: origin, in: position)
      } else {
        self.place(element, at: origin + self.freeOffsets[row], in: position)
      }
    }
    self.placeLeaving(in: position)
    // Not kept past the pass, so a removed cell is not held on to.
    self.cells.removeAll(keepingCapacity: true)
    self.rows.removeAll(keepingCapacity: true)
  }
}
