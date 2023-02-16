//
//  TextField.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 07.02.2023.
//

import AppKit

struct TextSelection {
  // row and col
  var start: (UInt32, UInt32) = (1, 1)
  // row and col
  var end: (UInt32, UInt32) = (1, 1)
  
  var isEmpty: Bool {
    return start.0 == 1 && start.1 == 1 && end.0 == 1 && end.1 == 1
  }
}

struct TextFieldState {
//  var text: [UInt32]
  var scroll = ScrollState()
  var cursorOffset = float2()
  var column: UInt32 = 1
  var selected: Bool = false
//  var font: Font = defaultFont
//  var fontSize: Float = defaultFontSize
  var trackArea = TrackArea()
  var textSelection = TextSelection()
  
  mutating func getSelectedTextRange(text: inout [UInt32]) -> Range<Int> {
    var row = 1
    var col = 1
    
    var start = 0
    var end = 0
    
    text.withUnsafeBufferPointer { buffer in
      enumerateLines(for: buffer) { range in
        if row < self.textSelection.start.0 {
          row += 1
          return false
        }
        if row > self.textSelection.end.0 {
          return true
        }
        
        col = 1
        
        // range.upperBound + 1 to take into accound new line or null terminator character
        let plusOneRange = range.lowerBound..<(range.upperBound + 1)
        for i in plusOneRange {
          if self.textSelection.start.0 == row && self.textSelection.start.1 == col {
            start = i
          }
          if self.textSelection.end.0 == row && self.textSelection.end.1 == col {
            end = i
          }
          
          col += 1
        }
        
        row += 1
        return false
      }
    }

    return start..<end
  }
  
