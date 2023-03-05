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
  
  var center: float2 {
    position + size * 0.5
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
    let index = clipRectIndices.withUnsafeBufferPointer { $0[clipRectIndicesCount - 1] }
    let clipRect = clipRects.withUnsafeMutableBufferPointer { $0[index] }.rect
    let hit = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: clipRect.position, size: clipRect.size) && pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: position, size: size)
    
    if hit {
      cb()
    }

    return HitResult(hit: hit)
  }
  
  @discardableResult
  func mousePress(_ cb: VoidFunc) -> HitResult {
    let index = clipRectIndices.withUnsafeBufferPointer { $0[clipRectIndicesCount - 1] }
    let clipRect = clipRects.withUnsafeMutableBufferPointer { $0[index] }.rect
    let hit = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: clipRect.position, size: clipRect.size) && pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: position, size: size)
    
    if hit && Input.mousePressed {
      cb()
    }

    return HitResult(hit: hit)
  }
  
  @discardableResult
  func mouseDown(_ cb: VoidFunc) -> HitResult {
    let index = clipRectIndices.withUnsafeBufferPointer { $0[clipRectIndicesCount - 1] }
    let clipRect = clipRects.withUnsafeMutableBufferPointer { $0[index] }.rect
    let hit = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: clipRect.position, size: clipRect.size) && pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: position, size: size)
    
    if hit && Input.mouseDown {
      cb()
    }

    return HitResult(hit: hit)
  }
}

struct RectProps {
  var rect = Rect()
  var borderRadius = uchar4()
  var color = Color()
  var depth = Float()
  var crispness = UInt8()
  var clipId = UInt16()
}

struct ClipRect {
  var rect = Rect()
  var borderRadius = float4()
  var crispness = Float()
  var id = UInt16()
  var parentIndex = UInt16()
}

struct HitResult {
  var hit: Bool

  @discardableResult
  func mouseOver(cb: VoidFunc) -> HitResult {
    if self.hit {
      cb()
    }

    return self
  }
  
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
  var contentScale: Float = 1
  var time: Float = 0
}

var clipRects = [ClipRect](repeating: ClipRect(), count: 300)
var clipRectsCount: Int = 0
var clipRectIndices = [Int](repeating: 0, count: 300)
var clipRectIndicesCount = 0

var rects = [RectProps](repeating: RectProps(), count: 100_000)
var rectsCount = 0
var vertexData = RectVertexData()

func setFramebufferSize(_ size: float2) {
  vertexData.resolution = size
}

func setContentScale(_ value: Float) {
  vertexData.contentScale = value
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
//  clipLayerId = 0
//  blurRectsCount = 0 // MARK: find better place
//  copyRectsCount = 0
}

func endRectFrame() {
}

// borderRadius.x = roundness top-right
// borderRadius.y = roundness boottom-right
// borderRadius.z = roundness top-left
// borderRadius.w = roundness bottom-left
struct RectStyle {
  var color: Color = .white
  var borderRadius = uchar4()
  var crispness: UInt8 = 2
}

func rect(
  _ rect: Rect,
  style: RectStyle
) {
  let clipLayerId = clipRectIndices.withUnsafeBufferPointer { $0[clipRectIndicesCount - 1] }
  rects.withUnsafeMutableBufferPointer { buffer in
    buffer[rectsCount] = RectProps(
      rect: rect,
      borderRadius: style.borderRadius,
      color: style.color,
      depth: getDepth(),
      crispness: style.crispness,
      clipId: UInt16(clipLayerId)
    )
    rectsCount &+= 1
  }
}

struct BorderStyle {
  var rect = RectStyle()
  var size = Float(1)
}

/// cb - passes downscaled rect and border radius
func border(
  content: Rect,
  style: BorderStyle,
  _ cb: (Rect) -> Void
) {
  rect(content, style: style.rect)
  cb(content.deflate(by: Inset(all: style.size)))
}

struct ShadowStyle {
  var rect = RectStyle(color: .black)
  var offset = float2()
  var spreadRadius = Float(0)
}

func shadow(
  content: Rect,
  style: ShadowStyle,
  _ cb: (Rect) -> Void
) {
  let shadowRect = Rect(
    position: (content.position - style.spreadRadius) + style.offset,
    size: content.size + (style.spreadRadius * 2)
  )
  
  rect(shadowRect, style: style.rect)
  cb(content)
}

func clip(
  rect: Rect,
  borderRadius: float4 = float4(),
  crispness: Float = 0,
  _ cb: (Rect) -> Void
) {
  let clipRectIndicesBuffer = clipRectIndices.withUnsafeMutableBufferPointer { $0 }
  clipRects.withUnsafeMutableBufferPointer { buffer in
    buffer[clipRectsCount] = ClipRect(
      rect: rect,
      borderRadius: borderRadius,
      crispness: crispness,
      id: UInt16(clipRectsCount),
      parentIndex: UInt16(clipRectIndicesCount > 0 ? clipRectIndicesBuffer[clipRectIndicesCount &- 1] : 0)
    )
    clipRectIndicesBuffer[clipRectIndicesCount] = clipRectsCount
    clipRectIndicesCount &+= 1
    clipRectsCount &+= 1
  }
  
  cb(rect)
  
  clipRectIndicesCount &-= 1
}

func drawRectData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawRectsInstanced(at: encoder, uniforms: &vertexData, rects: &rects, rectsCount: rectsCount)
}
