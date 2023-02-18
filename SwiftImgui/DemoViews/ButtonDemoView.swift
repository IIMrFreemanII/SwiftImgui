//
//  ButtonDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

import MetalKit

class ButtonDemoView : ViewRenderer {
  var str = "Click".uint32
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    
    startFrame()
    
    clip(rect: windowRect) { r in
      let result = button(r.position + float2(100, 100), &str, style: ButtonStyle())
      result.hit.mouseDown {
        print("click!")
      }
    }
    
    endFrame()
    
    drawData(at: view)
  }
}
