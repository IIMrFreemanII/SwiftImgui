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
      self.strings.append("\(i). Hello world! asdf ads asdf sadf sdf as fa dafs faf adfasf".uint32)
      self.textFieldStates.append(TextFieldState())
    }
  }
  var textFieldStates: [TextFieldState] = []
  var strings: [[UInt32]] = []
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    
    startFrame()
    
    clip(rect: windowRect) { r in
      vStack(position: r.position + float2(10, 10), spacing: 6) { c, t in
        for y in 0..<1 {
          t = hStack(position: c.position, spacing: 6) { c, t in
            for x in 0..<1 {
              let index = x + y * 10
              t = textField(position: c.position, state: &textFieldStates[index], width: 300, string: &strings[index])
              c.offset(by: &t)
            }
          }
          c.offset(by: &t)
        }
      }
    }
    
    endFrame()
    
    drawData(at: view)
  }
}
