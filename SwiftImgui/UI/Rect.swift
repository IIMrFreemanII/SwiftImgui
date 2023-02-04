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
    let clipRect = clipRects.withUnsafeMutableBufferPointer { $0[clipRectsCount - 1] }.rect
    let hit = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: clipRect.position, size: clipRect.size) && pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: position, size: size)
    
    if hit {
      cb?()
    }

    return HitResult(hit: hit)
  }
  
  @discardableResult
  func mousePress(_ cb: VoidFunc? = nil) -> HitResult {
    let clipRect = clipRects.withUnsafeMutableBufferPointer { $0[clipRectsCount - 1] }.rect
    let hit = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: clipRect.position, size: clipRect.size) && pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: position, size: size)
    
    if hit && Input.mousePressed {
      cb?()
    }

    return HitResult(hit: hit)
  }
}

struct RectProps {
  var rect = Rect()
  var borderRadius = float4()
  var color = float4()
  var borderColor = float4()
  var depth = Float()
  var clipId = UInt32()
  var crispness = Float()
  var borderSize = Float()
}

struct ClipRect {
  var rect = Rect()
  var depth = Float()
  var id = UInt32()
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

var clipRects = [ClipRect](repeating: ClipRect(), count: 100)
var clipRectsCount = 0

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
  clipRectsCount = 0
}

func endRectFrame() {
}

// borderRadius.x = roundness top-right
// borderRadius.y = roundness boottom-right
// borderRadius.z = roundness top-left
// borderRadius.w = roundness bottom-left
func rect(
  _ rect: Rect,
  color: float4 = float4(1, 1, 1, 1),
  borderRadius: float4 = float4(),
  crispness: Float = 0.005
) {
  rects.withUnsafeMutableBufferPointer { buffer in
    buffer[rectsCount] = RectProps(
      rect: rect,
      borderRadius: borderRadius,
      color: color,
      depth: getDepth(),
      clipId: UInt32(clipRectsCount),
      crispness: crispness
    )
    rectsCount += 1
  }
}

/// cb - passes downscaled rect and border radius
func border(
  content: Rect,
  color: float4 = float4(1, 1, 1, 1),
  radius: float4 = float4(),
  size: Float = 1,
  _ cb: (Rect, float4) -> Void
) {
  rect(content, color: color, borderRadius: radius)
  cb(content.deflate(by: Inset(all: size)), radius)
}

func shadow(
  content: Rect,
  borderRadius: float4 = float4(),
  color: float4 = float4(0, 0, 0, 1),
  offset: float2 = float2(),
  blurRadius: Float = 0,
  spreadRadius: Float = 0,
  _ cb: (Rect, float4) -> Void
) {
//  let blurRadius = blurRadius.clamped(to: 0...1)
  let shadowRect = Rect(
    position: (content.position - spreadRadius) + offset,
    size: content.size + (spreadRadius * 2)
  )
//    .deflate(by: Inset(all: (blurRadius * 15).clamped(to: 0...15)))
  
  rect(shadowRect, color: color, borderRadius: borderRadius, crispness: blurRadius)
  cb(content, borderRadius)
}

func clip(rect: Rect, _ cb: (Rect) -> Void) {
  clipRects.withUnsafeMutableBufferPointer { buffer in
    buffer[clipRectsCount] = ClipRect(
      rect: rect,
      depth: 0,
      id: UInt32(clipRectsCount + 1)
    )
    clipRectsCount += 1
  }
  
  cb(rect)
}

func drawRectData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawRectsInstanced(at: encoder, uniforms: &vertexData, rects: &rects, rectsCount: rectsCount)
}
