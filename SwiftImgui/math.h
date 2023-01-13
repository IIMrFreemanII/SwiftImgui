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

#endif /* math_h */
