//
//  SDFRoundBox.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 05.02.2023.
//

#include <metal_stdlib>
using namespace metal;

// b.x = width
// b.y = height
// r.x = roundness top-right
// r.y = roundness boottom-right
// r.z = roundness top-left
// r.w = roundness bottom-left
float sdRoundBox(float2 p, float2 b, float4 r)
{
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  r.x  = (p.y > 0.0) ? r.x : r.y;
  
  float2 q = abs(p) - b + r.x;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}
