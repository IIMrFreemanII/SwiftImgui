//
//  Line.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 11.02.2023.
//

#include <metal_stdlib>
using namespace metal;

#import "math.h"
#import "SDFRoundBox.h"
#import "RectVertexData.h"

struct VertexIn {
  float4 position [[attribute(0)]];
  float2 uv [[attribute(1)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 color [[flat]];
  float2 uv;
};

struct Line {
  float2 start;
  float2 end;
  float4 color;
  float size;
  float depth;
};

vertex VertexOut vertex_line(
                             const VertexIn in [[stage_in]],
                             constant RectVertexData &vertexData [[buffer(10)]],
                             const constant Line* lines [[buffer(11)]],
                             uint instance [[instance_id]]
                             )
{
  Line line = lines[instance];
  float2 uv = in.uv * 2 - 1;
  
  float len = length(line.start - line.end);
  float2 dir = normalize(line.end - line.start);
  
  matrix_float4x4 model = translation(float3(line.start, line.depth)) * rotationZ(dir) * scale(float3(float2(len, line.size), 1));
  // move origin to middle-left of NDC of rect wich has origin at top-left of NDC (0, 0)
  float4 position = translation(float3(0, -0.5, 0)) * in.position;
  position = vertexData.projectionMatrix * vertexData.viewMatrix * model * position;
  
  return {
    .position = position,
    .uv = uv,
    .color = line.color,
  };
}

fragment float4 fragment_line(VertexOut in [[stage_in]])
{
  float2 size = float2(1);
  float4 borderRadius = float4(0);
  float4 bgColor = float4(0.0, 0.0, 0.0, 0.0);
  float4 lineColor = in.color;
  
  float distance = sdRoundBox(in.uv, size, borderRadius);
  float4 color = bgColor;
  color = mix(color, lineColor, 1.0 - smoothstep(0, 0, distance));
  return color;
}
