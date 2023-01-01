//
//  Shaders.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

using namespace metal;

#include <metal_stdlib>
#import "math.h"

struct VertexIn {
  float4 position [[attribute(0)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 color;
};

struct FragmentIn {
  float4 color;
};

struct Rect {
  float3 position;
  float2 size;
  float4 color;
};

struct RectVertexData {
  float4x4 viewMatrix;
  float4x4 projectionMatrix;
};

vertex VertexOut vertex_rect(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             const device Rect* rects [[buffer(11)]],
                             uint instance [[instance_id]]
                             )
{
  Rect rect = rects[instance];
  matrix_float4x4 model = translation(rect.position) * scale(float3(rect.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .color = rect.color
  };
}

fragment float4 fragment_rect(FragmentIn in [[stage_in]]) {
  return in.color;
}
