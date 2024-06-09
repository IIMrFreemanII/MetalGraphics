#include <metal_stdlib>
using namespace metal;

constant float π = M_PI_F;

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
