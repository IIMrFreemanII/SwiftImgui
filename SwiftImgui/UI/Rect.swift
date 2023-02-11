//
//  Rect.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

import MetalKit

struct TrackArea {
  // persist between frames
  var mouseInArea = false
  // set every frame new hit value
  var hit = false
  
  mutating func mouseEnter(_ cb: () -> Void) {
    if hit && mouseInArea == false {
      cb()
      mouseInArea = true
    }
  }
  
  mutating func mouseExit(_ cb: () -> Void) {
    if hit == false && mouseInArea == true {
      cb()
      mouseInArea = false
    }
  }
}

struct Rect {
  var position: float2
  var size: float2
  
  init(position: float2 = float2(), size: float2 = float2()) {
    self.position = position
    self.size = size
  }
  
  init(x: Float = 0, y: Float = 0, width: Float = 0, height: Float = 0) {
    self.position = float2(x, y)
    self.size = float2(width, height)
  }
  
  var width: Float {
    size.x
  }
  var height: Float {
    size.y
  }
  
  var minX: Float {
    position.x
  }
  var minY: Float {
    position.y
  }
  
  var maxX: Float {
    position.x + size.x
  }
  var maxY: Float {
    position.y + size.y
  }
  
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
  func mouseOver(_ cb: VoidFunc) -> HitResult {
    let clipRect = clipRects.withUnsafeMutableBufferPointer { $0[clipRectsCount - 1] }.rect
    let hit = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: clipRect.position, size: clipRect.size) && pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: position, size: size)
    
    if hit {
      cb()
    }

    return HitResult(hit: hit)
  }
  
  @discardableResult
  func mousePress(_ cb: VoidFunc) -> HitResult {
    let clipRect = clipRects.withUnsafeMutableBufferPointer { $0[clipRectsCount - 1] }.rect
    let hit = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: clipRect.position, size: clipRect.size) && pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: position, size: size)
    
    if hit && Input.mousePressed {
      cb()
    }

    return HitResult(hit: hit)
  }
  
  @discardableResult
  func mouseDown(_ cb: VoidFunc) -> HitResult {
    let clipRect = clipRects.withUnsafeMutableBufferPointer { $0[clipRectsCount - 1] }.rect
    let hit = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: clipRect.position, size: clipRect.size) && pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: position, size: size)
    
    if hit && Input.mouseDown {
      cb()
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
  var clipId = UInt16()
  var crispness = Float()
  var borderSize = Float()
}

struct ClipRect {
  var rect = Rect()
  var borderRadius = float4()
  var depth = Float()
  var crispness = Float()
  var id = UInt16()
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
  var resolution: float2 = float2()
  var time: Float = 0
}

var clipRects = [ClipRect](repeating: ClipRect(), count: 100)
var clipRectsCount = 0
var clipLayerId = UInt16()

var rects = [RectProps](repeating: RectProps(), count: 100_000)
var rectsCount = 0
var vertexData = RectVertexData()

func setFramebufferSize(_ size: float2) {
  vertexData.resolution = size
}

func setProjection(matrix: float4x4) {
  vertexData.projectionMatrix = matrix
}

func setView(matrix: float4x4) {
  vertexData.viewMatrix = matrix
}

func setTime(value: Float) {
  vertexData.time = value
}

func startRectFrame() {
  rectsCount = 0
  clipRectsCount = 0
  blurRectsCount = 0 // MARK: find better place
  copyRectsCount = 0
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
      clipId: clipLayerId,
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

func clip(
  rect: Rect,
  borderRadius: float4 = float4(),
  crispness: Float = 0,
  _ cb: (Rect) -> Void
) {
  clipRects.withUnsafeMutableBufferPointer { buffer in
    clipLayerId += 1
    buffer[clipRectsCount] = ClipRect(
      rect: rect,
      borderRadius: borderRadius,
      depth: 0,
      crispness: crispness,
      id: clipLayerId
    )
    clipRectsCount += 1
  }
  
  cb(rect)
  
  clipLayerId -= 1
}

func drawRectData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawRectsInstanced(at: encoder, uniforms: &vertexData, rects: &rects, rectsCount: rectsCount)
}
