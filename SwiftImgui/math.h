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
matrix_float4x4 scale(vector_float3 value);
matrix_float2x2 scale(vector_float2 value);
matrix_float4x4 rotationZ(float angle);

#endif /* math_h */
