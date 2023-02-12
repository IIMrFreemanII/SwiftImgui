//
//  DemoViewRenderer.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import MetalKit

class DemoViewRenderer : ViewRenderer {
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    
    startFrame()
    
    endFrame()
    
    drawData(at: view)
  }
}
