//
//  WavesView1D.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 25.05.2024.
//

import Foundation
import MetalKit

class WavesView1D : ViewRenderer {
  var particles: [WaveParticle] = []
  var particlesCount = Int(100)
  var spacing = Float(0)
  var particleRadius = Float(2)
  var posOffset = float2(100, 350)
  
  override func start() {
    self.particles = Array(repeating: WaveParticle(), count: self.particlesCount)
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    if Time.time < 2 * Float.pi {
      do {
        let index = Int(50)
        var particle = self.particles[index]
        
        particle.addForce(-1 * sin(Time.time))
        
        self.particles[index] = particle
      }
    }
    
    // simulate
    for _ in 0..<5 {
      for i in 0..<self.particlesCount {
        var current = self.particles[i]
        
        var left = WaveParticle()
        left.value = current.value - current.velocity * 2
        left.mass = 1
        if i > 0 {
          left = self.particles[i - 1]
        }
        
        var right = WaveParticle()
        right.value = current.value - current.velocity * 2
        right.mass = 1
        if i < self.particlesCount - 1 {
          right = self.particles[i + 1]
        }
        
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
        
        var scalar = Float(i) / Float(self.particlesCount)
        scalar = scalar * 2 - 1
        scalar = abs(scalar)
//        if i == 30 {
//          print(scalar)
//        }
        // drag force
        let k: Float = 0.1
        let velocity = current.velocity
        if abs(velocity) > 0 {
          let dragForce = -1 * velocity * k
          current.addForce(dragForce * scalar)
        }
        
        current.integrate()
        
        self.particles[i] = current
      }
    }
    
    ui(in: view) { r in
      for i in 0..<self.particlesCount {
        let particle = self.particles[i]
        let particlePos = posOffset + Float(i) * float2(self.particleRadius * 2 + self.spacing, particle.value)
        if i > 0 {
          let prevParticle = self.particles[i - 1]
          let prevParticlePos = posOffset + Float(i - 1) * float2(self.particleRadius * 2 + self.spacing, prevParticle.value)
          line(prevParticlePos, particlePos, .black)
        }
        circle(position: particlePos, radius: self.particleRadius, borderSize: 1, color: .black)
      }
    }
  }
}
