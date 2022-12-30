//
//  Shaders.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

using namespace metal;

#include <metal_stdlib>
#import "math.h"
#import "Common.h"

struct VertexIn {
  float4 position [[attribute(Position)]];
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

vertex VertexOut vertex_main(
                             const VertexIn in [[stage_in]],
                             const device Rect* rects [[buffer(1)]],
                             constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                             uint instance [[instance_id]]
                             )
{
  Rect rect = rects[instance];
  matrix_float4x4 model = translation(rect.position) * scale(float3(rect.size, 1));
  float4 position =
  uniforms.projectionMatrix * uniforms.viewMatrix * model * in.position;
  
  return {
    .position = position,
    .color = rect.color
  };
}

fragment float4 fragment_main(FragmentIn in [[stage_in]]) {
  return in.color;
}
