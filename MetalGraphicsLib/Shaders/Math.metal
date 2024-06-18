#include "Math.h"

float2 select(float2 a, float2 b, bool t) {
  float2 values[2] = {a, b};
  return values[t];
}
float3 select(float3 a, float3 b, bool t) {
  float3 values[2] = {a, b};
  return values[t];
}
float4 select(float4 a, float4 b, bool t) {
  float4 values[2] = {a, b};
  return values[t];
}

float dot2(float2 v ) { return dot(v,v); }
float dot2(float3 v ) { return dot(v,v); }
float ndot(float2 a, float2 b ) { return a.x*b.x - a.y*b.y; }

float remap(float value, float2 inputMinMax, float2 outputMinMax) {
  return outputMinMax.x + (outputMinMax.y - outputMinMax.x) * ((value - inputMinMax.x) / (inputMinMax.y - inputMinMax.x));
}

float2 remap(float2 value, float2 inputMinMax, float2 outputMinMax) {
  return outputMinMax.x + (outputMinMax.y - outputMinMax.x) * ((value - inputMinMax.x) / (inputMinMax.y - inputMinMax.x));
}

float lerp(float min, float max, float t) {
  return min + (max - min) * t;
}

float normalize(float value, float min, float max) {
  return (value - min) / (max - min);
}

float2x2 rotation(float angle) {
  float s = sin(angle);
  float c = cos(angle);
  
  return float2x2(
                  float2( c, s),
                  float2(-s, c)
                  );
}

float4x4 rotationX(float angle) {
  float cosAngle = cos(angle);
  float sinAngle = sin(angle);
  return float4x4(
                  float4(1, 0, 0, 0),
                  float4(0, cosAngle, sinAngle, 0),
                  float4(0, -sinAngle, cosAngle, 0),
                  float4(0, 0, 0, 1)
                  );
}

float4x4 rotationY(float angle) {
  float cosAngle = cos(angle);
  float sinAngle = sin(angle);
  return float4x4(
                  float4(cosAngle, 0, -sinAngle, 0),
                  float4(0, 1, 0, 0),
                  float4(sinAngle, 0, cosAngle, 0),
                  float4(0, 0, 0, 1)
                  );
}

float4x4 rotationZ(float angle) {
  float cosAngle = cos(angle);
  float sinAngle = sin(angle);
  return float4x4(
                  float4(cosAngle, sinAngle, 0, 0),
                  float4(-sinAngle, cosAngle, 0, 0),
                  float4(0, 0, 1, 0),
                  float4(0, 0, 0, 1)
                  );
}

float4x4 rotation(float3 eulerAngles) {
  //  float pitch = eulerAngles.x;
  //  float yaw = eulerAngles.y;
  //  float roll = eulerAngles.z;
  
  // Combine the rotation matrices (Z * Y * X)
  return rotationZ(eulerAngles.z) * rotationY(eulerAngles.y) * rotationX(eulerAngles.x);
}

float toRadians(float value) {
  return (value / 180) * π;
};

float toDegrees(float value) {
  return (value / π) * 180;
};
