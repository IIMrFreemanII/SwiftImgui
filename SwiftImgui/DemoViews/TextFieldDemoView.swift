//
//  TextFieldDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

import MetalKit

class TextFieldDemoView : ViewRenderer {
  var app = UIApp()
  //  override func start() {
  //    for i in 0..<25 {
  //      //      self.strings.append(Ref(value: "(\(i), \(i), \(i))".uint32))
  //      self.floats.append(Float(i))
  //      self.floats1.append(Float(i))
  //      //      self.ints.append(Int(i))
  //      //      self.textFieldStates.append(TextFieldState())
  //      self.floatFieldStates.append(FloatFieldState())
  //      self.floatFieldStates1.append(FloatFieldState())
  //      //      self.intFieldStates.append(IntFieldState())
  //    }
  //  }
  //  var textFieldStates: [TextFieldState] = []
  //  var floatFieldStates: [FloatFieldState] = []
  //  var floatFieldStates1: [FloatFieldState] = []
  //  var intFieldStates: [IntFieldState] = []
  //  var strings: [Ref<[UInt32]>] = []
  //  var floats: [Float] = []
  //  var floats1: [Float] = []
  //  var ints: [Int] = []
  //  var scrollStates = [ScrollState(), ScrollState()]
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    ui(in: view) { r in
      app.update(r: r)
      //      scroll(state: &scrollStates[0], Rect(size: float2(200, 200)), contentSize: float2(500, 500), style: ScrollStyle(borderRadius: float4(repeating: 0))) { p, state in
      //        vStack(position: p, spacing: 6) { c, t in
      //          for y in 0..<5 {
      //            t = hStack(position: c.position, spacing: 6) { c, t in
      //              for x in 0..<5 {
      //                let index = x + y * 5
      //                var result = floatField(
      //                  position: c.position,
      //                  state: &floatFieldStates[index],
      //                  value: &floats[index]
      //                )
      //                c.offset(by: &result.rect)
      //              }
      //            }
      //            c.offset(by: &t)
      //          }
      //        }
    }
    
    //      scroll(state: &scrollStates[1], Rect(position: float2(300, 0), size: float2(200, 200)), contentSize: float2(500, 500)) { p, state in
    //        vStack(position: p, spacing: 6) { c, t in
    //          for y in 0..<5 {
    //            t = hStack(position: c.position, spacing: 6) { c, t in
    //              for x in 0..<5 {
    //                let index = x + y * 5
    //                var result = floatField(
    //                  position: c.position,
    //                  state: &floatFieldStates1[index],
    //                  value: &floats1[index]
    //                )
    //                c.offset(by: &result.rect)
    //              }
    //            }
    //            c.offset(by: &t)
    //          }
    //        }
    //      }
    
  }
}
