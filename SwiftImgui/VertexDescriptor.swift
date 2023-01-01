import MetalKit

extension MTLVertexDescriptor {
  static var rectLayout: MTLVertexDescriptor {
    let vertexDescriptor = MTLVertexDescriptor()
    // position
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
    
    // uv
    vertexDescriptor.attributes[1].format = .float2
    vertexDescriptor.attributes[1].offset = 0
    vertexDescriptor.attributes[1].bufferIndex = 1
    vertexDescriptor.layouts[1].stride = MemoryLayout<float2>.stride
    
    return vertexDescriptor
  }
}

extension BufferIndices {
  var index: Int {
    return Int(self.rawValue)
  }
}

extension Attributes {
  var index: Int {
    return Int(self.rawValue)
  }
}

extension TextureIndices {
  var index: Int {
    return Int(self.rawValue)
  }
}

extension RenderTarget {
  var index: Int {
    return Int(rawValue)
  }
}
