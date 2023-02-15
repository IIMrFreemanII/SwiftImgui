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
    _ = Rect(position: Input.windowPosition, size: Input.windowSize)
    
    startFrame()
    
    let mousePosition = Input.mousePosition
    
    var rect1 = Rect(position: float2(300, 300), size: float2(100, 100))
    let point1 = closestPointToSDBox(point: mousePosition, rect: &rect1)
    let dist = sdBox(point: mousePosition, rect: &rect1)
    
    rect(rect1, color: .red)
    line(mousePosition, point1, .black)
    circle(position: mousePosition, radius: dist, borderSize: 0.01, color: .black)
    
    endFrame()
    
    drawData(at: view)
  }
}
