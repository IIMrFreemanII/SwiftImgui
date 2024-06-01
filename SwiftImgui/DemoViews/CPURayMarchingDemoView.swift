//
//  CPURayMarchingDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 01.06.2024.
//

import Foundation
import MetalKit

class Canvas {
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

class CPURayMarchingDemoView : ViewRenderer {
  var canvas: Canvas!
  var size = int2(256, 256)
  
  func update() {
    self.canvas.forEachPixel { ctx in
      let uv = ctx.uv
      let bgColor = float4(0, 0, 0, 1)
      let circleColor = float4(1, 1, 1, 1)
      var color = bgColor
      
      let radius = Float(0.5)
      
      let dist = sdCircle(uv, radius)
      color = mix(color, circleColor, t: 1.0 - step(dist, edge: 0))
      
      return color.toUChar4()
    }
  }
  
  override func start() {
    self.canvas = Canvas(uchar4(0, 100, 0, 255), self.size)
    self.update()
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    Input.keyDown(.spacebar) {
      self.update()
    }
    
    ui(in: view) { r in
      image(Rect(position: float2(), size: float2(800, 800)), texture: self.canvas.texture)
    }
  }
}
