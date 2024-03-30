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

struct BoundingBox {
  float2 center;
  float left;
  float right;
  float top;
  float bottom;
};

struct ComputeData {
  float4x4 projMat;
  int2 sceneGridSize;
  float2 windowSize;
  float deltaTime;
  float time;
  float gridElemSize;
  BoundingBox gridBounds;
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
  float2 resolution = float2(textureWidth, textureHeight);
  float2 fragCoord = float2(id);
//  float2 uv = fragCoord;
//  uv = uv / float2(textureWidth, textureHeight);
//  uv = uv * 2 - 1;
  
//  float2 position = (2 * fragCoord - resolution) / resolution.y;
  float2 position = (2 * fragCoord - resolution);
//  position *= 1000;
//  uv = (data.projMat * float4(uv, 0, 1)).xy;
//  color = half4(uv.x, uv.y, 0, 1);
  
//  float2 center = float2(0, 0);
//  half4 itemColor = half4(1, 1, 1, 1);
//  float itemRadius = 100;
//  float dist = distToCircle(position - center, itemRadius);
//  color = mix(color, itemColor, 1 - smoothstep(0, 0, dist));
  
  int remapedX = floor(remap(position.x, float2(data.gridBounds.left, data.gridBounds.right), float2(0, data.sceneGridSize.x)));
  int remapedY = floor(remap(position.y, float2(data.gridBounds.bottom, data.gridBounds.top), float2(0, data.sceneGridSize.y)));
  
  if (remapedX >= 0 && remapedX <= data.sceneGridSize.x && remapedY >= 0 && remapedY <= data.sceneGridSize.y) {
      int sceneGridIndex = from2DTo1DArray(int2(remapedX, remapedY), data.sceneGridSize);
      int itemIndex = grids[sceneGridIndex].itemIndex;
    
      if (itemIndex >= 0) {
        Circle item = circles[itemIndex];
    
        float dist = distToCircle(position - item.position, item.radius * 0.5);
        color = mix(color, half4(item.color), 1 - smoothstep(0, 0, dist));
      }
  }
  
  // draw debug grid
  if (position.x >= data.gridBounds.left && position.x <= data.gridBounds.right && position.y >= data.gridBounds.bottom && position.y <= data.gridBounds.top) {
    if (fmod(position.x, data.gridElemSize) == 0 || fmod(position.y, data.gridElemSize) == 0) {
      color = half4(1, 1, 1, 1);
    }
  }
  
  output.write(color, id);
}
