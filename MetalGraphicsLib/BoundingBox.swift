import simd

public struct BoundingBox2D {
  public var center: float2 = .init()
  public var size = float2(1, 1)

  public init() {}

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
    -self.size.x * 0.5
  }

  public var right: Float {
    self.size.x * 0.5
  }

  public var bottom: Float {
    -self.size.y * 0.5
  }

  public var top: Float {
    self.size.y * 0.5
  }

  public var width: Float {
    self.size.x
  }

  public var height: Float {
    self.size.y
  }

  public var topLeft: float2 {
    self.center + float2(-self.size.x, self.size.y) * 0.5
  }

  public var bottomRight: float2 {
    self.center + float2(self.size.x, -self.size.y) * 0.5
  }
}

public func boundingBox2D(position: float2, size: float2, rotation: Float = 0) -> BoundingBox2D {
  if rotation != 0 {
    let rotMat = float2x2(rotation: rotation)
    let rotTopleft = rotMat * float2(-size.x, size.y) * 0.5
    let rotTopRight = rotMat * float2(size.x, size.y) * 0.5
    
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
    
    return BoundingBox2D(center: position, size: newSize)
  }
  
  return BoundingBox2D(center: position, size: size)
}

public struct BoundingBox3D {
  public var center: float3 = .init()
  public var size = float3(1, 1, 1)

  public init() {}

  public init(center: float3, size: float3) {
    self.center = center
    self.size = size
  }

  public init(center: float3, radius: Float) {
    self.center = center
    self.size = float3(radius, radius, radius)
  }

  public var left: Float {
    -self.size.x * 0.5
  }

  public var right: Float {
    self.size.x * 0.5
  }

  public var bottom: Float {
    -self.size.y * 0.5
  }

  public var top: Float {
    self.size.y * 0.5
  }

  public var back: Float {
    -self.size.z * 0.5
  }

  public var front: Float {
    self.size.z * 0.5
  }

  public var width: Float {
    self.size.x
  }

  public var height: Float {
    self.size.y
  }

  public var depth: Float {
    self.size.z
  }

  public var topLeftFront: float3 {
    self.center + float3(-self.size.x, self.size.y, self.size.z) * 0.5
  }

  public var bottomRightBack: float3 {
    self.center + float3(self.size.x, -self.size.y, -self.size.z) * 0.5
  }
}
