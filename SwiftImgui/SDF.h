//
//  SDF.h
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 09.01.2023.
//

#ifndef SDF_h
#define SDF_h

#import <simd/simd.h>

float lineSegment2DSDF(vector_float2 p, vector_float2 a, vector_float2 b);
float lineSegmentOfPolygon(vector_float2 p, vector_float2 a, vector_float2 b, thread float &winding);

#endif /* SDF_h */
