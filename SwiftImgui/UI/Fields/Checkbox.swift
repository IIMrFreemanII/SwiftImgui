//
//  Checkbox.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 21.02.2023.
//

struct CheckboxStyle {
  var rect = RectStyle(color: .gray, borderRadius: uchar4(repeating: 25))
  var innerRect = RectStyle(color: Color(255, 255, 255, 150), borderRadius: uchar4(repeating: 25))
}

struct CheckboxResult {
  var rect: Rect
  var changed: Bool
}

@discardableResult
func checkbox(_ r: Rect, value: inout Bool, style: CheckboxStyle) -> CheckboxResult {
  var changed = false
  
  rect(r, style: style.rect)
  r.mouseDown {
    value = !value
    changed = true
  }
  
  if value {
    rect(r.deflate(by: Inset(all: 5)), style: style.innerRect)
  }
  
  return CheckboxResult(rect: r, changed: changed)
}
