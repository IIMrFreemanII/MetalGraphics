/// A kind of alignment guide of your own, as SwiftUI's `AlignmentID`: where it lies in an
/// element unless the element says otherwise with `.alignmentGuide(_:computeValue:)`.
///
/// ```swift
/// enum Quarter: AlignmentID {
///   static func defaultValue(in d: ViewDimensions) -> Float { d.width * 0.25 }
/// }
/// extension HorizontalAlignment { static let quarter = HorizontalAlignment(Quarter.self) }
/// ```
public protocol AlignmentID {
  static func defaultValue(in context: ViewDimensions) -> Float
}

/// An element's size, as an alignment guide's `computeValue` sees it.
public struct ViewDimensions {
  public let width: Float
  public let height: Float

  public init(width: Float, height: Float) {
    self.width = width
    self.height = height
  }

  init(_ size: float2) {
    self.init(width: size.x, height: size.y)
  }

  /// Where `guide` lies by default, from the left edge.
  public subscript(guide: HorizontalAlignment) -> Float {
    guide.key.defaultValue(in: self)
  }

  /// Where `guide` lies by default, from the top edge.
  public subscript(guide: VerticalAlignment) -> Float {
    guide.key.defaultValue(in: self)
  }
}

/// One alignment guide: which axis it runs along, and what it is. Explicit guides are keyed by
/// it, so `.alignmentGuide(.leading)` overrides exactly what `VStack(alignment: .leading)` reads.
public struct AlignmentKey: Hashable, @unchecked Sendable {
  enum Kind: Hashable {
    /// A fixed fraction of the size along `axis`: leading, center, top, 0.3…
    case fraction(Float)
    case firstTextBaseline
    case lastTextBaseline
    case custom(ObjectIdentifier)
  }

  /// 0 for a horizontal alignment (a position along x), 1 for a vertical one.
  let axis: Int
  let kind: Kind
  private let custom: (any AlignmentID.Type)?

  init(axis: Int, _ kind: Kind) {
    self.axis = axis
    self.kind = kind
    self.custom = nil
  }

  init(axis: Int, _ id: any AlignmentID.Type) {
    self.axis = axis
    self.kind = .custom(ObjectIdentifier(id))
    self.custom = id
  }

  public static func == (a: AlignmentKey, b: AlignmentKey) -> Bool {
    a.axis == b.axis && a.kind == b.kind
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.axis)
    hasher.combine(self.kind)
  }

  /// A fraction of the size, the one kind nothing inside an element ever changes unless it has
  /// explicit guides.
  var isFraction: Bool {
    if case .fraction = self.kind { return true }
    return false
  }

  /// Where the guide lies in an element of `size` that says nothing about it: a baseline at the
  /// bottom, as for anything without text.
  func defaultValue(in dimensions: ViewDimensions) -> Float {
    let length = self.axis == 0 ? dimensions.width : dimensions.height
    switch self.kind {
    case .fraction(let fraction): return length * fraction
    case .firstTextBaseline, .lastTextBaseline: return length
    case .custom: return self.custom?.defaultValue(in: dimensions) ?? 0
    }
  }

  func defaultValue(_ size: float2) -> Float {
    self.defaultValue(in: ViewDimensions(size))
  }

  /// Set once any element is given an explicit guide. Until then a fraction guide is always its
  /// default, and layout skips asking elements for it.
  nonisolated(unsafe) static var anyExplicit = false
}

public struct HorizontalAlignment : Sendable, Equatable {
  public let key: AlignmentKey

  public init(_ offset: Float) {
    self.key = AlignmentKey(axis: 0, .fraction(offset))
  }

  public init(_ id: any AlignmentID.Type) {
    self.key = AlignmentKey(axis: 0, id)
  }

  /// The fraction of the width it lies at; 0 for a custom alignment.
  public var offset: Float {
    if case .fraction(let fraction) = self.key.kind { return fraction }
    return 0
  }

  public static let leading: Self = .init(0.0)
  public static let center: Self = .init(0.5)
  public static let trailing: Self = .init(1.0)
}

public struct VerticalAlignment : Sendable, Equatable {
  public let key: AlignmentKey

  public init(_ offset: Float) {
    self.key = AlignmentKey(axis: 1, .fraction(offset))
  }

  public init(_ id: any AlignmentID.Type) {
    self.key = AlignmentKey(axis: 1, id)
  }

  private init(_ kind: AlignmentKey.Kind) {
    self.key = AlignmentKey(axis: 1, kind)
  }

  /// The fraction of the height it lies at; 1 for a baseline, 0 for a custom alignment.
  public var offset: Float {
    switch self.key.kind {
    case .fraction(let fraction): return fraction
    case .firstTextBaseline, .lastTextBaseline: return 1
    case .custom: return 0
    }
  }

  public static let top: Self = .init(0)
  public static let center: Self = .init(0.5)
  public static let bottom: Self = .init(1)
  /// The baseline of an element's first line of text; its bottom when it has no text.
  public static let firstTextBaseline: Self = .init(.firstTextBaseline)
  /// The baseline of an element's last line of text; its bottom when it has no text.
  public static let lastTextBaseline: Self = .init(.lastTextBaseline)
}

public struct Alignment : Sendable, Equatable {
  public let horizontal: HorizontalAlignment
  public let vertical: VerticalAlignment

  public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
    self.horizontal = horizontal
    self.vertical = vertical
  }

  public init(_ xOffset: Float, _ yOffset: Float) {
    self.init(horizontal: HorizontalAlignment(xOffset), vertical: VerticalAlignment(yOffset))
  }

  public var xOffset: Float { self.horizontal.offset }
  public var yOffset: Float { self.vertical.offset }

  /// The fractions of the size it lies at; see `HorizontalAlignment.offset`.
  public var offset: float2 {
    float2(self.xOffset, self.yOffset)
  }

  /// The guide along x, then along y.
  func key(_ axis: Int) -> AlignmentKey {
    axis == 0 ? self.horizontal.key : self.vertical.key
  }

  public static let topLeading: Self = .init(0.0, 0.0)
  public static let top: Self = .init(0.5, 0.0)
  public static let topTrailing: Self = .init(1.0, 0.0)
  public static let leading: Self = .init(0.0, 0.5)
  public static let center: Self = .init(0.5, 0.5)
  public static let trailing: Self = .init(1.0, 0.5)
  public static let bottomLeading: Self = .init(0.0, 1.0)
  public static let bottom: Self = .init(0.5, 1.0)
  public static let bottomTrailing: Self = .init(1.0, 1.0)
}
