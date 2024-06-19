import simd

//public func circleSDFNormal(_ p: float2, _ r: Float) -> float2 {
//  let eps = Float(0.0001)
//  let dx = (sdCircle(p + float2(eps, 0), r) - sdCircle(p - float2(eps, 0), r)) / (2 * eps)
//  let dy = (sdCircle(p + float2(0, eps), r) - sdCircle(p - float2(0, eps), r)) / (2 * eps)
//  let dSDF = float2(dx, dy)
//  let normal = dSDF / length(dSDF)
//  
//  return normal
//}
//
//public func circleSDFNormal(_ p: float3, _ r: Float) -> float3 {
//  let eps = Float(0.0001)
//  let dx = (sdCircle(p + float3(eps, 0, 0), r) - sdCircle(p - float3(eps, 0, 0), r)) / (2 * eps)
//  let dy = (sdCircle(p + float3(0, eps, 0), r) - sdCircle(p - float3(0, eps, 0), r)) / (2 * eps)
//  let dz = (sdCircle(p + float3(0, 0, eps), r) - sdCircle(p - float3(0, 0, eps), r)) / (2 * eps)
//  let dSDF = float3(dx, dy, dz)
////  let normal = dSDF / length(dSDF)
//  let normal = normalize(dSDF)
//  
//  return normal
//}

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

func sdfNormal(_ cb: (float2) -> Float) -> float2 {
  let eps = Float(0.0001)
  let dx = cb(float2(eps, 0)) - cb(float2(-eps, 0))
  let dy = cb(float2(0, eps)) - cb(float2(0, -eps))
  let dSDF = float2(dx, dy)
  let normal = normalize(dSDF)
  
  return normal
}

func sdfNormal(_ cb: (float3) -> Float) -> float3 {
  let eps = Float(0.0001)
  let dx = cb(float3(eps, 0, 0)) - cb(float3(-eps, 0, 0))
  let dy = cb(float3(0, eps, 0)) - cb(float3(0, -eps, 0))
  let dz = cb(float3(0, 0, eps)) - cb(float3(0, 0, -eps))
  let dSDF = float3(dx, dy, dz)
  let normal = normalize(dSDF)
  
  return normal
}

public func sdCircle(_ p: float2, _ r: Float) -> Float {
  return length(p) - r;
}

public func sdCircle(_ p: float3, _ r: Float) -> Float {
  return length(p) - r;
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

public func sdBox(_ p: float2, _ b: float2) -> Float {
  let d = abs(p) - b
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0)
}

// top-left origin
public func sdBoxTopLeft(point: float2, rect: inout Rect) -> Float {
  let halfSize = (rect.size * 0.5)
  let pos = float2(rect.position.x, rect.position.y) + halfSize

  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize

  // clamped to the edge of top right quadrant of the box
  let topRightVector = max(d, 0)

  // min(max(d.x, d.y), 0) - distance inside the box (to the closest edge) but I need point on the closest edge and penetration amount
  return length(topRightVector) + min(max(d.x, d.y), 0)
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

func sdSegment(_ p: float2, _ a: float2, _ b: float2 ) -> Float
{
  let pa = p-a, ba = b-a;
  let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0 );
  return length(pa - ba * h);
}
