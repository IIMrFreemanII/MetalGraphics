#pragma once

#include <metal_stdlib>
using namespace metal;

int from3DTo1DArray(int3 index, int3 size);
int3 from1DTo3DArray(int index, int3 size);
int from2DTo1DArray(int2 index, int2 size);
int2 from1DTo2DArray(int index, int2 size);

bool isBetween(float value, float min, float max);

namespace color {
constant const float4 white = float4(1, 1, 1, 1);
constant const float4 black = float4(0, 0, 0, 1);
constant const float4 red = float4(1, 0.231, 0.188, 1.0);
constant const float4 green = float4(0.156, 0.803, 0.254, 1.0);
constant const float4 blue = float4(0.0, 0.478, 1, 1.0);
}
