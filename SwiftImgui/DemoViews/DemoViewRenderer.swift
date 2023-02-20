//
//  DemoViewRenderer.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import MetalKit

class DemoViewRenderer : ViewRenderer {
  override func start() {
    print("size: \(MemoryLayout<RectProps>.size)")
    print("stride: \(MemoryLayout<RectProps>.stride)")
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    _ = Rect(position: Input.windowPosition, size: Input.windowSize)
    
    startFrame()
    
//    let mousePosition = Input.mousePosition
    
    var rect1 = Rect(position: float2(300, 300), size: float2(100, 100))
//    let point1 = closestPointToSDBox(point: mousePosition, rect: &rect1)
//    let dist = sdBox(point: mousePosition, rect: &rect1)
//
    let red = UInt8(remap(sin(Time.time * 2), float2(-1, 1), float2(0, 255)))
    let green = UInt8(remap(sin(Time.time * 1.5), float2(-1, 1), float2(0, 255)))
    let blue = UInt8(remap(sin(Time.time * 3), float2(-1, 1), float2(0, 255)))
    let crispness = UInt8(remap(sin(Time.time), float2(-1, 1), float2(0, 255)))
    let borderRadius = uchar4(repeating: UInt8(remap(sin(Time.time), float2(-1, 1), float2(0, 100))))
    rect(rect1, style: RectStyle(color: Color(red, green, blue, 255), borderRadius: borderRadius, crispness: crispness))
//    line(mousePosition, point1, .black)
//    circle(position: mousePosition, radius: dist, borderSize: 0.01, color: .black)
    
    endFrame()
    
    drawData(at: view)
  }
}
