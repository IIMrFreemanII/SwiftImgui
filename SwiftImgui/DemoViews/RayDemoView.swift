//
//  RayDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.05.2024.
//

import MetalKit
import Foundation

struct GridItem {
  var color: Color = .lightGray
}

class RayDemoView : ViewRenderer {
  var gridSize = int2(100, 100)
  var spacing = Float(0)
  var itemSize = Float(6)
  var gridItems: [GridItem] = []
  var rayPosition = int2(10, 10)
  
  func setRayPos(_ pos: int2) {
    self.rayPosition = pos
    let index = from2DTo1DArray(int2(pos.x, pos.y), self.gridSize)
    var item = self.gridItems[index]
    item.color = .red
    self.gridItems[index] = item
  }
  
  override func start() {
    self.gridItems = Array(repeating: GridItem(), count: self.gridSize.x * self.gridSize.y)
    self.setRayPos(self.rayPosition)
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    Input.keyDown(.keyW) {
      self.setRayPos((self.rayPosition &+ int2(0, -1)).clamped(lowerBound: int2(0, 0), upperBound: self.gridSize))
    }
    
    Input.keyDown(.keyS) {
      self.setRayPos((self.rayPosition &+ int2(0, 1)).clamped(lowerBound: int2(0, 0), upperBound: self.gridSize))
    }
    
    Input.keyDown(.keyA) {
      self.setRayPos((self.rayPosition &+ int2(-1, 0)).clamped(lowerBound: int2(0, 0), upperBound: self.gridSize))
    }
    
    Input.keyDown(.keyD) {
      self.setRayPos((self.rayPosition &+ int2(1, 0)).clamped(lowerBound: int2(0, 0), upperBound: self.gridSize))
    }
    
    ui(in: view) { r in
      for y in 0..<self.gridSize.y {
        for x in 0..<self.gridSize.x {
          let index = from2DTo1DArray(int2(x, y), self.gridSize)
          var item = self.gridItems[index]
          
          rect(Rect(position: float2(Float(x) * (self.itemSize + self.spacing), Float(y) * (self.itemSize + self.spacing)), size: float2(self.itemSize, self.itemSize)), style: RectStyle(color: item.color))
          
          self.gridItems[index] = item
        }
      }
    }
  }
}
