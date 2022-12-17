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
                          float4 position [[attribute(Position)]] [[stage_in]]
                          )
{
  return position;
}

fragment float4 fragment_main() {
  return float4(0, 0, 1, 1);
}
