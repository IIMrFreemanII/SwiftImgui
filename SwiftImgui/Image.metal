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
  uint clipId;
};

struct FragmentIn {
  float4 position [[position]];
  float2 uv;
  int textureSlot [[flat]];
  uint clipId [[flat]];
};

struct Rect {
  float2 position;
  float2 size;
};

struct Image {
  Rect rect;
  float depth;
  int textureSlot;
  uint clipId;
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
  matrix_float4x4 model = translation(float3(image.rect.position, image.depth)) * scale(float3(image.rect.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .uv = in.uv,
    .textureSlot = image.textureSlot,
    .clipId = image.clipId,
  };
}

fragment float4 fragment_image(
                               FragmentIn in [[stage_in]],
                               texture2d<uint> clipTexture [[texture(31)]],
                               array<texture2d<float, access::sample>, 30> textures
                               )
{
  uint2 fragPosition = uint2(in.position.xy);
  uint id = clipTexture.read(fragPosition).r;
  
  if (id != in.clipId) {
    discard_fragment();
    return 0;
  }
  
  constexpr sampler textureSampler(
                                   filter::linear,
                                   address::repeat,
                                   mip_filter::linear
                                   );
  
  float4 color = textures[in.textureSlot].sample(textureSampler, in.uv);
  return color;
}


