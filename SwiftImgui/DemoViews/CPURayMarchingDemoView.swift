//
//  CPURayMarchingDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 01.06.2024.
//

import Foundation
import MetalKit

private class Canvas {
  struct Context {
    var size = int2()
    var uv = float2()
    var pixelCoord = int2()
  }
  
  var texture: MTLTexture! = nil
  var colorData: [uchar4] = []
  var size: int2
  
  init(_ color: uchar4, _ size: int2) {
    self.colorData = Array(repeating: color, count: size.x * size.y)
    self.size = size
    self.texture = TextureController.makeTexture(&self.colorData, size)
  }

  func forEachPixel(_ cb: (Context) -> uchar4) {
    for y in 0..<self.size.y {
      for x in 0..<self.size.x {
        var uv = float2(Float(x), Float(y)) / Float(self.size.y)
        uv = uv * 2 - 1
        
        let color = cb(Context(size: self.size, uv: uv, pixelCoord: int2(x, y)))
        
        let index = from2DTo1DArray(int2(x, y), self.size)
        self.colorData[index] = color
      }
    }
    
    let region = MTLRegionMake2D(0, 0, size.x, size.y)
    self.texture.replace(region: region, mipmapLevel: 0, withBytes: &self.colorData, bytesPerRow: size.x * 4)
  }
}

private struct CircleShape {
  var position = float2()
  var radius = Float(1)
  var color = float4(1, 1, 1, 1)
  
  var boundingBox: BoundingBox {
    return BoundingBox(center: position, radius: radius)
  }
}

private class Grid {
  class Item {
    // shapes ids, currently supports only CircleShape
    var shapes: [Int] = []
  }
  
  var size: int2
  var itemSize: Float
  var items: [Item] = []
  var bounds: BoundingBox
  
  init(size: SIMD2<Int> = int2(10, 10), itemSize: Float = Float(1)) {
    self.size = size
    self.itemSize = itemSize
    self.items = Array(repeating: Item(), count: size.x * size.y)
    self.bounds = BoundingBox(center: float2(), size: float2(Float(size.x), Float(size.y)) * itemSize)
  }
  
  func reset() {
    self.items = Array(repeating: Item(), count: size.x * size.y)
  }
  
  func mapBoundingBoxToGrid(_ box: BoundingBox, _ itemIndex: Int) {
    for y in stride(from: box.bottomRight.y, through: box.topLeft.y, by: box.height / 2) {
      let yIndex = floor(remap(y, float2(self.bounds.bottom, self.bounds.top), float2(0, Float(self.size.y))))
      for x in stride(from: box.topLeft.x, through: box.bottomRight.x, by: box.width / 2) {
        let xIndex = floor(remap(x, float2(self.bounds.left, self.bounds.right), float2(0, Float(self.size.x))))
        let index = from2DTo1DArray(SIMD2<Int>(Int(xIndex), Int(yIndex)), self.size)
        self.items[index].shapes.append(itemIndex)
      }
    }
  }
  
  func updateGrid(with shape: CircleShape, _ itemIndex: Int) {
    self.mapBoundingBoxToGrid(shape.boundingBox, itemIndex)
  }
}

class CPURayMarchingDemoView : ViewRenderer {
  private var canvas: Canvas!
  var canvasSize = int2(256, 256)
  private var grid: Grid!
  private var shapes: [CircleShape] = []
  
  func update() {
    benchmark(title: "Update") {
      self.canvas.forEachPixel { ctx in
        let uv = ctx.uv
        let bgColor = float4(0, 0, 0, 1)
        
        let gridIndex = fromPixelCoordToGridIndex(uv, self.grid.size.toFloat())
        let itemIndex = from2DTo1DArray(gridIndex, grid.size)
        let shapeIndices = self.grid.items[itemIndex].shapes
        
        var color = bgColor
        
        for i in shapeIndices {
          let shape = self.shapes[i]
          
          let dist = sdCircle(uv - shape.position, shape.radius)
          color = mix(color, shape.color, t: 1.0 - step(dist, edge: 0))
        }
        
        return color.toUChar()
      }
    }
  }
  
  override func start() {
    self.grid = Grid()
    self.canvas = Canvas(uchar4(0, 0, 0, 255), self.canvasSize)
    
    self.shapes.append(CircleShape(position: float2(-0.5, 0), radius: Float(0.2), color: float4(1, 0, 0, 1)))
    self.shapes.append(CircleShape(position: float2(0, 0), radius: Float(0.2), color: float4(0, 1, 0, 1)))
    self.shapes.append(CircleShape(position: float2(0.5, 0), radius: Float(0.2), color: float4(0, 0, 1, 1)))
    
    for i in 0..<self.shapes.count {
      let shape = self.shapes[i]
      self.grid.updateGrid(with: shape, i)
    }
    
    self.update()
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    Input.keyDown(.leftArrow) {
      var shape = self.shapes[1]
      
      shape.position += float2(-0.1, 0)
      
      self.shapes[1] = shape
      
      self.update()
    }
    
    Input.keyDown(.rightArrow) {
      var shape = self.shapes[1]
      
      shape.position += float2(0.1, 0)
      
      self.shapes[1] = shape
      
      self.update()
    }
    
    Input.keyDown(.spacebar) {
      self.update()
    }
    
    ui(in: view) { r in
      image(Rect(position: float2(), size: float2(800, 800)), texture: self.canvas.texture)
    }
  }
}
