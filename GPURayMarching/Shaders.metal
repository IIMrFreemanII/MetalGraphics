//
//  Shaders.metal
//  GPURayMarching
//
//  Created by Nikolay Diahovets on 08.06.2024.
//

#include <metal_stdlib>
using namespace metal;

struct Camera {
  float3 position;
  float3 rotation;
  // in radians
  float fov;
};

struct Sphere {
  float3 position;
  float radius;
  
  Sphere(float3 p, float r) {
    position = p;
    radius = r;
  }
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

float distanceToScene(Ray r) {
  float dist = 100000;
  
  {
    Sphere s = Sphere(float3(0.0), 1.0);
    dist = min(dist, sdCircle(r.position - s.position, s.radius));
  }
  
  {
    Sphere s = Sphere(float3(3, 0, 0), 1.0);
    dist = min(dist, sdCircle(r.position - s.position, s.radius));
  }
  
  return dist;
}

kernel void compute(
                    texture2d<float, access::write> output [[texture(0)]],
                    constant float &time [[buffer(0)]],
                    constant Camera &camera [[buffer(1)]],
                    uint2 gid [[thread_position_in_grid]])
{
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = 2 * float2(gid) - float2(width, height);
  uv /= height;
  float4 color = float4(0.0, 0.0, 0.0, 1.0);
  
  float focalLength = 1 / tan(camera.fov / 2);
  Ray ray = Ray(float3(0.0, 0.0, -3.0), normalize(float3(uv, focalLength)));
  
  for (int i = 0.0; i < 100.0; i++) {
    float distance = distanceToScene(ray);
    if (distance < 0.001) {
      color = float4(1.0);
      break;
    }
    ray.position += ray.direction * distance;
  }
  
  output.write(color, gid);
}
