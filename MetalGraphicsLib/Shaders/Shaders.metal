//
//  Shaders.metal
//  MetalGraphicsLib
//
//  Created by Nikolay Diahovets on 16.06.2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Math.h"
#include "SDF.h"
#include "Utils.h"

struct Shape {
  int index;
  int shapeType;
  // index into `ShapeArgBuffer.clips`; 0 clips nothing
  int clip;
  // the shape's own depth, so a cell can be cut off at a glass's depth without loading it
  float depth;
};

struct Line {
  float2 start;
  float2 end;
  float4 color;
  float depth;
  float thickness;
};

struct Circle {
  float2 position;
  float radius;
  float depth;
  float4 color;
};

struct Square {
  float2 position;
  float2 size;
  float depth;
  float rotation;
  float4 color;
};

struct Glyph {
  // top left corner, y down
  float2 position;
  float2 size;
  // region of the SDF atlas
  float2 uvMin;
  float2 uvMax;
  float4 color;
  float depth;
  float fontSize;
  // a shadow's blur, as a standard deviation in points; 0 when sharp
  float blur;
};

struct ImageQuad {
  // top left corner, y down
  float2 position;
  float2 size;
  // region of the texture
  float2 uvMin;
  float2 uvMax;
  // a template image's color; an original image takes only its alpha, as opacity
  float4 tint;
  float depth;
  int textureIndex;
  // bit 0 - template, bit 1 - nearest filtering, bit 2 - shadow: transparent past the edges
  uint flags;
  // mip level to sample, log2 of texels per pixel
  float lod;
};

struct VectorItem {
  // local = (dot(row0.xy, p) + row0.z, dot(row1.xy, p) + row1.z) for p in points
  // row0.w - points per local unit, row1.w - depth
  float4 row0;
  float4 row1;
  // baked: local bounds of the region | ellipse: center, radii | rounded box: center, half size
  float4 params0;
  // baked: atlas uv of the region | rounded box: corner radii, as `sdRoundedBox` takes them
  float4 params1;
  float4 color;
  // min x, min y, max x, max y in points
  float4 clip;
  // half width, trim from, trim to, length of the path
  float4 stroke;
  // 0 - baked fill, 1 - baked stroke, 2 - ellipse, 3 - rounded box
  uint kind;
  // bit 0 - closed path, bit 1 - stroke
  uint flags;
  // a shadow's blur, as a standard deviation in points; 0 when sharp
  float blur;
  float padding1;
};

// One entry of the clip table; rects are min x, min y, max x, max y in centered points, y down.
struct Clip {
  // everything under the clip is inside it: its own rect cut to every clip above
  float4 bounds;
  // its own rounded rect, tested only when some radius is not zero
  float4 rect;
  // corner radii, as `sdRoundedBox` takes them
  float4 radii;
  // the next entry up whose rounded rect applies as well, 0 when none does
  int rounded;
  // a shadow's soft clip: its rounded rect is blurred by this standard deviation, in points,
  // and caps the shape's coverage instead of scaling it; 0 for a hard clip
  float blur;
  int padding1;
  int padding2;
};

// A frosted glass panel: a rounded rect filled with the blurred scene behind it, which a
// `backdrop2D` pass and two `glassBlur` passes left in a region of the glass atlas.
struct Glass {
  // min x, min y, max x, max y in centered points, y down
  float4 rect;
  // corner radii, as `sdRoundedBox` takes them
  float4 radii;
  // composited over the blurred backdrop, straight alpha
  float4 tint;
  // where atlas texel `regionMin` samples the scene, in centered points
  float2 sceneOrigin;
  // the backdrop's region of the glass atlas, in texels; empty when there is none
  float2 regionMin;
  float2 regionMax;
  float pointsPerTexel;
  // 1 leaves the backdrop's colors as they are, more makes them more vivid
  float saturation;
  // grain amplitude, 0...1
  float noise;
  float opacity;
  float depth;
  float padding;
};

