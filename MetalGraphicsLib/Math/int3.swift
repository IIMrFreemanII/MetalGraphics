public typealias int3 = SIMD3<Int>

public extension int3 {
  func toFloat() -> float3 {
    float3(Float(x), Float(y), Float(z))
  }
}
