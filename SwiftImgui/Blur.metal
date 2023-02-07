//
//  Blur.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 05.02.2023.
//

#include <metal_stdlib>
using namespace metal;

#import "math.h"
#import "RectVertexData.h"

struct Rect {
  float2 position;
  float2 size;
};

struct BlurRect {
  Rect rect;
//  float4 borderRadius;
  float blurSize;
  float depth;
//  uint16_t clipId;
//  float crispness;
//  float borderSize;
};

struct VertexIn {
  float4 position [[attribute(0)]];
};

struct VertexOut {
  float4 position [[position]];
  float2 resolution [[flat]];
  float blurSize [[flat]];
//  uint16_t clipId [[flat]];
//  float crispness [[flat]];
};

vertex VertexOut vertex_blur(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             constant BlurRect* rects [[buffer(11)]],
                             uint instance [[instance_id]]
                             )
{
  BlurRect blurRect = rects[instance];
  Rect rect = blurRect.rect;
  
  matrix_float4x4 model = translation(float3(rect.position, blurRect.depth)) * scale(float3(rect.size, 1));
  float4 position = vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .resolution = vertexData.resolution,
    .blurSize = blurRect.blurSize,
  };
}

fragment float4 fragment_blur(
                              VertexOut in [[stage_in]],
                              texture2d<float, access::sample> texture [[texture(0)]]
                              )
{
//  float pi = 6.28318530718; // Pi*2
//
//  // GAUSSIAN BLUR SETTINGS {{{
//  float directions = 6.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
//  float quality = 6.0; // BLUR QUALITY (Default 4.0 - More is better but slower)
//  float size = in.blurSize; // BLUR SIZE (Radius)
//  // GAUSSIAN BLUR SETTINGS }}}
//
//  float2 radius = size / in.resolution;
//
//  // Normalized pixel coordinates (from 0 to 1)
  float2 uv = in.position.xy / in.resolution;
//
  constexpr sampler textureSampler(filter::linear, address::repeat, mip_filter::linear);
//
//  float4 color = texture.sample(textureSampler, uv);
//
//  // Blur calculations
//  for(float d = 0.0; d < pi; d += pi / directions)
//  {
//    for(float i = 1.0 / quality; i <= 1.0; i += 1.0 / quality)
//    {
//      // use dot and cross2d instead of cos and sin if dir vector is normalized
//      color += texture.sample(textureSampler, uv + (float2(cos(d),sin(d)) * radius * i));
//    }
//  }
//
//  color /= quality * directions;
  
  float offset = 1.0 / 300.0;
  float2 offsets[9] = {
   float2(-offset,  offset), // top-left
   float2( 0.0f,    offset), // top-center
   float2( offset,  offset), // top-right
   float2(-offset,  0.0f),   // center-left
   float2( 0.0f,    0.0f),   // center-center
   float2( offset,  0.0f),   // center-right
   float2(-offset, -offset), // bottom-left
   float2( 0.0f,   -offset), // bottom-center
   float2( offset, -offset)  // bottom-right
  };
  
  // sharpenKernel
//  float tempKernel[9] = {
//    -1, -1, -1,
//    -1,  9, -1,
//    -1, -1, -1
//  };
  
  float tempKernel[9] = {
    1.0 / 16, 2.0 / 16, 1.0 / 16,
    2.0 / 16, 4.0 / 16, 2.0 / 16,
    1.0 / 16, 2.0 / 16, 1.0 / 16
  };
  
  float4 sampleTex[9];
  for(int i = 0; i < 9; i++)
  {
    sampleTex[i] = texture.sample(textureSampler, uv + offsets[i]);
  }
  
  float4 color = float4();
  for(int i = 0; i < 9; i++)
  {
    color += sampleTex[i] * tempKernel[i];
  }
  
  return color;
}
