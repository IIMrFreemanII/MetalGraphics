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

struct Circle {
  float2 position;
  float radius;
  float4 color;
};

struct Square {
  float2 position;
  float2 size;
  float rotation;
  float4 color;
};

struct ShapeArgBuffer {
  device Circle* circles [[id(0)]];
  device Square* squares [[id(1)]];
  int circlesCount [[id(2)]];
  int squaresCount [[id(3)]];
};

kernel void compute2D(
                    texture2d<float, access::write> output [[texture(0)]],
                    constant float &time [[buffer(0)]],
                    constant ShapeArgBuffer *buffers [[buffer(1)]],
                    uint2 gid [[thread_position_in_grid]]
                    )
{
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = 2 * float2(gid) - float2(width, height);
  uv /= height;
//  uv = remap();
  float4 color = float4(0.0, 0.0, 0.0, 1.0);
  
  ShapeArgBuffer args = buffers[0];
  int circlesCount = args.circlesCount;
  int squaresCount = args.squaresCount;
  
  for (int i = 0; i < circlesCount; i++) {
    Circle circle = args.circles[i];
    float dist = sdCircle(uv - circle.position, circle.radius);
    color = mix(color, circle.color, 1 - step(0, dist));
  }
  
  for (int i = 0; i < squaresCount; i++) {
    Square square = args.squares[i];
    float dist = sdBox(uv - square.position, square.size * 0.5);
    color = mix(color, square.color, 1 - step(0, dist));
  }
  
  output.write(color, gid);
}
