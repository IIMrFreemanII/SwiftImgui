//
//  Text.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

import MetalKit

var glyphs = [SDFGlyph](repeating: SDFGlyph(), count: 25_000)
var glyphsCount = 0
var glyphsStyle = [SDFGlyphStyle](repeating: SDFGlyphStyle(), count: 500)
var glyphsStyleCount = 0

func startTextFrame() {
  glyphsCount = 0
  glyphsStyleCount = 0
}

func endTextFrame() {
  
}

struct TextStyle {
  var color: Color = .black
  var font: Font = Theme.defaultFont
  var fontSize: Float = Theme.defaultFontSize
}

@discardableResult
func text(
  position: float2,
  size: float2 = float2(),
  style: TextStyle = TextStyle(),
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
    style: style,
    glyphs: &glyphs,
    glyphsCount: &glyphsCount,
    glyphsStyle: &glyphsStyle,
    glyphsStyleCount: &glyphsStyleCount
  )
}

func drawTextData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawTextInstanced(
    at: encoder,
    uniforms: &vertexData,
    glyphs: &glyphs,
    glyphsCount: glyphsCount,
    glyphsStyle: &glyphsStyle,
    glyphsStyleCount: glyphsStyleCount,
    // MARK: add support for multiple fonts
    texture: Theme.defaultFont.sdfTexture
  )
}
