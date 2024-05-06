//
//  PhysicsDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 10.04.2024.
//

import MetalKit
import Foundation

struct Particle {
  var position = float2()
  var prevPosition = float2()
  var mass = Float(1)
  
  init(position: float2 = float2(), mass: Float = Float(1)) {
    self.position = position
    self.prevPosition = position
    self.mass = mass
  }
}

struct DistanceConstraint {
  var p0: Int
  var p1: Int
  var length: Float
}

class PhysicsWorld {
  var particles: [Particle] = []
  var distanceConstraints: [DistanceConstraint] = []
  
  var worldBounds = float2(500, 500)
  
  func keepInsideView(_ particle: inout Particle) {
    if particle.position.y >= self.worldBounds.y {
      particle.position.y = self.worldBounds.y
    }
    
    if particle.position.x >= self.worldBounds.x {
      particle.position.x = self.worldBounds.x
    }
    
    if particle.position.y < 0 {
      particle.position.y = 0
    }
    
    if particle.position.x < 0 {
      particle.position.x = 0
    }
  }
  
  func applyVerletIntegration() {
    for i in 0..<self.particles.count {
      var particle = self.particles[i]
      
      let force = float2(0, 10) * 8
      let acceleration = force / particle.mass
  
      let prevPosition = particle.position
      particle.position = 2 * particle.position - particle.prevPosition + acceleration * (Time.deltaTime * Time.deltaTime)
      particle.prevPosition = prevPosition
      
      self.keepInsideView(&particle)
      
      self.particles[i] = particle
    }
  }
  
  func updateDistanceConstraints() {
    for constraint in self.distanceConstraints {
      var p0 = self.particles[constraint.p0]
      var p1 = self.particles[constraint.p1]
      
      let distanceDiff = p0.position - p1.position
      let distanceLenght = length(distanceDiff)
      let diffFactor = (constraint.length - distanceLenght) / distanceLenght * 0.5
      let offset = distanceDiff * diffFactor
      
      p0.position += offset
      p1.position -= offset
      
      self.particles[constraint.p0] = p0
      self.particles[constraint.p1] = p1
    }
  }
  
  func update() {
    self.applyVerletIntegration()
    self.updateDistanceConstraints()
  }
  
  @discardableResult
  func add(_ particle: Particle) -> Int {
    let index = self.particles.count
    
    self.particles.append(particle)
    
    return index
  }
  
  @discardableResult
  func add(_ constraint: DistanceConstraint) -> Int {
    let index = self.distanceConstraints.count
    
    self.distanceConstraints.append(constraint)
    
    return index
  }
}

class PhysicsDemoView : ViewRenderer {
  let physicsWorld = PhysicsWorld()
  
  override func start() {
    let topLeft = Particle(position: float2(150, 100)) // top left
    let topRight = Particle(position: float2(250, 100)) // top right
    let bottomLeft = Particle(position: float2(100, 200)) // bottom left
    let bottomRight = Particle(position: float2(200, 200)) // bottom right
    
    let topLeftIndex = self.physicsWorld.add(topLeft)
    let topRightIndex = self.physicsWorld.add(topRight)
    let bottomLeftIndex = self.physicsWorld.add(bottomLeft)
    let bottomRightIndex = self.physicsWorld.add(bottomRight)
    
    let topLeftToTopRight = DistanceConstraint(p0: topLeftIndex, p1: topRightIndex, length: length(topLeft.position - topRight.position))
    let topRightToBottomRight = DistanceConstraint(p0: topRightIndex, p1: bottomRightIndex, length: length(topRight.position - bottomRight.position))
    let bottomRightToBottomLeft = DistanceConstraint(p0: bottomRightIndex, p1: bottomLeftIndex, length: length(bottomRight.position - bottomLeft.position))
    let bottomLeftToTopLeft = DistanceConstraint(p0: bottomLeftIndex, p1: topLeftIndex, length: length(bottomLeft.position - topLeft.position))
    let bottomLeftToTopRight = DistanceConstraint(p0: bottomLeftIndex, p1: topRightIndex, length: length(bottomLeft.position - topRight.position))
    
    self.physicsWorld.add(topLeftToTopRight)
    self.physicsWorld.add(topRightToBottomRight)
    self.physicsWorld.add(bottomRightToBottomLeft)
    self.physicsWorld.add(bottomLeftToTopLeft)
    self.physicsWorld.add(bottomLeftToTopRight)
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    let frame = view.frame
    self.physicsWorld.worldBounds = float2(Float(frame.width), Float(frame.height))
    
    // simulate
    self.physicsWorld.update()
    
    // draw
    ui(in: view) { r in
      for constraint in physicsWorld.distanceConstraints {
        line(physicsWorld.particles[constraint.p0].position, physicsWorld.particles[constraint.p1].position)
      }
      for particle in self.physicsWorld.particles {
        circle(position: particle.position, radius: 10, borderSize: 1)
      }
    }
  }
}
