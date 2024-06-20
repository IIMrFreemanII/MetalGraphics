public struct BoundingBox2D {
  public var center: float2 = float2()
  public var size = float2(1, 1)
  
  public init() {
    
  }
  
  public init(center: float2, size: float2) {
    self.center = center
    self.size = size
  }
  
  public init(center: float2, radius: Float) {
    self.center = center
    let temp = radius * 2
    self.size = float2(temp, temp)
  }
  
  public var left: Float {
    return -self.size.x * 0.5
  }
  public var right: Float {
    return self.size.x * 0.5
  }
  public var bottom: Float {
    return -self.size.y * 0.5
  }
  public var top: Float {
    return self.size.y * 0.5
  }
  
  public var width: Float {
    return self.size.x
  }
  public var height: Float {
    return self.size.y
  }
  public var topLeft: float2 {
    return center + float2(-self.size.x, self.size.y) * 0.5
  }
  public var bottomRight: float2 {
    return center + float2(self.size.x, -self.size.y) * 0.5
  }
}

public struct BoundingBox3D {
  public var center: float3 = float3()
  public var size = float3(1, 1, 1)
  
  public init() {
    
  }
  
  public init(center: float3, size: float3) {
    self.center = center
    self.size = size
  }
  
  public init(center: float3, radius: Float) {
    self.center = center
    self.size = float3(radius, radius, radius)
  }
  
  public var left: Float {
    return -self.size.x * 0.5
  }
  public var right: Float {
    return self.size.x * 0.5
  }
  public var bottom: Float {
    return -self.size.y * 0.5
  }
  public var top: Float {
    return self.size.y * 0.5
  }
  public var back: Float {
    return -self.size.z * 0.5
  }
  public var front: Float {
    return self.size.z * 0.5
  }
  
  public var width: Float {
    return self.size.x
  }
  public var height: Float {
    return self.size.y
  }
  public var depth: Float {
    return self.size.z
  }
  public var topLeftFront: float3 {
    return self.center + float3(-self.size.x, self.size.y, self.size.z) * 0.5
  }
  public var bottomRightBack: float3 {
    return self.center + float3(self.size.x, -self.size.y, -self.size.z) * 0.5
  }
}
