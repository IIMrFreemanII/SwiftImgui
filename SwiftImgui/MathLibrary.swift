// Math Library v3.02

// swiftlint:disable type_name
// swiftlint:disable identifier_name
// swiftlint:disable comma

import simd
import CoreGraphics

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

let π = Float.pi

extension Float {
  var radiansToDegrees: Float {
    (self / π) * 180
  }
  var degreesToRadians: Float {
    (self / 180) * π
  }
}

// MARK: - float4
extension float4x4 {
  // MARK: - Translate
  init(translation: float3) {
    let matrix = float4x4(
      float4(            1,             0,             0, 0),
      float4(            0,             1,             0, 0),
      float4(            0,             0,             1, 0),
      float4(translation.x, translation.y, translation.z, 1)
    )
    self = matrix
  }
  
  // MARK: - Scale
  init(scaling: float3) {
    let matrix = float4x4(
      float4(scaling.x,         0,         0, 0),
      float4(        0, scaling.y,         0, 0),
      float4(        0,         0, scaling.z, 0),
      float4(        0,         0,         0, 1)
    )
    self = matrix
  }
  
  init(scaling: Float) {
    self = matrix_identity_float4x4
    columns.3.w = 1 / scaling
  }
  
  // MARK: - Rotate
  init(rotationX angle: Float) {
    let matrix = float4x4(
      float4(1,           0,          0, 0),
      float4(0,  cos(angle), sin(angle), 0),
      float4(0, -sin(angle), cos(angle), 0),
      float4(0,           0,          0, 1)
    )
    self = matrix
  }
  
  init(rotationY angle: Float) {
    let matrix = float4x4(
      float4(cos(angle), 0, -sin(angle), 0),
      float4(         0, 1,           0, 0),
      float4(sin(angle), 0,  cos(angle), 0),
      float4(         0, 0,           0, 1)
    )
    self = matrix
  }
  
  init(rotationZ angle: Float) {
    let matrix = float4x4(
      float4( cos(angle), sin(angle), 0, 0),
      float4(-sin(angle), cos(angle), 0, 0),
      float4(          0,          0, 1, 0),
      float4(          0,          0, 0, 1)
    )
    self = matrix
  }
  
  init(rotation angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationX * rotationY * rotationZ
  }
  
  init(rotationYXZ angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationY * rotationX * rotationZ
  }
  
  // MARK: - Identity
  static var identity: float4x4 {
    matrix_identity_float4x4
  }
  
  // MARK: - Upper left 3x3
  var upperLeft: float3x3 {
    let x = columns.0.xyz
    let y = columns.1.xyz
    let z = columns.2.xyz
    return float3x3(columns: (x, y, z))
  }
  
  // MARK: - Left handed projection matrix
  init(projectionFov fov: Float, near: Float, far: Float, aspect: Float, lhs: Bool = true) {
    let y = 1 / tan(fov * 0.5)
    let x = y / aspect
    let z = lhs ? far / (far - near) : far / (near - far)
    let X = float4( x,  0,  0,  0)
    let Y = float4( 0,  y,  0,  0)
    let Z = lhs ? float4( 0,  0,  z, 1) : float4( 0,  0,  z, -1)
    let W = lhs ? float4( 0,  0,  z * -near,  0) : float4( 0,  0,  z * near,  0)
    self.init()
    columns = (X, Y, Z, W)
  }
  
  // left-handed LookAt
  init(eye: float3, center: float3, up: float3) {
    let z = normalize(center - eye)
    let x = normalize(cross(up, z))
    let y = cross(z, x)
    
    let X = float4(x.x, y.x, z.x, 0)
    let Y = float4(x.y, y.y, z.y, 0)
    let Z = float4(x.z, y.z, z.z, 0)
    let W = float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
    
    self.init()
    columns = (X, Y, Z, W)
  }
  
