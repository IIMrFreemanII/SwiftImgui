import MetalKit
import Foundation

private struct Ray {
  var position: float2
  var direction: float2
}

private struct Sphere {
  var position: float2
  var radius: Float
}

func circleIntersect(_ rayOrigin: float2, _ rayDirection: float2, _ circleOrigin: float2, _ radius: Float) -> float2 {
  var oc = rayOrigin - circleOrigin
  var b = dot(oc, rayDirection)
  var c = dot(oc, oc) - radius * radius
  var h = b * b - c
  
  if h < 0 {
    return float2(-1, -1)
  }
  
  h = sqrt(h)
  
  return float2(-b - h, -b + h)
}

// axis aligned box centered at the origin, with size boxSize
// to move box in space just subtruct box position from ray position
func boxIntersection(_ rayOrigin: float2, _ rayDirection: float2, _ boxSize: float2) -> float2 {
  var m = 1 / rayDirection // can precompute if traversing a set of aligned boxes
  var n = m * rayOrigin // can precompute if traversing a set of aligned boxes
  var k = abs(m) * boxSize
  var t1 = -n - k
  var t2 = -n + k
  var tN = max(t1.x, t1.y)
  var tF = min(t2.x, t2.y)
  if tN > tF || tF < 0 {
    return float2(-1, -1)
  }
  
//  outNormal = tN > 0 ? step(float2(tN, tN), edge: t1) : step(t2, edge: float2(tF, tF))
  
  return float2(tN, tF)
}

class IntersectionsDemoView : ViewRenderer {
  private var ray = Ray(position: float2(), direction: float2())
  var angle = Float(45).degreesToRadians
  private var sphere = Sphere(position: float2(), radius: Float())
  var rect2D = Rect()
  
  override func start() {
    let direction = float2x2(rotation: self.angle) * float2(1, 0)
    self.ray = Ray(position: float2(100, 100), direction: direction)
    self.sphere = Sphere(position: float2(400, 400), radius: Float(50))
    self.rect2D = Rect(position: float2(600, 400), size: float2(100, 100))
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    self.ray.position = Input.mousePosition
    self.angle += Input.mouseScroll.y * Time.deltaTime;
    ray.direction = float2x2(rotation: self.angle) * float2(1, 0)
    
//    let oc = self.ray.position - self.sphere.position
//    let b = dot(oc, self.ray.direction)
//    let c = dot(oc, oc) - self.sphere.radius * self.sphere.radius
//    var h = b * b - c
//    
//    print("b: \(b)")
//    print("c: \(c)")
//    print("h: \(h)")
//    print("--------------")
    
//    if h > 0 {
//      h = sqrt(h)
//      let result = float2(-b-h, -b+h)
//      print("Intersection: \(result)")
//    }
    
    var result = circleIntersect(self.ray.position, self.ray.direction, self.sphere.position, self.sphere.radius)
//    print(result)
    
//    var normal = float2()
    var result1 = boxIntersection(self.ray.position - self.rect2D.position, self.ray.direction, self.rect2D.size * 0.5)
    print(result1)
//    print(normal)
    
    ui(in: view) { r in
      circle(position: self.sphere.position, radius: self.sphere.radius, borderSize: 1)
      var temp = self.rect2D
      temp.position -= temp.size * 0.5
      rect(temp, style: RectStyle(color: .black))
      
      line(self.ray.position, self.ray.position + self.ray.direction * 100, .red)
//      line(self.sphere.position, self.sphere.position + oc, .blue)
      if result.x >= 0 {
        circle(position: self.ray.position + self.ray.direction * result.x, radius: 4, borderSize: 1, color: .red)
      }
      
      if result.y >= 0 {
        circle(position: self.ray.position + self.ray.direction * result.y, radius: 4, borderSize: 1, color: .red)
      }
      
      if result1.x >= 0 {
        circle(position: self.ray.position + self.ray.direction * result1.x, radius: 4, borderSize: 1, color: .red)
      }
      
      if result1.y >= 0 {
        circle(position: self.ray.position + self.ray.direction * result1.y, radius: 4, borderSize: 1, color: .red)
      }
    }
  }
}