struct TextureHandle {
  texture2d<float> texture;
};

struct GridCell {
  // maps into shapes buffer
  int startIndex;
  int count;
};

struct GridArgBuffer {
  device GridCell* gridCells [[id(0)]];
  device Shape* shapes [[id(1)]];
  int2 gridSize [[id(2)]];
  float cellSize [[id(3)]];
  float2 gridPosition [[id(4)]];
};

struct ShapeArgBuffer {
  device Circle* circles [[id(0)]];
  int circlesCount [[id(1)]];
  
  device Square* squares [[id(2)]];
  int squaresCount [[id(3)]];
  
  device Line* lines [[id(4)]];
  int linesCount [[id(5)]];
  
  device Glyph* glyphs [[id(6)]];
  int glyphsCount [[id(7)]];

  device ImageQuad* images [[id(8)]];
  int imagesCount [[id(9)]];
  // premultiplied bitmaps, indexed by `ImageQuad.textureIndex`
  device TextureHandle* textures [[id(10)]];

  device VectorItem* vectors [[id(11)]];
  int vectorsCount [[id(12)]];

  device Clip* clips [[id(13)]];
  int clipsCount [[id(14)]];

  device Glass* glasses [[id(15)]];
  int glassesCount [[id(16)]];
};

struct DebugData {
  bool drawGrid;
  bool showFilledCells;
};

struct SceneData {
  int2 windowSize;
  float time;
  DebugData debug;
};

constant const float kVectorOutside = 1e4;

// Distance to a stroke of half width stroke.x, trimmed to stroke.y...stroke.z of a path
// stroke.w long, for a point `centerDistance` from its centerline, nearest to position `along`
// (0...1) of it. Past a trimmed end the distance is to the end's point, which rounds its cap.
static float trimmedStroke(float centerDistance, float along, float4 stroke, bool closed) {
  float from = stroke.y;
  float to = stroke.z;
  if (from <= 0 && to >= 1) {
    return centerDistance - stroke.x;
  }
  if (to <= from) {
    return kVectorOutside;
  }
  float past = 0;
  if (along < from || along > to) {
    if (closed) {
      // the gap between the ends wraps round the path's start
      float toFrom = along < from ? from - along : 1 - along + from;
      float fromTo = along > to ? along - to : along + 1 - to;
      past = min(toFrom, fromTo);
    } else {
      past = along < from ? from - along : along - to;
    }
  }
  return length(float2(past * stroke.w, centerDistance)) - stroke.x;
}

// Signed distance to an ellipse centered at the origin, negative inside.
// https://iquilezles.org/articles/ellipsedist/
static float sdEllipse(float2 p, float2 ab) {
  if (abs(ab.x - ab.y) <= 1e-4 * max(ab.x, ab.y)) {
    return length(p) - ab.x;
  }
  p = abs(p);
  if (p.x > p.y) {
    p = p.yx;
    ab = ab.yx;
  }
  float l = ab.y * ab.y - ab.x * ab.x;
  float m = ab.x * p.x / l;
  float m2 = m * m;
  float n = ab.y * p.y / l;
  float n2 = n * n;
  float c = (m2 + n2 - 1.0) / 3.0;
  float c3 = c * c * c;
  float q = c3 + m2 * n2 * 2.0;
  float d = c3 + m2 * n2;
  float g = m + m * n2;
  float co;
  if (d < 0.0) {
    float h = acos(clamp(q / c3, -1.0, 1.0)) / 3.0;
    float s = cos(h);
    float t = sin(h) * sqrt(3.0);
    float rx = sqrt(max(-c * (s + t + 2.0) + m2, 0.0));
    float ry = sqrt(max(-c * (s - t + 2.0) + m2, 0.0));
    co = (ry + sign(l) * rx + abs(g) / max(rx * ry, 1e-12) - m) / 2.0;
  } else {
    float h = 2.0 * m * n * sqrt(d);
    float s = sign(q + h) * pow(abs(q + h), 1.0 / 3.0);
    float u = sign(q - h) * pow(abs(q - h), 1.0 / 3.0);
    float rx = -s - u - c * 4.0 + 2.0 * m2;
    float ry = (s - u) * sqrt(3.0);
    float rm = sqrt(rx * rx + ry * ry);
    co = (ry / sqrt(max(rm - rx, 1e-12)) + 2.0 * g / max(rm, 1e-12) - m) / 2.0;
  }
  co = saturate(co);
  float2 r = ab * float2(co, sqrt(1.0 - co * co));
  return length(r - p) * sign(p.y - r.y);
}

