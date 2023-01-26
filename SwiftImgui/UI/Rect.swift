//
//  Rect.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

import MetalKit

struct Rect {
  var position = float3()
  var size = float2()
  var color = float4()
}

struct RectVertexData {
  var viewMatrix: float4x4 = float4x4.identity
  var projectionMatrix: float4x4 = float4x4.identity
  var time: Float = 0;
}

var rects = [Rect](repeating: Rect(), count: 100_000)
var rectsCount = 0
var vertexData = RectVertexData()

func setProjectionMatrix(matrix: float4x4) {
  vertexData.projectionMatrix = matrix
}

func setViewMatrix(matrix: float4x4) {
  vertexData.viewMatrix = matrix
}

func setTime(value: Float) {
  vertexData.time = value
}

func startRectFrame() {
  rectsCount = 0
}

func endRectFrame() {
}

func rect(position: float2, size: float2, color: float4 = float4(repeating: 1)) {
  rects.withUnsafeMutableBufferPointer { buffer in
    buffer[rectsCount] = Rect(position: float3(position.x, position.y, 0), size: size, color: color)
    rectsCount += 1
  }
}

func drawRectData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawRectsInstanced(at: encoder, uniforms: &vertexData, rects: &rects)
}
