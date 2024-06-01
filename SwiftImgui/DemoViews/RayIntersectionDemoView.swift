//
//  RaySquareIntersectionDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 28.05.2024.
//

import MetalKit
import Foundation

private struct Ray {
  var position = float2()
  var direction = float2()
}

class RayIntersectionDemoView : ViewRenderer {
  var gridSize = float2()
  var square = Rect(position: float2(100, 100), size: float2(100, 100))
  var shapes: [CircleShape] = []
  var speed = Float(500)
  private var rays: [Ray] = []
  
  override func start() {
    for _ in 0..<10 {
      let rx = Float.random(in: 0...1000)
      let ry = Float.random(in: 0...1000)
      let rr = Float.random(in: 20...50)
      
      self.shapes.append(CircleShape(position: float2(rx, ry), radius: rr))
    }
    
    for _ in 0..<100 {
      let rd = normalize(float2(Float.random(in: -1...1), Float.random(in: -1...1)))
      self.rays.append(Ray(position: float2(200, 200), direction: rd))
    }
  }
  
  private func keepInsideView(_ ray: inout Ray) {
    if ray.position.x <= 0 {
      ray.position.x = 0
      ray.direction.x *= -1
    }

    if ray.position.x >= Float(self.gridSize.x) {
      ray.position.x = Float(self.gridSize.x)
      ray.direction.x *= -1
    }

    if ray.position.y <= 0 {
      ray.position.y = 0
      ray.direction.y *= -1
    }

    if ray.position.y >= Float(self.gridSize.y) {
      ray.position.y = Float(self.gridSize.y)
      ray.direction.y *= -1
    }
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    self.gridSize = float2(Float(view.frame.width), Float(view.frame.height))
    
    ui(in: view) { r in
      for i in 0..<self.rays.count {
        var ray = self.rays[i]
        
        for shape in self.shapes {
          let dist = sdCircle(ray.position - shape.position, shape.radius)
          if dist < 0 {
            let normal = circleSDFNormal(ray.position - shape.position, shape.radius)
            ray.position = ray.position + normal * -dist
            ray.direction = reflect(ray.direction, n: normal)
          }
        }
        
        self.rays[i] = ray
      }
      
      for i in 0..<self.rays.count {
        var ray = self.rays[i]
        
        ray.position += ray.direction * Time.deltaTime * self.speed
        self.keepInsideView(&ray)
        
        self.rays[i] = ray
      }
      
      for ray in rays {
        circle(position: ray.position, radius: 2, borderSize: 1, color: .red)
      }
      for shape in self.shapes {
        circle(position: shape.position, radius: shape.radius, borderSize: 1, color: .black)
      }
    }
  }
}
