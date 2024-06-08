public typealias int2 = SIMD2<Int>

public extension int2 {
  func toFloat() -> float2 {
    return float2(Float(self.x), Float(self.y))
  }
}
