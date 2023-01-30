//
//  Padding.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.01.2023.
//

@discardableResult
func padding(rect: Rect, by inset: Inset, _ cb: (Rect) -> Void) -> Rect {
  let result = rect.inflate(by: inset)
  cb(result.deflate(by: inset))
  return result
}
