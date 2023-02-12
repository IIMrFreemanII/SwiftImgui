//
//  TextField.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 07.02.2023.
//

import AppKit

struct TextFieldState {
  var text: [UInt32]
  var scroll = ScrollState()
  var cursorOffset = float2()
  var column: UInt32 = 1
  var selected: Bool = false
  var font: Font = defaultFont
  var fontSize: Float = defaultFontSize
  var trackArea = TrackArea()
  
  mutating func setColumn(_ value: UInt32) {
    // text.count + 1 to take into accound new line or null terminator character
    let result = value.clamped(to: 1...UInt32(text.count + 1))
    self.cursorOffset = calcCursorOffset(
      row: 1,
      column: result,
      &text,
      fontSize: fontSize,
      font: font
    )
    self.column = result
    Time.resetCursorBlinking()
  }
  
  mutating func calcScrollOffsetToCursor(visibleArea: float2, direction: Int) {
    // check if cursor is in visible area
    let xScrollOffset = abs(self.scroll.offset.x)
    let isVisible = self.cursorOffset.x >= xScrollOffset && self.cursorOffset.x <= (xScrollOffset + visibleArea.width)
    
    if !isVisible {
      if direction > 0 {
        self.scroll.offset.x -= visibleArea.width * 0.5
      } else {
        self.scroll.offset.x += visibleArea.width * 0.5
      }
    }
  }

  mutating func handleCharacter(code: UInt32) {
    switch code {
    case Input.returnOrEnterKey:
      break
    case Input.leftArrow:
      self.setColumn(self.column - 1)
      break
    case Input.rightArrow:
      self.setColumn(self.column + 1)
      break
    case Input.topArrow:
      break
    case Input.downArrow:
      break
    case Input.deleteKey:
      let index = Int(self.column) - 2
      if index >= 0 && index < self.text.count {
        self.text.remove(at: index)
        self.setColumn(self.column - 1)
      }
      break
    default:
      self.text.insert(code, at: Int(self.column) - 1)
      self.setColumn(self.column + 1)
    }
  }
}

let outlineSize = Float(2)

@discardableResult
func textField(
  position: float2,
  state: inout TextFieldState,
  _ width: Float = 140,
  _ fontSize: Float = defaultFontSize
) -> Rect {
  if state.selected {
    Input.charactersCode {
      state.handleCharacter(code: $0)
    }
  }
  
  let inset = Inset(vertical: 4, horizontal: 8)
  let strBounds = calcBoundsForString(
    &state.text,
    fontSize: state.fontSize,
    font: state.font
  )
  
  let textFieldBounds = Rect(
    position: position,
    size: float2(width, strBounds.height)
  ).inflate(by: inset)
  
  if Input.mouseDown {
    state.selected = false
  }
  let hit = textFieldBounds
    .mouseDown {
      state.selected = true
      Time.resetCursorBlinking()
    }
  
  Input.dragChange { value in
    print(value)
  }
  Input.dragEnd { value in
    print(value)
  }

  let drag = Input.dragGesture
  rect(Rect(position: drag.start, size: drag.translation), color: .red)
  
  state.trackArea.hit = hit.hit
  state.trackArea.mouseEnter {
    NSCursor.iBeam.push()
  }
  state.trackArea.mouseExit {
    NSCursor.pop()
  }
  
  let borderRadius = float4(repeating: 0.25)
  
  if state.selected {
    var outlineRect = textFieldBounds
    outlineRect.position -= outlineSize
    outlineRect.size += outlineSize * 2

    rect(outlineRect, color: .blue, borderRadius: borderRadius)
    
    Input.charactersCode { charCode in
      let visibleArea = textFieldBounds.deflate(by: inset)
      
      let direction = charCode == Input.leftArrow ? -1 : 1
      state.calcScrollOffsetToCursor(visibleArea: visibleArea.size, direction: direction)
    }
  }
  
  rect(textFieldBounds, color: .gray, borderRadius: borderRadius)
  
  var scrollState = state.scroll
  scroll(
    state: &scrollState,
    textFieldBounds.deflate(by: inset),
    contentSize: strBounds.size + float2(1, 0),
    showScrollBars: false
  ) { offset in
    let position = offset
    let textRect = text(position: position, color: .white, text: &state.text)
    
    // calc column index for cursor
    if state.selected {
      textRect.mouseDown {
        let localMousePosition = max(Input.mousePosition - textRect.position, float2())
        let rowAndCol = findRowAndCol(
          from: localMousePosition,
          in: Rect(size: textRect.size),
          &state.text,
          fontSize: state.fontSize,
          font: state.font
        )
        state.setColumn(rowAndCol.1)
      }
    }
    
    // draw text field cursor
    if state.selected && Time.cursorSinBlinking >= 0 {
      let lineHeight: Float = fontSize * 1.333
      rect(Rect(position: position + state.cursorOffset, size: float2(1, lineHeight)), color: .white)
    }
  }
  state.scroll = scrollState
  
  return textFieldBounds
}
