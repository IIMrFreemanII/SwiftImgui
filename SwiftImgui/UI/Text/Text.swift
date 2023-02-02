//
//  Text.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

import MetalKit

var glyphs = [SDFGlyph](repeating: SDFGlyph(), count: 100_000)
var glyphsCount = 0
var fontAtlas: Font!
var fontSize: Int = 16

func setFont(_ value: Font) {
  fontAtlas = value
}

func setFontSize(_ value: Int) {
  fontSize = value
}

func startTextFrame() {
  glyphsCount = 0
}

func endTextFrame() {
  
}

func text(
  position: float2,
  size: float2 = float2(),
  color: float4 = float4(0, 0, 0, 1),
  text: inout [UInt32]
) {
  _ = buildSDFGlyphsFromString(
    &text,
    inRect: CGRect(
      x: CGFloat(position.x),
      y: CGFloat(position.y),
      width: size.x != 0 ? CGFloat(size.x) : CGFloat.greatestFiniteMagnitude,
      height: size.y != 0 ? CGFloat(size.y) : CGFloat.greatestFiniteMagnitude
    ),
    color: color,
    withFont: fontAtlas,
    atSize: fontSize,
    glyphs: &glyphs,
    glyphsCount: &glyphsCount
  )
}

func drawTextData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawTextInstanced(at: encoder, uniforms: &vertexData, glyphs: &glyphs, glyphsCount: glyphsCount, texture: fontAtlas.sdfTexture)
}