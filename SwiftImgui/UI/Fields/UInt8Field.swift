//
//  Int8Field.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 18.02.2023.
//

import Foundation

struct UInt8FieldState {
  var base = TextFieldState()
  var string = Ref(value: String(UInt8(0)).uint32)
  var value: UInt8 = 0
}

@discardableResult
func uint8Field(
  position: float2,
  state: inout UInt8FieldState,
  value: inout UInt8,
  style: TextFieldStyle
) -> TextFieldResult {
  if value != state.value {
    state.value = value
    state.string.value = String(value).uint32
  }
  
  let result = textField(
    position: position,
    state: &state.base,
    string: state.string,
    style: style
  )
  if result.changed {
    if let temp = UInt8(String(values: state.string.value)) {
      value = temp
      state.base.error = false
    } else {
      state.base.error = true
    }
  }
  if !state.base.selected {
    result.hit.mouseOver {
      Input.scrollCounter { count in
        value += UInt8(count.y)
      }
    }
  }
  
  return result
}
