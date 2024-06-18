public struct Circle {
  public var position = float2()
  public var radius = Float()
  public var depth = Float()
  public var color = float4(0, 0, 0, 1)
  
  public init(position: float2 = float2(), radius: Float = Float(), color: float4 = float4(0, 0, 0, 1)) {
    self.position = float2(position.x, position.y)
    self.radius = radius
    self.color = color
  }
}
