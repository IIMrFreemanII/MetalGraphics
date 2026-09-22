//
//  GlyphSDF.metal
//  MetalGraphicsLib
//
//  Bakes the signed distance field of a single glyph outline into a region of the SDF atlas.
//  Ported from SwiftImgui's VectorText.metal, with the render pass replaced by a compute kernel.
//

#include <metal_stdlib>
using namespace metal;

#include "Math.h"

// type
// 0 - moveToPoint, starts new path
// 1 - addLineToPoint, adds line from current point to a new point. Element holds 1 point for destination
// 2 - addQuadCurveToPoint, adds a quadratice curve from current point to the specified point.
//     Element holds control point (point0) and a destination point (point1).
// 3 - addCurveToPoint, never uploaded: cubics are split into quadratics on the CPU
// 4 - closePath, path element that closes and completes a subpath. The element does not contain any points.
struct PathElement {
  float2 point0;
  float2 point1;
  uint8_t type;
};

struct SubPath {
  uint start;
  uint end;
};

struct GlyphBakeParams {
  // region of the atlas in texels
  uint2 origin;
  uint2 size;
  // em space position of the center of the region's top left texel, y up
  float2 emTopLeft;
  float emPerTexel;
  uint subPathStart;
  uint subPathEnd;
  // bounds every index into the path element buffer
  uint pathElementCount;
};

// Hard caps, so corrupt input can never turn into an unbounded loop on the GPU.
constant const uint kMaxPathElements = 4096;
constant const uint kMaxSubPaths = 256;
// Distance returned for an empty outline: far outside any glyph.
constant const float kOutside = 1e3;

// squared distance from p to the segment ab
static float sdSegmentSquared(float2 p, float2 a, float2 b) {
  float2 e = b - a;
  float2 w = p - a;
  float ee = dot(e, e);
  if (ee == 0) {
    return dot(w, w);
  }
  float2 d = w - e * saturate(dot(w, e) / ee);
  return dot(d, d);
}

// Signed crossing of the segment ab with a ray from p towards +x: +1 going up, -1 going down.
// A segment owns its lower end and not its upper one, so a ray through a vertex shared by two
// segments counts once, and a horizontal segment never counts.
static int lineWinding(float2 p, float2 a, float2 b) {
  float side = cross2d(b - a, p - a);
  if (a.y <= p.y && p.y < b.y) {
    return side > 0 ? 1 : 0;
  }
  if (b.y <= p.y && p.y < a.y) {
    return side < 0 ? -1 : 0;
  }
  return 0;
}

// squared distance to the quadratic bezier A, B (control), C
// https://www.shadertoy.com/view/MlKcDD
static float sdQuadraticBezierSquared(float2 pos, float2 A, float2 B, float2 C) {
  float2 a = B - A;
  float2 b = A - 2.0 * B + C;
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
    // 1 root
    h = sqrt(h);
    float2 x = (float2(h, -h) - q) / 2.0;
    float2 uv = sign(x) * pow(abs(x), float2(1.0 / 3.0));
    float t = saturate(uv.x + uv.y - kx);
    return dot2(d + (c + b * t) * t);
  }

  // 3 roots, the third is never the closest
  float z = sqrt(-p);
  // rounding can push the ratio a hair outside acos's domain
  float v = acos(clamp(q / (p * z * 2.0), -1.0, 1.0)) / 3.0;
  float m = cos(v);
  float n = sin(v) * 1.732050808;
  float2 t = saturate(float2(m + m, -n - m) * z - kx);
  return min(dot2(d + (c + b * t.x) * t.x), dot2(d + (c + b * t.y) * t.y));
}