  mutating func setColumn(_ value: UInt32, text: inout [UInt32], font: Font, fontSize: Float) {
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
  
  mutating func handleCharacter(charCode: UInt32, text: inout [UInt32], font: Font, fontSize: Float) {
    if let modifierFlags = Input.modifierFlags {
      if modifierFlags.contains(.command) {
        // command + C
        if Input.keysDown.contains(.keyC) {
          if !self.textSelection.isEmpty {
            let range = self.getSelectedTextRange(text: &text)
            let string = String(values: Array(text[range]))
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(string, forType: .string)
            return
          }
        }
        
        // command + V
        if Input.keysDown.contains(.keyV) {
          if let string = NSPasteboard.general.string(forType: .string) {
            let charCodes = string.uint32
            
            if !self.textSelection.isEmpty {
              let range = self.getSelectedTextRange(text: &text)
              text.replaceSubrange(range, with: charCodes)
              self.setColumn(UInt32(range.lowerBound + charCodes.count + 1), text: &text, font: font, fontSize: fontSize)
              self.textSelection = TextSelection()
            } else {
              text.insert(contentsOf: charCodes, at: Int(self.column) - 1)
              self.setColumn(self.column + UInt32(charCodes.count), text: &text, font: font, fontSize: fontSize)
            }
            return
          }
        }
        
        if Input.keysDown.contains(.keyX) {
          if !self.textSelection.isEmpty {
            let range = self.getSelectedTextRange(text: &text)
            let string = String(values: Array(text[range]))
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(string, forType: .string)
            
            text.removeSubrange(range)
            self.setColumn(UInt32(range.lowerBound + 1), text: &text, font: font, fontSize: fontSize)
            self.textSelection = TextSelection()
            return
          }
        }
        
        if Input.keysDown.contains(.keyA) {
          self.textSelection = TextSelection(start: (1, 1), end: (1, UInt32(text.count + 1)))
          return
        }
        
        return
      }
    }
    
    switch charCode {
    case Input.returnOrEnterKey:
      break
    case Input.leftArrow:
      self.setColumn(self.column - 1, text: &text, font: font, fontSize: fontSize)
      break
    case Input.rightArrow:
      self.setColumn(self.column + 1, text: &text, font: font, fontSize: fontSize)
      break
    case Input.topArrow:
      break
    case Input.downArrow:
      break
    case Input.deleteKey:
      if !self.textSelection.isEmpty {
        let range = self.getSelectedTextRange(text: &text)
        text.removeSubrange(range)
        self.setColumn(UInt32(range.lowerBound + 1), text: &text, font: font, fontSize: fontSize)
        self.textSelection = TextSelection()
      } else {
        let index = Int(self.column) - 2
        if index >= 0 && index < text.count {
          text.remove(at: index)
          self.setColumn(self.column - 1, text: &text, font: font, fontSize: fontSize)
        }
      }
      break
    default:
      if !self.textSelection.isEmpty {
        let range = self.getSelectedTextRange(text: &text)
        text.replaceSubrange(range, with: [charCode])
        self.setColumn(UInt32(range.lowerBound + 2), text: &text, font: font, fontSize: fontSize)
        self.textSelection = TextSelection()
      } else {
        text.insert(charCode, at: Int(self.column) - 1)
        self.setColumn(self.column + 1, text: &text, font: font, fontSize: fontSize)
      }
    }
  }
}

let outlineSize = Float(2)

@discardableResult
func textField(
  position: float2,
  state: inout TextFieldState,
  width: Float = 140,
  string: inout [UInt32],
  font: Font = defaultFont,
  fontSize: Float = defaultFontSize
) -> Rect {
  if state.selected {
    Input.charactersCode {
      state.handleCharacter(charCode: $0, text: &string, font: font, fontSize: fontSize)
    }
  }
  
  let inset = Inset(vertical: 4, horizontal: 8)
  var strBounds = calcBoundsForString(
    &string,
    fontSize: fontSize,
    font: font
  )
  
  let textFieldBounds = Rect(
    position: position,
    size: float2(width, strBounds.height)
  ).inflate(by: inset)
  
  if Input.mouseDown {
    // reset field selection
    state.selected = false
    // reset text selection
    state.textSelection = TextSelection(start: (1, 1), end: (1, 1))
  }
  let hit = textFieldBounds
    .mouseDown {
      state.selected = true
      Time.resetCursorBlinking()
    }
  
  // handle cursor icon
  state.trackArea.hit = hit.hit
  state.trackArea.mouseEnter {
    NSCursor.iBeam.push()
  }
  state.trackArea.mouseExit {
    NSCursor.pop()
  }
  
  let borderRadius = float4(repeating: 0.25)
  
  // draw outline when field is selected
  if state.selected {
    var outlineRect = textFieldBounds
    outlineRect.position -= outlineSize
    outlineRect.size += outlineSize * 2
    
    rect(outlineRect, color: .blue, borderRadius: borderRadius)
    
    // handle scroll offset to cursor
    Input.charactersCode { charCode in
      let visibleArea = textFieldBounds.deflate(by: inset)
      
      let direction = charCode == Input.leftArrow ? -1 : 1
      state.calcScrollOffsetToCursor(visibleArea: visibleArea.size, direction: direction)
    }
  }
  
  rect(textFieldBounds, color: .gray, borderRadius: borderRadius)
  
  var scrollState = state.scroll
  let textFieldScrollBounds = textFieldBounds.deflate(by: inset)
  
  scroll(
    state: &scrollState,
    textFieldScrollBounds,
    contentSize: strBounds.size + float2(1, 0),
    showScrollBars: false
  ) { position, scrollState in
    strBounds.position += position
    
    // calc column index for cursor on mouse down
    if state.selected {
      // handle double click (select word)
      if Input.doubleClick {
        let localMousePosition = max(Input.mousePosition - strBounds.position, float2())
        let rowAndCol = findRowAndCol(
          from: localMousePosition,
          in: Rect(size: strBounds.size),
          &string,
          fontSize: fontSize,
          font: font
        )
        var start: (UInt32, UInt32) = rowAndCol
        while true {
          start.1 = start.1 == 1 ? 1 : start.1 - 1
          
          if start.1 == 1 {
            break
          }
          let charCode = string[Int(start.1) - 1]
          if charCode == Input.space {
            start.1 += 1
            break
          }
        }
        
        var end: (UInt32, UInt32) = rowAndCol
        while true {
          if end.1 > string.count {
            break
          }
          let charCode = string[Int(end.1).clamped(to: 1...string.count) - 1]
          if charCode == Input.space {
            break
          }
          
          end.1 += 1
        }
        
        state.textSelection = TextSelection(start: start, end: end)
      }
      
      // calc cursor position
      strBounds.mouseDown {
        let localMousePosition = max(Input.mousePosition - strBounds.position, float2())
        let rowAndCol = findRowAndCol(
          from: localMousePosition,
          in: Rect(size: strBounds.size),
          &string,
          fontSize: fontSize,
          font: font
        )
        state.setColumn(rowAndCol.1, text: &string, font: font, fontSize: fontSize)
      }
      
      // find start and end for selected text
      if Input.drag {
        let value = Input.dragGesture
        
        let localMousePosition = max(value.start - strBounds.position + scrollState.dragScrollOffset, float2())
        var start = findRowAndCol(
          from: localMousePosition,
          in: Rect(size: strBounds.size),
          &string,
          fontSize: fontSize,
          font: font
        )
        
        let localMousePositionEnd = max(value.location - strBounds.position, float2())
        var end = findRowAndCol(
          from: localMousePositionEnd,
          in: Rect(size: strBounds.size),
          &string,
          fontSize: fontSize,
          font: font
        )
        
        if start.0 > end.0 {
          let temp = start.0
          start.0 = end.0
          end.0 = temp
        }
        
        if start.0 == end.0 && start.1 > end.1 {
          let temp = start.1
          start.1 = end.1
          end.1 = temp
        }
        
        state.textSelection = TextSelection(start: start, end: end)
      }
    }
    
    // draw text selection
    let isTextSelected = !state.textSelection.isEmpty
    if isTextSelected {
      // MARK: dont recalc text selection every frame
      textSelection(
        &string,
        textSelection: &state.textSelection,
        position: position,
        fontSize: fontSize,
        font: font
      )
    }
    
    // draw text
    text(position: position, color: .white, text: &string)
    
    // draw text field cursor
    if state.selected && Time.cursorSinBlinking >= 0 && !isTextSelected {
      let lineHeight: Float = calcLineHeight(from: fontSize)
      rect(Rect(position: position + state.cursorOffset, size: float2(1, lineHeight)), color: .white)
    }
  }
  state.scroll = scrollState
  
  return textFieldBounds
}
