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

// signed distance to a 2D triangle
float sdTriangle( float2 p, float2 p0, float2 p1, float2 p2 )
{
  float2 e0 = p1 - p0;
  float2 e1 = p2 - p1;
  float2 e2 = p0 - p2;
  
  float2 v0 = p - p0;
  float2 v1 = p - p1;
  float2 v2 = p - p2;
  
  float2 pq0 = v0 - e0*saturate( dot(v0,e0)/dot(e0,e0));
  float2 pq1 = v1 - e1*saturate( dot(v1,e1)/dot(e1,e1));
  float2 pq2 = v2 - e2*saturate( dot(v2,e2)/dot(e2,e2));
  
  float s = e0.x*e2.y - e0.y*e2.x;
  float2 d = min( min( float2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                     float2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                float2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));
  
  return -sqrt(d.x)*sign(d.y);
}
