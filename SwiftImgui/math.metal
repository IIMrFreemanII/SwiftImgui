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
