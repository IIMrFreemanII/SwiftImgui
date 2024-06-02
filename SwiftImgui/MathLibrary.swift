// Math Library v3.02

// swiftlint:disable type_name
// swiftlint:disable identifier_name
// swiftlint:disable comma

import simd

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

typealias int2 = SIMD2<Int>

typealias uchar4 = SIMD4<UInt8>
typealias Color = uchar4

let π = Float.pi

extension Float {
  var radiansToDegrees: Float {
    (self / π) * 180
  }
  var degreesToRadians: Float {
    (self / 180) * π
  }
  var isNegative: Bool {
    return self.sign == .minus
  }
}

extension float4x4 {
  private func format(_ columnt: simd_float4, _ value: Float) -> String {
    let hasNegativeSignInColumnt = columnt.x.isNegative || columnt.y.isNegative || columnt.z.isNegative || columnt.w.isNegative
    return hasNegativeSignInColumnt && value.isNegative ? "\(String(format: "%.4f", value))" : " \(String(format: "%.4f", value))"
  }
  
  var formated: String {
    """
    *------------ float4x4 ------------*
    |\(self.format(self.columns.0, self.columns.0.x)), \(self.format(self.columns.1, self.columns.1.x)), \(self.format(self.columns.2, self.columns.2.x)), \(self.format(self.columns.3, self.columns.3.x))|
    |\(self.format(self.columns.0, self.columns.0.y)), \(self.format(self.columns.1, self.columns.1.y)), \(self.format(self.columns.2, self.columns.2.y)), \(self.format(self.columns.3, self.columns.3.y))|
    |\(self.format(self.columns.0, self.columns.0.z)), \(self.format(self.columns.1, self.columns.1.z)), \(self.format(self.columns.2, self.columns.2.z)), \(self.format(self.columns.3, self.columns.3.z))|
    |\(self.format(self.columns.0, self.columns.0.w)), \(self.format(self.columns.1, self.columns.1.w)), \(self.format(self.columns.2, self.columns.2.w)), \(self.format(self.columns.3, self.columns.3.w))|
    *----------------------------------*
    """
  }
}

extension float2x2 {
  init(rotation angle: Float) {
    let s = sin(angle)
    let c = cos(angle)
    let matrix = float2x2(
      float2( c, s),
      float2(-s, c)
    )
    self = matrix
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
    let c = cos(angle)
    let s = sin(angle)
    
    let matrix = float4x4(
      float4(1, 0, 0, 0),
      float4(0, c, s, 0),
      float4(0,-s, c, 0),
      float4(0, 0, 0, 1)
    )
    self = matrix
  }
  
  init(rotationY angle: Float) {
    let c = cos(angle)
    let s = sin(angle)
    
    let matrix = float4x4(
      float4(c, 0,-s, 0),
      float4(0, 1, 0, 0),
      float4(s, 0, c, 0),
      float4(0, 0, 0, 1)
    )
    self = matrix
  }
  
