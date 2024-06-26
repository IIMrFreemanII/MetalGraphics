import simd

public extension float3x3 {
  init(normalFrom4x4 matrix: float4x4) {
    self.init()
    columns = matrix.upperLeft.inverse.transpose.columns
  }

  // MARK: - Rotate

  init(rotationX angle: Float) {
    let c = cos(angle)
    let s = sin(angle)

    let matrix = float3x3(
      float3(1, 0, 0),
      float3(0, c, s),
      float3(0, -s, c)
    )
    self = matrix
  }

  init(rotationY angle: Float) {
    let c = cos(angle)
    let s = sin(angle)

    let matrix = float3x3(
      float3(c, 0, -s),
      float3(0, 1, 0),
      float3(s, 0, c)
    )
    self = matrix
  }

  init(rotationZ angle: Float) {
    let c = cos(angle)
    let s = sin(angle)

    let matrix = float3x3(
      float3(c, s, 0),
      float3(-s, c, 0),
      float3(0, 0, 1)
    )
    self = matrix
  }

  init(rotation angle: float3) {
    let rotationX = float3x3(rotationX: angle.x)
    let rotationY = float3x3(rotationY: angle.y)
    let rotationZ = float3x3(rotationZ: angle.z)
    self = rotationZ * rotationY * rotationX
  }

  init(rotationYXZ angle: float3) {
    let rotationX = float3x3(rotationX: angle.x)
    let rotationY = float3x3(rotationY: angle.y)
    let rotationZ = float3x3(rotationZ: angle.z)
    self = rotationY * rotationX * rotationZ
  }
}
