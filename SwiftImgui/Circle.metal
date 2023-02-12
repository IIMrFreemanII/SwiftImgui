//
//  Circle.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 11.02.2023.
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
  float4 color [[flat]];
  float2 uv;
  float borderSize [[flat]];
  float crispness [[flat]];
};

struct Circle {
  float4 color;
  float2 position;
  float radius;
  float borderSize;
  float depth;
};

float sdCircle(float2 p, float r) {
  return length(p) - r;
}

vertex VertexOut vertex_circle(
                               const VertexIn in [[stage_in]],
                               constant RectVertexData &vertexData [[buffer(10)]],
                               const constant Circle* circles [[buffer(11)]],
                               uint instance [[instance_id]]
                               )
{
  float crispness = 0.0;
  Circle circle = circles[instance];
  float2 size = float2(circle.radius * 2);
  float2 uv = in.uv * 2 - 1;
  uv *= 1 + circle.borderSize + crispness;
  
  matrix_float4x4 model = translation(float3(circle.position, circle.depth)) * scale(float3(size, 1));
  float4 position = translation(float3(-0.5, -0.5, 0)) * in.position;
  position = vertexData.projectionMatrix * vertexData.viewMatrix * model * position;
  
  return {
    .position = position,
    .uv = uv,
    .color = circle.color,
    .borderSize = circle.borderSize,
    .crispness = crispness,
  };
}

fragment float4 fragment_circle(VertexOut in [[stage_in]])
{
  float4 bgColor = float4(0.0, 0.0, 0.0, 0.0);
  float4 circleColor = in.color;
  
  float radius = 1;
  float distance = sdCircle(in.uv, radius);
  distance = abs(distance) - in.borderSize;
  
  if(distance > 0) {
    discard_fragment();
    return 0;
  }
  
  float4 color = bgColor;
  color = mix(color, circleColor, 1.0 - smoothstep(0, in.crispness, distance));
  
  return color;
}
