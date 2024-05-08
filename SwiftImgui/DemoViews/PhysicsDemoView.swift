//
//  PhysicsDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 10.04.2024.
//

import MetalKit
import Foundation

class PhysicsDemoView : ViewRenderer {
  let physicsWorld = PhysicsWorld()
  
  override func start() {
    let posOffset = float2(400, 300)
    let scalar: Float = 0.5
    let k: Float = 10
//    let rotation = float2x2(rotation: Float(60).degreesToRadians)
    
    let pinned = Particle(position: float2(150, -150) * scalar + posOffset, mass: 0) // pinned
    
    let one = Particle(position: float2(150, -100) * scalar + posOffset)
    let two = Particle(position: float2(150, -50) * scalar + posOffset)
    let three = Particle(position: float2(150, 0) * scalar + posOffset)
    let four = Particle(position: float2(150, 50) * scalar + posOffset)
//    let topLeft = Particle(position: rotation * float2(-100, 100) * scalar + posOffset) // top left
//    let topRight = Particle(position: rotation * float2(100, 100) * scalar + posOffset) // top right
//    let bottomLeft = Particle(position: rotation * float2(-100, -100) * scalar + posOffset) // bottom left
//    let bottomRight = Particle(position: rotation * float2(100, -100) * scalar + posOffset) // bottom right
    
    let pinnedIndex = self.physicsWorld.addParticle(pinned)
    let oneIndex = self.physicsWorld.addParticle(one)
    let twoIndex = self.physicsWorld.addParticle(two)
    let threeIndex = self.physicsWorld.addParticle(three)
    let fourIndex = self.physicsWorld.addParticle(four)
    
//    let pinnedToTopLeft = DistanceConstraint(p0: pinnedIndex, p1: topLeftIndex, length: length(pinned.position - topLeft.position))
    let pinnedToOne = SpringConstraint(p0: pinnedIndex, p1: oneIndex, restLength: length(pinned.position - one.position), k: k)
    
//    let topLeftToTopRight = DistanceConstraint(p0: topLeftIndex, p1: topRightIndex, length: length(topLeft.position - topRight.position))
//    let topRightToBottomRight = DistanceConstraint(p0: topRightIndex, p1: bottomRightIndex, length: length(topRight.position - bottomRight.position))
//    let bottomRightToBottomLeft = DistanceConstraint(p0: bottomRightIndex, p1: bottomLeftIndex, length: length(bottomRight.position - bottomLeft.position))
//    let bottomLeftToTopLeft = DistanceConstraint(p0: bottomLeftIndex, p1: topLeftIndex, length: length(bottomLeft.position - topLeft.position))
//    let bottomLeftToTopRight = DistanceConstraint(p0: bottomLeftIndex, p1: topRightIndex, length: length(bottomLeft.position - topRight.position))
    
    let oneToTwo = SpringConstraint(p0: oneIndex, p1: twoIndex, restLength: length(one.position - two.position), k: k)
    let twoToTree = SpringConstraint(p0: twoIndex, p1: threeIndex, restLength: length(two.position - three.position), k: k)
    let threeToFour = SpringConstraint(p0: threeIndex, p1: fourIndex, restLength: length(three.position - four.position), k: k)
//    let bottomLeftToTopLeft = SpringConstraint(p0: bottomLeftIndex, p1: topLeftIndex, restLength: length(bottomLeft.position - topLeft.position), k: k)
//    let bottomLeftToTopRight = SpringConstraint(p0: bottomLeftIndex, p1: topRightIndex, restLength: length(bottomLeft.position - topRight.position), k: k)
//    let topLeftToBottomRight = SpringConstraint(p0: topLeftIndex, p1: bottomRightIndex, restLength: length(topLeft.position - bottomRight.position), k: k)
    
    self.physicsWorld.addConstraint(pinnedToOne)
    
    self.physicsWorld.addConstraint(oneToTwo)
    self.physicsWorld.addConstraint(twoToTree)
    self.physicsWorld.addConstraint(threeToFour)
//    self.physicsWorld.addConstraint(bottomLeftToTopLeft)
//    self.physicsWorld.addConstraint(bottomLeftToTopRight)
//    self.physicsWorld.addConstraint(topLeftToBottomRight)
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
      for constraint in physicsWorld.sprintConstraints {
        line(physicsWorld.particles[constraint.p0].position, physicsWorld.particles[constraint.p1].position)
      }
      for particle in self.physicsWorld.particles {
        circle(position: particle.position, radius: 10, borderSize: 1)
      }
    }
  }
}
