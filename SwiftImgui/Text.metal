//
//  Text.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 03.01.2023.
//

#include <metal_stdlib>
using namespace metal;
#import "math.h"

struct VertexIn {
  float4 position [[attribute(0)]];
  float2 uv [[attribute(1)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 color;
  float2 uv;
  float crispness;
  uint clipId;
};

struct FragmentIn {
  float4 position [[position]];
  float4 color [[flat]];
  float2 uv;
  float crispness [[flat]];
  uint clipId [[flat]];
};

struct Glyph {
  float4 color;
  float3 position;
  float2 size;
  float2 topLeftUv;
  float2 bottomRightUv;
  float crispness;
  uint clipId;
};

struct RectVertexData {
  float4x4 viewMatrix;
  float4x4 projectionMatrix;
  float time;
};

vertex VertexOut vertex_text(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             const constant Glyph* glyphs [[buffer(11)]],
                             uint instance [[instance_id]]
                             )
{
  Glyph glyph = glyphs[instance];
  float crispness = glyph.crispness;
  float scalar = 5;
  
  float2 currentSize = float2(glyph.bottomRightUv.x - glyph.topLeftUv.x, glyph.topLeftUv.y - glyph.bottomRightUv.y);
  float2 newSize = currentSize * (1 + crispness);
  float2 deltaSize = (newSize - currentSize) * 0.5 * scalar;
  glyph.topLeftUv.x -= deltaSize.x;
  glyph.topLeftUv.y += deltaSize.y;
  glyph.bottomRightUv.x += deltaSize.x;
  glyph.bottomRightUv.y -= deltaSize.y;
  
  currentSize = glyph.size;
  newSize = float2(currentSize * (1 + crispness));
  deltaSize = (newSize - currentSize) * 0.5 * scalar;
  glyph.position -= float3(deltaSize, 0);
  glyph.size += deltaSize * 2;
  
  matrix_float4x4 model = translation(glyph.position) * scale(float3(glyph.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  float2 uv = in.uv;
  if (in.uv.x == 0 && in.uv.y == 1) {
    uv = glyph.topLeftUv;
  } else if (in.uv.x == 1 && in.uv.y == 1) {
    uv = float2(glyph.bottomRightUv.x, glyph.topLeftUv.y);
  } else if (in.uv.x == 0 && in.uv.y == 0) {
    uv = float2(glyph.topLeftUv.x, glyph.bottomRightUv.y);
  } else if (in.uv.x == 1 && in.uv.y == 0) {
    uv = glyph.bottomRightUv;
  }
  
  return {
    .position = position,
    .color = glyph.color,
    .uv = uv,
    .crispness = crispness,
    .clipId = glyph.clipId,
  };
}

fragment float4 fragment_text(
                              FragmentIn in [[stage_in]],
                              sampler sampler [[sampler(0)]],
                              texture2d<float, access::sample> texture [[texture(0)]],
                              texture2d<uint> clipTexture [[texture(1)]]
                              )
{
  uint2 fragPosition = uint2(in.position.xy);
  uint id = clipTexture.read(fragPosition).r;
  
  if (id != in.clipId) {
    discard_fragment();
    return 0;
  }
  
  float4 bgColor = float4(1.0, 1.0, 1.0, 0.0);
  float4 textColor = in.color;
  
  float4 color = bgColor;
  
  float sampleDistance = texture.sample(sampler, in.uv).r;
  color = mix(color, textColor, 1.0 - smoothstep(0, in.crispness, sampleDistance));
  
  return color;
}
