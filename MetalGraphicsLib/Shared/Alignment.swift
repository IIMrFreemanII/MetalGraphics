public struct Alignment {
  public let xOffset: Float
  public let yOffset: Float
  
  public var offset: float2 {
    float2(xOffset, yOffset)
  }
  
  public init(_ xOffset: Float, _ yOffset: Float) {
    self.xOffset = xOffset
    self.yOffset = yOffset
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

public struct HorizontalAlignment {
  public let offset: Float
  
  public init(_ offset: Float) {
    self.offset = offset
  }
  
  public static let leading: Self = .init(0.0)
  public static let center: Self = .init(0.5)
  public static let trailing: Self = .init(1.0)
}

public struct VerticalAlignment {
  public let offset: Float
  
  public init(_ offset: Float) {
    self.offset = offset
  }
  
  public static let top: Self = .init(0)
  public static let center: Self = .init(0.5)
  public static let bottom: Self = .init(1)
}
