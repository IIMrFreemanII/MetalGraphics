public typealias float4 = SIMD4<Float>

public extension float4 {
  static let up: float4 = float4(0, 1, 0, 0)
  static let forward: float4 = float4(0, 0, 1, 0)
  static let right: float4 = float4(1, 0, 0, 0)
  
  var xyz: float3 {
    get {
      float3(x, y, z)
    }
    set {
      x = newValue.x
      y = newValue.y
      z = newValue.z
    }
  }
  
  init(_ value: float3, _ w: Float) {
    self.init(value.x, value.y, value.z, w)
  }
  
  // convert from double4
  init(_ d: SIMD4<Double>) {
    self.init()
    self = [Float(d.x), Float(d.y), Float(d.z), Float(d.w)]
  }
}

public extension float4 {
  func toUChar() -> uchar4 {
    return uchar4(UInt8(self.x.clamped(to: 0...1) * 255), UInt8(self.y.clamped(to: 0...1) * 255), UInt8(self.z.clamped(to: 0...1) * 255), UInt8(self.w.clamped(to: 0...1) * 255))
  }
}
