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
  float3 position;
  float radius;
  float4 color;
};

struct Square {
  float3 position;
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

struct SceneData {
  int2 windowSize;
  float time;
};

kernel void compute2D(
                    texture2d<float, access::write> output [[texture(0)]],
                    constant SceneData &data [[buffer(0)]],
                    constant ShapeArgBuffer *buffers [[buffer(1)]],
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
  
  float4 color = float4(0.0, 0.0, 0.0, 1.0);
  
  ShapeArgBuffer args = buffers[0];
  int circlesCount = args.circlesCount;
  int squaresCount = args.squaresCount;
  
  // todo: set cameraPos based on the biggest depth value
  float cameraPos = 1000000;
  float distToCamera = cameraPos;
  
  for (int i = 0; i < circlesCount; i++) {
    Circle circle = args.circles[i];
    float dist = sdCircle(uv - circle.position.xy, circle.radius);
    float newDistToCamera = cameraPos - circle.position.z;
    float intersect = step(dist, 0);
    float closestToTheCamera = step(newDistToCamera, distToCamera);
    int hit = int(intersect) & int(closestToTheCamera);
    color = mix(color, circle.color, hit);
    distToCamera = select(distToCamera, newDistToCamera, hit);
  }
  
  for (int i = 0; i < squaresCount; i++) {
    Square square = args.squares[i];
    float dist = sdBox(rotation(square.rotation) * (uv - square.position.xy), square.size * 0.5);
    float newDistToCamera = cameraPos - square.position.z;
    float intersect = step(dist, 0);
    float closestToTheCamera = step(newDistToCamera, distToCamera);
    int hit = int(intersect) & int(closestToTheCamera);
    color = mix(color, square.color, hit);
    distToCamera = select(distToCamera, newDistToCamera, hit);
  }
  
  output.write(color, gid);
  
//  float2 tempUv = rotation(data.time) * uv;
//  output.write(float4(tempUv.x, tempUv.y, 0, 1), gid);
}
