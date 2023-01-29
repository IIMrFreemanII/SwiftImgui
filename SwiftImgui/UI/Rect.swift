//
//  Rect.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

import MetalKit

struct Rect {
  var position = float2()
  var size = float2()
  
  /// Returns a new rect that is smaller than the given rect by the amount of inset in the horizontal and vertical directions.
  func deflate(by inset: Inset) -> Rect {
    return Rect(
      position: self.position + inset.topLeft,
      size: inset.deflate(size: self.size)
    )
  }
  
  ///Returns a new rect that is bigger than the given rect by the amount of inset in the horizontal and vertical directions.
  func inflate(by inset: Inset) -> Rect {
    return Rect(
      position: self.position,
      size: inset.inflate(size: self.size)
    )
  }
  
  @discardableResult
  func mouseOver(_ cb: VoidFunc? = nil) -> HitResult {
    let hit = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: position, size: size)
    
    if hit {
      cb?()
    }

    return HitResult(hit: hit)
  }
}

struct RectProps {
  var rect = Rect()
  var color = float4()
  var depth = Float()
}

struct HitResult {
  var hit: Bool

  @discardableResult
  func mouseDown(cb: VoidFunc) -> HitResult {
    if self.hit && Input.mouseDown {
      cb()
    }

    return self
  }

  @discardableResult
  func mousePress(cb: VoidFunc) -> HitResult {
    if self.hit && Input.mousePressed {
      cb()
    }

    return self
  }

  @discardableResult
  func mouseUp(cb: VoidFunc) -> HitResult {
    if self.hit && Input.mouseUp {
      cb()
    }

    return self
  }
}

struct RectVertexData {
  var viewMatrix: float4x4 = float4x4.identity
  var projectionMatrix: float4x4 = float4x4.identity
  var time: Float = 0;
}

var rects = [RectProps](repeating: RectProps(), count: 100_000)
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

func rect(
  _ rect: Rect,
  color: float4 = float4(1, 1, 1, 1)
) {
  rects.withUnsafeMutableBufferPointer { buffer in
    buffer[rectsCount] = RectProps(
      rect: rect,
      color: color,
      depth: getDepth()
    )
    rectsCount += 1
  }
}

func drawRectData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawRectsInstanced(at: encoder, uniforms: &vertexData, rects: &rects, rectsCount: rectsCount)
}
