import simd

public let π = Float.pi

public func toRadians(_ value: Float) -> Float {
  return (value / 180) * π
}

public func toDegrees(_ value: Float) -> Float {
  return (value / π) * 180
}

public func toRadians(_ value: float2) -> float2 {
  return float2(toRadians(value.x), toRadians(value.y))
}

public func toDegrees(_ value: float2) -> float2 {
  return float2(toDegrees(value.x), toDegrees(value.y))
}

public func toRadians(_ value: float3) -> float3 {
  return float3(toRadians(value.x), toRadians(value.y), toRadians(value.z))
}

public func toDegrees(_ value: float3) -> float3 {
  return float3(toDegrees(value.x), toDegrees(value.y), toDegrees(value.z))
}

public func modelFrom(trans: float3, rot: float3, scale: float3) -> matrix_float4x4 {
  let translation = float4x4(translation: trans)
  let rotation = float4x4(rotation: rot)
  let scale = float4x4(scaling: scale)
  return translation * rotation * scale
}

public func remap(
  _ value: Float,
  _ inMinMax: float2,
  _ outMinMax: float2
) -> Float
  {
    return outMinMax.x +
           (value - inMinMax.x) *
           (outMinMax.y - outMinMax.x) /
           (inMinMax.y - inMinMax.x);
  }

public func remap(
  _ value: Float,
  _ inMinMax: ClosedRange<Float>,
  _ outMinMax: ClosedRange<Float>
) -> Float
  {
    return outMinMax.lowerBound +
    (value - inMinMax.lowerBound) *
           (outMinMax.upperBound - outMinMax.lowerBound) /
           (inMinMax.upperBound - inMinMax.lowerBound);
  }

public func lerp(min: Float, max: Float, t: Float) -> Float {
  return (max - min) * t + min
}

public func normalize(value: Float, min: Float, max: Float) -> Float {
  return (value - min) / (max - min)
}

// adapted form of sdfBox function https://iquilezles.org/articles/distfunctions2d/
// box origin at center
public func pointInAABBox(point: float2, position: float2, size: float2) -> Bool {
  let pointOffset = point - position
  let d = abs(pointOffset) - size - 1
  return min(max(d.x, d.y), 0) < 0
}

// top-left origin
public func pointInAABBoxTopLeftOrigin(point: float2, position: float2, size: float2) -> Bool {
  let halfSize = (size * 0.5)
  let pos = float2(position.x, position.y) + halfSize
  
  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize - 1
  return min(max(d.x, d.y), 0) < 0
}

// top-left origin
public func sdBox(point: float2, rect: inout Rect) -> Float {
  let halfSize = (rect.size * 0.5)
  let pos = float2(rect.position.x, rect.position.y) + halfSize

  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize

  // clamped to the edge of top right quadrant of the box
  let topRightVector = max(d, 0)

  // min(max(d.x, d.y), 0) - distance inside the box (to the closest edge) but I need point on the closest edge and penetration amount
  return length(topRightVector) + min(max(d.x, d.y), 0)
}

// b.x = width
// b.y = height
// r.x = roundness top-right
// r.y = roundness boottom-right
// r.z = roundness top-left
// r.w = roundness bottom-left
// origin at center
public func sdRoundBox(_ p: float2, _ b: float2, _ r: float4) -> Float
{
 var r = r
  //  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  if p.x > 0.0 {
    r.x = r.x
    r.y = r.y
  } else {
    r.x = r.z
    r.y = r.w
  }
  r.x  = (p.y > 0.0) ? r.x : r.y;
  
  let q: float2 = abs(p) - b + r.x;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

// top-left origin
public func closestPointToSDBox(point: float2, rect: inout Rect) -> float2 {
  let halfSize = (rect.size * 0.5)
  let pos = float2(rect.position.x, rect.position.y) + halfSize
  
  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize
  
  // clamped to the edge of top right quadrant of the box
  let topRightVector = max(d, 0)
  //  let innerTopRightVector = min(d.greatestComponent, 0)
  
  //  let offsetToClosestPoint = (topRightVector + innerTopRightVector) * sign(pointOffset)
  let offsetToClosestPoint = topRightVector * sign(pointOffset)
  
  return point - offsetToClosestPoint
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
  let t = ((x - edge0) / (edge1 - edge0)).clamped(to: 0...1);
  return t * t * (3.0 - 2.0 * t);
}

public func mix(x: Float, y: Float, t: Float) -> Float {
  return x * (1 - t) + y * t;
}

public func sdCircle(_ p: float2, _ r: Float) -> Float {
  return length(p) - r;
}

public func sdCircle(_ p: float3, _ r: Float) -> Float {
  return length(p) - r;
}

public func circleSDFNormal(_ p: float2, _ r: Float) -> float2 {
  let eps = Float(0.0001)
  let dx = (sdCircle(p + float2(eps, 0), r) - sdCircle(p - float2(eps, 0), r)) / (2 * eps)
  let dy = (sdCircle(p + float2(0, eps), r) - sdCircle(p - float2(0, eps), r)) / (2 * eps)
  let dSDF = float2(dx, dy)
  let normal = dSDF / length(dSDF)
  
  return normal
}

public func circleSDFNormal(_ p: float3, _ r: Float) -> float3 {
  let eps = Float(0.0001)
  let dx = (sdCircle(p + float3(eps, 0, 0), r) - sdCircle(p - float3(eps, 0, 0), r)) / (2 * eps)
  let dy = (sdCircle(p + float3(0, eps, 0), r) - sdCircle(p - float3(0, eps, 0), r)) / (2 * eps)
  let dz = (sdCircle(p + float3(0, 0, eps), r) - sdCircle(p - float3(0, 0, eps), r)) / (2 * eps)
  let dSDF = float3(dx, dy, dz)
//  let normal = dSDF / length(dSDF)
  let normal = normalize(dSDF)
  
  return normal
}

//func circleSDFNormal(_ p: float3, _ r: Float) -> float3 {
//  let eps = Float(0.0001)
//  let dx = (sdCircle(p + float3(eps, 0, 0), r) - sdCircle(p - float3(eps, 0, 0), r))
//  let dy = (sdCircle(p + float3(0, eps, 0), r) - sdCircle(p - float3(0, eps, 0), r))
//  let dz = (sdCircle(p + float3(0, 0, eps), r) - sdCircle(p - float3(0, 0, eps), r))
//  let dSDF = float3(dx, dy, dz)
//  let normal = normalize(dSDF)
//
//  return normal
//}

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
  return (index.z * size.y * size.x) + (index.y * size.x + index.x)
}

public func from1DTo3DArray(_ index: Int, _ size: SIMD3<Int>) -> SIMD3<Int> {
  let x = index % size.z
  let y = (index / size.z) % size.y
  let z = index / (size.y * size.z)
  
  return int3(x, y, z)
}

public func from2DTo1DArray(_ index: SIMD2<Int>, _ size: SIMD2<Int>) -> Int {
  return index.y * size.x + index.x
}

public func from1DTo2DArray(_ index: Int, _ size: SIMD2<Int>) -> SIMD2<Int> {
  let y = index / size.x
  let x = index - y * size.x
  
  return int2(x, y)
}

