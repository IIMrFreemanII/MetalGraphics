//
//  VectorSDF.metal
//  MetalGraphicsLib
//
//  Bakes a `VectorCanvas` path into a tile of the dynamic SDF atlas. A path can re-bake every
//  frame while its geometry animates, so this is built for speed where `bakeSDF` is built for
//  generality: segments come with bounding boxes to skip, and crossings are solved in closed
//  form rather than by bisection.
//

#include <metal_stdlib>
using namespace metal;

#include "Math.h"

// A line (isLine != 0, b unused) or a quadratic bezier a, b (control), c. In local units, y down.
struct VectorSegment {
  float2 a;
  float2 b;
  float2 c;
  float2 boxMin;
  float2 boxMax;
  // length along the path up to a, and of the segment
  float start;
  float length;
  uint isLine;
  float padding;
};

struct VectorBakeParams {
  // region of the atlas in texels
  uint2 origin;
  uint2 size;
  // local position of the center of the region's top left texel
  float2 topLeft;
  float unitsPerTexel;
  // 0 - fill, nonzero winding
  // 1 - fill, even-odd winding
  // 2 - stroke: distance to the centerline, and position along the path over its length
  uint mode;
  uint segmentStart;
  uint segmentEnd;
  float totalLength;
  // bounds every index into the segment buffer
  uint segmentCount;
};

// Hard cap, so corrupt input can never turn into an unbounded loop on the GPU.
constant const uint kMaxSegments = 16384;
constant const float kFar = 1e4;

// squared distance from p to the segment ac, and where along it the nearest point is
static float2 closestOnLine(float2 p, float2 a, float2 c) {
  float2 e = c - a;
  float2 w = p - a;
  float ee = dot(e, e);
  float t = ee > 0 ? saturate(dot(w, e) / ee) : 0;
  float2 d = w - e * t;
  return float2(dot(d, d), t);
}

// squared distance to the quadratic bezier A, B (control), C, and the t of the nearest point
// https://www.shadertoy.com/view/MlKcDD
static float2 closestOnQuadratic(float2 pos, float2 A, float2 B, float2 C) {
  float2 a = B - A;
  float2 b = A - 2.0 * B + C;
  if (dot(b, b) < 1e-10) {
    return closestOnLine(pos, A, C);
  }
  float2 c = a * 2.0;
  float2 d = A - pos;

  float kk = 1.0 / dot(b, b);
  float kx = kk * dot(a, b);
  float ky = kk * (2.0 * dot(a, a) + dot(d, b)) / 3.0;
  float kz = kk * dot(d, a);

  float p = ky - kx * kx;
  float q = kx * (2.0 * kx * kx - 3.0 * ky) + kz;
  float p3 = p * p * p;
  float h = q * q + 4.0 * p3;

  if (h >= 0.0) {
    h = sqrt(h);
    float2 x = (float2(h, -h) - q) / 2.0;
    float2 uv = sign(x) * pow(abs(x), float2(1.0 / 3.0));
    float t = saturate(uv.x + uv.y - kx);
    return float2(dot2(d + (c + b * t) * t), t);
  }

  float z = sqrt(-p);
  float v = acos(clamp(q / (p * z * 2.0), -1.0, 1.0)) / 3.0;
  float m = cos(v);
  float n = sin(v) * 1.732050808;
  float2 t = saturate(float2(m + m, -n - m) * z - kx);
  float d0 = dot2(d + (c + b * t.x) * t.x);
  float d1 = dot2(d + (c + b * t.y) * t.y);
  return d0 < d1 ? float2(d0, t.x) : float2(d1, t.y);
}

// Signed crossing of the segment ac with a ray from p towards +x: +1 going down, -1 going up.
// A segment owns its lower-y end and not its other one, so a ray through a shared vertex
// counts once, and a horizontal segment never counts.
static int lineCrossing(float2 p, float2 a, float2 c) {
  float side = cross2d(c - a, p - a);
  if (a.y <= p.y && p.y < c.y) {
    return side > 0 ? 1 : 0;
  }
  if (c.y <= p.y && p.y < a.y) {
    return side < 0 ? -1 : 0;
  }
  return 0;
}

static float quadraticY(float2 A, float2 B, float2 C, float t) {
  return mix(mix(A.y, B.y, t), mix(B.y, C.y, t), t);
}

