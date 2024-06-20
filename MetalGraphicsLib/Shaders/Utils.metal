//
//  Utils.metal
//  MetalGraphicsLib
//
//  Created by Nikolay Diahovets on 20.06.2024.
//

#include "Utils.h"

int from3DTo1DArray(int3 index, int3 size) {
    return (index.z * size.y * size.x) + (index.y * size.x + index.x);
}

int3 from1DTo3DArray(int index, int3 size) {
    int x = index % size.z;
    int y = (index / size.z) % size.y;
    int z = index / (size.y * size.z);
    return int3(x, y, z);
}

int from2DTo1DArray(int2 index, int2 size) {
    return index.y * size.x + index.x;
}

int2 from1DTo2DArray(int index, int2 size) {
    int y = index / size.x;
    int x = index - y * size.x;
    return int2(x, y);
}

bool isBetween(float value, float min, float max) {
  return value >= min && value <= max;
}
