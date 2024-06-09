//
//  Shaders.metal
//  GPURayMarching
//
//  Created by Nikolay Diahovets on 08.06.2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Math.metal"

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

float distanceToScene(Ray r, constant GridArgBuffer* grid) {
  float dist = MAXFLOAT;
  
  int count = grid->gridItemsCount;
  for (int i = 0; i < count; i++) {
    GridItem item = grid->gridItems[i];
    
    switch(item.shapeType) {
      // Sphere shape
      case 0: {
        Sphere sphere = grid->spheres[item.index];
        dist = min(dist, sdCircle(r.position - sphere.position, sphere.radius));
      }
    }
  }
  
  //  Ray repeatedRay = r;
  //  repeatedRay.position.x = fmod(abs(repeatedRay.position.x), 1);
  
  //  {
  //    Sphere s = Sphere(float3(0.5, 0, 0), 0.5);
  //    dist = min(dist, sdCircle(repeatedRay.position - s.position, s.radius));
  //  }
  
  //  {
  //    Sphere s = Sphere(float3(3, 0, 0), 1.0);
  //    dist = min(dist, sdCircle(r.position - s.position, s.radius));
  //  }
  
  return dist;
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
  float3 rayDir = (rotationMatrix * float4(normalize(float3(uv, focalLength)), 1)).xyz;
  Ray ray = Ray(float3(camera.position), rayDir);
  
  for (int i = 0.0; i < 100.0; i++) {
    float distance = distanceToScene(ray, grid);
    if (distance < 0.001) {
      color = float4(1);
      break;
    }
    ray.position += ray.direction * distance;
  }
  
  output.write(color, gid);
}