// Position along an ellipse's outline, 0...1, from its rightmost point clockwise (y down).
static float ellipseAlong(float2 p, float2 radii) {
  float angle = atan2(p.y / radii.y, p.x / radii.x);
  return fract(angle / (2.0 * M_PI_F) + 1.0);
}

// Position along a rounded box's outline, 0...1, clockwise from where its top edge starts.
static float roundedBoxAlong(float2 q, float2 halfSize, float r) {
  float2 inner = max(halfSize - r, 0.0);
  float width = 2 * inner.x;
  float height = 2 * inner.y;
  float arc = 0.5 * M_PI_F * r;
  float total = 2 * width + 2 * height + 4 * arc;
  if (total <= 0) {
    return 0;
  }
  float2 k = clamp(q, -inner, inner);
  float2 e = q - k;
  if (e.x == 0 && e.y == 0) {
    // inside the straight part: the nearest side
    if (halfSize.x - abs(q.x) < halfSize.y - abs(q.y)) {
      e = float2(q.x >= 0 ? 1 : -1, 0);
    } else {
      e = float2(0, q.y >= 0 ? 1 : -1);
    }
  }
  float along;
  if (e.x == 0 && e.y < 0) {
    along = k.x + inner.x;
  } else if (e.x > 0 && e.y < 0) {
    along = width + atan2(e.x, -e.y) * r;
  } else if (e.x > 0 && e.y == 0) {
    along = width + arc + k.y + inner.y;
  } else if (e.x > 0 && e.y > 0) {
    along = width + arc + height + atan2(e.y, e.x) * r;
  } else if (e.x == 0 && e.y > 0) {
    along = width + 2 * arc + height + inner.x - k.x;
  } else if (e.x < 0 && e.y > 0) {
    along = 2 * width + 2 * arc + height + atan2(-e.x, e.y) * r;
  } else if (e.x < 0 && e.y == 0) {
    along = 2 * width + 3 * arc + height + inner.y - k.y;
  } else {
    along = 2 * width + 3 * arc + 2 * height + atan2(-e.y, -e.x) * r;
  }
  return along / total;
}

// Coverage of a shape blurred by a Gaussian of standard deviation `sigma`, at `dist` points from
// its outline, positive outside: the Gaussian's integral across a straight edge, with erf
// approximated by tanh. The argument is clamped: fast-math tanh of a huge value (a tiny sigma,
// as a blur or shadow animates through 0) is NaN, which would cover the whole shape's bounds.
static float shadowCoverage(float dist, float sigma) {
  float x = clamp(1.2027 * dist / (sigma * M_SQRT2_F), -9.0, 9.0);
  return 0.5 - 0.5 * tanh(x);
}

