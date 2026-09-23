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

// Hard cap on the shapes a pixel walks, so a corrupt cell can never stall the GPU.
constant const int kMaxShapesPerCell = 512;

kernel void compute2D(
                      texture2d<float, access::write> output [[texture(0)]],
                      constant SceneData &data [[buffer(0)]],
                      constant ShapeArgBuffer *buffers [[buffer(1)]],
                      constant GridArgBuffer *gridBuffer [[buffer(2)]],
                      texture2d<float> glyphAtlas [[texture(1)]],
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
