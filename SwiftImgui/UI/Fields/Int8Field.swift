//
//  Int8Field.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 18.02.2023.
//

import Foundation

struct Int8FieldState {
  var base = TextFieldState()
  var string: [UInt32] = String(Int8(0)).uint32
  var value: Int8 = 0
}

func int8Field(
  position: float2,
  state: inout Int8FieldState,
  value: inout Int8,
  style: TextFieldStyle
) -> TextFieldResult {
  if value != state.value {
    state.value = value
    state.string = String(value).uint32
  }
  
  let result = textField(
    position: position,
    state: &state.base,
    string: &state.string,
    style: style
  )
  if result.changed {
    if let temp = Int8(String(values: state.string)) {
      value = temp
      state.base.error = false
    } else {
      state.base.error = true
    }
  }
  
  return result
}