// Signed distance from a point in a vector item's local units, negative inside.
static float vectorDistance(VectorItem item, float2 p, texture2d<float> atlas, sampler atlasSampler) {
  bool closed = (item.flags & 1) != 0;
  bool isStroke = (item.flags & 2) != 0;
  switch (item.kind) {
    case 0:
    case 1: {
      float2 extent = item.params0.zw - item.params0.xy;
      if (any(extent <= 0)) {
        return kVectorOutside;
      }
      float2 t = (p - item.params0.xy) / extent;
      // A blurred path reaches past its baked region: the distance there is the region edge's
      // plus how far past the edge `p` is — never nearer than the truth.
      float beyond = 0;
      if (any(t < 0) || any(t > 1)) {
        if (item.blur <= 0) {
          return kVectorOutside;
        }
        float2 edge = saturate(t);
        beyond = length((t - edge) * extent);
        t = edge;
      }
      float2 value = atlas.sample(atlasSampler, mix(item.params1.xy, item.params1.zw, t)).rg;
      return (item.kind == 0 ? value.x : trimmedStroke(value.x, value.y, item.stroke, closed)) + beyond;
    }
    case 2: {
      float2 q = p - item.params0.xy;
      float d = sdEllipse(q, item.params0.zw);
      if (!isStroke) {
        return d;
      }
      bool trimmed = item.stroke.y > 0 || item.stroke.z < 1;
      return trimmedStroke(abs(d), trimmed ? ellipseAlong(q, item.params0.zw) : 0, item.stroke, true);
    }
    case 3: {
      float2 q = p - item.params0.xy;
      float d = sdRoundedBox(q, item.params0.zw, item.params1);
      if (!isStroke) {
        return d;
      }
      bool trimmed = item.stroke.y > 0 || item.stroke.z < 1;
      // only a canvas shape is trimmed, and its corners are all alike
      return trimmedStroke(abs(d), trimmed ? roundedBoxAlong(q, item.params0.zw, item.params1.x) : 0, item.stroke, true);
    }
  }
  return kVectorOutside;
}

// Pipelines are specialised on these, so a frame without glass, and the main pass, never pay
// for what they do not use: the glass branch alone costs occupancy in every pixel.
// Whether the frame has any glass to draw.
constant bool kHasGlass [[function_constant(0)]];
// Whether shapes at or above `maxDepth` are skipped: only a glass's backdrop pass is cut off.
constant bool kCutsAtDepth [[function_constant(1)]];

// Hard cap on the shapes a pixel walks, so a corrupt cell can never stall the GPU.
constant const int kMaxShapesPerCell = 512;
// Hard cap on the rounded clips one shape is tested against, for the same reason.
constant const int kMaxRoundedClips = 8;

// How much of the pixel at `uv` the rounded clips of entry `index` and those it chains to let
// through, 0...1, anti-aliased over one pixel.
static float roundedClipCoverage(device Clip* clips, int count, int index, float2 uv, float pixelsPerPoint) {
  float coverage = 1;
  for (int n = 0; n < kMaxRoundedClips && index > 0 && index < count; n++) {
    Clip clip = clips[index];
    float2 center = (clip.rect.xy + clip.rect.zw) * 0.5;
    float2 halfSize = (clip.rect.zw - clip.rect.xy) * 0.5;
    coverage *= saturate(0.5 - sdRoundedBox(uv - center, halfSize, clip.radii) * pixelsPerPoint);
    index = clip.rounded;
  }
  return coverage;
}

