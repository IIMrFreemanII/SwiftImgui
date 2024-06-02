//
//  CPURayMarchingDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 01.06.2024.
//

import Foundation
import MetalKit

private struct Ray {
  var position = float3()
  var direction: float3 = .forward
}

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
  var position = float3()
  var radius = Float(1)
  var color = float4(1, 1, 1, 1)
  
  var boundingBox: BoundingBox2D {
    return BoundingBox2D(center: float2(self.position.x, self.position.y), radius: radius)
  }
  
  var boundingBox3D: BoundingBox3D {
    return BoundingBox3D(center: self.position, radius: self.radius)
  }
}

private class Grid {
  class Item {
    // shapes ids, currently supports only CircleShape
    var shapes: [Int] = []
  }
  
  var size: int2
  var size3D: int3
  var itemSize: Float
  var items: [Item] = []
  var items3D: [Item] = []
  var bounds: BoundingBox2D
  var bounds3D: BoundingBox3D
  
  init(size: SIMD2<Int> = int2(10, 10), itemSize: Float = Float(1)) {
    self.size = size
    self.size3D = int3(2, 2, 2)
    self.itemSize = itemSize
    self.items = Array(repeating: Item(), count: self.size.x * self.size.y)
    self.items3D = Array(repeating: Item(), count: self.size3D.x * self.size3D.y * self.size3D.z)
    self.bounds = BoundingBox2D(center: float2(), size: float2(Float(size.x), Float(size.y)) * itemSize)
    self.bounds3D = BoundingBox3D(center: float3(), size: float3(Float(self.size3D.x), Float(self.size3D.y), Float(self.size3D.z)) * itemSize)
  }
  
  func reset() {
    self.items = Array(repeating: Item(), count: size.x * size.y)
    self.items3D = Array(repeating: Item(), count: size3D.x * size3D.y * size3D.z)
  }
  
  func mapBoundingBoxToGrid(_ box: BoundingBox2D, _ itemIndex: Int) {
    for y in stride(from: box.bottomRight.y, through: box.topLeft.y, by: box.height / 2) {
      let yIndex = floor(remap(y, float2(self.bounds.bottom, self.bounds.top), float2(0, Float(self.size.y))))
      for x in stride(from: box.topLeft.x, through: box.bottomRight.x, by: box.width / 2) {
        let xIndex = floor(remap(x, float2(self.bounds.left, self.bounds.right), float2(0, Float(self.size.x))))
        let index = from2DTo1DArray(SIMD2<Int>(Int(xIndex), Int(yIndex)), self.size)
        self.items[index].shapes.append(itemIndex)
      }
    }
  }
  
  func mapBoundingBoxTo3DGrid(_ box: BoundingBox3D, _ itemIndex: Int) {
    for z in stride(from: box.bottomRightBack.z, through: box.topLeftFront.z, by: box.depth / 2) {
      let zIndex = Int(floor(remap(z, float2(self.bounds3D.back, self.bounds3D.front), float2(0, Float(self.size3D.z)))))
      for y in stride(from: box.bottomRightBack.y, through: box.topLeftFront.y, by: box.height / 2) {
        let yIndex = Int(floor(remap(y, float2(self.bounds3D.bottom, self.bounds3D.top), float2(0, Float(self.size3D.y)))))
        for x in stride(from: box.topLeftFront.x, through: box.bottomRightBack.x, by: box.width / 2) {
          let xIndex = Int(floor(remap(x, float2(self.bounds3D.left, self.bounds3D.right), float2(0, Float(self.size3D.x)))))
          
          if zIndex.isBetween(0...(self.size3D.z - 1)) && yIndex.isBetween(0...(self.size3D.y - 1)) && xIndex.isBetween(0...(self.size3D.x - 1)) {
            let index = from3DTo1DArray(SIMD3<Int>(xIndex, yIndex, zIndex), self.size3D)
            self.items3D[index].shapes.append(itemIndex)
          }
        }
      }
    }
  }
  
  func updateGrid(with shape: CircleShape, _ itemIndex: Int) {
    self.mapBoundingBoxTo3DGrid(shape.boundingBox3D, itemIndex)
    //    self.mapBoundingBoxToGrid(shape.boundingBox, itemIndex)
  }
}

private struct Light {
  var position = float3()
}

private struct Camera {
  var position = float3()
  var rotation = float3()
  
  var viewMatrix: float4x4 {
    var translation = float4x4(translation: self.position)
    var rotation = float4x4(rotation: self.rotation)
    
    return translation * rotation
  }
}

private func lighting(_ ray: Ray, _ normal: float3, _ light: Light) -> Float {
  // 1
  let lightRay = normalize(light.position - ray.position);
  // 2
  let diffuse = max(0.0, dot(normal, lightRay));
  // 3
  let reflectedRay = reflect(ray.direction, n: normal);
  var specular = max(0.0, dot(reflectedRay, lightRay));
  // 4
  specular = pow(specular, 200.0);
  return diffuse + specular;
}


