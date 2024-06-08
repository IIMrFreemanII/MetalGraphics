public typealias float2 = SIMD2<Float>

extension float2 {
  public var width: Float {
    self.x
  }
  
  public var height: Float {
    self.y
  }
  
  /// returns new float2 with greatest component and other components set to 0
  public var greatestComponent: float2 {
    let condition = self.x > self.y
    return float2(self.x * Float(condition), self.y * Float(!condition))
  }
}
