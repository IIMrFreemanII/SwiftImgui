import MetalKit

func getQuadVertices(w: Float, h: Float, x: Float = 0, y: Float = 0) -> [float3] {
  return [
    float3(x, y, 0),
    float3(x + w, y, 0),
    float3(x, y + h, 0),
    float3(x + w, y + h, 0),
  ]
}

struct Quad {
//  var vertices: [float3] = [
//    [-0.5,  0.5,  0],
//    [0.5,  0.5,  0],
//    [-0.5, -0.5,  0],
//    [0.5, -0.5,  0],
//  ]
  var vertices = getQuadVertices(w: 1, h: 1)

  var indices: [UInt16] = [
    0, 3, 2,
    0, 1, 3
  ]
  
  let vertexBuffer: MTLBuffer
  let indexBuffer: MTLBuffer

  init() {
    guard let vertexBuffer = Renderer.device.makeBuffer(
      bytes: &vertices,
      length: MemoryLayout<float3>.stride * vertices.count,
      options: []) else {
      fatalError("Unable to create quad vertex buffer")
    }
    self.vertexBuffer = vertexBuffer
    
    guard let indexBuffer = Renderer.device.makeBuffer(
      bytes: &indices,
      length: MemoryLayout<UInt16>.stride * indices.count,
      options: []) else {
      fatalError("Unable to create quad index buffer")
    }
    self.indexBuffer = indexBuffer
  }
}
