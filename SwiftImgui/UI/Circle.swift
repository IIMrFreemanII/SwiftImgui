//
//  Circle.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 11.02.2023.
//

import MetalKit

struct Circle {
  var color = Color()
  var position = float2()
  var radius = Float()
  var borderSize = Float()
  var depth = Float()
}

var circles = Array(repeating: Circle(), count: 10)
var circlesCount = 0

func startCircleFrame() {
  circlesCount = 0
}

func circle(position: float2, radius: Float, borderSize: Float = 0.01, color: Color = .black) {
  circles.withUnsafeMutableBufferPointer { buffer in
    buffer[circlesCount] = Circle(
      color: color,
      position: position,
      radius: radius,
      borderSize: borderSize,
      depth: getDepth()
    )
    circlesCount += 1
  }
}

func drawCircleData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawCirclesInstanced(at: encoder, uniforms: &vertexData, circles: &circles, circlesCount: circlesCount)
}
