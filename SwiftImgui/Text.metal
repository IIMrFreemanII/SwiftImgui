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
  float2 uv;
};

struct FragmentIn {
  float2 uv;
};

struct Glyph {
  float3 position;
  float2 size;
  float2 topLeftTexCoord;
  float2 bottomRightTexCoord;
};

struct RectVertexData {
  float4x4 viewMatrix;
  float4x4 projectionMatrix;
};

vertex VertexOut vertex_text(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             const constant Glyph* glyphs [[buffer(11)]],
                             uint instance [[instance_id]]
                             )
{
  Glyph glyph = glyphs[instance];
  matrix_float4x4 model = translation(glyph.position) * scale(float3(glyph.size, 1));
  float4 position =
  vertexData.projectionMatrix * vertexData.viewMatrix * model * in.position;
  
  float2 uv = in.uv;
  if (in.uv.x == 0 && in.uv.y == 1) {
    uv = glyph.topLeftTexCoord;
  } else if (in.uv.x == 1 && in.uv.y == 1) {
    uv = float2(glyph.bottomRightTexCoord.x, glyph.topLeftTexCoord.y);
  } else if (in.uv.x == 0 && in.uv.y == 0) {
    uv = float2(glyph.topLeftTexCoord.x, glyph.bottomRightTexCoord.y);
  } else if (in.uv.x == 1 && in.uv.y == 0) {
    uv = glyph.bottomRightTexCoord;
  }
  
  return {
    .position = position,
    .uv = uv,
  };
}

fragment float4 fragment_text(
                              FragmentIn in [[stage_in]],
                              sampler sampler [[sampler(0)]],
                              texture2d<float, access::sample> texture [[texture(0)]]
                              )
{
  float4 color = float4(0, 0, 0, 1);
  // Outline of glyph is the isocontour with value 50%
  float edgeDistance = 0.5;
  // Sample the signed-distance field to find distance from this fragment to the glyph outline
  float sampleDistance = texture.sample(sampler, in.uv).r;
  // Use local automatic gradients to find anti-aliased anisotropic edge width, cf. Gustavson 2012
  float edgeWidth = 0.75 * length(float2(dfdx(sampleDistance), dfdy(sampleDistance)));
  // Smooth the glyph edge by interpolating across the boundary in a band with the width determined above
  float insideness = smoothstep(edgeDistance - edgeWidth, edgeDistance + edgeWidth, sampleDistance);
  return float4(color.r, color.g, color.b, insideness);
}
