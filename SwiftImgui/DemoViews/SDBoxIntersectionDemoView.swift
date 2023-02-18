//
//  SDBoxIntersection.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

import MetalKit

class SDBoxIntersectionDemoView : ViewRenderer {
  override func draw(in view: MTKView) {
    super.draw(in: view)
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    startFrame()
    
    clip(rect: windowRect) { _ in
      let mousePosition = Input.mousePosition
      
      var rect1 = Rect(position: float2(300, 300), size: float2(100, 100))
      var rect2 = Rect(position: mousePosition, size: float2(100, 100))
      
      let point1 = closestPointToSDBox(point: rect2.center, rect: &rect1)
      let point2 = closestPointToSDBox(point: point1, rect: &rect2)
      
      let intersect = (point1 - point2) == float2()
      let color: float4 = intersect ? .red : .green
      
      rect(rect1, style: RectStyle(color: color))
      rect(rect2, style: RectStyle(color: color))
      
      line(point1, point2, .black)
    }
    
    endFrame()
    
    drawData(at: view)
  }
}
