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

@discardableResult
func floatField(
  position: float2,
  state: inout FloatFieldState,
  value: inout Float,
  incrementBy: Float = 0.1,
  style: TextFieldStyle = Theme.active.textField,
  styleFocused: TextFieldStyle = Theme.active.textFieldFocused,
  styleError: TextFieldStyle = Theme.active.textFieldError,
  styleMouseOver: TextFieldStyle = Theme.active.numberFieldMouseOver
) -> TextFieldResult {
  if value != state.value {
    state.value = value
    state.string.value = String(value).uint32
  }
  
  let result = textField(
    position: position,
    state: &state.base,
    string: state.string,
    style: style,
    styleFocused: styleFocused,
    styleError: styleError,
    styleMouseOver: styleMouseOver
  )
  if result.changed {
    if let temp = Float(String(values: state.string.value)) {
      value = temp
      state.base.error = false
    } else {
      state.base.error = true
    }
  }
  if !state.base.focused {
    result.hit.mouseOver {
      Input.scrollCounter { count in
        let first = NSNumber(value: value).decimalValue
        let second = NSNumber(value: count.y * incrementBy).decimalValue
        let result = first + second
        value = NSDecimalNumber(decimal: result).floatValue
      }
    }
  }
  
  return result
}
