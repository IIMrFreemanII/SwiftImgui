//
//  Image.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 31.12.2022.
//

using namespace metal;

#include <metal_stdlib>
#import "math.h"
#import "RectVertexData.h"
#import "SDFRoundBox.h"

struct VertexIn {
  float4 position [[attribute(0)]];
  float2 uv [[attribute(1)]];
};

struct VertexOut {
  float4 position [[position]];
  float2 uv;
  int textureSlot [[flat]];
  float contentScale [[flat]];
  uint16_t clipRectIndex [[flat]];
};

struct Rect {
  float2 position;
  float2 size;
};

struct Image {
  Rect rect;
  float depth;
  int textureSlot;
  uint16_t clipRectIndex;
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
    .contentScale = vertexData.contentScale,
    .clipRectIndex = image.clipRectIndex,
  };
}

struct ClipRect {
  Rect rect;
  float4 borderRadius;
  uint16_t parentIndex;
};

fragment float4 fragment_image(
                               VertexOut in [[stage_in]],
                               array<texture2d<float, access::sample>, 31> textures,
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
    
    clipDist = max(
                   clipDist,
                   sdRoundBox(fragCoord - clipPosition, clipSize, clipRect.borderRadius * min(clipSize.x, clipSize.y))
                   );
  } while (index != 0);
  
  if (clipDist >= 0) {
    discard_fragment();
    
    return 0;
  }
  //
  
  constexpr sampler textureSampler(
                                   filter::linear,
                                   address::repeat,
                                   mip_filter::linear
                                   );
  
  float4 color = textures[in.textureSlot].sample(textureSampler, in.uv);
  return color;
}
