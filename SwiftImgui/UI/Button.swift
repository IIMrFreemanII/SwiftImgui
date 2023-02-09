//
//  Button.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 07.02.2023.
//

import Foundation

@discardableResult
func button(_ position: float2, _ str: inout [UInt32]) -> (HitResult, Rect) {
  let inset = Inset(vertical: 4, horizontal: 8)
  var bounds = calcBoundsForString(&str, fontSize: defaultFontSize, font: defaultFont).inflate(by: inset)
  bounds.position = position
  let innerBounds = bounds.deflate(by: inset)
  
  var color: float4 = .gray
  let borderRadius = float4(repeating: 0.25)
  
  let hit = bounds
    .mouseOver {
      color.w *= 0.9
    }
    .mousePress {
      color.w *= 0.8
    }
  
  rect(bounds, color: color, borderRadius: borderRadius)
  text(position: innerBounds.position, color: .white, text: &str)
  
  return (hit, bounds)
}
