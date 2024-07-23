extension IMView {
  struct Axis {
    let horizontal: Float
    let vertical: Float
    
    var size: float2 {
      float2(horizontal, vertical)
    }
    var inverted: float2 {
      float2(vertical, horizontal)
    }
    
    private init(_ horizontal: Float, _ vertical: Float) {
      self.horizontal = horizontal
      self.vertical = vertical
    }
    
    static let none: Self = .init(0.0, 0.0)
    static let horizontal: Self = .init(1.0, 0.0)
    static let vertical: Self = .init(0.0, 1.0)
    static let both: Self = .init(1.0, 1.0)
  }
}
