//
//  ClipRect.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.01.2023.
//

#include <metal_stdlib>
using namespace metal;
#import "math.h"

struct VertexIn {
  float4 position [[attribute(0)]];
};

struct VertexOut {
  float4 position [[position]];
  uint id;
};

struct Rect {
  float2 position;
  float2 size;
};

struct ClipRect {
  Rect rect;
  float depth;
  uint id;
};

struct FragmentIn {
  uint id [[flat]];
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
  matrix_float4x4 model = translation(float3(props.rect.position, props.depth)) * scale(float3(props.rect.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .id = props.id,
  };
}

fragment uint fragment_clip_rect(FragmentIn in [[stage_in]])
{
  return in.id;
}
