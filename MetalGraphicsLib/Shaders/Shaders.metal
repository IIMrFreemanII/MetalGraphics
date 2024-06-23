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

struct GridCellArgBuffer {
  device Shape* shapes [[id(0)]];
  int count [[id(1)]];
};

struct GridArgBuffer {
  device GridCellArgBuffer* gridCells [[id(0)]];
  int2 gridSize [[id(1)]];
  float cellSize [[id(2)]];
  float2 gridPosition [[id(3)]];
};

struct ShapeArgBuffer {
  device Circle* circles [[id(0)]];
  int circlesCount [[id(1)]];
  
  device Square* squares [[id(2)]];
  int squaresCount [[id(3)]];
  
  device Line* lines [[id(4)]];
  int linesCount [[id(5)]];
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

kernel void compute2D(
                      texture2d<float, access::write> output [[texture(0)]],
                      constant SceneData &data [[buffer(0)]],
                      constant ShapeArgBuffer *buffers [[buffer(1)]],
                      constant GridArgBuffer *gridBuffer [[buffer(2)]],
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
  
  float4 bgColor = color::white;
  float4 color = bgColor;
  
  GridArgBuffer grid = gridBuffer[0];
  float2 gridSize = float2(grid.gridSize) * grid.cellSize;
  float minX = grid.gridPosition.x - gridSize.x * 0.5;
  float maxX = grid.gridPosition.x + gridSize.x * 0.5;
  float minY = grid.gridPosition.y - gridSize.y * 0.5;
  float maxY = grid.gridPosition.y + gridSize.y * 0.5;
  
  if (isBetween(uv.x, minX, maxX) && isBetween(uv.y, minY, maxY)) {
    ShapeArgBuffer buffer = buffers[0];
    
    int xIndex = floor(remap(uv.x, float2(minX, maxX), float2(0, grid.gridSize.x)));
    int yIndex = floor(remap(uv.y, float2(minY, maxY), float2(0, grid.gridSize.y)));
    int index = from2DTo1DArray(int2(xIndex, yIndex), grid.gridSize);
    GridCellArgBuffer cell = grid.gridCells[index];
    int shapesCount = cell.count;
    int stop = 0;
    for (int i = 0; i < shapesCount; i++) {
      if (stop) {
        break;
      }
      
      Shape shape = cell.shapes[i];
      switch (shape.shapeType) {
          // circle
        case 0: {
          Circle item = buffer.circles[shape.index];
          float dist = sdCircle(uv - item.position.xy, item.radius);
          int intersect = step(dist, 0);
          color = mix(color, item.color, intersect);
          stop = intersect;
          
          break;
        }
          // square
        case 1: {
          Square item = buffer.squares[shape.index];
          float dist = sdBox(rotation(item.rotation) * (uv - item.position.xy), item.size * 0.5);
          int intersect = step(dist, 0);
          color = mix(color, item.color, intersect);
          stop = intersect;
          
          break;
        }
          // line
        case 2: {
          Line item = buffer.lines[shape.index];
          float dist = sdSegment(uv, item.start, item.end) - item.thickness;
          int intersect = step(dist, 0);
          color = mix(color, item.color, intersect);
          stop = intersect;
          
          break;
        }
      }
    }
    
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
        color = mix(color, shapesCount && data.debug.showFilledCells ? nonEmptyColor : gridColor, intersect);
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
