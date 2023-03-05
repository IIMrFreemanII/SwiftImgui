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
#import "RectVertexData.h"

struct VertexIn {
  float4 position [[attribute(0)]];
  float2 uv [[attribute(1)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 borderRadius [[flat]];
  float2 resolution [[flat]];
  float2 uv;
  float2 aspect [[flat]];
  float contentScale [[flat]];
  float crispness [[flat]];
  uint16_t parentIndex [[flat]];
  uint16_t id [[flat]];
};

struct Rect {
  float2 position;
  float2 size;
};

struct ClipRect {
  Rect rect;
  float4 borderRadius;
  float crispness;
  uint16_t id;
  uint16_t parentIndex;
};

struct FragmentOut {
  uint16_t clipId [[color(0)]];
  float opacity [[color(1)]];
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
  
  matrix_float4x4 model = translation(float3(rect.position, 0)) * scale(float3(rect.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .borderRadius = props.borderRadius,
    .resolution = vertexData.resolution,
    .uv = uv,
    .aspect = aspect,
    .contentScale = vertexData.contentScale,
    .crispness = crispness,
    .id = props.id,
    .parentIndex = props.parentIndex,
  };
}

fragment FragmentOut fragment_clip_rect(VertexOut in [[stage_in]], constant ClipRect* rects [[buffer(11)]])
{
  Rect parentRect = rects[in.parentIndex].rect;
  float2 clipPosition = parentRect.position * in.contentScale;
  float2 clipSize = parentRect.size * in.contentScale * 0.5;
  clipPosition += clipSize;
  
  float2 fragCoord = in.position.xy;
  
  float clipDist = sdRoundBox(fragCoord - clipPosition, clipSize, float4());
  if (clipDist >= 0) {
    discard_fragment();

    return {
      .clipId = in.id,
      .opacity = 0,
    };
  }
  
  float2 size = float2(1) * in.aspect;
  
  float distance = sdRoundBox(in.uv, size, in.borderRadius);
  float opacity = mix(0, 1, 1 - smoothstep(0, in.crispness, distance));
  
  if (opacity <= 0) {
    discard_fragment();
  }
  
  return {
    .clipId = in.id,
    .opacity = opacity,
  };
}
