import simd

public struct Square {
  public var position = float2()
  public var size = float2()
  public var depth = Float()
  public var rotation = Float()
  public var color = float4(0, 0, 0, 1)

  public var bounds: BoundingBox2D {
    if self.rotation != 0 {
      let rotMat = float2x2(rotation: rotation)
      let rotTopleft = rotMat * float2(-self.size.x, self.size.y) * 0.5
      let rotTopRight = rotMat * float2(self.size.x, self.size.y) * 0.5

      var minX = Float.greatestFiniteMagnitude
      minX = min(minX, rotTopleft.x)
      minX = min(minX, -rotTopleft.x)
      minX = min(minX, rotTopRight.x)
      minX = min(minX, -rotTopRight.x)

      var minY = Float.greatestFiniteMagnitude
      minY = min(minY, rotTopleft.y)
      minY = min(minY, -rotTopleft.y)
      minY = min(minY, rotTopRight.y)
      minY = min(minY, -rotTopRight.y)

      let newSize = abs(float2(minX, minY)) * 2

      return BoundingBox2D(center: self.position, size: newSize)
    }

    return BoundingBox2D(center: self.position, size: self.size)
  }

  public init(position: float2 = float2(), size: float2 = float2(1, 1), rotation: Float = Float(), color: float4 = float4(0, 0, 0, 1)) {
    self.position = float2(position.x, position.y)
    self.size = size
    self.rotation = rotation
    self.color = color
  }
}
