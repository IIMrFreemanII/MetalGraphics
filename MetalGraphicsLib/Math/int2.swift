public typealias int2 = SIMD2<Int>

public extension int2 {
  init(_ value: float2) {
    self.init()

    x = Int(value.x)
    y = Int(value.y)
  }

  func asFloat2() -> float2 {
    float2(Float(x), Float(y))
  }
}
