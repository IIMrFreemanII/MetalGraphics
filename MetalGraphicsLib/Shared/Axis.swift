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
