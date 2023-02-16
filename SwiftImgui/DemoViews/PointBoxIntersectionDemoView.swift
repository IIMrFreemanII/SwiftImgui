//
//  PointBoxIntersection.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 16.02.2023.
//

import MetalKit

class PointBoxIntersectionDemoView : ViewRenderer {
  var rect1 = Rect(position: float2(300, 300), size: float2(100, 100))
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    startFrame()
    
    clip(rect: windowRect) { _ in
      let mousePosition = Input.mousePosition
      
      rect1.position += dragDirection(point: mousePosition, rect: &rect1) * 0.1
      let point1 = closestPointToSDBox(point: mousePosition, rect: &rect1)
      
      let intersect = point1 - mousePosition == float2()
      let color: float4 = intersect ? .red : .green
      
      rect(rect1, color: color)
      
      line(point1, mousePosition, .black)
    }
    
    endFrame()
    
    drawData(at: view)
  }
}
