//
//  Line.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 11.02.2023.
//

import MetalKit

struct Line {
  var start = float2()
  var end = float2()
  var color = Color()
  var size = Float()
  var depth = Float()
}

var lines = [Line](repeating: Line(start: float2(), end: float2(), color: .black, size: 0), count: 10)
var linesCount = 0

func startLineFrame() {
  linesCount = 0
}

func line(_ start: float2, _ end: float2, _ color: Color = .black, _ size: Float = 1) {
  lines.withUnsafeMutableBufferPointer { buffer in
    buffer[linesCount] = Line(start: start, end: end, color: color, size: size, depth: getDepth())
    linesCount += 1
  }
}

func drawLineData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawLinesInstanced(at: encoder, uniforms: &vertexData, lines: &lines, linesCount: linesCount)
}
