//
//  TextFieldDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

import MetalKit

class TextFieldDemoView : ViewRenderer {
  lazy var textFieldStates = [
    TextFieldState(text: "Hello q world! sadf".uint32)
  ]
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    
    startFrame()
    
    clip(rect: windowRect) { r in
      textField(position: r.position + float2(repeating: 100), state: &textFieldStates[0])
    }
    
    endFrame()
    
    drawData(at: view)
  }
}
