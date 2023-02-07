//
//  Copy.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 06.02.2023.
//

#include <metal_stdlib>
using namespace metal;

#import "math.h"
#import "RectVertexData.h"

struct Rect {
  float2 position;
  float2 size;
};

struct VertexIn {
  float4 position [[attribute(0)]];
};

struct VertexOut {
  float4 position [[position]];
  float2 resolution [[flat]];
};

vertex VertexOut vertex_copy(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             constant Rect* rects [[buffer(11)]],
                             uint instance [[instance_id]]
                             )
{
  Rect rect = rects[instance];
  
  matrix_float4x4 model = translation(float3(rect.position, 0)) * scale(float3(rect.size, 1));
  float4 position = vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .resolution = vertexData.resolution,
  };
}

fragment float4 fragment_copy(
                              VertexOut in [[stage_in]],
                              texture2d<float, access::sample> source [[texture(0)]]
                              )
{
  constexpr sampler textureSampler(filter::linear, address::repeat, mip_filter::linear);
  float2 uv = in.position.xy / in.resolution;
  return source.sample(textureSampler, uv);
}
