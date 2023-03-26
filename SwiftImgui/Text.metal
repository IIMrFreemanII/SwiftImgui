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
#import "SDFRoundBox.h"

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
  float4 color;
  float2 uv;
  float crispness [[flat]];
  float contentScale [[flat]];
  uint16_t clipRectIndex [[flat]];
  uint argsIndex [[flat]];
};

struct GlyphStyle {
  uchar4 color;
  uchar crispness;
  float depth;
  uint16_t clipRectIndex;
};

struct Glyph {
  float2 position;
  float2 size;
  float2 topLeftUv;
  float2 bottomRightUv;
  uint styleIndex;
  uint argsIndex;
};

struct GlyphArgs {
  float2 topLeftUv [[id(0)]];
  float2 bottomRightUv [[id(1)]];
  texture2d<float> glyphSDF [[id(2)]];
};

vertex VertexOut vertex_text(
                                const VertexIn in [[stage_in]],
                                constant GlyphArgs *glyphArgs [[buffer(9)]],
                                constant RectVertexData &vertexData [[buffer(10)]],
                                const constant Glyph* glyphs [[buffer(11)]],
                                const constant GlyphStyle* glyphsStyle [[buffer(12)]],
                                uint instance [[instance_id]]
                                )
{
  Glyph glyph = glyphs[instance];
  GlyphArgs args = glyphArgs[glyph.argsIndex];
  
  glyph.topLeftUv = args.topLeftUv;
  glyph.bottomRightUv = args.bottomRightUv;
  
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
    .contentScale = vertexData.contentScale,
    .clipRectIndex = style.clipRectIndex,
    .argsIndex = glyph.argsIndex,
  };
}

struct ClipRect {
  Rect rect;
  float4 borderRadius;
  uint16_t parentIndex;
};

fragment float4 fragment_text(
                                 VertexOut in [[stage_in]],
                                 sampler sampler [[sampler(0)]],
                                 constant GlyphArgs *glyphArgs [[buffer(9)]],
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
  
  float4 bgColor = float4(1.0, 1.0, 1.0, 0.0);
  float4 textColor = in.color;
  
  float4 color = bgColor;
  
  texture2d<float> texture = glyphArgs[in.argsIndex].glyphSDF;
  float sampleDistance = texture.sample(sampler, in.uv).r;
  color = mix(color, textColor, smoothstep(0, in.crispness, sampleDistance));
  
  return color;
}
