//
//  Button.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 07.02.2023.
//

struct ButtonStyle {
  var rect = RectStyle()
  var text = TextStyle()
  var inset = Inset(vertical: 4, horizontal: 8)
}

struct ButtonResult {
  var rect: Rect
  var hit: HitResult
}

@discardableResult
func button(_ position: float2, _ str: inout [UInt32], style: ButtonStyle) -> ButtonResult {
  var bounds = calcBoundsForString(&str, fontSize: style.text.fontSize, font: style.text.font).inflate(by: style.inset)
  bounds.position = position
  let innerBounds = bounds.deflate(by: style.inset)
  
  var rectStyle = style.rect
  
  let hit = bounds
    .mouseOver {
      rectStyle.color.w = UInt8(Float(rectStyle.color.w) * 0.9)
    }
    .mousePress {
      rectStyle.color.w = UInt8(Float(rectStyle.color.w) * 0.8)
    }
  
  rect(bounds, style: rectStyle)
  text(position: innerBounds.position, style: style.text, text: &str)
  
  return ButtonResult(rect: bounds, hit: hit)
}
