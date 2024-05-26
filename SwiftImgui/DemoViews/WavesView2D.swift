//
//  WavesView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 31.03.2024.
//

import MetalKit
import Foundation

struct WaveParticle {
  var value = Float()
  var velocity = Float()
  var color: Color = .black
  var mass = Float(1) {
    willSet(newValue) {
      self.invMass = newValue == 0 ? 0 : 1 / newValue
    }
  }
  private var invMass = Float(1)
  private var sumOfForces = Float()
  
  var isStatic: Bool {
    return mass == 0
  }
  
  mutating func addForce(_ force: Float) {
    self.sumOfForces += force
  }
  
  mutating func applyImpulse(_ j: Float) {
    if self.isStatic {
      return
    }
    
    self.velocity += j * self.invMass
  }
  
  mutating func clearForces() {
    self.sumOfForces = 0
  }
  
  mutating func integrate() {
    if self.isStatic {
      return
    }
    
    let acceleration = self.sumOfForces * self.invMass
    self.velocity += acceleration * Time.deltaTime
    self.value += self.velocity * Time.deltaTime
    
    // clear forces
    self.clearForces()
  }
}

struct CanvasContext {
  var size = int2()
  var uv = float2()
  var pixel = int2()
}

func forEachPixel(_ canvasSize: int2, _ cb: (CanvasContext) -> Void) {
  for y in 0..<canvasSize.y {
    for x in 0..<canvasSize.x {
      var uv = float2(Float(x), Float(y)) / Float(canvasSize.y)
      uv = uv * 2 - 1
      cb(CanvasContext(size: canvasSize, uv: uv, pixel: int2(x, y)))
    }
  }
}

class WavesView2D : ViewRenderer {
  var particles: [WaveParticle] = []
  var gridSize = int2(100, 100)
  var spacing = Float(0)
  var particleRadius = Float(6)
  
  override func start() {
    self.particles = Array(repeating: WaveParticle(), count: self.gridSize.x * self.gridSize.y)
    forEachPixel(self.gridSize) { ctx in
      let uv = ctx.uv
      
      let i = from2DTo1DArray(ctx.pixel, self.gridSize)
      var particle = self.particles[i]
      
//      // draw box
//      do {
//        let size = float2(0.5, 0.01)
//        let position = float2(0.6, 0.6)
//        let dist = sdRoundBox(uv - position, size, float4(0, 0, 0, 0))
//        let temp = 1 - step(0, edge: dist)
//        if temp == 0 {
//          particle.color = .red
//          particle.mass = 0
//        }
//      }
//      
//      // draw box
//      do {
//        let size = float2(0.5, 0.01)
//        let position = float2(-0.6, 0.6)
//        let dist = sdRoundBox(uv - position, size, float4(0, 0, 0, 0))
//        let temp = 1 - step(0, edge: dist)
//        if temp == 0 {
//          particle.color = .red
//          particle.mass = 0
//        }
//      }
      
      self.particles[i] = particle
    }
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    do {
      let index = from2DTo1DArray(int2(50, 50), self.gridSize)
      var particle = self.particles[index]
      particle.addForce(20 * sin(Time.time * 3))
      self.particles[index] = particle
    }
    
    // simulate
    for _ in 0..<5 {
      forEachPixel(self.gridSize) { ctx in
        var uv = ctx.uv
        let pixel = ctx.pixel
        let x = pixel.x
        let y = pixel.y
        
        let i = from2DTo1DArray(pixel, ctx.size)
        
        var current = self.particles[i]
        
        var left = WaveParticle()
//        left.value = current.value
        left.value = current.value - current.velocity * 2
        if x > 0 {
          left = self.particles[from2DTo1DArray(int2(x - 1, y), self.gridSize)]
        }
        
        var right = WaveParticle()
//        right.value = current.value
        right.value = current.value - current.velocity * 2
        if x < self.gridSize.x - 1 {
          right = self.particles[from2DTo1DArray(int2(x + 1, y), self.gridSize)]
        }
        
        var top = WaveParticle()
//        top.value = current.value
        top.value = current.value - current.velocity * 2
        if y > 0 {
          top = self.particles[from2DTo1DArray(int2(x, y - 1), self.gridSize)]
        }
        
        var bottom = WaveParticle()
//        bottom.value = current.value
        bottom.value = current.value - current.velocity * 2
        if y < self.gridSize.y - 1 {
          bottom = self.particles[from2DTo1DArray(int2(x, y + 1), self.gridSize)]
        }
        
//        var drag: Float = 1
        
        //        if pixel == int2(0, 0) {
//        do {
          //            let size = float2(0.1, 0.1)
          //            let position = float2(0, 0)
          //            let dist = sdRoundBox(uv - position, size, float4(0.1, 0.1, 0.1, 0.1))
//          drag = 1 - min(length(uv), 1)
          //            print()
          //          drag = 1 - dist
          //          let temp = 1 - step(0, edge: dist)
          //          if temp == 1 {
          ////            current.color = .blue
          //            drag = true
          //          }
//        }
        //        }
        
        //
        //        do {
        //          let size = float2(0.96, 0.96)
        //          let position = float2(0, 0)
        //          let dist = sdRoundBox(uv - position, size, float4(0.1, 0.1, 0.1, 0.1))
        //          let temp = 1 - step(0, edge: dist)
        //          if temp == 1 {
        ////            current.color = .red
        //            drag = 1 - 1
        //          }
        //        }
        
        do {
          let leftCurrValueDiff = left.value - current.value
          let scalar = current.mass / (left.mass + current.mass)
          let leftCurrForce = leftCurrValueDiff * scalar
          current.addForce(leftCurrForce)
        }
        
        do {
          let rightCurrValueDiff = right.value - current.value
          let scalar = current.mass / (right.mass + current.mass)
          let rightCurrForce = rightCurrValueDiff * scalar
          current.addForce(rightCurrForce)
        }
        
        do {
          let topCurrValueDiff = top.value - current.value
          let scalar = current.mass / (top.mass + current.mass)
          let topCurrForce = topCurrValueDiff * scalar
          current.addForce(topCurrForce)
        }
        
        do {
          let bottomCurrValueDiff = bottom.value - current.value
          let scalar = current.mass / (bottom.mass + current.mass)
          let bottomCurrForce = bottomCurrValueDiff * scalar
          current.addForce(bottomCurrForce)
        }
        
        self.particles[i] = current
      }
      
      self.particles.forEach { current in
        current.integrate()
      }
    }
    
    ui(in: view) { r in
      // 2d view
      for y in 0..<self.gridSize.y {
        for x in 0..<self.gridSize.x {
          let index = from2DTo1DArray(int2(x, y), self.gridSize)
          var particle = self.particles[index]
          
          if particle.mass != 0 {
            // calc new color after integration
            let colorValue = remap(particle.value, float2(-1, 1), float2(0, 1))
            let temp = UInt8(remap(colorValue, float2(0, 1), float2(0, 255)).clamped(to: 0...255))
            particle.color = Color(temp, temp, temp, UInt8(255))
          }
          
          rect(Rect(position: float2(Float(x) * (self.particleRadius + self.spacing), Float(y) * (particleRadius + self.spacing)), size: float2(self.particleRadius, self.particleRadius)), style: RectStyle(color: particle.color))
          
          self.particles[index] = particle
        }
      }
    }
  }
}
