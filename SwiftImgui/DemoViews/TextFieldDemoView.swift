//
//  TextFieldDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

import MetalKit

class TextFieldDemoView : ViewRenderer {
  override func start() {
    for i in 0..<100 {
      self.strings.append("(\(i), \(i), \(i))".uint32)
      self.floats.append(Float(i))
      self.ints.append(Int(i))
      self.textFieldStates.append(TextFieldState())
      self.floatFieldStates.append(FloatFieldState())
      self.intFieldStates.append(IntFieldState())
    }
  }
  var textFieldStates: [TextFieldState] = []
  var floatFieldStates: [FloatFieldState] = []
  var intFieldStates: [IntFieldState] = []
  var strings: [[UInt32]] = []
  var floats: [Float] = []
  var ints: [Int] = []
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    
    startFrame()
    
    clip(rect: windowRect) { r in
      //      benchmark(title: "textField") {
      vStack(position: r.position + float2(10, 10), spacing: 6) { c, t in
        for y in 0..<10 {
          t = hStack(position: c.position, spacing: 6) { c, t in
            for x in 0..<10 {
              let index = x + y * 10
//              var result = intField(
//                position: c.position,
//                state: &intFieldStates[index],
//                value: &ints[index],
//                style: intFieldStates[index].base.error ? Theme.active.textFieldError : Theme.active.textField
//              )
//              if result.changed {
//                print(ints[index])
//              }
              var result = floatField(
                position: c.position,
                state: &floatFieldStates[index],
                value: &floats[index],
                style: floatFieldStates[index].base.error ? Theme.active.textFieldError : Theme.active.textField
              )
              if result.changed {
                print(floats[index])
              }
              //              var result = textField(position: c.position, state: &textFieldStates[index], string: &strings[index])
              //              if result.changed {
              //                print(strings[index])
              //              }
              c.offset(by: &result.rect)
            }
          }
          c.offset(by: &t)
        }
      }
      //      }
    }
    
    endFrame()
    
    drawData(at: view)
  }
}
