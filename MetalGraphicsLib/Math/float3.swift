public typealias float3 = SIMD3<Float>

// MARK: - float3
public extension float3 {
  static let up: float3 = float3(0, 1, 0)
  static let down: float3 = float3(0, -1, 0)
  static let forward: float3 = float3(0, 0, 1)
  static let back: float3 = float3(0, 0, -1)
  static let left: float3 = float3(-1, 0, 0)
  static let right: float3 = float3(1, 0, 0)
  
  var xy: float2 {
    get {
      return float2(self.x, self.y)
    }
    set(new) {
      self.x = new.x
      self.y = new.y
    }
  }
  
  var width: Float {
    self.x
  }
  
  var height: Float {
    self.y
  }
  
  var depth: Float {
    self.z
  }
}
