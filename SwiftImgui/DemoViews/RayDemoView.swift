//
//  RayDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.05.2024.
//

import MetalKit
import Foundation

//struct GridItem {
//  var color: Color = .lightGray
//}
//
//var angle = Float(35).degreesToRadians

//class RayDemoView : ViewRenderer {
//  var gridSize = int2(300, 300)
//  var spacing = Float(0)
//  var itemSize = Float(1)
//  var gridItems: [GridItem] = []
//  var rayPosition = float2(10, 10)
//  var direction = float2(cos(angle), sin(angle))
//  
//  func keepInsideView() {
//    if self.rayPosition.x <= 0 {
//      self.rayPosition.x = 0
//      self.direction.x *= -1
//    }
//    
//    if self.rayPosition.x >= Float(self.gridSize.x) {
//      self.rayPosition.x = Float(self.gridSize.x)
//      self.direction.x *= -1
//    }
//    
//    if self.rayPosition.y <= 0 {
//      self.rayPosition.y = 0
//      self.direction.y *= -1
//    }
//    
//    if self.rayPosition.y >= Float(self.gridSize.y) {
//      self.rayPosition.y = Float(self.gridSize.y)
//      self.direction.y *= -1
//    }
//  }
//  
//  func colorPixel(at pos: float2) {
//    if pos.x > Float(gridSize.x - 1) || pos.x < 0 || pos.y > Float(gridSize.y - 1) || pos.y < 0 {
//      return
//    }
//    
//    let index = from2DTo1DArray(int2(Int(floor(pos.x)), Int(floor(pos.y))), self.gridSize)
//    var item = self.gridItems[index]
//    item.color = .red
//    self.gridItems[index] = item
//  }
//  
//  override func start() {
//    self.gridItems = Array(repeating: GridItem(), count: self.gridSize.x * self.gridSize.y)
//    self.colorPixel(at: self.rayPosition)
//  }
//  
//  override func draw(in view: MTKView) {
//    super.draw(in: view)
//    
//    let deltaAngle = Input.mouseScroll.y * Time.deltaTime
//    let deltaDir = float2(self.direction.x * cos(deltaAngle) - self.direction.y * sin(deltaAngle), self.direction.x * sin(deltaAngle) + self.direction.y * cos(deltaAngle))
//    self.direction = deltaDir
//    
//    let nextPos = self.rayPosition + self.direction * Time.deltaTime * 500
//    let dist = length(nextPos - self.rayPosition)
//    if dist > 1 {
//      for scalar in stride(from: Float(0), through: dist, by: 1) {
//        self.colorPixel(at: self.rayPosition + self.direction * scalar)
//      }
//    } else {
//      self.colorPixel(at: nextPos)
//    }
//    
//    self.rayPosition = nextPos
//    self.keepInsideView()
//    
//    
////    Input.keyDown(.keyW) {
////      self.setRayPos((self.rayPosition &+ int2(0, -1)).clamped(lowerBound: int2(0, 0), upperBound: self.gridSize))
////    }
////    
////    Input.keyDown(.keyS) {
////      self.setRayPos((self.rayPosition &+ int2(0, 1)).clamped(lowerBound: int2(0, 0), upperBound: self.gridSize))
////    }
////    
////    Input.keyDown(.keyA) {
////      self.setRayPos((self.rayPosition &+ int2(-1, 0)).clamped(lowerBound: int2(0, 0), upperBound: self.gridSize))
////    }
////    
////    Input.keyDown(.keyD) {
////      self.setRayPos((self.rayPosition &+ int2(1, 0)).clamped(lowerBound: int2(0, 0), upperBound: self.gridSize))
////    }
//    
//    ui(in: view) { r in
//      for y in 0..<self.gridSize.y {
//        for x in 0..<self.gridSize.x {
//          let index = from2DTo1DArray(int2(x, y), self.gridSize)
//          let item = self.gridItems[index]
//          
//          rect(Rect(position: float2(Float(x) * (self.itemSize + self.spacing), Float(y) * (self.itemSize + self.spacing)), size: float2(self.itemSize, self.itemSize)), style: RectStyle(color: item.color))
//          
//          self.gridItems[index] = item
//        }
//      }
//    }
//  }
//}

// -----------------------------------------------------------------------

private struct CircleShape {
  var position = float2()
  var radius = Float(1)
}

private struct GridItem {
  var shapes: [CircleShape] = []
  var color: Color = .black
}

class RayDemoView : ViewRenderer {
  var gridSize = int2(5, 5)
  var spacing = Float(0)
  var itemSize = Float(100)
  private var gridItems: [GridItem] = []
  private var circleShape = CircleShape(position: float2(0, 0), radius: 50)
//  var rayPosition = float2(10, 10)
//  var direction = float2(cos(angle), sin(angle))
  
//  func keepInsideView() {
//    if self.rayPosition.x <= 0 {
//      self.rayPosition.x = 0
//      self.direction.x *= -1
//    }
//    
//    if self.rayPosition.x >= Float(self.gridSize.x) {
//      self.rayPosition.x = Float(self.gridSize.x)
//      self.direction.x *= -1
//    }
//    
//    if self.rayPosition.y <= 0 {
//      self.rayPosition.y = 0
//      self.direction.y *= -1
//    }
//    
//    if self.rayPosition.y >= Float(self.gridSize.y) {
//      self.rayPosition.y = Float(self.gridSize.y)
//      self.direction.y *= -1
//    }
//  }
  
//  func colorPixel(at pos: float2) {
//    if pos.x > Float(gridSize.x - 1) || pos.x < 0 || pos.y > Float(gridSize.y - 1) || pos.y < 0 {
//      return
//    }
//    
//    let index = from2DTo1DArray(int2(Int(floor(pos.x)), Int(floor(pos.y))), self.gridSize)
//    var item = self.gridItems[index]
//    item.color = .red
//    self.gridItems[index] = item
//  }
  
  func initGrid() {
    self.gridItems = Array(repeating: GridItem(), count: self.gridSize.x * self.gridSize.y)
//    forEachPixel(self.gridSize) { ctx in
//      var pixel = float2(Float(ctx.pixel.x), Float(ctx.pixel.y)) * self.itemSize
//      print(pixel)
//      let dist = sdCircle(pixel - self.circleShape.position, self.circleShape.radius)
//      let result = step(dist, edge: 0)
//      
//      if result == 0 {
////        print(dist)
//        let index = from2DTo1DArray(ctx.pixel, self.gridSize)
//        var item = self.gridItems[index]
//        
//        item.color = .red
//
//        self.gridItems[index] = item
//      }
//    }
  }
  
  override func start() {
    self.initGrid()
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    Input.leftMouseDown {
      self.circleShape.position = Input.mousePosition
      self.initGrid()
    }
    
    ui(in: view) { r in
      for y in 0..<self.gridSize.y {
        for x in 0..<self.gridSize.x {
          let index = from2DTo1DArray(int2(x, y), self.gridSize)
          let item = self.gridItems[index]
          
          var tempRect = Rect(position: float2(Float(x) * (self.itemSize + self.spacing), Float(y) * (self.itemSize + self.spacing)), size: float2(self.itemSize, self.itemSize))
          rect(tempRect, style: RectStyle(color: item.color, crispness: 0))
          tempRect = tempRect.deflate(by: .init(all: 1))
          rect(tempRect, style: RectStyle(color: .white, crispness: 0))
          
          circle(position: self.circleShape.position, radius: self.circleShape.radius, borderSize: Float(1), color: .red)
          
          self.gridItems[index] = item
        }
      }
    }
  }
}
