//
//  WavesView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 31.03.2024.
//

import MetalKit
import Foundation

class WavesView : ViewRenderer {
  var rects: [Rect] = []
  var count = Int(150)
  var size = float2(5, 5)
  var offset = float2(150, 400)
  var spacing = Float(1)
  
  func update() {
//    for i in 0..<self.count {
//      var rect = rects[i]
//      
//      rect.position.y = sin(10)
//
//      rects[i] = rect
//    }
  }
  
  override func start() {
    self.rects = Array(repeating: Rect(), count: self.count)
    for i in 0..<self.count {
      self.rects[i] = Rect(position: self.offset + float2(self.size.x + self.spacing, 0) * Float(i), size: self.size)
    }
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    self.update()
    
    ui(in: view) { r in
      for (i, item) in self.rects.enumerated() {
        rect(Rect(position: item.position + float2(0, sin(Time.time + Float(i) * 0.1) * 100), size: item.size), style: RectStyle(color: .black))
      }
    }
  }
}