// Signed crossing count of the quadratic bezier A, B (control), C with a ray from p towards +x.
// The curve is split at its y extremum into pieces monotonic in y, and each piece follows the
// same rule as a line, so crossings stay consistent with the segments around it.
static int quadraticWinding(float2 p, float2 A, float2 B, float2 C) {
  // y(t) = A.y + t * qb + t^2 * qa
  float qa = A.y - 2.0 * B.y + C.y;
  float qb = 2.0 * (B.y - A.y);

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
    float y0 = t0 == 0 ? A.y : mix(mix(A.y, B.y, t0), mix(B.y, C.y, t0), t0);
    float y1 = t1 == 1 ? C.y : mix(mix(A.y, B.y, t1), mix(B.y, C.y, t1), t1);

    float direction;
    if (y0 <= p.y && p.y < y1) {
      direction = 1;
    } else if (y1 <= p.y && p.y < y0) {
      direction = -1;
    } else {
      continue;
    }

    // y is monotonic on the piece, so bisection finds the one t where it crosses p.y
    float lo = t0;
    float hi = t1;
    for (int j = 0; j < 24; j++) {
      float mid = 0.5 * (lo + hi);
      float y = mix(mix(A.y, B.y, mid), mix(B.y, C.y, mid), mid);
      if ((y - p.y) * direction <= 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    float t = 0.5 * (lo + hi);
    float x = mix(mix(A.x, B.x, t), mix(B.x, C.x, t), t);
    if (x > p.x) {
      winding += int(direction);
    }
  }

  return winding;
}

// Signed distance to a glyph outline, negative inside. Inside is decided by the nonzero winding
// rule over every subpath together, the way font rasterizers fill glyphs, so holes and
// overlapping contours both come out right.
static float sdGlyph(float2 p, constant SubPath *subPaths, uint start, uint end, constant PathElement *pathElems, uint pathElementCount) {
  end = min(end, start + kMaxSubPaths);
  if (start >= end) {
    return kOutside;
  }

  float distSquared = kOutside * kOutside;
  int winding = 0;

  for (uint s = start; s < end; s++) {
    SubPath subPath = subPaths[s];
    uint elementsEnd = min(min(subPath.end, pathElementCount), subPath.start + kMaxPathElements);

    float2 pathStart = float2();
    float2 prevPoint = float2();
    for (uint i = subPath.start; i < elementsEnd; i++) {
      PathElement pathElem = pathElems[i];

      switch (pathElem.type) {
        case 0: {
          pathStart = pathElem.point0;
          prevPoint = pathStart;
          break;
        }
        case 1: {
          float2 currentPoint = pathElem.point0;
          distSquared = min(distSquared, sdSegmentSquared(p, prevPoint, currentPoint));
          winding += lineWinding(p, prevPoint, currentPoint);
          prevPoint = currentPoint;
          break;
        }
        case 2: {
          float2 currentPoint = pathElem.point1;
          float2 controlPoint = pathElem.point0;

          // A control point on the chord makes the curve a straight line, and the cubic solve
          // divides by zero for it.
          float2 b = prevPoint - 2.0 * controlPoint + currentPoint;
          if (dot(b, b) < 1e-10) {
            distSquared = min(distSquared, sdSegmentSquared(p, prevPoint, currentPoint));
            winding += lineWinding(p, prevPoint, currentPoint);
          } else {
            distSquared = min(distSquared, sdQuadraticBezierSquared(p, prevPoint, controlPoint, currentPoint));
            winding += quadraticWinding(p, prevPoint, controlPoint, currentPoint);
          }
          prevPoint = currentPoint;
          break;
        }
        case 4: {
          distSquared = min(distSquared, sdSegmentSquared(p, prevPoint, pathStart));
          winding += lineWinding(p, prevPoint, pathStart);
          prevPoint = pathStart;
          break;
        }
      }
    }
  }

  float distance = sqrt(distSquared);
  return winding != 0 ? -distance : distance;
}

kernel void bakeGlyphSDF(
                         texture2d<float, access::write> atlas [[texture(0)]],
                         constant GlyphBakeParams &params [[buffer(0)]],
                         constant PathElement *pathElems [[buffer(1)]],
                         constant SubPath *subPaths [[buffer(2)]],
                         uint2 gid [[thread_position_in_grid]]
                         )
{
  if (gid.x >= params.size.x || gid.y >= params.size.y) {
    return;
  }

  // texel row 0 is the top of the glyph, font space is y up
  float2 p = params.emTopLeft + float2(gid.x, -float(gid.y)) * params.emPerTexel;

  float distance = sdGlyph(p, subPaths, params.subPathStart, params.subPathEnd, pathElems, params.pathElementCount);
  // positive inside the glyph
  atlas.write(float4(-distance, 0, 0, 0), params.origin + gid);
}