  // MARK: - Orthographic matrix
  init(orthographic rect: CGRect, near: Float, far: Float) {
    let left = Float(rect.origin.x)
    let right = Float(rect.origin.x + rect.width)
    let top = Float(rect.origin.y)
    let bottom = Float(rect.origin.y + rect.height)
    let X = float4(2 / (right - left), 0, 0, 0)
    let Y = float4(0, 2 / (top - bottom), 0, 0)
    let Z = float4(0, 0, 1 / (far - near), 0)
    let W = float4(
      (left + right) / (left - right),
      (top + bottom) / (bottom - top),
      near / (near - far),
      1)
    self.init()
    columns = (X, Y, Z, W)
  }
  
  // MARK: - Orthographic matrix
  init(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
    self.init()
    let invRL = 1 / (right - left)
    let invTB = 1 / (top - bottom)
    let invFN = 1 / (far - near)
    
    let X = float4(2 * invRL, 0, 0, 0)
    let Y = float4(0, 2 * invTB, 0, 0)
    let Z = float4(0, 0, -invFN, 0)
    let W = float4(
      -(right + left) * invRL,
      -(top + bottom) * invTB,
      -(far + near) * invFN,
      1
    )
    
    columns = (X, Y, Z, W)
  }
  
  // convert double4x4 to float4x4
  init(_ m: matrix_double4x4) {
    self.init()
    let matrix = float4x4(
      float4(m.columns.0),
      float4(m.columns.1),
      float4(m.columns.2),
      float4(m.columns.3))
    self = matrix
  }
}

// MARK: - float3x3
extension float3x3 {
  init(normalFrom4x4 matrix: float4x4) {
    self.init()
    columns = matrix.upperLeft.inverse.transpose.columns
  }
}

// MARK: - float3
extension float3 {
  static let up: float3 = float3(0, 1, 0)
  static let forward: float3 = float3(0, 0, 1)
  static let right: float3 = float3(1, 0, 0)
  
  var xy: float2 {
    get {
      return float2(self.x, self.y)
    }
    set(new) {
      self.x = new.x
      self.y = new.y
    }
  }
}

// MARK: - float4
extension float4 {
  static let up: float4 = float4(0, 1, 0, 0)
  static let forward: float4 = float4(0, 0, 1, 0)
  static let right: float4 = float4(1, 0, 0, 0)
  
  static let transparent = float4(0, 0, 0, 0)
  static let red = float4(1, 0, 0, 1)
  static let green = float4(0, 1, 0, 1)
  static let blue = float4(0, 0, 1, 1)
  static let black = float4(0, 0, 0, 1)
  static let gray = float4(0.5, 0.5, 0.5, 1)
  static let white = float4(1, 1, 1, 1)
  
  var xyz: float3 {
    get {
      float3(x, y, z)
    }
    set {
      x = newValue.x
      y = newValue.y
      z = newValue.z
    }
  }
  
  // convert from double4
  init(_ d: SIMD4<Double>) {
    self.init()
    self = [Float(d.x), Float(d.y), Float(d.z), Float(d.w)]
  }
}

func modelFrom(trans: float3, rot: float3, scale: float3) -> matrix_float4x4 {
  let translation = float4x4(translation: trans)
  let rotation = float4x4(rotation: rot)
  let scale = float4x4(scaling: scale)
  return translation * rotation * scale
}

func remap(
  value: Float,
  inMinMax: float2,
  outMinMax: float2
) -> Float
  {
    return outMinMax.x +
           (value - inMinMax.x) *
           (outMinMax.y - outMinMax.x) /
           (inMinMax.y - inMinMax.x);
  }

func lerp(min: Float, max: Float, t: Float) -> Float {
  return (max - min) * t + min
}

func normalize(value: Float, min: Float, max: Float) -> Float {
  return (value - min) / (max - min)
}

// adapted form of sdfBox function https://iquilezles.org/articles/distfunctions2d/
// box origin at center
func pointInAABBox(point: float2, position: float2, size: float2) -> Bool {
  let pointOffset = point - position
  let d = abs(pointOffset) - size - 1
  return min(max(d.x, d.y), 0) < 0
}

// top left origin
func pointInAABBoxTopLeftOrigin(point: float2, position: float2, size: float2) -> Bool {
  let halfSize = (size * 0.5)
  let pos = float2(position.x, position.y) + halfSize
  
  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize - 1
  return min(max(d.x, d.y), 0) < 0
}
