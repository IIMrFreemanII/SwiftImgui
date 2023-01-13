//
//  BezierCurves.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 09.01.2023.
//

#include <metal_stdlib>
using namespace metal;
#include "BezierCurves.h"

float2 quadraticBezier(float2 a, float2 b, float2 c, float t) {
    return pow(1 - t, 2) * a + (1 - t) * 2 * t * c + t * t * b;
}

float2 cubicBezier(float2 a, float2 b, float2 c0, float2 c1, float t) {
    return pow(1 - t, 3) * a +
          pow(1 - t, 2) * 3 * t * c0 +
          (1 - t) * 3 * t * t * c1 +
          t * t * t * b;
}
