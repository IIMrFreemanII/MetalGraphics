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
  // bit 0 - template, bit 1 - nearest filtering
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
  // baked: atlas uv of the region | rounded box: corner radius in x
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
  float padding0;
  float padding1;
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
      if (any(t < 0) || any(t > 1)) {
        return kVectorOutside;
      }
      float2 value = atlas.sample(atlasSampler, mix(item.params1.xy, item.params1.zw, t)).rg;
      return item.kind == 0 ? value.x : trimmedStroke(value.x, value.y, item.stroke, closed);
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
      float r = item.params1.x;
      float d = sdRoundedBox(q, item.params0.zw, float4(r));
      if (!isStroke) {
        return d;
      }
      bool trimmed = item.stroke.y > 0 || item.stroke.z < 1;
      return trimmedStroke(abs(d), trimmed ? roundedBoxAlong(q, item.params0.zw, r) : 0, item.stroke, true);
    }
  }
  return kVectorOutside;
}

// Hard cap on the shapes a pixel walks, so a corrupt cell can never stall the GPU.
constant const int kMaxShapesPerCell = 512;

kernel void compute2D(
                      texture2d<float, access::write> output [[texture(0)]],
                      constant SceneData &data [[buffer(0)]],
                      constant ShapeArgBuffer *buffers [[buffer(1)]],
                      constant GridArgBuffer *gridBuffer [[buffer(2)]],
                      texture2d<float> glyphAtlas [[texture(1)]],
                      texture2d<float> vectorAtlas [[texture(2)]],
                      uint2 gid [[thread_position_in_grid]]
                      )
{
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = 2 * float2(gid) - float2(width, height);
  uv /= float2(width, height);
  
  // Do projection for uv coords
  int2 windowSize = data.windowSize;
  float left = -windowSize.x * 0.5;
  float right = windowSize.x * 0.5;
  float bottom = -windowSize.y * 0.5;
  float top = windowSize.y * 0.5;
  
  //  float left = 0;
  //  float right = windowSize.x;
  //  float bottom = 0;
  //  float top = windowSize.y;
  
  uv.x *= (right - left) * 0.5;
  uv.y *= (top - bottom) * 0.5;
  
  uv.x += (right + left) * 0.5;
  uv.y += (top + bottom) * 0.5;
  // --------------------------
  
  constexpr sampler atlasSampler(filter::linear, address::clamp_to_edge);
  constexpr sampler imageSampler(filter::linear, mip_filter::linear, address::clamp_to_edge);
  constexpr sampler pixelatedSampler(filter::nearest, mip_filter::nearest, address::clamp_to_edge);
  float pixelsPerPoint = float(width) / float(windowSize.x);
  
  float4 bgColor = color::white;
  float4 color = bgColor;
  // premultiplied color, composited front to back
  float4 accumulated = float4(0);
  
  GridArgBuffer grid = gridBuffer[0];
  float2 gridSize = float2(grid.gridSize) * grid.cellSize;
  float minX = grid.gridPosition.x - gridSize.x * 0.5;
  float maxX = grid.gridPosition.x + gridSize.x * 0.5;
  float minY = grid.gridPosition.y - gridSize.y * 0.5;
  float maxY = grid.gridPosition.y + gridSize.y * 0.5;
  
  if (isBetween(uv.x, minX, maxX) && isBetween(uv.y, minY, maxY)) {
    ShapeArgBuffer buffer = buffers[0];
    
    // a pixel exactly on the far edge would otherwise index one cell past the grid
    int xIndex = clamp(int(floor(remap(uv.x, float2(minX, maxX), float2(0, grid.gridSize.x)))), 0, grid.gridSize.x - 1);
    int yIndex = clamp(int(floor(remap(uv.y, float2(minY, maxY), float2(0, grid.gridSize.y)))), 0, grid.gridSize.y - 1);
    int index = from2DTo1DArray(int2(xIndex, yIndex), grid.gridSize);
    GridCell cell = grid.gridCells[index];
    int startIndex = cell.startIndex;
    int endIndex = cell.startIndex + clamp(cell.count, 0, kMaxShapesPerCell);
    for (int i = startIndex; i < endIndex; i++) {
      Shape shape = grid.shapes[i];
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
          float4 texel = (item.flags & 2) != 0
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
          // one pixel wide anti-aliasing at any scale
          coverage = saturate(0.5 - dist * item.row0.w * pixelsPerPoint);
          shapeColor = item.color;
          
          break;
        }
      }
      
      float alpha = shapeColor.a * coverage;
      accumulated += (1 - accumulated.a) * float4(shapeColor.rgb * alpha, alpha);
      if (accumulated.a >= 0.999) {
        break;
      }
    }
    
    color = accumulated + (1 - accumulated.a) * bgColor;
    
    if (data.debug.drawGrid) {
      float2 center = (float2(xIndex, yIndex) - float2(grid.gridSize) * 0.5) * grid.cellSize + grid.cellSize * 0.5;
      
      float4 gridColor = color::black;
      float4 nonEmptyColor = color::green;
      float2 offset = center;
      float2 repeatedCoord = uv;
      float4 prevColor = color;
      {
        float dist = sdBox(repeatedCoord - offset, grid.cellSize * 0.5);
        int intersect = step(dist, 0);
        color = mix(color, cell.count && data.debug.showFilledCells ? nonEmptyColor : gridColor, intersect);
      }
      {
        float inset = 2;
        float dist = sdBox(repeatedCoord - offset, (grid.cellSize - inset) * 0.5);
        int intersect = step(dist, 0);
        color = mix(color, prevColor, intersect);
      }
    }
  }
  
  output.write(color, gid);
}
