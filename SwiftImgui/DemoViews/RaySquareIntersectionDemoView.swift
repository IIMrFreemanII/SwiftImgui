//
//  RaySquareIntersectionDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 28.05.2024.
//

import MetalKit
import Foundation

class RaySquareIntersectionDemoView : ViewRenderer {
  var elemSize = Float(100)
  var square = Rect(position: float2(100, 100), size: float2(100, 100))
  var circleShape = CircleShape(position: float2(200, 200), radius: 50)
  var point = float2(150, 150)
  var rotation = Float(0)
  
  override func start() {
    
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    self.point = Input.mousePosition
    self.rotation += Input.mouseScroll.y * Time.deltaTime
    self.rotation = fmod(self.rotation, Float.pi * 2)
    
    ui(in: view) { r in
      circle(position: self.circleShape.position, radius: self.circleShape.radius, borderSize: 1, color: .black)
//      rect(self.square, style: RectStyle(color: .black))
      circle(position: self.point, radius: 4, borderSize: 1, color: .red)
      
      let direction = float2(cos(self.rotation), sin(self.rotation))
      let movedPointAlongTheRay = self.point + direction * self.elemSize
      line(self.point, movedPointAlongTheRay, .blue)
      circle(position: movedPointAlongTheRay, radius: 4, borderSize: 1, color: .blue)
      
      let pointToCircleDir = self.circleShape.position - self.point
      line(self.point, self.point + pointToCircleDir, .red)
      
      let proj = self.point + max(0, dot(pointToCircleDir, direction)) * direction
      
      line(self.point, proj, .green)
      circle(position: proj, radius: 4, borderSize: 1, color: .green)
      
//      print(proj)
      
//      let distToSquare = sdBox(point: movedPointAlongTheRay, rect: &self.square)
//      print(distToSquare)
//      
//      let thirdPoint = movedPointAlongTheRay + normalize(self.point - movedPointAlongTheRay) * distToSquare
//      circle(position: thirdPoint, radius: 4, borderSize: 1, color: .green)
    }
  }
}
