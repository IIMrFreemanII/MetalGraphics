public struct Line {
  public var start = float2()
  public var end = float2()
  public var color = float4(0, 0, 0, 1)
  public var depth = Float()
  public var thickness = Float()
  
  var bounds: BoundingBox2D {
    // MARK: calc bounding box for line
    return BoundingBox2D(center: float2(), size: float2())
  }
  
  public init(start: float2 = float2(), end: float2 = float2(), color: float4 = float4(0, 0, 0, 1), thickness: Float = Float()) {
    self.start = start
    self.end = end
    self.color = color
    self.thickness = thickness
  }
}
