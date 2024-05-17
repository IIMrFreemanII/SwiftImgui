//
//  CollisionDetection.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 17.05.2024.
//

struct Contact {
  // particle index
  var a = Int()
  var b = Int()
  
  var start = float2()
  var end = float2()
  
  var normal = float2()
  var depth = Float()
  
  // Resolves the collision using the impulse method
  func resolvePenetration(_ a: inout Particle, _ b: inout Particle) {
    if a.isStatic && b.isStatic {
      return
    }
    
    let temp = self.depth / (a.invMass + b.invMass)
    let da = temp * a.invMass
    let db = temp * b.invMass
    
    a.position -= normal * da
    b.position += normal * db
  }
  
  func resolveCollition(_ a: inout Particle, _ b: inout Particle) {
    // Apply positional correction using the projection method
    self.resolvePenetration(&a, &b)
    
    // Define elasticity (coefficient of restitution e)
    let e = min(a.restitution, b.restitution)
    
    // Calculate the relative velocity between the tuo objects
    let vRel = a.velocity - b.velocity
    
    // Calculate the relative velocity along the normal collision vector
    let vRelDotNormal = dot(vRel, self.normal)
    
    // Now we proceed to calculate the collision impulse
    let impulseDirection = self.normal
    let impulseMagnitude = -(1 + e) * vRelDotNormal / (a.invMass + b.invMass)
    
    let j = impulseDirection * impulseMagnitude
    
    // Apply the impulse vector to both objects in opposite direction
    a.applyImpulse(j)
    b.applyImpulse(-j)
  }
}

class CollisionDetection {
  static func checkParticleCollision(_ a: inout Particle, _ b: inout Particle, _ contact: inout Contact) -> Bool {
    let ab = b.position - a.position
    let radiusSum = a.radius + b.radius
    let isColliding = length_squared(ab) <= (radiusSum * radiusSum)
    
    if isColliding {
      let normal = normalize(ab)
      
      let start = b.position - normal * b.radius
      let end = a.position + normal * a.radius
      
      contact.normal = normal
      contact.start = start
      contact.end = end
      contact.depth = length(start - end)
    }
    
    return isColliding
  }
}
