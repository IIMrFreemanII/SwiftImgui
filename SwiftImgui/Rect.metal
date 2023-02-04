//
//  Shaders.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

using namespace metal;

#include <metal_stdlib>
#import "math.h"

struct Rect {
  float2 position;
  float2 size;
};

struct VertexIn {
  float4 position [[attribute(0)]];
  float2 uv [[attribute(1)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 borderRadius [[flat]];
  float4 color;
  float2 size [[flat]];
  float2 uv;
  uint clipId [[flat]];
  float crispness [[flat]];
};

struct RectProps {
  Rect rect;
  float4 borderRadius;
  float4 color;
  float4 borderColor;
  float depth;
  uint clipId;
  float crispness;
  float borderSize;
};

struct RectVertexData {
  float4x4 viewMatrix;
  float4x4 projectionMatrix;
  float time;
};

vertex VertexOut vertex_rect(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             const device RectProps* rects [[buffer(11)]],
                             uint instance [[instance_id]]
                              )
{
  RectProps props = rects[instance];
  float crispness = props.crispness;
  Rect rect = props.rect;
  float2 aspect = rect.size / min(rect.size.x, rect.size.y);
  
  float2 uv = in.uv * 2 - 1;
  uv *= aspect;
  uv *= (1 + crispness);
  
  float2 currentSize = rect.size;
  float2 newSize = currentSize * (1 + crispness);
  float2 deltaSize = (newSize - currentSize) * 0.5;
  rect.position -= deltaSize;
  rect.size += deltaSize * 2;
  
  matrix_float4x4 model = translation(float3(rect.position, props.depth)) * scale(float3(rect.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .uv = uv,
    .size = rect.size,
    .borderRadius = props.borderRadius,
    .color = props.color,
    .clipId = props.clipId,
    .crispness = crispness,
  };
}

// b.x = width
// b.y = height
// r.x = roundness top-right
// r.y = roundness boottom-right
// r.z = roundness top-left
// r.w = roundness bottom-left
float sdRoundBox( float2 p, float2 b, float4 r )
{
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  r.x  = (p.y > 0.0) ? r.x : r.y;
  
  float2 q = abs(p) - b + r.x;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

fragment float4 fragment_rect(
                              VertexOut in [[stage_in]],
                              texture2d<uint> clipTexture [[texture(0)]]
                              )
{
  uint2 fragPosition = uint2(in.position.xy);
  uint id = clipTexture.read(fragPosition).r;
  
  if (id != in.clipId) {
    discard_fragment();
    return 0;
  }
  
  float2 aspect = in.size / min(in.size.x, in.size.y);
  float2 size = float2(1) * aspect;
  
  float distance = sdRoundBox(in.uv, size, in.borderRadius);
  float4 bgColor = float4(0.0, 0.0, 0.0, 0.0);
  float4 rectColor = in.color;
  
  float4 color = bgColor;
  color = mix(color, rectColor, 1.0 - smoothstep(-in.crispness, in.crispness, distance));
  return color;
}
