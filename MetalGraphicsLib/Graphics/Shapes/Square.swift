public struct Square {
  public var position = float3()
  public var size = float2(1, 1)
  public var rotation = Float()
  public var color = float4(0, 0, 0, 1)
  
  public init(position: float3 = float3(), size: float2 = float2(1, 1), rotation: Float = Float(), color: float4 = float4(0, 0, 0, 1)) {
    self.position = position
    self.size = size
    self.rotation = rotation
    self.color = color
  }
}
