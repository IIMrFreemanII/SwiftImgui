//
//  Shaders.metal
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

using namespace metal;

#include <metal_stdlib>
#import "Common.h"

vertex float4 vertex_main(
                          float4 _position [[attribute(Position)]] [[stage_in]],
                          constant Uniforms &uniforms [[buffer(UniformsBuffer)]]
                          )
{
  float4 position =
    uniforms.projectionMatrix * uniforms.viewMatrix
    * uniforms.modelMatrix * _position;
  return position;
}

fragment float4 fragment_main(constant QuadMaterial &quadMaterial [[buffer(QuadMaterialBuffer)]]) {
  return quadMaterial.color;
}