// Signed crossings of the quadratic A, B, C with the same ray. Split at its y extremum into
// pieces monotonic in y, each following the line rule; the crossing on each is a root of
// y(t) = p.y, solved in closed form.
static int quadraticCrossings(float2 p, float2 A, float2 B, float2 C) {
  float qa = A.y - 2.0 * B.y + C.y;
  float qb = 2.0 * (B.y - A.y);
  float qc = A.y - p.y;

  float splits[3] = { 0.0, 1.0, 1.0 };
  int pieces = 1;
  if (qa != 0) {
    float extremum = -qb / (2.0 * qa);
    if (extremum > 0 && extremum < 1) {
      splits[1] = extremum;
      pieces = 2;
    }
  }

  int winding = 0;
  for (int i = 0; i < pieces; i++) {
    float t0 = splits[i];
    float t1 = splits[i + 1];
    // the ends are taken as is, so they match the neighbouring segments bit for bit
    float y0 = t0 == 0 ? A.y : quadraticY(A, B, C, t0);
    float y1 = t1 == 1 ? C.y : quadraticY(A, B, C, t1);

    int direction;
    if (y0 <= p.y && p.y < y1) {
      direction = 1;
    } else if (y1 <= p.y && p.y < y0) {
      direction = -1;
    } else {
      continue;
    }

    float t;
    if (abs(qa) < 1e-9) {
      t = qb != 0 ? -qc / qb : t0;
    } else {
      float root = sqrt(max(qb * qb - 4.0 * qa * qc, 0.0));
      float q = -0.5 * (qb + (qb >= 0 ? root : -root));
      float r0 = q / qa;
      float r1 = q != 0 ? qc / q : r0;
      t = (r0 >= t0 - 1e-4 && r0 <= t1 + 1e-4) ? r0 : r1;
    }
    t = clamp(t, t0, t1);
    float x = mix(mix(A.x, B.x, t), mix(B.x, C.x, t), t);
    if (x > p.x) {
      winding += direction;
    }
  }
  return winding;
}

// Winding number of the segments start..<end around p.
static int windingAt(float2 p, constant VectorSegment *segments, uint start, uint end) {
  int winding = 0;
  for (uint i = start; i < end; i++) {
    VectorSegment segment = segments[i];
    if (p.y >= segment.boxMin.y && p.y <= segment.boxMax.y && segment.boxMax.x > p.x) {
      winding += segment.isLine != 0
        ? lineCrossing(p, segment.a, segment.c)
        : quadraticCrossings(p, segment.a, segment.b, segment.c);
    }
  }
  return winding;
}

static bool isInside(int winding, uint mode) {
  return mode == 1 ? (winding & 1) != 0 : winding != 0;
}

kernel void bakeVectorSDF(
                          texture2d<float, access::write> atlas [[texture(0)]],
                          constant VectorBakeParams &params [[buffer(0)]],
                          constant VectorSegment *segments [[buffer(1)]],
                          uint2 gid [[thread_position_in_grid]]
                          )
{
  if (gid.x >= params.size.x || gid.y >= params.size.y) {
    return;
  }

  float2 p = params.topLeft + float2(gid) * params.unitsPerTexel;
  bool isStroke = params.mode == 2;
  uint start = params.segmentStart;
  uint end = min(min(params.segmentEnd, params.segmentCount), start + kMaxSegments);

  float best = kFar * kFar;
  float bestAlong = 0;
  uint bestSegment = start;
  float bestT = 0;
  int winding = 0;

  for (uint i = start; i < end; i++) {
    VectorSegment segment = segments[i];

    // Only a segment reaching the ray's row, and to its right, can cross it.
    if (!isStroke && p.y >= segment.boxMin.y && p.y <= segment.boxMax.y && segment.boxMax.x > p.x) {
      winding += segment.isLine != 0
        ? lineCrossing(p, segment.a, segment.c)
        : quadraticCrossings(p, segment.a, segment.b, segment.c);
    }

    // Nothing in the box is nearer than the box itself.
    float2 outside = max(max(segment.boxMin - p, p - segment.boxMax), 0.0);
    if (dot(outside, outside) >= best) {
      continue;
    }
    float2 nearest = segment.isLine != 0
      ? closestOnLine(p, segment.a, segment.c)
      : closestOnQuadratic(p, segment.a, segment.b, segment.c);
    if (nearest.x < best) {
      best = nearest.x;
      bestAlong = segment.start + nearest.y * segment.length;
      bestSegment = i;
      bestT = nearest.y;
    }
  }

  float distance = sqrt(best);
  float2 value;
  if (isStroke) {
    value = float2(distance, bestAlong / max(params.totalLength, 1e-6));
  } else {
    bool inside = isInside(winding, params.mode);
    // Subpaths that touch or overlap leave edges inside the fill. Near an edge with fill on its
    // far side as well, the texel is deep inside, not at an outline — or the edge would show as
    // a seam. Only texels close enough for anti-aliasing to see are checked.
    float nearEdge = 3 * params.unitsPerTexel;
    if (inside && distance < nearEdge && end > start) {
      VectorSegment segment = segments[bestSegment];
      float t = bestT;
      float2 q;
      float2 tangent;
      if (segment.isLine != 0) {
        q = mix(segment.a, segment.c, t);
        tangent = segment.c - segment.a;
      } else {
        q = mix(mix(segment.a, segment.b, t), mix(segment.b, segment.c, t), t);
        tangent = mix(segment.b - segment.a, segment.c - segment.b, t);
      }
      float step = 0.5 * params.unitsPerTexel;
      float2 away = q - p;
      float2 normal = length(tangent) > 0 ? normalize(float2(-tangent.y, tangent.x)) : float2(1, 0);
      // across the edge from the texel; on the edge itself, both sides
      bool interior = dot(away, away) > step * step * 0.01
        ? isInside(windingAt(q + normalize(away) * step, segments, start, end), params.mode)
        : isInside(windingAt(q + normal * step, segments, start, end), params.mode)
          && isInside(windingAt(q - normal * step, segments, start, end), params.mode);
      if (interior) {
        distance = nearEdge;
      }
    }
    // negative inside
    value = float2(inside ? -distance : distance, 0);
  }
  atlas.write(float4(value, 0, 0), params.origin + gid);
}
