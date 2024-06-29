import simd

public let π = Float.pi

public func toRadians(_ value: Float) -> Float {
  (value / 180) * π
}

public func toDegrees(_ value: Float) -> Float {
  (value / π) * 180
}

public func toRadians(_ value: float2) -> float2 {
  float2(toRadians(value.x), toRadians(value.y))
}

public func toDegrees(_ value: float2) -> float2 {
  float2(toDegrees(value.x), toDegrees(value.y))
}

public func toRadians(_ value: float3) -> float3 {
  float3(toRadians(value.x), toRadians(value.y), toRadians(value.z))
}

public func toDegrees(_ value: float3) -> float3 {
  float3(toDegrees(value.x), toDegrees(value.y), toDegrees(value.z))
}

public func modelFrom(trans: float3, rot: float3, scale: float3) -> float4x4 {
  let translation = float4x4(translation: trans)
  let rotation = float4x4(rotation: rot)
  let scale = float4x4(scaling: scale)
  return translation * rotation * scale
}

public func remap(
  _ value: Float,
  _ inMinMax: float2,
  _ outMinMax: float2
) -> Float {
  outMinMax.x +
    (value - inMinMax.x) *
    (outMinMax.y - outMinMax.x) /
    (inMinMax.y - inMinMax.x)
}

public func remap(
  _ value: Float,
  _ inMinMax: ClosedRange<Float>,
  _ outMinMax: ClosedRange<Float>
) -> Float {
  outMinMax.lowerBound +
    (value - inMinMax.lowerBound) *
    (outMinMax.upperBound - outMinMax.lowerBound) /
    (inMinMax.upperBound - inMinMax.lowerBound)
}

public func lerp(min: Float, max: Float, t: Float) -> Float {
  min + (max - min) * t
}

public func normalize(value: Float, min: Float, max: Float) -> Float {
  (value - min) / (max - min)
}

// top-left origin
public func dragDirection(point: float2, rect: inout Rect) -> float2 {
  let halfSize = (rect.size * 0.5)
  let pos = float2(rect.position.x, rect.position.y) + halfSize

  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize

  return max(d, 0) * sign(pointOffset)
}

public func smoothstep(edge0: Float, edge1: Float, x: Float) -> Float {
  let t = ((x - edge0) / (edge1 - edge0)).clamped(to: 0...1)
  return t * t * (3.0 - 2.0 * t)
}

public func mix(x: Float, y: Float, t: Float) -> Float {
  x * (1 - t) + y * t
}

public func fromPixelCoordToGridIndex(_ normalizedCoord: SIMD2<Float>, _ gridSize: SIMD2<Float>) -> SIMD2<Int> {
  let x = Int(floor(remap(normalizedCoord.x, float2(-1, 1), float2(0, gridSize.x))))
  let y = Int(floor(remap(normalizedCoord.y, float2(-1, 1), float2(0, gridSize.y))))

  return int2(x, y)
}

public func fromWorldPositionToGridIndex(_ position: SIMD3<Float>, _ gridSize: SIMD3<Float>) -> SIMD3<Int> {
  let x = Int(floor(remap(position.x, float2(-1, 1) * gridSize.x * 0.5, float2(0, gridSize.x))))
  let y = Int(floor(remap(position.y, float2(-1, 1) * gridSize.y * 0.5, float2(0, gridSize.y))))
  let z = Int(floor(remap(position.z, float2(-1, 1) * gridSize.z * 0.5, float2(0, gridSize.z))))

  return int3(x, y, z)
}

public func from3DTo1DArray(_ index: SIMD3<Int>, _ size: SIMD3<Int>) -> Int {
  (index.z * size.y * size.x) + (index.y * size.x + index.x)
}

public func from1DTo3DArray(_ index: Int, _ size: SIMD3<Int>) -> SIMD3<Int> {
  let x = index % size.z
  let y = (index / size.z) % size.y
  let z = index / (size.y * size.z)

  return int3(x, y, z)
}

public func from2DTo1DArray(_ index: SIMD2<Int>, _ size: SIMD2<Int>) -> Int {
  index.y * size.x + index.x
}

public func from1DTo2DArray(_ index: Int, _ size: SIMD2<Int>) -> SIMD2<Int> {
  let y = index / size.x
  let x = index - y * size.x

  return int2(x, y)
}

func clamp<T: Comparable & FloatingPoint>(_ value: T, _ minValue: T, _ maxValue: T) -> T {
  max(minValue, min(value, maxValue))
}
