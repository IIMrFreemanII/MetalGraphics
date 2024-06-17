public struct Circle {
  public var position = float2()
  public var radius = Float(0.5)
  public var color = float4(0, 0, 0, 1)
  
  public init(position: float2 = float2(), radius: Float = Float(0.5), color: float4 = float4(0, 0, 0, 1)) {
    self.position = position
    self.radius = radius
    self.color = color
  }
}
