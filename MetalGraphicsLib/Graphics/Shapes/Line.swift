public struct Line {
  public var start = float2()
  public var end = float2()
  public var color = float4(0, 0, 0, 1)
  public var depth = Float()
  public var thickness = Float()

  public var bounds: BoundingBox2D {
    let minX: Float = min(start.x, self.end.x) - self.thickness
    let minY: Float = min(start.y, self.end.y) - self.thickness

    let maxX: Float = max(start.x, self.end.x) + self.thickness
    let maxY: Float = max(start.y, self.end.y) + self.thickness

    let size = float2(maxX - minX, maxY - minY)
    let center = float2(minX, minY) + size * 0.5

    return BoundingBox2D(center: center, size: size)
  }

  public init(start: float2 = float2(), end: float2 = float2(), color: float4 = float4(0, 0, 0, 1), thickness: Float = Float()) {
    self.start = start
    self.end = end
    self.color = color
    self.thickness = thickness
  }
}
