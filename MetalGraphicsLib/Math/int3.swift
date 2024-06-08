public typealias int3 = SIMD3<Int>

public extension int3 {
  func toFloat() -> float3 {
    return float3(Float(self.x), Float(self.y), Float(self.z))
  }
}
