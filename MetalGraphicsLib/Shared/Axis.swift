public struct Axis : Sendable {
  public let horizontal: Float
  public let vertical: Float
  
  public var size: float2 {
    float2(horizontal, vertical)
  }
  public var inverted: float2 {
    float2(vertical, horizontal)
  }
  
  private init(_ horizontal: Float, _ vertical: Float) {
    self.horizontal = horizontal
    self.vertical = vertical
  }
  
  public static let none: Self = .init(0.0, 0.0)
  public static let horizontal: Self = .init(1.0, 0.0)
  public static let vertical: Self = .init(0.0, 1.0)
  public static let both: Self = .init(1.0, 1.0)
}

extension Axis : Equatable, ExpressibleByArrayLiteral {
  /// `[.vertical, .horizontal]`, as SwiftUI spells `Axis.Set`: every axis any element names.
  public init(arrayLiteral elements: Axis...) {
    self.init(
      elements.map(\.horizontal).max() ?? 0,
      elements.map(\.vertical).max() ?? 0
    )
  }

  public func contains(_ other: Axis) -> Bool {
    (other.horizontal == 0 || self.horizontal != 0) && (other.vertical == 0 || self.vertical != 0)
  }
}
