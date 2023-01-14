//
//  math.h
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.12.2022.
//

#ifndef math_h
#define math_h

#import <simd/simd.h>

matrix_float4x4 translation(vector_float3 value);
matrix_float3x3 translation2D(vector_float2 value);
matrix_float4x4 scale(vector_float3 value);
matrix_float3x3 scale2D(vector_float2 value);
matrix_float4x4 rotationZ(float angle);
float remap(float value, vector_float2 inMinMax, vector_float2 outMinMax);
float dot2(vector_float2 v);
float cross2d(vector_float2 v0, vector_float2 v1);

#endif /* math_h */
