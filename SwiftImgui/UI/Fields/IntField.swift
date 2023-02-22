//
//  IntField.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 18.02.2023.
//

struct IntFieldState {
  var base = TextFieldState()
  var string = Ref(value: String(Int(0)).uint32)
  var value: Int = 0
}

@discardableResult
func intField(
  position: float2,
  state: inout IntFieldState,
  value: inout Int,
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
    if let temp = Int(String(values: state.string.value)) {
      value = temp
      state.base.error = false
    } else {
      state.base.error = true
    }
  }
  if !state.base.focused {
    result.hit.mouseOver {
      Input.scrollCounter { count in
        value += Int(count.y)
      }
    }
  }
  
  return result
}
