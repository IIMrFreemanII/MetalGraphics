public typealias float3 = SIMD3<Float>

// MARK: - float3

public extension float3 {
  static let up: float3 = .init(0, 1, 0)
  static let down: float3 = .init(0, -1, 0)
  static let forward: float3 = .init(0, 0, 1)
  static let back: float3 = .init(0, 0, -1)
  static let left: float3 = .init(-1, 0, 0)
  static let right: float3 = .init(1, 0, 0)

  var xy: float2 {
    get {
      float2(x, y)
    }
    set(new) {
      x = new.x
      y = new.y
    }
  }

  var width: Float {
    x
  }

  var height: Float {
    y
  }

  var depth: Float {
    z
  }
}