  init(rotationZ angle: Float) {
    let c = cos(angle)
    let s = sin(angle)
    
    let matrix = float4x4(
      float4( c, s, 0, 0),
      float4(-s, c, 0, 0),
      float4( 0, 0, 1, 0),
      float4( 0, 0, 0, 1)
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
  init(orthographic rect: Rect, near: Float, far: Float) {
    let left = rect.position.x
    let right = rect.position.x + rect.width
    let top = rect.position.y
    let bottom = rect.position.y + rect.height
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
    
    let X = float4(2 * invRL, 0        , 0     , 0)
    let Y = float4(0        , 2 * invTB, 0     , 0)
    let Z = float4(0        , 0        , -invFN, 0)
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
extension float2 {
  var width: Float {
    self.x
  }
  
  var height: Float {
    self.y
  }
  
  /// returns new float2 with greatest component and other components set to 0
  var greatestComponent: float2 {
    let condition = self.x > self.y
    return float2(self.x * Float(condition), self.y * Float(!condition))
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
  
  var width: Float {
    self.x
  }
  
  var height: Float {
    self.y
  }
  
  var depth: Float {
    self.z
  }
}

// MARK: - uchar4
extension uchar4 {
  static let transparent = uchar4(0, 0, 0, 0)
  static let red = uchar4(255, 0, 0, 255)
  static let green = uchar4(0, 255, 0, 255)
  static let blue = uchar4(0, 0, 255, 255)
  static let black = uchar4(0, 0, 0, 255)
  static let gray = uchar4(127, 127, 127, 255)
  static let lightGray = uchar4(150, 150, 150, 255)
  static let white = uchar4(255, 255, 255, 255)
  
  var r: UInt8 {
    get { self.x }
    set { self.x = newValue }
  }
  
  var g: UInt8 {
    get { self.y }
    set { self.y = newValue }
  }
  
  var b: UInt8 {
    get { self.z }
    set { self.z = newValue }
  }
  
  var a: UInt8 {
    get { self.w }
    set { self.w = newValue }
  }
}

// MARK: - float4
extension float4 {
  static let up: float4 = float4(0, 1, 0, 0)
  static let forward: float4 = float4(0, 0, 1, 0)
  static let right: float4 = float4(1, 0, 0, 0)
  
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
  _ value: Float,
  _ inMinMax: float2,
  _ outMinMax: float2
) -> Float
  {
    return outMinMax.x +
           (value - inMinMax.x) *
           (outMinMax.y - outMinMax.x) /
           (inMinMax.y - inMinMax.x);
  }

func remap(
  _ value: Float,
  _ inMinMax: ClosedRange<Float>,
  _ outMinMax: ClosedRange<Float>
) -> Float
  {
    return outMinMax.lowerBound +
    (value - inMinMax.lowerBound) *
           (outMinMax.upperBound - outMinMax.lowerBound) /
           (inMinMax.upperBound - inMinMax.lowerBound);
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

// top-left origin
func pointInAABBoxTopLeftOrigin(point: float2, position: float2, size: float2) -> Bool {
  let halfSize = (size * 0.5)
  let pos = float2(position.x, position.y) + halfSize
  
  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize - 1
  return min(max(d.x, d.y), 0) < 0
}

// top-left origin
func sdBox(point: float2, rect: inout Rect) -> Float {
  let halfSize = (rect.size * 0.5)
  let pos = float2(rect.position.x, rect.position.y) + halfSize

  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize

  // clamped to the edge of top right quadrant of the box
  let topRightVector = max(d, 0)

  // min(max(d.x, d.y), 0) - distance inside the box (to the closest edge) but I need point on the closest edge and penetration amount
  return length(topRightVector) + min(max(d.x, d.y), 0)
}

// b.x = width
// b.y = height
// r.x = roundness top-right
// r.y = roundness boottom-right
// r.z = roundness top-left
// r.w = roundness bottom-left
// origin at center
func sdRoundBox(_ p: float2, _ b: float2, _ r: float4) -> Float
{
 var r = r
  //  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  if p.x > 0.0 {
    r.x = r.x
    r.y = r.y
  } else {
    r.x = r.z
    r.y = r.w
  }
  r.x  = (p.y > 0.0) ? r.x : r.y;
  
  let q: float2 = abs(p) - b + r.x;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

// top-left origin
func closestPointToSDBox(point: float2, rect: inout Rect) -> float2 {
  let halfSize = (rect.size * 0.5)
  let pos = float2(rect.position.x, rect.position.y) + halfSize
  
  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize
  
  // clamped to the edge of top right quadrant of the box
  let topRightVector = max(d, 0)
  //  let innerTopRightVector = min(d.greatestComponent, 0)
  
  //  let offsetToClosestPoint = (topRightVector + innerTopRightVector) * sign(pointOffset)
  let offsetToClosestPoint = topRightVector * sign(pointOffset)
  
  return point - offsetToClosestPoint
}

// top-left origin
func dragDirection(point: float2, rect: inout Rect) -> float2 {
  let halfSize = (rect.size * 0.5)
  let pos = float2(rect.position.x, rect.position.y) + halfSize
  
  let pointOffset = point - pos
  let d = abs(pointOffset) - halfSize
  
  return max(d, 0) * sign(pointOffset)
}

func smoothstep(edge0: Float, edge1: Float, x: Float) -> Float {
  let t = ((x - edge0) / (edge1 - edge0)).clamped(to: 0...1);
  return t * t * (3.0 - 2.0 * t);
}

func mix(x: Float, y: Float, t: Float) -> Float {
  return x * (1 - t) + y * t;
}

func sdCircle(_ p: float2, _ r: Float) -> Float {
  return length(p) - r;
}

func circleSDFNormal(_ p: float2, _ r: Float) -> float2 {
  let eps = Float(0.0001)
  let dx = (sdCircle(p + float2(eps, 0), r) - sdCircle(p - float2(eps, 0), r)) / (2 * eps)
  let dy = (sdCircle(p + float2(0, eps), r) - sdCircle(p - float2(0, eps), r)) / (2 * eps)
  let dSDF = float2(dx, dy)
  let normal = dSDF / length(dSDF)
  
  return normal
}

extension float4 {
  func toUChar() -> uchar4 {
    return uchar4(UInt8(self.x.clamped(to: 0...1) * 255), UInt8(self.y.clamped(to: 0...1) * 255), UInt8(self.z.clamped(to: 0...1) * 255), UInt8(self.w.clamped(to: 0...1) * 255))
  }
}

extension int2 {
  func toFloat() -> float2 {
    return float2(Float(self.x), Float(self.y))
  }
}

func fromPixelCoordToGridIndex(_ normalizedCoord: SIMD2<Float>, _ gridSize: SIMD2<Float>) -> SIMD2<Int> {
  let x = Int(floor(remap(normalizedCoord.x, float2(-1, 1), float2(0, gridSize.x))))
  let y = Int(floor(remap(normalizedCoord.y, float2(-1, 1), float2(0, gridSize.y))))
  
  return int2(x, y)
}
