//
//  RectVertexData.h
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 05.02.2023.
//

#ifndef RectVertexData_h
#define RectVertexData_h

#import <simd/simd.h>

typedef struct {
  matrix_float4x4 viewMatrix;
  matrix_float4x4 projectionMatrix;
  simd_float2 resolution;
  float contentScale;
  float time;
} RectVertexData;


#endif /* RectVertexData_h */
