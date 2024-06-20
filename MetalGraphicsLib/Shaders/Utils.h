#pragma once

#include <metal_stdlib>
using namespace metal;

int from3DTo1DArray(int3 index, int3 size);
int3 from1DTo3DArray(int index, int3 size);
int from2DTo1DArray(int2 index, int2 size);
int2 from1DTo2DArray(int index, int2 size);

bool isBetween(float value, float min, float max);
