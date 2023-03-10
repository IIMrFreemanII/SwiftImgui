//
//  math.h
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.12.2022.
//

#ifndef math_h
#define math_h

#import <simd/simd.h>

constant const float π =  3.141592;

matrix_float4x4 translation(simd_float3 value);
matrix_float3x3 translation2D(simd_float2 value);
matrix_float4x4 scale(simd_float3 value);
matrix_float3x3 scale2D(simd_float2 value);
matrix_float4x4 rotationZ(float angle);
matrix_float4x4 rotationZ(simd_float2 dir);
float remap(float value, simd_float2 inMinMax, simd_float2 outMinMax);
float dot2(simd_float2 v);
float cross2d(simd_float2 v0, simd_float2 v1);
float radiansFrom(float degrees);
float degreesFrom(float radians);

#endif /* math_h */
