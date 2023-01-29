//
//  Layout.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 27.01.2023.
//

import Foundation

@discardableResult
func padding(rect: Rect, by inset: Inset, _ cb: (Rect) -> Void) -> Rect {
  let result = rect.inflate(by: inset)
  cb(result.deflate(by: inset))
  return result
}

//---------------------------------------------------------------------------

struct VCursor {
  var position: float2
  var size = float2()
  let spacing: Float
  
  mutating func offset(by rect: inout Rect) {
    self.position.y += rect.size.y + spacing
    self.size.y += rect.size.y
    
    if self.size.x < rect.size.x {
      self.size.x = rect.size.x
    }
  }
}

@discardableResult
func vStack(
  position: float2,
  spacing: Float = 0,
  _ cb: (inout VCursor, inout Rect) -> Void
) -> Rect {
  var cursor = VCursor(position: position, spacing: spacing)
  var rect = Rect()
  
  cb(&cursor, &rect)
  
  cursor.size.y -= spacing
  return Rect(position: position, size: cursor.size)
}

//---------------------------------------------------------------------------

struct HCursor {
  var position: float2
  var size = float2()
  let spacing: Float
  
  mutating func offset(by rect: inout Rect) {
    self.position.x += rect.size.x + spacing
    self.size.x += rect.size.x
    
    if self.size.y < rect.size.y {
      self.size.y = rect.size.y
    }
  }
}

@discardableResult
func hStack(
  position: float2,
  spacing: Float = 0,
  _ cb: (inout HCursor, inout Rect) -> Void
) -> Rect {
  var cursor = HCursor(position: position, spacing: spacing)
  var rect = Rect()
  
  cb(&cursor, &rect)
  
  cursor.size.x -= spacing
  return Rect(position: position, size: cursor.size)
}

//---------------------------------------------------------------------------

enum Alignment {
  case start
  case center
  case end
}

struct VAlignCursor {
  var position: float2
  var size: float2
  var alignment: Alignment
  
  mutating func offset(by size: float2) -> Rect {
    var result = float2()
    self.size.y = size.y
    
    switch alignment {
    case .start:
      result = position
    case .center:
      result = position + float2((self.size.x * 0.5) - (size.x * 0.5), 0)
    case .end:
      result = position + float2(self.size.x - size.x, 0)
    }
    
    return Rect(position: result, size: size)
  }
}

@discardableResult
func vAlign(_ parent: Rect, _ alignment: Alignment = .start, _ cb: (inout VAlignCursor) -> Void) -> Rect {
  var cursor = VAlignCursor(position: parent.position, size: parent.size, alignment: alignment)
  
  cb(&cursor)
  
  return Rect(position: parent.position, size: cursor.size)
}
