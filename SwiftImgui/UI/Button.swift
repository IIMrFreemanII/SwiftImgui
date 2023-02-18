//
//  Button.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 07.02.2023.
//

struct ButtonStyle {
  var rect = RectStyle()
  var text = TextStyle()
}

struct ButtonResult {
  var rect: Rect
  var hit: HitResult
}

@discardableResult
func button(_ position: float2, _ str: inout [UInt32], style: ButtonStyle) -> ButtonResult {
  let inset = Inset(vertical: 4, horizontal: 8)
  var bounds = calcBoundsForString(&str, fontSize: defaultFontSize, font: defaultFont).inflate(by: inset)
  bounds.position = position
  let innerBounds = bounds.deflate(by: inset)
  
  var rectStyle = style.rect
  
  let hit = bounds
    .mouseOver {
      rectStyle.color.w *= 0.9
    }
    .mousePress {
      rectStyle.color.w *= 0.8
    }
  
  rect(bounds, style: rectStyle)
  text(position: innerBounds.position, text: &str)
  
  return ButtonResult(rect: bounds, hit: hit)
}
