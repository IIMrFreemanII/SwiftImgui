//
//  UIApp.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 06.02.2024.
//

struct CustomFloatField {
  var floatFieldState = FloatFieldState()
  var label = "Label".uint32
  var value = Float(12)
  
  init() {
    
  }
  
  mutating func update(r: Rect) -> Rect {
    return hStack(position: r.position + float2(10, 10), spacing: 8) { c, t in
      var label = text(position: c.position, text: &label)
      c.offset(by: &label)
      var input = floatField(
        position: c.position,
        state: &floatFieldState,
        value: &value
      )
      c.offset(by: &input.rect)
    }
  }
}

struct UIApp {
  var textFieldStates: [TextFieldState] = []
  var floatFieldStates: [FloatFieldState] = []
  var floatFieldStates1: [FloatFieldState] = []
  var intFieldStates: [IntFieldState] = []
  var strings: [Ref<[UInt32]>] = []
  var floats: [Float] = []
  var floats1: [Float] = []
  var ints: [Int] = []
  var scrollStates = [ScrollState(), ScrollState()]
  var customFloatFields: [CustomFloatField] = []
  
  init() {
    print("init UIApp")
    for i in 0..<25 {
      //      self.strings.append(Ref(value: "(\(i), \(i), \(i))".uint32))
      self.floats.append(Float(i))
      self.floats1.append(Float(i))
      //      self.ints.append(Int(i))
      //      self.textFieldStates.append(TextFieldState())
      self.floatFieldStates.append(FloatFieldState())
      self.floatFieldStates1.append(FloatFieldState())
      self.customFloatFields.append(CustomFloatField())
      //      self.intFieldStates.append(IntFieldState())
    }
  }
  
  mutating func update(r: Rect) {
//    scroll(state: &scrollStates[0], Rect(size: float2(200, 200)), contentSize: float2(500, 500), style: ScrollStyle(borderRadius: float4(repeating: 0))) { p, state in
    vStack(position: r.position + float2(10, 10), spacing: 6) { c, t in
        for y in 0..<5 {
          t = hStack(position: c.position, spacing: 6) { c, t in
            for x in 0..<5 {
              let index = x + y * 5
//              var result = floatField(
//                position: c.position,
//                state: &floatFieldStates[index],
//                value: &floats[index]
//              )
              var result = customFloatFields[index].update(r: Rect(position: c.position, size: c.size))
              c.offset(by: &result)
            }
          }
          c.offset(by: &t)
        }
      }
    }
//  }
}