class CPURayMarchingDemoView : ViewRenderer {
  private var canvas: Canvas!
  var canvasSize = int2(256, 256)
//  var canvasSize = int2(256, 256)
  private var grid: Grid!
  private var shapes: [CircleShape] = []
  private var camera: Camera!
  private var light: Light!
  
  func update2D() {
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
          
          let dist = sdCircle(uv - shape.position.xy, shape.radius)
          color = mix(color, shape.color, t: 1.0 - step(dist, edge: 0))
        }
        
        return color.toUChar()
      }
    }
  }
  
  func update3D() {
    benchmark(title: "Update3D") {
      self.canvas.forEachPixel { ctx in
        let steps: Int = 20
        let stepSize = Float(0.1)
        let uv = ctx.uv
        let bgColor = float4(0, 0, 0, 1)
        var color = bgColor
        
        let viewMatrix = self.camera.viewMatrix
        var ray = Ray(position: (viewMatrix * float4(float3(uv.x, uv.y, 0), 1)).xyz, direction: float3.forward)
        for _ in 0..<steps {
          let gridIndex = fromWorldPositionToGridIndex(ray.position, self.grid.size3D.toFloat())
          if gridIndex.z.isBetween(0...(self.grid.size3D.z - 1)) && gridIndex.y.isBetween(0...(self.grid.size3D.y - 1)) && gridIndex.x.isBetween(0...(self.grid.size3D.x - 1)) {
            let itemIndex = from3DTo1DArray(gridIndex, self.grid.size3D)
            let shapeIndices = self.grid.items3D[itemIndex].shapes
            
            for i in shapeIndices {
              let shape = self.shapes[i]
              
              let dist = sdCircle(ray.position - shape.position, shape.radius)
              if dist <= 0 {
  //              color = mix(color, shape.color, t: 1.0 - step(dist, edge: 0))
                ray.position += ray.direction * -dist
                let normal = circleSDFNormal(ray.position - shape.position, shape.radius)
                let light = lighting(ray, normal, self.light)
                color = float4(shape.color.xyz * light, 1)
  //              color = float4(normal, 1)
                break
              }
            }
          }
          
          ray.position += ray.direction * stepSize
        }
        
        return color.toUChar()
      }
    }
  }
  
  func updateGrid() {
    self.grid.reset()
    for i in 0..<self.shapes.count {
      let shape = self.shapes[i]
      self.grid.updateGrid(with: shape, i)
    }
  }
  
  override func start() {
    self.camera = Camera(position: float3(0, 0, -1), rotation: float3(0, 0, 0))
    self.light = Light(position: float3(1, 3, 1))
    self.grid = Grid()
    self.canvas = Canvas(uchar4(0, 0, 0, 255), self.canvasSize)
    
    self.shapes.append(CircleShape(position: float3(-0.5, 0, 0), radius: Float(0.2), color: float4(1, 0, 0, 1)))
    self.shapes.append(CircleShape(position: float3(0, 0, 0), radius: Float(0.2), color: float4(0, 1, 0, 1)))
    self.shapes.append(CircleShape(position: float3(0.5, 0, 0), radius: Float(0.2), color: float4(0, 0, 1, 1)))
    
    self.updateGrid()
    
    //    self.update2D()
    self.update3D()
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    Input.keyDown(.keyW) {
      self.camera.rotation += float3(Float(10).degreesToRadians, 0, 0)
      self.update3D()
    }
    
    Input.keyDown(.keyS) {
      self.camera.rotation += float3(Float(-10).degreesToRadians, 0, 0)
      self.update3D()
    }
    
    Input.keyDown(.keyA) {
      self.camera.rotation += float3(0, Float(10).degreesToRadians, 0)
      self.update3D()
    }
    
    Input.keyDown(.keyD) {
      self.camera.rotation += float3(0, Float(-10).degreesToRadians, 0)
      self.update3D()
    }
    
    Input.keyDown(.leftArrow) {
      //      var shape = self.shapes[1]
      //
      //      shape.position += float3(-0.1, 0, 0)
      //
      //      self.shapes[1] = shape
      
      //      self.updateGrid()
      
      self.camera.position += float3(-0.1, 0, 0)
      self.update3D()
      //      self.update2D()
    }
    
    Input.keyDown(.rightArrow) {
      //      var shape = self.shapes[1]
      //
      //      shape.position += float3(0.1, 0, 0)
      //
      //      self.shapes[1] = shape
      
      //      self.updateGrid()
      self.camera.position += float3(0.1, 0, 0)
      self.update3D()
      //      self.update2D()
    }
    
    Input.keyDown(.upArrow) {
      self.camera.position += float3(0, 0.1, 0)
      self.update3D()
    }
    
    Input.keyDown(.downArrow) {
      self.camera.position += float3(0, -0.1, 0)
      self.update3D()
    }
    
    Input.keyDown(.spacebar) {
      //      self.update2D()
      self.update3D()
    }
    
    ui(in: view) { r in
      image(Rect(position: float2(), size: float2(800, 800)), texture: self.canvas.texture)
    }
  }
}
