#pragma once

#include <metal_stdlib>
using namespace metal;

constant float π = M_PI_F;

float dot2(float2 v);
float dot2(float3 v);
float ndot(float2 a, float2 b);

float remap(float value, float2 inputMinMax, float2 outputMinMax);
float lerp(float min, float max, float t);
float normalize(float value, float min, float max);

float4x4 rotationX(float angle);
float4x4 rotationY(float angle);
float4x4 rotationZ(float angle);
float4x4 rotation(float3 eulerAngles);

float toRadians(float value);
float toDegrees(float value);
