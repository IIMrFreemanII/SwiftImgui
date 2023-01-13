//
//  SDF.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 09.01.2023.
//

#include <metal_stdlib>
using namespace metal;
#include "SDF.h"

// p = point to check if belongs to line segment between a and b
// a = point of the line segment
// b = point of the line segment
// returns distance to the line segment between points a and b
float lineSegment2DSDF(float2 p, float2 a, float2 b) {
  float2 ba = b - a;
  float2 pa = p - a;
  float k = saturate(dot(pa, ba) / dot(ba, ba));
  
  return length(pa - ba * k);
}

// returns squared distance
float lineSegmentOfPolygon(float2 p, float2 a, float2 b, thread float &winding) {
   float2 e = b - a;
   float2 w = p - a;
   float2 d = w - e * saturate(dot(w,e)/dot(e,e));
   float value = dot(d,d);
   
    // winding number from http://geomalgorithms.com/a03-_inclusion.html
    bool3 cond = bool3( p.y>=a.y,
                        p.y <b.y,
                        e.x*w.y>e.y*w.x );
    if( all(cond) || all(not(cond)) ) winding = -winding;
   
   return value;
}
