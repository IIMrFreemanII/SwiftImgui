//
//  math.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.12.2022.
//

#include <metal_stdlib>
using namespace metal;
#include "math.h"

float4x4 translation(float3 value) {
  return {
    {      1,       0,       0, 0},
    {      0,       1,       0, 0},
    {      0,       0,       1, 0},
    {value.x, value.y, value.z, 1},
  };
}

float3x3 translation2D(float2 value) {
  return {
    {      1,       0, 0},
    {      0,       1, 0},
    {value.x, value.y, 1},
  };
}

matrix_float4x4 rotationZ(float angle) {
  return {
    { cos(angle), sin(angle), 0, 0},
    {-sin(angle), cos(angle), 0, 0},
    { 0,          0,          1, 0},
    { 0,          0,          0, 1},
  };
}

float4x4 scale(float3 value) {
  return {
    {value.x,       0,       0, 0},
    {      0, value.y,       0, 0},
    {      0,       0, value.z, 0},
    {      0,       0,       0, 1},
  };
}

float3x3 scale2D(float2 value) {
  return {
    {value.x,       0, 0},
    {      0, value.y, 0},
    {      0,       0, 1},
  };
}

float remap(float value, float2 inMinMax, float2 outMinMax)
{
  return outMinMax.x +
  (value - inMinMax.x) *
  (outMinMax.y - outMinMax.x) /
  (inMinMax.y - inMinMax.x);
}

float dot2(float2 v) { return dot(v,v); }

float cross2d(float2 v0, float2 v1) {
  return v0.x*v1.y - v0.y*v1.x;
}
