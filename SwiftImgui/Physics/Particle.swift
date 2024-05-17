//
//  Particle.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 08.05.2024.
//

struct Particle {
//  var colliding = false
  
  var position = float2()
  var prevPosition = float2()
  var velocity: float2 {
    get {
      return self.position - self.prevPosition
    }
    set {
      self.prevPosition = self.position - newValue
    }
  }
  
  var radius = Float(10)
  var restitution = Float(0.9)
  
  var mass = Float(1)
  var invMass = Float(1)
  
  var sumOfForces = float2()
  
  var isStatic: Bool {
    return mass == 0
  }
  
  init(position: float2 = float2(), mass: Float = Float(1)) {
    self.position = position
    self.prevPosition = position
    self.mass = mass
    self.invMass = mass == 0 ? 0 : 1 / mass
  }
  
  mutating func addForce(_ force: float2) {
    self.sumOfForces += force
  }
  
  mutating func applyImpulse(_ j: float2) {
    if self.isStatic {
      return
    }
    
    var vel = self.velocity
    vel += j * self.invMass
    
    self.velocity = vel
  }
  
  mutating func clearForces() {
    self.sumOfForces = float2()
  }
  
  // Verlet integration
  mutating func integrate() {
    // check if particle is static (or pinned)
    if self.mass == 0 {
      self.clearForces()
      return
    }
    
    // compute acceleration using a = F / m.
    // Where F = force, m = mass of the object
    let acceleration = self.sumOfForces / self.mass
    let velocity = self.position - self.prevPosition
    
    // current position becomes old one
    self.prevPosition = self.position
    
    // Verlet explicit formula. x(n + 1) = x(n) + (x(n) - x(n - 1)) + a * dt * dt
    // (x(n) - x(n - 1)) = implicit velocity
    // where (n) = current position, (n + 1) = next position, (n - 1) previous position
    // a = acceleration, dt = delta time
    self.position += velocity + acceleration * (Time.deltaTime * Time.deltaTime)
    
    self.clearForces()
  }
}
