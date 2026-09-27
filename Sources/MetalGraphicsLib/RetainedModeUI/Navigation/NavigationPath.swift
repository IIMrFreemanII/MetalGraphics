import simd

/// What a `NavigationStack`'s `path:` can be: an array of one `Hashable` type, or a
/// `NavigationPath` of any. The stack holds the values type-erased, and converts back through
/// this when it reports a change.
public protocol NavigationPathRepresentable {
  /// Nil when an element is not of the path's type: a value link of another type does not fit
  /// a typed path, and is dropped, as SwiftUI does.
  init?(navigationElements: [AnyHashable])
  var navigationElements: [AnyHashable] { get }
  /// Whether this path holds exactly `elements`, without building an array.
  func matchesNavigationElements(_ elements: [AnyHashable]) -> Bool
}

extension Array: NavigationPathRepresentable where Element: Hashable {
  public init?(navigationElements: [AnyHashable]) {
    var values: [Element] = []
    values.reserveCapacity(navigationElements.count)
    for element in navigationElements {
      guard let value = element.base as? Element else { return nil }
      values.append(value)
    }
    self = values
  }

  public var navigationElements: [AnyHashable] {
    self.map { AnyHashable($0) }
  }

  public func matchesNavigationElements(_ elements: [AnyHashable]) -> Bool {
    guard self.count == elements.count else { return false }
    for index in self.indices where AnyHashable(self[index]) != elements[index] {
      return false
    }
    return true
  }
}

/// A path of values of any `Hashable` types, as SwiftUI's: what a stack whose destinations take
/// several types binds to.
public struct NavigationPath: Equatable, NavigationPathRepresentable {
  private var elements: [AnyHashable]

  public init() {
    self.elements = []
  }

  public init<S: Sequence>(_ elements: S) where S.Element: Hashable {
    self.elements = elements.map { AnyHashable($0) }
  }

  public init?(navigationElements: [AnyHashable]) {
    self.elements = navigationElements
  }

  public var navigationElements: [AnyHashable] { self.elements }

  public func matchesNavigationElements(_ elements: [AnyHashable]) -> Bool {
    self.elements == elements
  }

  public var count: Int { self.elements.count }
  public var isEmpty: Bool { self.elements.isEmpty }

  public mutating func append<V: Hashable>(_ value: V) {
    self.elements.append(AnyHashable(value))
  }

  public mutating func removeLast(_ k: Int = 1) {
    self.elements.removeLast(k)
  }
}

/// How navigation looks and moves: one place, like `FormMetrics`.
public enum NavigationMetrics {
  public static let barHeight: Float = 38
  public static let barColor = float4(0.97, 0.97, 0.97, 1)
  public static let separatorColor = float4(0, 0, 0, 0.12)
  public static let titleFont = TextFont.custom(FormMetrics.face, size: 14).weight(.semibold)
  public static let titleColor = FormMetrics.labelColor
  /// Behind every page, so the one it covers does not show through while it slides.
  public static let contentBackground = float4(1, 1, 1, 1)

  public static let sidebarWidth: Float = 220
  public static let sidebarColor = float4(0.93, 0.93, 0.94, 1)
  public static let sidebarInset: Float = 8
  /// Behind the selected link in a sidebar.
  public static let selectionColor = float4(0.0, 0.48, 1.0, 0.18)

  /// A push or pop made without an animation of its own, as SwiftUI always animates them.
  public static let transition = UIAnimation.easeInOut(0.3)
  /// How far the covered page moves while the new one slides over it, as a fraction of the
  /// stack's width.
  public static let parallax: Float = 1.0 / 3
}
