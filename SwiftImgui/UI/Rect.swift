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

struct ModifiableRect {
  let rect: UnsafeMutablePointer<Rect>
  
  private func hitTest() -> Bool {
    let pos = rect.pointee.position
    return pointInAABBoxTopLeftOrigin(
      point: Input.mousePosition,
      position: float2(pos.x, pos.y),
      size: rect.pointee.size
    )
  }
  
  @discardableResult
  func modify(cb: (inout Rect) -> Void) -> ModifiableRect {
    cb(&rect.pointee)
    
    return self
  }
  
  @discardableResult
  func mouseOver(cb: (inout Rect) -> Void) -> ModifiableRect {
    if self.hitTest() {
      cb(&rect.pointee)
    }
    
    return self
  }
  
  @discardableResult
  func mouseDown(cb: (inout Rect) -> Void) -> ModifiableRect {
    if self.hitTest() && Input.mouseDown {
      cb(&rect.pointee)
    }
    
    return self
  }
  
  @discardableResult
  func mousePress(cb: (inout Rect) -> Void) -> ModifiableRect {
    if self.hitTest() && Input.mousePressed {
      cb(&rect.pointee)
    }
    
    return self
  }
  
  @discardableResult
  func mouseUp(cb: (inout Rect) -> Void) -> ModifiableRect {
    if self.hitTest() && Input.mouseUp {
      cb(&rect.pointee)
    }
    
    return self
  }
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

@discardableResult
func rect(
  position: float2 = float2(),
  size: float2 = float2(),
  color: float4 = float4(1, 1, 1, 1)
) -> ModifiableRect {
  let props = Rect(position: float3(position, Float(depth)), size: size, color: color)
  
  let buffer = rects.withUnsafeMutableBufferPointer { $0 }
  buffer[rectsCount] = props
  let rectHit = ModifiableRect(rect: &buffer[rectsCount])
  
  rectsCount += 1
  incrementDepth()
  
  return rectHit
}

func drawRectData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawRectsInstanced(at: encoder, uniforms: &vertexData, rects: &rects, rectsCount: rectsCount)
}
