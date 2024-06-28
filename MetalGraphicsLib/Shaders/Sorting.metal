#include "Sorting.h"

constant const int MIN_MERGE = 32;

int minRunLength(int n) {
  int r = 0;
  while (n >= MIN_MERGE) {
    r |= (n & 1);
    n >>= 1;
  }
  return n + r;
}

template <typename T>
void insertionSort(device T* array, int left, int right, SortCb<T> callback) {
  for (int i = left + 1; i <= right; ++i) {
    T temp = array[i];
    int j = i - 1;
    while (j >= left && !callback(array[j], temp)) {
      array[j + 1] = array[j];
      --j;
    }
    array[j + 1] = temp;
  }
}

constant int count = 10000;

template <typename T>
void merge(device T* array, int l, int m, int r, SortCb<T> callback) {
  int len1 = m - l + 1, len2 = r - m;
  T left[count] = {}, right[count] = {};
  
  for (int i = 0; i < len1; ++i)
    left[i] = array[l + i];
  for (int i = 0; i < len2; ++i)
    right[i] = array[m + 1 + i];
  
  int i = 0, j = 0, k = l;
  while (i < len1 && j < len2) {
    if (callback(left[i], right[j])) {
      array[k] = left[i];
      ++i;
    } else {
      array[k] = right[j];
      ++j;
    }
    ++k;
  }
  
  while (i < len1) {
    array[k] = left[i];
    ++i;
    ++k;
  }
  
  while (j < len2) {
    array[k] = right[j];
    ++j;
    ++k;
  }
}

template <typename T>
void timSort(device T* array, int size, SortCb<T> callback) {
  int n = size;
  int minRun = minRunLength(n);
  
  for (int start = 0; start < n; start += minRun) {
    int end = min(start + minRun - 1, n - 1);
    insertionSort(array, start, end);
  }
  
  for (int size = minRun; size < n; size *= 2) {
    for (int left = 0; left < n; left += 2 * size) {
      int mid = min(left + size - 1, n - 1);
      if (mid >= n - 1) break;
      int right = min(left + 2 * size - 1, n - 1);
      merge(array, left, mid, right);
    }
  }
}
