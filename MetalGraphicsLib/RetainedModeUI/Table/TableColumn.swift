import Foundation
import simd

/// How wide a `TableColumn` may be: `ideal` when there is room for every column's ideal, and
/// anywhere between `min` and `max` as flexible columns share what the table is offered.
public struct TableColumnWidth: Sendable, Equatable {
  public var min: Float
  public var ideal: Float
  public var max: Float

  public init(min: Float, ideal: Float, max: Float) {
    self.min = min
    self.ideal = Swift.min(Swift.max(ideal, min), max)
    self.max = max
  }

  public static func fixed(_ width: Float) -> TableColumnWidth {
    TableColumnWidth(min: width, ideal: width, max: width)
  }

  public static let flexible = TableColumnWidth(min: 30, ideal: 100, max: .infinity)

  func clamp(_ width: Float) -> Float {
    Swift.min(Swift.max(width, self.min), self.max)
  }
}

/// A column of a `Table`, as SwiftUI's: a title, how each row's cell is made, and — when made
/// from a key path — how the column sorts.
public struct TableColumn<T> {
  public var title: String
  public var width: TableColumnWidth = .flexible
  /// Where cells narrower than the column sit in it, header included.
  public var alignment: HorizontalAlignment = .leading
  /// What sorting by this column sorts by; nil when the column does not sort.
  public let comparator: KeyPathComparator<T>?
  let content: @MainActor (T) -> UIElement

  /// A column of text read from each row, sorting by it.
  public init(_ title: String, value: KeyPath<T, String> & Sendable) {
    self.title = title
    self.comparator = KeyPathComparator(value)
    self.content = { @MainActor item in Text(item[keyPath: value]).font(TableMetrics.cellFont) }
  }

  /// A column of cells made by `content`, sorting by `value`.
  public init<V: Comparable>(
    _ title: String, value: KeyPath<T, V> & Sendable, content: @escaping @MainActor (T) -> UIElement
  ) {
    self.title = title
    self.comparator = KeyPathComparator(value)
    self.content = content
  }

  /// A column of cells made by `content`, which does not sort.
  public init(_ title: String, content: @escaping @MainActor (T) -> UIElement) {
    self.title = title
    self.comparator = nil
    self.content = content
  }

  /// Always `width` wide; dragging its header divider does not resize it.
  public func width(_ width: Float) -> TableColumn<T> {
    var column = self
    column.width = .fixed(width)
    return column
  }

  /// Between `min` and `max`, `ideal` when there is room for it.
  public func width(min: Float? = nil, ideal: Float? = nil, max: Float? = nil) -> TableColumn<T> {
    var column = self
    let base = TableColumnWidth.flexible
    column.width = TableColumnWidth(min: min ?? 10, ideal: ideal ?? base.ideal, max: max ?? base.max)
    return column
  }

  public func alignment(_ alignment: HorizontalAlignment) -> TableColumn<T> {
    var column = self
    column.alignment = alignment
    return column
  }
}

/// Builds a table's columns: `Table(items:) { TableColumn(…); TableColumn(…) }`.
@resultBuilder
public enum TableColumnBuilder<T> {
  public static func buildExpression(_ column: TableColumn<T>) -> [TableColumn<T>] { [column] }
  public static func buildBlock(_ parts: [TableColumn<T>]...) -> [TableColumn<T>] { parts.flatMap { $0 } }
  public static func buildOptional(_ part: [TableColumn<T>]?) -> [TableColumn<T>] { part ?? [] }
  public static func buildEither(first part: [TableColumn<T>]) -> [TableColumn<T>] { part }
  public static func buildEither(second part: [TableColumn<T>]) -> [TableColumn<T>] { part }
  public static func buildArray(_ parts: [[TableColumn<T>]]) -> [TableColumn<T>] { parts.flatMap { $0 } }
}

/// The widths of a table's columns, shared by its header and every row so they line up.
///
/// Widths depend only on the width offered and on what was resized, so every row asks for them
/// with its own proposal and all but the first get the answer memoised: O(1) per row.
@MainActor
final class TableColumnLayout {
  let specs: [TableColumnWidth]
  /// Widths set by dragging a header divider; nil for a column never resized.
  private(set) var resized: [Float?]

  private(set) var widths: [Float] = []
  /// Where each column starts, from the table's leading edge.
  private(set) var offsets: [Float] = []
  private(set) var total: Float = 0

  private var version = 0
  private var resolvedVersion = -1
  private var resolvedWidth: Float? = nil
  private var order: [Int] = []

  var count: Int { self.specs.count }

  init(specs: [TableColumnWidth]) {
    self.specs = specs
    self.resized = Array(repeating: nil, count: specs.count)
    self.widths.reserveCapacity(specs.count)
    self.offsets.reserveCapacity(specs.count)
    self.order.reserveCapacity(specs.count)
  }

  /// Sets column `index` to `width`, clamped to what it allows. Returns whether that changed it.
  func resize(_ index: Int, to width: Float) -> Bool {
    let clamped = self.specs[index].clamp(width)
    guard self.resized[index] != clamped else { return false }
    self.resized[index] = clamped
    self.version += 1
    return true
  }

  /// Works out `widths` and `offsets` for a table `available` wide; nil or infinite asks for
  /// every column's ideal. Each column starts at its resized width, else its ideal. The columns
  /// never resized then share what is left over, or give back what is missing: least room first,
  /// each an equal share of what remains, within its min and max — the way `Grid` shares tracks.
  func resolve(_ available: Float?) {
    let available = available.flatMap { $0.isFinite ? $0 : nil }
    guard self.resolvedVersion != self.version || self.resolvedWidth != available else { return }
    self.resolvedVersion = self.version
    self.resolvedWidth = available

    self.widths.removeAll(keepingCapacity: true)
    for index in self.specs.indices {
      self.widths.append(self.resized[index] ?? self.specs[index].ideal)
    }

    if let available {
      let extra = available - self.widths.reduce(0, +)
      self.order.removeAll(keepingCapacity: true)
      for index in self.specs.indices where self.resized[index] == nil {
        self.order.append(index)
      }
      // Room each flexible column has in the direction the width must go.
      let growing = extra > 0
      self.order.sort { a, b in
        let roomA = growing ? self.specs[a].max - self.widths[a] : self.widths[a] - self.specs[a].min
        let roomB = growing ? self.specs[b].max - self.widths[b] : self.widths[b] - self.specs[b].min
        return roomA != roomB ? roomA < roomB : a < b
      }
      var remaining = extra
      for (position, index) in self.order.enumerated() {
        let share = remaining / Float(self.order.count - position)
        let width = self.specs[index].clamp(self.widths[index] + share)
        remaining -= width - self.widths[index]
        self.widths[index] = width
      }
    }

    self.offsets.removeAll(keepingCapacity: true)
    var offset: Float = 0
    for width in self.widths {
      self.offsets.append(offset)
      offset += width
    }
    self.total = offset
  }
}
