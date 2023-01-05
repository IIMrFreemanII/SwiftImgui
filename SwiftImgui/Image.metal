//
//  Image.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 31.12.2022.
//

using namespace metal;

#include <metal_stdlib>
#import "math.h"

struct VertexIn {
  float4 position [[attribute(0)]];
  float2 uv [[attribute(1)]];
};

struct VertexOut {
  float4 position [[position]];
  float2 uv;
  int textureSlot;
};

struct FragmentIn {
  float2 uv;
  int textureSlot [[flat]];
};

struct Image {
  float3 position;
  float2 size;
  int textureSlot;
};

struct RectVertexData {
  float4x4 viewMatrix;
  float4x4 projectionMatrix;
};

vertex VertexOut vertex_image(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             const device Image* images [[buffer(11)]],
                             uint instance [[instance_id]]
                             )
{
  Image image = images[instance];
  matrix_float4x4 model = translation(image.position) * scale(float3(image.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .uv = in.uv,
    .textureSlot = image.textureSlot
  };
}

fragment float4 fragment_image(
                              FragmentIn in [[stage_in]],
                              array<texture2d<float, access::sample>, 31> textures
                              )
{
  constexpr sampler textureSampler(
                                   filter::linear,
                                   address::repeat,
                                   mip_filter::linear
                                   );
  
  float4 color = textures[in.textureSlot].sample(textureSampler, in.uv);
  return color;
}


