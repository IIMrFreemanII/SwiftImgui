//
//  Shaders.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

using namespace metal;

#include <metal_stdlib>
#import "math.h"
#import "SDFRoundBox.h"
#import "RectVertexData.h"

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
  float crispness [[flat]];
  float contentScale [[flat]];
  uint16_t clipRectIndex [[flat]];
};

struct RectProps {
  Rect rect;
  uchar4 borderRadius;
  uchar4 color;
  float depth;
  uchar crispness;
  uint16_t clipRectIndex;
};

vertex VertexOut vertex_rect(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             const constant RectProps* rects [[buffer(11)]],
                             uint instance [[instance_id]]
                              )
{
  RectProps props = rects[instance];
  float crispness = float(props.crispness) / 255.0;
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
    .borderRadius = float4(props.borderRadius) / 100.0,
    .color = float4(props.color) / 255.0,
    .contentScale = vertexData.contentScale,
    .clipRectIndex = props.clipRectIndex,
    .crispness = crispness,
  };
}

struct ClipRect {
  Rect rect;
  float4 borderRadius;
  uint16_t parentIndex;
};

fragment float4 fragment_rect(
                              VertexOut in [[stage_in]],
                              constant ClipRect* rects [[buffer(11)]]
                              )
{
  // handle nested clipping
  float2 fragCoord = in.position.xy;
  float clipDist = -1;
  int16_t index = in.clipRectIndex;
  
  do {
    ClipRect clipRect = rects[index];
    index = clipRect.parentIndex;
    Rect parentRect = clipRect.rect;
    float2 clipPosition = parentRect.position * in.contentScale;
    float2 clipSize = parentRect.size * in.contentScale * 0.5;
    clipPosition += clipSize;
    
    clipDist = max(clipDist, sdRoundBox(fragCoord - clipPosition, clipSize, clipRect.borderRadius * min(clipSize.x, clipSize.y)));
  } while (index != 0);
  
  if (clipDist >= 0) {
    discard_fragment();
    
    return 0;
  }
  //
  
  float2 aspect = in.size / min(in.size.x, in.size.y);
  float2 size = float2(1) * aspect;
  
  float distance = sdRoundBox(in.uv, size, in.borderRadius);
  float4 bgColor = float4(0.0, 0.0, 0.0, 0.0);
  float4 rectColor = in.color;
  
  float4 color = bgColor;
  color = mix(color, rectColor, 1.0 - smoothstep(-in.crispness, in.crispness, distance));
  return color;
}
