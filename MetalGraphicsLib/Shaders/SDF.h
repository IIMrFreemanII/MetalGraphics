#pragma once

#include <metal_stdlib>
using namespace metal;

float sdCircleSquared(float2 p, float r);
float sdCircle(float2 p, float r);
float sdRoundedBoxSquared(float2 p, simd_float2 b, float4 r);
float sdRoundedBox(float2 p, float2 b, float4 r);
float sdBoxSquared(float2 p, float2 b);
float sdBox(float2 p, float2 b);
float sdOrientedBox(float2 p, float2 a, float2 b, float th);
float sdSegment(float2 p, float2 a, float2 b);
float sdTriangle(float2 p, float2 p0, float2 p1, float2 p2);

float opRound(float d, float r);
float opOnion(float d, float r);
float opUnion(float d1, float d2);
float opSubtraction(float d1, float d2);
float opIntersection(float d1, float d2);
float opSmoothUnion(float d1, float d2, float k);
float opSmoothSubtraction(float d1, float d2, float k);
float opSmoothIntersection(float d1, float d2, float k);
float opXor(float d1, float d2);
