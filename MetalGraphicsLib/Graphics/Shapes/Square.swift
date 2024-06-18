public struct Square {
  public var position = float2()
  public var size = float2()
  public var depth = Float()
  public var rotation = Float()
  public var color = float4(0, 0, 0, 1)
  
  public init(position: float2 = float2(), size: float2 = float2(1, 1), rotation: Float = Float(), color: float4 = float4(0, 0, 0, 1)) {
    self.position = float2(position.x, position.y)
    self.size = size
    self.rotation = rotation
    self.color = color
  }
}
