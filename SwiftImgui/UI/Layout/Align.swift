//
//  HAlign.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.01.2023.
//

enum Alignment {
  case start
  case center
  case end
}

struct HAlignCursor {
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
func hAlign(_ parent: Rect, _ alignment: Alignment = .start, _ cb: (inout HAlignCursor) -> Void) -> Rect {
  var cursor = HAlignCursor(position: parent.position, size: parent.size, alignment: alignment)
  
  cb(&cursor)
  
  return Rect(position: parent.position, size: cursor.size)
}

//---------------------------------------------------------------------------

struct VAlignCursor {
  var position: float2
  var size: float2
  var alignment: Alignment
  
  mutating func offset(by size: float2) -> Rect {
    var result = float2()
    self.size.x = size.x
    
    switch alignment {
    case .start:
      result = position
    case .center:
      result = position + float2(0, (self.size.y * 0.5) - (size.y * 0.5))
    case .end:
      result = position + float2(0, self.size.y - size.y)
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
