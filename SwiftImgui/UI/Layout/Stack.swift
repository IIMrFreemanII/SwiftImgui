//
//  Stack.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.01.2023.
//

struct VCursor {
  var position: float2
  var size = float2()
  let spacing: Float
  
  mutating func offset(by rect: inout Rect) {
    self.position.y += rect.size.y + spacing
    self.size.y += rect.size.y + spacing
    
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
    self.size.x += rect.size.x + spacing
    
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
