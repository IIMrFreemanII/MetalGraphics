#pragma once

#include <metal_stdlib>
using namespace metal;

template <typename T>
using SortCb = bool(*)(T, T);

template <typename T>
void timSort(device T* array, int size, SortCb<T> callback);