// A pseudo-random number in 0...1 for a pixel, the same every frame so still glass stays still.
static float hash12(float2 p) {
  float3 p3 = fract(float3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

// The grid cell `uv` falls in, or false when it is outside the grid.
static bool gridCell(float2 uv, GridArgBuffer grid, thread int2 &cell) {
  float2 gridSize = float2(grid.gridSize) * grid.cellSize;
  float minX = grid.gridPosition.x - gridSize.x * 0.5;
  float maxX = grid.gridPosition.x + gridSize.x * 0.5;
  float minY = grid.gridPosition.y - gridSize.y * 0.5;
  float maxY = grid.gridPosition.y + gridSize.y * 0.5;
  if (!isBetween(uv.x, minX, maxX) || !isBetween(uv.y, minY, maxY)) {
    return false;
  }
  // a pixel exactly on the far edge would otherwise index one cell past the grid
  cell.x = clamp(int(floor(remap(uv.x, float2(minX, maxX), float2(0, grid.gridSize.x)))), 0, grid.gridSize.x - 1);
  cell.y = clamp(int(floor(remap(uv.y, float2(minY, maxY), float2(0, grid.gridSize.y)))), 0, grid.gridSize.y - 1);
  return true;
}

// The color of the scene at `uv`, in centered points, y down, over the white background: every
// shape filed in its grid cell with a depth below `maxDepth`, composited front to back.
// `pixelsPerPoint` sets the anti-aliasing width, and `pixel` seeds glass grain.
static float4 shadeScene(
                         float2 uv, float pixelsPerPoint, float maxDepth, float2 pixel,
                         constant ShapeArgBuffer *buffers, constant GridArgBuffer *gridBuffer,
                         texture2d<float> glyphAtlas, texture2d<float> vectorAtlas, texture2d<float> glassAtlas
                         )
{
  constexpr sampler atlasSampler(filter::linear, address::clamp_to_edge);
  constexpr sampler imageSampler(filter::linear, mip_filter::linear, address::clamp_to_edge);
  constexpr sampler pixelatedSampler(filter::nearest, mip_filter::nearest, address::clamp_to_edge);
  constexpr sampler shadowSampler(filter::linear, mip_filter::linear, address::clamp_to_zero);
  constexpr sampler glassSampler(coord::pixel, filter::linear, address::clamp_to_edge);

  float4 bgColor = color::white;
  // premultiplied color, composited front to back
  float4 accumulated = float4(0);

  GridArgBuffer grid = gridBuffer[0];
  int2 cellCoord;
  if (!gridCell(uv, grid, cellCoord)) {
    return bgColor;
  }
  ShapeArgBuffer buffer = buffers[0];
  GridCell cell = grid.gridCells[from2DTo1DArray(cellCoord, grid.gridSize)];
  int startIndex = cell.startIndex;
  int endIndex = cell.startIndex + clamp(cell.count, 0, kMaxShapesPerCell);
  for (int i = startIndex; i < endIndex; i++) {
    Shape shape = grid.shapes[i];
    // Cells are sorted topmost first, so this skips what is drawn above a glass's backdrop.
    if (kCutsAtDepth && shape.depth >= maxDepth) {
      continue;
    }
    float clipCoverage = 1;
    // A shadow of something clipped is the blur of the shape cut to the clip. Blurred with
    // the same falloff, the lower of the two coverages is exactly that of the cut shape's
    // distance, the larger of the two distances.
    float softCoverage = 1;
    if (shape.clip > 0 && shape.clip < buffer.clipsCount) {
      Clip clip = buffer.clips[shape.clip];
      float4 bounds = clip.bounds;
      if (uv.x < bounds.x || uv.y < bounds.y || uv.x >= bounds.z || uv.y >= bounds.w) {
        continue;
      }
      if (clip.blur > 0) {
        float2 center = (clip.rect.xy + clip.rect.zw) * 0.5;
        float2 halfSize = (clip.rect.zw - clip.rect.xy) * 0.5;
        softCoverage = shadowCoverage(sdRoundedBox(uv - center, halfSize, clip.radii), clip.blur);
        if (softCoverage <= 0) {
          continue;
        }
      }
      // Rect clips stop at the bounds test; only rounded ones pay for a distance.
      int rounded = clip.blur <= 0 && any(clip.radii > 0) ? shape.clip : clip.rounded;
      if (rounded > 0) {
        clipCoverage = roundedClipCoverage(buffer.clips, buffer.clipsCount, rounded, uv, pixelsPerPoint);
        if (clipCoverage <= 0) {
          continue;
        }
      }
    }
    float4 shapeColor = float4(0);
    float coverage = 0;

    switch (shape.shapeType) {
        // circle
      case 0: {
        if (shape.index < 0 || shape.index >= buffer.circlesCount) {
          break;
        }
        Circle item = buffer.circles[shape.index];
        float dist = sdCircle(uv - item.position.xy, item.radius);
        coverage = step(dist, 0);
        shapeColor = item.color;

        break;
      }
        // square
      case 1: {
        if (shape.index < 0 || shape.index >= buffer.squaresCount) {
          break;
        }
        Square item = buffer.squares[shape.index];
        float dist = sdBox(rotation(item.rotation) * (uv - item.position.xy), item.size * 0.5);
        coverage = step(dist, 0);
        shapeColor = item.color;

        break;
      }
        // line
      case 2: {
        if (shape.index < 0 || shape.index >= buffer.linesCount) {
          break;
        }
        Line item = buffer.lines[shape.index];
        float dist = sdSegment(uv, item.start, item.end) - item.thickness;
        coverage = step(dist, 0);
        shapeColor = item.color;

        break;
      }
        // glyph
      case 3: {
        if (shape.index < 0 || shape.index >= buffer.glyphsCount) {
          break;
        }
        Glyph item = buffer.glyphs[shape.index];
        if (any(item.size <= 0)) {
          break;
        }
        float2 t = (uv - item.position) / item.size;
        if (item.blur > 0) {
          // A blurred glyph reaches past its quad: there, the quad edge's distance, less how
          // far past the edge `uv` is.
          float2 edge = saturate(t);
          float beyond = length((t - edge) * item.size);
          // in points, positive inside the glyph
          float dist = glyphAtlas.sample(atlasSampler, mix(item.uvMin, item.uvMax, edge)).r * item.fontSize - beyond;
          coverage = shadowCoverage(-dist, item.blur);
          shapeColor = item.color;
          break;
        }
        if (any(t < 0) || any(t > 1)) {
          break;
        }
        // distance in em, positive inside the glyph
        float dist = glyphAtlas.sample(atlasSampler, mix(item.uvMin, item.uvMax, t)).r;
        // one pixel wide anti-aliasing regardless of the font size
        coverage = saturate(0.5 + dist * item.fontSize * pixelsPerPoint);
        shapeColor = item.color;

        break;
      }
        // image
      case 4: {
        if (shape.index < 0 || shape.index >= buffer.imagesCount) {
          break;
        }
        ImageQuad item = buffer.images[shape.index];
        if (any(item.size <= 0) || item.textureIndex < 0) {
          break;
        }
        float2 t = (uv - item.position) / item.size;
        if (any(t < 0) || any(t > 1)) {
          break;
        }
        texture2d<float> image = buffer.textures[item.textureIndex].texture;
        float2 imageUV = mix(item.uvMin, item.uvMax, t);
        float4 texel = (item.flags & 4) != 0
          ? image.sample(shadowSampler, imageUV, level(item.lod))
          : (item.flags & 2) != 0
          ? image.sample(pixelatedSampler, imageUV, level(item.lod))
          : image.sample(imageSampler, imageUV, level(item.lod));
        coverage = 1;
        if ((item.flags & 1) != 0) {
          shapeColor = float4(item.tint.rgb, item.tint.a * texel.a);
        } else {
          // stored premultiplied, composited straight
          shapeColor = float4(texel.rgb / max(texel.a, 1e-6), texel.a * item.tint.a);
        }

        break;
      }
        // vector shape
      case 5: {
        if (shape.index < 0 || shape.index >= buffer.vectorsCount) {
          break;
        }
        VectorItem item = buffer.vectors[shape.index];
        if (uv.x < item.clip.x || uv.y < item.clip.y || uv.x > item.clip.z || uv.y > item.clip.w) {
          break;
        }
        float2 local = float2(dot(item.row0.xy, uv) + item.row0.z, dot(item.row1.xy, uv) + item.row1.z);
        float dist = vectorDistance(item, local, vectorAtlas, atlasSampler);
        // one pixel wide anti-aliasing at any scale, or a blur
        coverage = item.blur > 0
          ? shadowCoverage(dist * item.row0.w, item.blur)
          : saturate(0.5 - dist * item.row0.w * pixelsPerPoint);
        shapeColor = item.color;

        break;
      }
        // frosted glass
      case 6: {
        if (!kHasGlass || shape.index < 0 || shape.index >= buffer.glassesCount) {
          break;
        }
        Glass item = buffer.glasses[shape.index];
        float2 center = (item.rect.xy + item.rect.zw) * 0.5;
        float2 halfSize = (item.rect.zw - item.rect.xy) * 0.5;
        coverage = saturate(0.5 - sdRoundedBox(uv - center, halfSize, item.radii) * pixelsPerPoint);
        if (coverage <= 0) {
          break;
        }
        // Without a backdrop (the atlas was full) the glass is its tint over the background.
        float3 backdrop = bgColor.rgb;
        float2 regionSize = item.regionMax - item.regionMin;
        if (all(regionSize > 0)) {
          // Texel j of the region holds the scene at `sceneOrigin + j * pointsPerTexel`; its
          // center is at j + 0.5. Kept half a texel inside, so a neighbour never bleeds in.
          float2 local = (uv - item.sceneOrigin) / item.pointsPerTexel + 0.5;
          float2 texel = item.regionMin + clamp(local, float2(0.5), regionSize - 0.5);
          backdrop = glassAtlas.sample(glassSampler, texel).rgb;
        }
        float luma = dot(backdrop, float3(0.2126, 0.7152, 0.0722));
        float3 glassColor = mix(float3(luma), backdrop, item.saturation);
        glassColor = mix(glassColor, item.tint.rgb, item.tint.a);
        glassColor += (hash12(pixel) - 0.5) * item.noise;
        shapeColor = float4(saturate(glassColor), item.opacity);

        break;
      }
    }

    float alpha = shapeColor.a * min(coverage, softCoverage) * clipCoverage;
    accumulated += (1 - accumulated.a) * float4(shapeColor.rgb * alpha, alpha);
    if (accumulated.a >= 0.999) {
      break;
    }
  }

  return accumulated + (1 - accumulated.a) * bgColor;
}

// The centered point, in points, that `compute2D` samples for pixel `gid`.
static float2 pixelToPoint(uint2 gid, int width, int height, int2 windowSize) {
  float2 uv = 2 * float2(gid) - float2(width, height);
  uv /= float2(width, height);
  return uv * float2(windowSize) * 0.5;
}

kernel void compute2D(
                      texture2d<float, access::write> output [[texture(0)]],
                      constant SceneData &data [[buffer(0)]],
                      constant ShapeArgBuffer *buffers [[buffer(1)]],
                      constant GridArgBuffer *gridBuffer [[buffer(2)]],
                      texture2d<float> glyphAtlas [[texture(1)]],
                      texture2d<float> vectorAtlas [[texture(2)]],
                      texture2d<float> glassAtlas [[texture(3)]],
                      uint2 gid [[thread_position_in_grid]]
                      )
{
  int width = output.get_width();
  int height = output.get_height();
  if (int(gid.x) >= width || int(gid.y) >= height) {
    return;
  }
  float2 uv = pixelToPoint(gid, width, height, data.windowSize);
  float pixelsPerPoint = float(width) / float(data.windowSize.x);

  float4 color = shadeScene(uv, pixelsPerPoint, INFINITY, float2(gid), buffers, gridBuffer, glyphAtlas, vectorAtlas, glassAtlas);

  GridArgBuffer grid = gridBuffer[0];
  int2 cellCoord;
  if (data.debug.drawGrid && gridCell(uv, grid, cellCoord)) {
    GridCell cell = grid.gridCells[from2DTo1DArray(cellCoord, grid.gridSize)];
    float2 center = (float2(cellCoord) - float2(grid.gridSize) * 0.5) * grid.cellSize + grid.cellSize * 0.5;

    float4 gridColor = color::black;
    float4 nonEmptyColor = color::green;
    float4 prevColor = color;
    {
      float dist = sdBox(uv - center, grid.cellSize * 0.5);
      int intersect = step(dist, 0);
      color = mix(color, cell.count && data.debug.showFilledCells ? nonEmptyColor : gridColor, intersect);
    }
    {
      float inset = 2;
      float dist = sdBox(uv - center, (grid.cellSize - inset) * 0.5);
      int intersect = step(dist, 0);
      color = mix(color, prevColor, intersect);
    }
  }

  output.write(color, gid);
}

// One glass's backdrop pass, or one direction of its blur. Regions are in texels.
struct GlassPass {
  // where the region starts in the glass atlas
  int2 atlasOrigin;
  int2 size;
  // where texel (0, 0) samples the scene, in centered points
  float2 sceneOrigin;
  float pointsPerTexel;
  // only what is drawn below the glass is its backdrop
  float maxDepth;
  // the blur's standard deviation, in texels
  float sigma;
  int padding;
  // (1, 0) for the horizontal blur, (0, 1) for the vertical one
  float2 direction;
};

// The scene below one glass, over its region, at the glass's own resolution: texel `gid` into
// `output`, a scratch texture, at (0, 0).
kernel void backdrop2D(
                       texture2d<float, access::write> output [[texture(0)]],
                       constant SceneData &data [[buffer(0)]],
                       constant ShapeArgBuffer *buffers [[buffer(1)]],
                       constant GridArgBuffer *gridBuffer [[buffer(2)]],
                       constant GlassPass &pass [[buffer(3)]],
                       texture2d<float> glyphAtlas [[texture(1)]],
                       texture2d<float> vectorAtlas [[texture(2)]],
                       texture2d<float> glassAtlas [[texture(3)]],
                       uint2 gid [[thread_position_in_grid]]
                       )
{
  if (int(gid.x) >= pass.size.x || int(gid.y) >= pass.size.y) {
    return;
  }
  float2 uv = pass.sceneOrigin + float2(gid) * pass.pointsPerTexel;
  float4 color = shadeScene(uv, 1 / pass.pointsPerTexel, pass.maxDepth, float2(gid), buffers, gridBuffer, glyphAtlas, vectorAtlas, glassAtlas);
  output.write(color, gid);
}

// Hard cap on the taps either side of a blurred texel, whatever the sigma.
constant const int kMaxBlurTaps = 32;

// One direction of a separable Gaussian over a region at (0, 0) of `source`, written to
// `output` at `outputOrigin`. Reads stay inside the region, so neighbours in the atlas never
// bleed in; two taps are taken per linearly filtered sample.
kernel void glassBlur(
                      texture2d<float> source [[texture(0)]],
                      texture2d<float, access::write> output [[texture(1)]],
                      constant GlassPass &pass [[buffer(0)]],
                      constant int2 &outputOrigin [[buffer(1)]],
                      uint2 gid [[thread_position_in_grid]]
                      )
{
  if (int(gid.x) >= pass.size.x || int(gid.y) >= pass.size.y) {
    return;
  }
  constexpr sampler blurSampler(coord::pixel, filter::linear, address::clamp_to_edge);
  float2 lo = float2(0.5);
  float2 hi = float2(pass.size) - 0.5;
  float2 center = float2(gid) + 0.5;
  float4 sum = source.sample(blurSampler, center);
  float total = 1;
  if (pass.sigma > 0) {
    int radius = min(int(ceil(3 * pass.sigma)), kMaxBlurTaps);
    float k = -0.5 / (pass.sigma * pass.sigma);
    for (int i = 1; i <= radius; i += 2) {
      float w1 = exp(k * float(i * i));
      float w2 = i + 1 <= radius ? exp(k * float((i + 1) * (i + 1))) : 0;
      float w = w1 + w2;
      float offset = (float(i) * w1 + float(i + 1) * w2) / w;
      float2 step = pass.direction * offset;
      sum += w * source.sample(blurSampler, clamp(center + step, lo, hi));
      sum += w * source.sample(blurSampler, clamp(center - step, lo, hi));
      total += 2 * w;
    }
  }
  output.write(sum / total, uint2(outputOrigin + int2(gid)));
}
