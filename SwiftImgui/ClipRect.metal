//
//  ClipRect.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.01.2023.
//

#include <metal_stdlib>
using namespace metal;
#import "math.h"
#import "SDFRoundBox.h"

struct VertexIn {
  float4 position [[attribute(0)]];
  float2 uv [[attribute(1)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 borderRadius [[flat]];
  float2 size [[flat]];
  float2 uv;
  float crispness [[flat]];
  uint16_t id;
};

struct Rect {
  float2 position;
  float2 size;
};

struct ClipRect {
  Rect rect;
  float4 borderRadius;
  float depth;
  float crispness;
  uint16_t id;
};

struct FragmentOut {
  uint16_t clipId [[color(0)]];
  float opacity [[color(1)]];
};

struct RectVertexData {
  float4x4 viewMatrix;
  float4x4 projectionMatrix;
};

vertex VertexOut vertex_clip_rect(
                                  const VertexIn in [[stage_in]],
                                  constant RectVertexData &vertexData [[buffer(10)]],
                                  constant ClipRect* rects [[buffer(11)]],
                                  uint instance [[instance_id]]
                                  )
{
  ClipRect props = rects[instance];
  Rect rect = props.rect;
  float crispness = props.crispness;
  
  float2 aspect = rect.size / min(rect.size.x, rect.size.y);
  
  float2 uv = in.uv * 2 - 1;
  uv *= aspect;
  uv *= float2((1 + crispness / aspect.x), (1 + crispness / aspect.y));
  
  matrix_float4x4 model = translation(float3(rect.position, props.depth)) * scale(float3(rect.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .borderRadius = props.borderRadius,
    .size = props.rect.size,
    .uv = uv,
    .crispness = crispness,
    .id = props.id,
  };
}

fragment FragmentOut fragment_clip_rect(VertexOut in [[stage_in]])
{
  float2 aspect = in.size / min(in.size.x, in.size.y);
  float2 size = float2(1) * aspect;
  
  float distance = sdRoundBox(in.uv, size, in.borderRadius);
  float opacity = mix(0, 1, 1 - smoothstep(0, in.crispness, distance));
  
  return {
    .clipId = in.id,
    .opacity = opacity,
  };
}
