import simd

extension float2x2 {
  public init(rotation angle: Float) {
    let s = sin(angle)
    let c = cos(angle)
    let matrix = float2x2(
      float2( c, s),
      float2(-s, c)
    )
    self = matrix
  }
}
