import MetalKit

func getRectVertices3D(w: Float, h: Float, x: Float = 0, y: Float = 0) -> [float3] {
  return [
    float3(x, y, 0),
    float3(x + w, y, 0),
    float3(x, y + h, 0),
    float3(x + w, y + h, 0),
  ]
}

func getRectVertices2D(w: Float, h: Float, x: Float = 0, y: Float = 0) -> [float2] {
  return [
    float2(x, y),
    float2(x + w, y),
    float2(x, y + h),
    float2(x + w, y + h),
  ]
}

struct RectMesh {
  var vertices = getRectVertices3D(w: 1, h: 1)
  var uv: [float2] = [
    float2(0, 1), float2(1, 1),
    float2(0, 0), float2(1, 0),
  ]

  var indices: [UInt16] = [
    0, 3, 2,
    0, 1, 3
  ]
  
  
  let vertexBuffer: MTLBuffer
  let uvBuffer: MTLBuffer
  let indexBuffer: MTLBuffer

  init() {
    guard let vertexBuffer = Renderer.device.makeBuffer(
      bytes: &vertices,
      length: MemoryLayout<float3>.stride * vertices.count,
      options: []) else {
      fatalError("Unable to create rect vertex buffer")
    }
    self.vertexBuffer = vertexBuffer
    
    guard let uvBuffer = Renderer.device.makeBuffer(
      bytes: &uv,
      length: MemoryLayout<float2>.stride * uv.count,
      options: []) else {
      fatalError("Unable to create rect uv buffer")
    }
    self.uvBuffer = uvBuffer
    
    guard let indexBuffer = Renderer.device.makeBuffer(
      bytes: &indices,
      length: MemoryLayout<UInt16>.stride * indices.count,
      options: []) else {
      fatalError("Unable to create rect index buffer")
    }
    self.indexBuffer = indexBuffer
  }
}
