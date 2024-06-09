import simd

extension float4x4 {
  private func format(_ columnt: simd_float4, _ value: Float) -> String {
    let hasNegativeSignInColumnt = columnt.x.isNegative || columnt.y.isNegative || columnt.z.isNegative || columnt.w.isNegative
    return hasNegativeSignInColumnt && value.isNegative ? "\(String(format: "%.4f", value))" : " \(String(format: "%.4f", value))"
  }
  
  public var formated: String {
    """
    *------------ float4x4 ------------*
    |\(self.format(self.columns.0, self.columns.0.x)), \(self.format(self.columns.1, self.columns.1.x)), \(self.format(self.columns.2, self.columns.2.x)), \(self.format(self.columns.3, self.columns.3.x))|
    |\(self.format(self.columns.0, self.columns.0.y)), \(self.format(self.columns.1, self.columns.1.y)), \(self.format(self.columns.2, self.columns.2.y)), \(self.format(self.columns.3, self.columns.3.y))|
    |\(self.format(self.columns.0, self.columns.0.z)), \(self.format(self.columns.1, self.columns.1.z)), \(self.format(self.columns.2, self.columns.2.z)), \(self.format(self.columns.3, self.columns.3.z))|
    |\(self.format(self.columns.0, self.columns.0.w)), \(self.format(self.columns.1, self.columns.1.w)), \(self.format(self.columns.2, self.columns.2.w)), \(self.format(self.columns.3, self.columns.3.w))|
    *----------------------------------*
    """
  }
}

extension float4x4 {
  public static func * (m: Self, v: float3) -> float3 {
    return (m * float4(v, 1)).xyz
  }
  
  // MARK: - Translate
  public init(translation: float3) {
    let matrix = float4x4(
      float4(            1,             0,             0, 0),
      float4(            0,             1,             0, 0),
      float4(            0,             0,             1, 0),
      float4(translation.x, translation.y, translation.z, 1)
    )
    self = matrix
  }
  
  // MARK: - Scale
  public init(scaling: float3) {
    let matrix = float4x4(
      float4(scaling.x,         0,         0, 0),
      float4(        0, scaling.y,         0, 0),
      float4(        0,         0, scaling.z, 0),
      float4(        0,         0,         0, 1)
    )
    self = matrix
  }
  
  public init(scaling: Float) {
    self = matrix_identity_float4x4
    columns.3.w = 1 / scaling
  }
  
  // MARK: - Rotate
  public init(rotationX angle: Float) {
    let c = cos(angle)
    let s = sin(angle)
    
    let matrix = float4x4(
      float4(1, 0, 0, 0),
      float4(0, c, s, 0),
      float4(0,-s, c, 0),
      float4(0, 0, 0, 1)
    )
    self = matrix
  }
  
  public init(rotationY angle: Float) {
    let c = cos(angle)
    let s = sin(angle)
    
    let matrix = float4x4(
      float4(c, 0,-s, 0),
      float4(0, 1, 0, 0),
      float4(s, 0, c, 0),
      float4(0, 0, 0, 1)
    )
    self = matrix
  }
  
  public init(rotationZ angle: Float) {
    let c = cos(angle)
    let s = sin(angle)
    
    let matrix = float4x4(
      float4( c, s, 0, 0),
      float4(-s, c, 0, 0),
      float4( 0, 0, 1, 0),
      float4( 0, 0, 0, 1)
    )
    self = matrix
  }
  
  public init(rotation angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationZ * rotationY * rotationZ
  }
  
  public init(rotationYXZ angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationY * rotationX * rotationZ
  }
  
  // MARK: - Identity
  public static var identity: float4x4 {
    matrix_identity_float4x4
  }
  
  // MARK: - Upper left 3x3
  public var upperLeft: float3x3 {
    let x = columns.0.xyz
    let y = columns.1.xyz
    let z = columns.2.xyz
    return float3x3(columns: (x, y, z))
  }
  
  // MARK: - Left handed projection matrix
  public init(projectionFov fov: Float, near: Float, far: Float, aspect: Float, lhs: Bool = true) {
    let y = 1 / tan(fov * 0.5)
    let x = y / aspect
    let z = lhs ? far / (far - near) : far / (near - far)
    
    let X = float4( x,  0,  0,  0)
    let Y = float4( 0,  y,  0,  0)
    let Z = lhs ? float4( 0,  0,  z, 1) : float4( 0,  0,  z, -1)
    let W = lhs ? float4( 0,  0,  z * -near,  0) : float4( 0,  0,  z * near,  0)
    
    self.init()
    columns = (X, Y, Z, W)
  }
  
  // left-handed LookAt
  public init(eye: float3, center: float3, up: float3) {
    let z = normalize(center - eye)
    let x = normalize(cross(up, z))
    let y = cross(z, x)
    
    let X = float4(x.x, y.x, z.x, 0)
    let Y = float4(x.y, y.y, z.y, 0)
    let Z = float4(x.z, y.z, z.z, 0)
    let W = float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
    
    self.init()
    columns = (X, Y, Z, W)
  }
  
  // MARK: - Orthographic matrix
  public init(orthographic rect: Rect, near: Float, far: Float) {
    let left = rect.position.x
    let right = rect.position.x + rect.width
    let top = rect.position.y
    let bottom = rect.position.y + rect.height
    let X = float4(2 / (right - left), 0, 0, 0)
    let Y = float4(0, 2 / (top - bottom), 0, 0)
    let Z = float4(0, 0, 1 / (far - near), 0)
    let W = float4(
      (left + right) / (left - right),
      (top + bottom) / (bottom - top),
      near / (near - far),
      1)
    self.init()
    columns = (X, Y, Z, W)
  }
  
  // MARK: - Orthographic matrix
  public init(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
    self.init()
    let invRL = 1 / (right - left)
    let invTB = 1 / (top - bottom)
    let invFN = 1 / (far - near)
    
    let X = float4(2 * invRL, 0        , 0     , 0)
    let Y = float4(0        , 2 * invTB, 0     , 0)
    let Z = float4(0        , 0        , -invFN, 0)
    let W = float4(
      -(right + left) * invRL,
      -(top + bottom) * invTB,
      -(far + near) * invFN,
      1
    )
    
    columns = (X, Y, Z, W)
  }
  
  // convert double4x4 to float4x4
  public init(_ m: matrix_double4x4) {
    self.init()
    let matrix = float4x4(
      float4(m.columns.0),
      float4(m.columns.1),
      float4(m.columns.2),
      float4(m.columns.3))
    self = matrix
  }
}
