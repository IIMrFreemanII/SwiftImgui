//
//  PhysicsWorld.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 08.05.2024.
//

class PhysicsWorld {
  var particles: [Particle] = []
  var distanceConstraints: [DistanceConstraint] = []
  var sprintConstraints: [SpringConstraint] = []
  
  var worldBounds = float2(500, 500)
  
  func keepInsideView(_ particle: inout Particle) {
    var vel = particle.position - particle.prevPosition
    let scalar: Float = -0.9
    
    if particle.position.y + particle.radius >= self.worldBounds.y {
      particle.position.y = self.worldBounds.y - particle.radius
      vel.y *= scalar
    }
    
    if particle.position.x + particle.radius >= self.worldBounds.x {
      particle.position.x = self.worldBounds.x - particle.radius
      vel.x *= scalar
    }
    
    if particle.position.y - particle.radius < 0 {
      particle.position.y = 0 + particle.radius
      vel.y *= scalar
    }
    
    if particle.position.x - particle.radius < 0 {
      particle.position.x = 0 + particle.radius
      vel.x *= scalar
    }
    
    particle.prevPosition = particle.position - vel
  }
  
  func applyVerletIntegration() {
    for i in 0..<self.particles.count {
      var particle = self.particles[i]
      
      particle.integrate()
      self.keepInsideView(&particle)
      
      self.particles[i] = particle
    }
  }
  
  func updateDistanceConstraints() {
    for constraint in self.distanceConstraints {
      var p0 = self.particles[constraint.p0]
      var p1 = self.particles[constraint.p1]
      
      let deltaPos = p0.position - p1.position
      let dist = length(deltaPos)
      let diff = constraint.length - dist
      let percent = diff / dist * 0.5
      let offset = deltaPos * percent
      
      p0.position += offset
      p1.position -= offset
      
      // check if particle is static (or pinned)
      if p0.mass != 0 {
        self.particles[constraint.p0] = p0
      }
      
      // check if particle is static (or pinned)
      if p1.mass != 0 {
        self.particles[constraint.p1] = p1
      }
    }
  }
  
  func updateSpringConstraints() {
    for spring in self.sprintConstraints {
      var p0 = self.particles[spring.p0]
      var p1 = self.particles[spring.p1]
      
      let dist = p1.position - p0.position
      // Find the spring displacement considering the rest length
      let displacement = length(dist) - spring.restLength
      
      // Calc the direction and the magnitude of the spring force
      let springDir = normalize(dist)
      let springMagnitude = -spring.k * displacement
      
      // Calc the final resulting spring force vector
      let springForce = springDir * springMagnitude
      
      if !p0.isStatic {
        p0.addForce(-springForce)
      }
      if !p1.isStatic {
        p1.addForce(springForce)
      }
      
      self.particles[spring.p0] = p0
      self.particles[spring.p1] = p1
    }
  }
  
  func handleCollisions() {
    for i in 0..<self.particles.count {
      for j in (i + 1)..<self.particles.count {
        if i == j {
          continue
        }
        
        var a = self.particles[i]
        var b = self.particles[j]
        var contact = Contact()
        if CollisionDetection.checkParticleCollision(&a, &b, &contact) {
          // fill indices
          contact.a = i
          contact.b = j
          
          // Resolve the collision using impulse method
          contact.resolveCollition(&a, &b)
        }
        
        self.particles[i] = a
        self.particles[j] = b
      }
    }
  }
  
  func applyGlobalForces() {
    for i in 0..<self.particles.count {
      var particle = self.particles[i]
      
      // wind force
      let windForce = float2(10, 0) * 5
      particle.addForce(windForce)
      
      // weight force
      // Weight is a force that is caused by gravity. g = 9.81 m/s*s
      // Therefore, W(vector force) = m * g
      let weightForce = float2(0, particle.mass * 9.8) * 20
      particle.addForce(weightForce)
      
      // drag force
      let k: Float = 0.03
      let velocity = particle.position - particle.prevPosition
      let magnitudeSquared = length_squared(velocity)
      if magnitudeSquared > 0 {
        let dragDir = normalize(velocity) * -1
        let dragMagnitude = k * magnitudeSquared
        
        let dragForce = dragDir * dragMagnitude
        particle.addForce(dragForce)
      }
      
      
      self.particles[i] = particle
    }
  }
  
  func update() {
    self.applyGlobalForces()
    self.updateSpringConstraints()
    self.applyVerletIntegration()
    self.updateDistanceConstraints()
    for _ in 0..<5 {
      self.handleCollisions()
    }
  }
  
  @discardableResult
  func addParticle(_ particle: Particle) -> Int {
    let index = self.particles.count
    
    self.particles.append(particle)
    
    return index
  }
  
  @discardableResult
  func addConstraint(_ constraint: DistanceConstraint) -> Int {
    let index = self.distanceConstraints.count
    
    self.distanceConstraints.append(constraint)
    
    return index
  }
  
  @discardableResult
  func addConstraint(_ constraint: SpringConstraint) -> Int {
    let index = self.sprintConstraints.count
    
    self.sprintConstraints.append(constraint)
    
    return index
  }
}
