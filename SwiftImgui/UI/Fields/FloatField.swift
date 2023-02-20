//
//  NumberField.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 17.02.2023.
//

import Foundation

struct FloatFieldState {
  var base = TextFieldState()
  var string = Ref(value: String(Float(0)).uint32)
  var value: Float = 0
}

func floatField(
  position: float2,
  state: inout FloatFieldState,
  value: inout Float,
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
    if let temp = Float(String(values: state.string.value)) {
      value = temp
      state.base.error = false
    } else {
      state.base.error = true
    }
  }
  
  return result
}
