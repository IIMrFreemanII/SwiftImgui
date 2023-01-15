//
//  VectorText.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 09.01.2023.
//

#include <metal_stdlib>
using namespace metal;
#import "math.h"
#import "BezierCurves.h"

struct VertexIn {
  float4 position [[attribute(0)]];
  float2 uv [[attribute(1)]];
};

struct VertexOut {
  float4 position [[position]];
  float2 uv;
  // start of the SubPath range
  uint32_t start;
  // end of the SubPath range
  uint32_t end;
  float crispness;
};

struct FragmentIn {
  float2 uv;
  // start of the SubPath range
  uint32_t start [[flat]];
  // end of the SubPath range
  uint32_t end [[flat]];
  float crispness [[flat]];
};

struct Glyph {
  float3 position;
  float2 size;
  float2 topLeftUv;
  float2 bottomRightUv;
  uint fontSize;
  uint start;
  uint end;
};

struct RectVertexData {
  float4x4 viewMatrix;
  float4x4 projectionMatrix;
  float time;
};

constant float crispness = 0.01;

vertex VertexOut vertex_vector_text(
                                    const VertexIn in [[stage_in]],
                                    constant RectVertexData &vertexData [[buffer(10)]],
                                    const constant Glyph* glyphs [[buffer(11)]],
                                    uint instance [[instance_id]]
                                    )
{
//  float crispness = remap(sin(vertexData.time), float2(-1, 1), float2(0, 1));
  float scalar = 15;
  
  Glyph glyph = glyphs[instance];
  
  float2 currentSize = float2(glyph.bottomRightUv.x - glyph.topLeftUv.x, glyph.topLeftUv.y - glyph.bottomRightUv.y);
  float2 newSize = float2(currentSize * (1 + crispness));
  float2 deltaSize = (newSize - currentSize) * 0.5 * scalar;
  glyph.topLeftUv.x -= deltaSize.x;
  glyph.topLeftUv.y += deltaSize.y;
  glyph.bottomRightUv.x += deltaSize.x;
  glyph.bottomRightUv.y -= deltaSize.y;
  
  currentSize = glyph.size;
  newSize = float2(currentSize * (1 + crispness));
  deltaSize = (newSize - currentSize) * 0.5 * scalar;
  glyph.position -= float3(deltaSize, 0);
  glyph.size += deltaSize * 2;
  
  matrix_float4x4 model = translation(glyph.position) * scale(float3(glyph.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  float2 uv = in.uv;
  if (in.uv.x == 0 && in.uv.y == 1) {
    uv = glyph.topLeftUv;
  }
  else if (in.uv.x == 1 && in.uv.y == 1) {
    uv = float2(glyph.bottomRightUv.x, glyph.topLeftUv.y);
  }
  else if (in.uv.x == 0 && in.uv.y == 0) {
    uv = float2(glyph.topLeftUv.x, glyph.bottomRightUv.y);
  }
  else if (in.uv.x == 1 && in.uv.y == 0) {
    uv = glyph.bottomRightUv;
  }
  
  return {
    .position = position,
    .uv = uv,
    .start = glyph.start,
    .end = glyph.end,
    .crispness = crispness,
  };
}

// ----------------------------------------------------------------------------------

const constant int NUM_LEGS = 1;
// type
// 0 - moveToPoint, starts new path
// 1 - addLineToPoint, adds line from current point to a new point. Element holds 1 point for destination
// 2 - addQuadCurveToPoint, adds a quadratice curve from current point to the specified point.
//     Element holds control point (point0) and a destination point (point1).
// 3 - addCurveToPoint, adds a quadratic curve from current point to the specified point.
//     Element holds 2 control points (point0, point1) and a destination point (point3).
// 4 - closePath, path element that closes and completes a subpath. The element does not contain any points.
struct PathElement {
  float2 point0 = float2();
  float2 point1 = float2();
//  float2 point2 = float2();
  uint8_t type = 0;
};

struct SubPath {
  uint32_t start = 0;
  uint32_t end = 0;
};

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

// signed distance to a quadratic bezier
float2 sdQuadraticBezier(float2 pos, float2 A, float2 B, float2 C )
{
  float2 a = B - A;
  float2 b = A - 2.0 * B + C;
  float2 c = a * 2.0;
  float2 d = A - pos;
  
  float kk = 1.0 / dot(b,b);
  float kx = kk * dot(a,b);
  float ky = kk * (2.0 * dot(a,a) + dot(d,b)) / 3.0;
  float kz = kk * dot(d,a);
  
  float res = 0.0;
  float sgn = 0.0;
  
  float p  = ky - kx * kx;
  float q  = kx*(2.0 * kx * kx - 3.0 * ky) + kz;
  float p3 = p * p * p;
  float q2 = q * q;
  float h  = q2 + 4.0 * p3;
  
  if( h >= 0.0 )
  {   // 1 root
    h = sqrt(h);
    float2 x = (float2(h,-h)-q)/2.0;
    
    float2 uv = sign(x) * pow(abs(x), float2(1.0/3.0));
    float t = saturate( uv.x+uv.y-kx);
    float2  q = d + (c + b * t) * t;
    res = dot2(q);
    sgn = cross2d(c + 2.0 * b * t, q);
  }
  else
  {   // 3 roots
    float z = sqrt(-p);
    float v = acos(q / (p * z * 2.0)) / 3.0;
    float m = cos(v);
    float n = sin(v) * 1.732050808;
    float3 t = saturate(float3(m + m, -n -m, n -m) * z - kx);
    float2 qx = d + (c + b * t.x) * t.x; float dx = dot2(qx), sx = cross2d(c + 2.0 * b * t.x, qx);
    float2 qy = d + (c + b * t.y) * t.y; float dy = dot2(qy), sy = cross2d(c + 2.0 * b * t.y, qy);
    if(dx<dy) { res=dx; sgn=sx; } else {res=dy; sgn=sy; }
  }
  
  // clamp sgn to start line between A and C
  float2 newA = A - pos;
  float2 newC = C - pos;
  float triangleWinding = cross2d(A - B, B - C);
  float bezierSign = sgn * triangleWinding;
  float newSign = cross2d(newA, newC) * triangleWinding;
  
  return float2(res, sign(max(newSign, bezierSign)));
}

void handleWinding(float2 p, float2 a, float2 b, thread float &winding) {
  float2 e = b - a;
  float2 w = p - a;
  
  bool3 cond = bool3(p.y >= a.y, p.y < b.y, e.x * w.y > e.y * w.x);
  if(all(cond) || all(not(cond))) winding = -winding;
}

// returns squared distance to polygon, also can be negative
float sdPolygon(float2 p, constant PathElement *path, int start, int end) {
  float distSquared = 0;
  float winding = 1.0;
  
  float2 pathStart = float2();
  float2 prevPoint = float2();
  
  for (int i = start; i < end; i++) {
    PathElement pathElem = path[i];
    
    switch(pathElem.type) {
      case 0: {
        pathStart = pathElem.point0;
        prevPoint = pathStart;

        float2 initialDist = p - pathStart;
        distSquared = dot(initialDist, initialDist);
        break;
      }
      case 1: {
        float2 currentPoint = pathElem.point0;

        float result = lineSegmentOfPolygon(p, prevPoint, currentPoint, winding);
        distSquared = min(result, distSquared);

        prevPoint = currentPoint;
        break;
      }
      case 2: {
        float2 currentPoint = pathElem.point1;
        float2 controlPoint = pathElem.point0;

        float2 squaredDistAndSign = sdQuadraticBezier(p, prevPoint, controlPoint, currentPoint);
        distSquared = min(squaredDistAndSign.x, distSquared);
        winding *= squaredDistAndSign.y;
        // to fix winding (crutch)
        handleWinding(p, prevPoint, currentPoint, winding);

        prevPoint = currentPoint;
        break;
      }
//      case 3: {
//        float2 currentPoint = pathElem.point2;
//        float2 controlPoint0 = pathElem.point0;
//        float2 controlPoint1 = pathElem.point1;
//
//        float2 p0 = prevPoint;
//        float2 p1 = float2();
//
//        for (int i = 1; i <= NUM_LEGS; i++) {
//          float t = float(i) / float(NUM_LEGS);
//          p1 = cubicBezier(prevPoint, currentPoint, controlPoint0, controlPoint1, t);
//
//          float result = lineSegmentOfPolygon(p, p0, p1, winding);
//          distSquared = min(result, distSquared);
//
//          p0 = p1;
//        }
//
//        prevPoint = currentPoint;
//        break;
//      }
      case 4: {
        float2 currentPoint = pathStart;

        float result = lineSegmentOfPolygon(p, prevPoint, currentPoint, winding);
        distSquared = min(result, distSquared);

        prevPoint = currentPoint;
        break;
      }
    }
  }
  
  return distSquared * winding;
}

float sdSubPaths(float2 p, constant SubPath *subPaths, int start, int end, constant PathElement *pathElems) {
  SubPath subpath = subPaths[start];
  float d = sdPolygon(p, pathElems, subpath.start, subpath.end);
  
  for (int i = start + 1; i < end; i++) {
    SubPath subpath = subPaths[i];
    float tempDist = sdPolygon(p, pathElems, subpath.start, subpath.end);
    // color is excluded in places where subPaths intersects
    float opSubtraction0 = max(d, -tempDist);
    float opSubtraction1 = max(-d, tempDist);
    d = min(opSubtraction0, opSubtraction1);
  }
  
  return sqrt(abs(d)) * sign(d);
}

// MARK: Required props
// array of paths [PathElement] && array of [SubPath] && startIndex && endIndex
// font color
// background color
// font size
// screen resolution and ratio
// thickness && crispness
fragment float4 fragment_vector_text(
                                     FragmentIn in [[stage_in]],
                                     const constant PathElement* pathElems [[buffer(0)]],
                                     const constant SubPath* subPaths [[buffer(1)]]
                                     )
{
//  float thickness = 0.0;
  float4 bgColor = float4(1.0, 1.0, 1.0, 0.0);
  float4 textColor = float4(0.0, 0.0, 0.0, 1);
  float2 uv = float2(in.uv); // 0.0 - 1.0 bottom-left origin
  
  float distance = sdSubPaths(uv, subPaths, in.start, in.end, pathElems);
  float4 color = bgColor;
  color = mix(color, textColor, 1.0 - smoothstep(0, float(in.crispness), distance));
  
  return color;
}
