//
//  compute.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 24.03.2024.
//

#include <metal_stdlib>
using namespace metal;

#include "math.h"

float distToCircle(float2 p, float r) {
  return length(p) - r;
}

struct Circle {
  float4 color;
  float2 position;
  float radius;
};

struct GridElem {
  int itemIndex;
};

//kernel void drawCircles(
//  constant float4x4 &projMat [[buffer(0)]],
//  device Circle *circles [[buffer(1)]],
//  texture2d<half, access::write> output [[texture(0)]],
//  uint id [[thread_position_in_grid]])
//{
//  Circle item = circles[id];
//  float2 center = (projMat * float4(item.position, 0, 1)).xy;
//  
//  for (int y = 0; y < item.radius; y++) {
//    for (int x = 0; x < item.radius; x++) {
//      float2 position = float2(x, y) + center - float2(item.radius * 0.5);
//      
//      // handle boundaries
//      if (position.x < 0 || position.y < 0) {
//        continue;
//      }
//      
////      float dist = distToCircle(position - item.position, item.radius);
////      half4 color = half4(0.0, 0.0, 0.0, 1.0);
////      color = mix(color, half4(item.color), 1 - smoothstep(0, 0, dist));
//      
//      output.write(half4(item.color), uint2(position));
//    }
//  }
//}

struct ComputeData {
  float4x4 projMat;
  int2 sceneGridSize;
};

int from2DTo1DArray(int2 index, int2 size) {
  return index.y * size.x + index.x;
}

kernel void clearScreen(
  texture2d<half, access::write> output [[texture(0)]],
  constant ComputeData &data [[buffer(0)]],
  constant Circle *circles [[buffer(1)]],
  constant GridElem *grids [[buffer(2)]],
  uint2 id [[thread_position_in_grid]]
)
{
  half4 color = half4(0.5, 0.5, 0.5, 1.0);
  half textureWidth = output.get_width();
  half textureHeight = output.get_height();
  
  int remapedX = floor(remap(id.x, float2(0, textureWidth), float2(0, data.sceneGridSize.x)));
  int remapedY = floor(remap(id.y, float2(0, textureHeight), float2(0, data.sceneGridSize.y)));
  
  int sceneGridIndex = from2DTo1DArray(int2(remapedX, remapedY), data.sceneGridSize);
  int itemIndex = grids[sceneGridIndex].itemIndex;
  
  if (itemIndex >= 0) {
    Circle item = circles[itemIndex];
    float4 center = data.projMat * float4(item.position, 0, 1);

    float dist = distToCircle(float2(id.x, id.y) - center.xy, item.radius);
    color = mix(color, half4(item.color), 1 - smoothstep(0, 0, dist));
  }
  
  output.write(color, id);
}
