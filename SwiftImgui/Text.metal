//
//  Text.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 03.01.2023.
//

#include <metal_stdlib>
using namespace metal;
#import "math.h"
#import "RectVertexData.h"

struct VertexIn {
  float4 position [[attribute(0)]];
  float2 uv [[attribute(1)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 color;
  float2 uv;
  float crispness;
  uint16_t clipId;
};

struct FragmentIn {
  float4 position [[position]];
  float4 color [[flat]];
  float2 uv;
  float crispness [[flat]];
  uint16_t clipId [[flat]];
};

struct GlyphStyle {
  uchar4 color;
  uchar crispness;
  float depth;
  uint16_t clipId;
};

struct Glyph {
  float2 position;
  float2 size;
  float2 topLeftUv;
  float2 bottomRightUv;
  uint styleIndex;
};

vertex VertexOut vertex_text(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             const constant Glyph* glyphs [[buffer(11)]],
                             const constant GlyphStyle* glyphsStyle [[buffer(12)]],
                             uint instance [[instance_id]]
                             )
{
  Glyph glyph = glyphs[instance];
  GlyphStyle style = glyphsStyle[glyph.styleIndex];
  float crispness = float(style.crispness) / 255.0;
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
  glyph.position -= deltaSize;
  glyph.size += deltaSize * 2;
  
  matrix_float4x4 model = translation(float3(glyph.position, style.depth)) * scale(float3(glyph.size, 1));
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
    .color = float4(style.color) / 255.0,
    .uv = uv,
    .crispness = crispness,
    .clipId = style.clipId,
  };
}

fragment float4 fragment_text(
                              FragmentIn in [[stage_in]],
                              sampler sampler [[sampler(0)]],
                              texture2d<float, access::sample> texture [[texture(0)]],
                              texture2d<uint16_t> clipTexture [[texture(1)]],
                              texture2d<float> opacityTexture [[texture(2)]]
                              )
{
  uint2 fragPosition = uint2(in.position.xy);
  uint16_t id = clipTexture.read(fragPosition).r;
  
  if (!(in.clipId <= id)) {
    discard_fragment();
    return 0;
  }
  
  float opacity = opacityTexture.read(fragPosition).r;
  
  float4 bgColor = float4(1.0, 1.0, 1.0, 0.0);
  float4 textColor = in.color;
  
  float4 color = bgColor;
  
  float sampleDistance = texture.sample(sampler, in.uv).r;
  color = mix(color, textColor, 1.0 - smoothstep(0, in.crispness, sampleDistance));
  
  return color * opacity;
}
