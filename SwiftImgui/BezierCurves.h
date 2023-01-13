//
//  BezierCurves.h
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 09.01.2023.
//

#ifndef BezierCurves_h
#define BezierCurves_h

#import <simd/simd.h>

vector_float2 quadraticBezier(vector_float2 a, vector_float2 b, vector_float2 c, float t);
vector_float2 cubicBezier(vector_float2 a, vector_float2 b, vector_float2 c0, vector_float2 c1, float t);

#endif /* BezierCurves_h */
