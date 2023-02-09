//
//  Text.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

import MetalKit

var glyphs = [SDFGlyph](repeating: SDFGlyph(), count: 100_000)
var glyphsCount = 0
var defaultFont: Font!
let defaultFontSize = Float(16)

func setFont(_ value: Font) {
  defaultFont = value
}

func startTextFrame() {
  glyphsCount = 0
}

func endTextFrame() {
  
}

@discardableResult
func text(
  position: float2,
  size: float2 = float2(),
  color: float4 = float4(0, 0, 0, 1),
  fontSize: Float = defaultFontSize,
  text: inout [UInt32]
) -> Rect {
  return buildSDFGlyphsFromString(
    &text,
    inRect: Rect(
      position: position,
      size: float2(
        size.x != 0 ? size.x : Float.greatestFiniteMagnitude,
        size.y != 0 ? size.y : Float.greatestFiniteMagnitude
      )
    ),
    color: color,
    withFont: defaultFont,
    atSize: fontSize,
    glyphs: &glyphs,
    glyphsCount: &glyphsCount
  )
}

func drawTextData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawTextInstanced(at: encoder, uniforms: &vertexData, glyphs: &glyphs, glyphsCount: glyphsCount, texture: defaultFont.sdfTexture)
}
