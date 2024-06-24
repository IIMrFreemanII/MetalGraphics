//
//  Shaders.metal
//  GPURayMarching
//
//  Created by Nikolay Diahovets on 08.06.2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Math.h"

struct Camera {
  float3 position;
  float3 rotation;
  // in degrees
  float fov;
};

struct Sphere {
  float4 color;
  float3 position;
  float radius;
  
  Sphere(float3 p, float r) {
    position = p;
    radius = r;
  }
};

struct GridItem {
  int index;
  int shapeType;
};

struct GridArgBuffer {
  device GridItem* gridItems [[id(0)]];
  device Sphere* spheres [[id(1)]];
  int gridItemsCount [[id(2)]];
};

struct Ray {
  float3 position;
  float3 direction;
  
  Ray(float3 p, float3 d) {
    position = p;
    direction = d;
  }
};

float sdCircle( float3 p, float r )
{
  return length(p) - r;
}

struct SceneData {
  float4 color;
  float distance;
  bool hit;
  
  SceneData(float d, float4 c, bool h) {
    color = c;
    distance = d;
    hit = h;
  }
};

SceneData distanceToScene(Ray r, constant GridArgBuffer* grid) {
  float dist = MAXFLOAT;
  float4 bg = float4(0, 0, 0, 1);
  float4 color = bg;
  bool hit = false;
  
  int count = grid->gridItemsCount;
  for (int i = 0; i < count; i++) {
    GridItem item = grid->gridItems[i];
    
    switch(item.shapeType) {
      // Sphere shape
      case 0: {
        Sphere sphere = grid->spheres[item.index];
        dist = min(dist, sdCircle(r.position - sphere.position, sphere.radius));
        
        if (dist < 0.001) {
          color = sphere.color;
          hit = true;
          return SceneData(dist, color, hit);
        }
      }
    }
  }
  
  return SceneData(dist, color, hit);
}

kernel void compute(
                    texture2d<float, access::write> output [[texture(0)]],
                    constant float &time [[buffer(0)]],
                    constant Camera &camera [[buffer(1)]],
                    constant GridArgBuffer *grid [[buffer(2)]],
                    uint2 gid [[thread_position_in_grid]]
                    )
{
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = 2 * float2(gid) - float2(width, height);
  uv /= height;
  float4 color = float4(0.0, 0.0, 0.0, 1.0);
  
  float focalLength = 1 / tan(toRadians(camera.fov) / 2);
  float4x4 rotationMatrix = rotation(float3(toRadians(camera.rotation.x), toRadians(camera.rotation.y), toRadians(camera.rotation.z)));
//  float focalLength = 1;
//  float4x4 rotationMatrix = float4x4();
  float3 rayDir = (rotationMatrix * float4(normalize(float3(uv, focalLength)), 1)).xyz;
  Ray ray = Ray(float3(camera.position), rayDir);
  
  for (int i = 0.0; i < 100.0; i++) {
    SceneData data = distanceToScene(ray, grid);
    if (data.hit) {
      color = data.color;
      break;
    }
    ray.position += ray.direction * data.distance;
//    ray.position += ray.direction * 1;
  }
  
  output.write(color, gid);
}
