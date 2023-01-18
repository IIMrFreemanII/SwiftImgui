import MetalKit

struct Renderer {
  static var rect: RectMesh = {
    RectMesh()
  }()
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  static var colorPixelFormat: MTLPixelFormat!
  
  static var rectPipelineState: MTLRenderPipelineState!
  static var imagePipelineState: MTLRenderPipelineState!
  static var vectorTextPipelineState: MTLRenderPipelineState!
  static var textPipelineState: MTLRenderPipelineState!
  static var sdfTexturePipelineState: MTLRenderPipelineState!
  
  static var textSampler: MTLSamplerState!
  //  static var depthStencilState: MTLDepthStencilState!
  
  static func initialize() -> Void {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
      fatalError("GPU not available")
    }
    Self.device = device
    Self.commandQueue = commandQueue
    
    // create the shader function library
    Self.library = Self.device.makeDefaultLibrary()
    Self.colorPixelFormat = .bgra8Unorm
    
//    depthStencilState = buildDepthStencilState()
    Self.rectPipelineState = buildRectPipelineState()
    Self.imagePipelineState = buildImagePipelineState()
    Self.vectorTextPipelineState = buildVectorTextPipelineState()
    Self.textPipelineState = buildTextPipelineState()
    Self.sdfTexturePipelineState = buildSDFTexturePSO()
    
    Self.textSampler = buildTextSampler()
    
    Self.rectBuffer = Self.device.makeBuffer(length: MemoryLayout<Rect>.stride * Self.rectsCount)
  }
  
  static func buildRectPipelineState() -> MTLRenderPipelineState {
    let vertexFunction = library?.makeFunction(name: "vertex_rect")
    let fragmentFunction = library?.makeFunction(name: "fragment_rect")
    
    // create the pipeline state object
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Rect Pipeline State"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat =
      Self.colorPixelFormat
    do {
      pipelineDescriptor.vertexDescriptor =
        MTLVertexDescriptor.rectLayout
      return try Self.device.makeRenderPipelineState(
        descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  static func buildImagePipelineState() -> MTLRenderPipelineState {
    let vertexFunction = library?.makeFunction(name: "vertex_image")
    let fragmentFunction = library?.makeFunction(name: "fragment_image")
    
    // create the pipeline state object
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Image Pipeline State"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat =
      Self.colorPixelFormat
    do {
      pipelineDescriptor.vertexDescriptor =
        MTLVertexDescriptor.rectLayout
      return try Self.device.makeRenderPipelineState(
          descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  static func buildVectorTextPipelineState() -> MTLRenderPipelineState {
    let vertexFunction = library?.makeFunction(name: "vertex_vector_text")
    let fragmentFunction = library?.makeFunction(name: "fragment_vector_text")
    
    // create the pipeline state object
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Vector Text Pipeline State"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat =
      Self.colorPixelFormat
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled =
      true
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
    
    do {
      pipelineDescriptor.vertexDescriptor =
        MTLVertexDescriptor.rectLayout
      return try Self.device.makeRenderPipelineState(
          descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  static func buildTextPipelineState() -> MTLRenderPipelineState {
    let vertexFunction = library?.makeFunction(name: "vertex_text")
    let fragmentFunction = library?.makeFunction(name: "fragment_text")
    
    // create the pipeline state object
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Text Pipeline State"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat =
      Self.colorPixelFormat
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled =
      true
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
    
    do {
      pipelineDescriptor.vertexDescriptor =
        MTLVertexDescriptor.rectLayout
      return try Self.device.makeRenderPipelineState(
          descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  static func buildSDFTexturePSO() -> MTLRenderPipelineState {
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "SDF Texture Pipeline State"
    let vertexFunction =
    Renderer.library?.makeFunction(name: "vertex_sdf_vector_text")
    let fragmentFunction =
    Renderer.library?.makeFunction(name: "fragment_sdf_vector_text")
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .r32Float
    pipelineDescriptor.depthAttachmentPixelFormat = .invalid
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.rectLayout
    
    do {
      return try Renderer.device.makeRenderPipelineState(
          descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  static func buildTextSampler() -> MTLSamplerState {
    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.minFilter = .nearest
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.sAddressMode = .clampToZero
    samplerDescriptor.tAddressMode = .clampToZero
    
    return Self.device.makeSamplerState(descriptor: samplerDescriptor)!
  }
  
  static func makeTexture(
    size: CGSize,
    pixelFormat: MTLPixelFormat,
    label: String,
    storageMode: MTLStorageMode = .private,
    usage: MTLTextureUsage = [.shaderRead, .renderTarget]
  ) -> MTLTexture? {
    let width = Int(size.width)
    let height = Int(size.height)
    guard width > 0 && height > 0 else { return nil }
    let textureDesc =
      MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: pixelFormat,
        width: width,
        height: height,
        mipmapped: false)
    textureDesc.storageMode = storageMode
    textureDesc.usage = usage
    guard let texture =
      Renderer.device.makeTexture(descriptor: textureDesc) else {
        fatalError("Failed to create texture")
      }
    texture.label = label
    return texture
  }
}

extension Renderer {
  static var rectBuffer: MTLBuffer!
  static var rectsCount: Int = 1
  static func drawRectsInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, rects: inout [Rect]) {
    guard rects.count != 0 else { return }
      
    if Self.rectsCount < rects.count {
      Self.rectsCount = rects.count * 2
      Self.rectBuffer = Self.device.makeBuffer(length: MemoryLayout<Rect>.stride * Self.rectsCount)
      Self.rectBuffer?.label = "Rect Buffer"
    }
    encoder.setRenderPipelineState(Renderer.rectPipelineState)
    
    encoder.setVertexBuffer(
      Self.rect.vertexBuffer,
      offset: 0,
      index: 0
    )
    encoder.setVertexBuffer(
      Self.rect.uvBuffer,
      offset: 0,
      index: 1
    )
    
    encoder.setVertexBytes(&vertex, length: MemoryLayout<RectVertexData>.stride, index: 10)
    
    Self.rectBuffer.contents().copyMemory(from: &rects, byteCount: MemoryLayout<Rect>.stride * rects.count)
    encoder.setVertexBuffer(Self.rectBuffer, offset: 0, index: 11)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Self.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: rects.count
    )
  }
  
  static func drawImagesInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, images: inout [Image], textures: inout [MTLTexture]) {
    guard images.count != 0 else { return }
    
    encoder.setRenderPipelineState(Renderer.imagePipelineState)
    
    encoder.setVertexBuffer(
      Self.rect.vertexBuffer,
      offset: 0,
      index: 0
    )
    encoder.setVertexBuffer(
      Self.rect.uvBuffer,
      offset: 0,
      index: 1
    )
    
    encoder.setVertexBytes(&vertex, length: MemoryLayout<RectVertexData>.stride, index: 10)
    
    let imagesBuffer = Self.device.makeBuffer(bytes: &images, length: MemoryLayout<Image>.stride * images.count)
    imagesBuffer?.label = "Image buffer"
    encoder.setVertexBuffer(imagesBuffer, offset: 0, index: 11)
    
    encoder.setFragmentTextures(textures, range: textures.indices)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Self.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: images.count
    )
  }
  
  static func drawTextInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, glyphs: inout [SDFGlyph], texture: MTLTexture) {
    guard !glyphs.isEmpty else { return }

    encoder.setRenderPipelineState(Renderer.textPipelineState)

    encoder.setVertexBuffer(
      Self.rect.vertexBuffer,
      offset: 0,
      index: 0
    )
    encoder.setVertexBuffer(
      Self.rect.uvBuffer,
      offset: 0,
      index: 1
    )

    encoder.setVertexBytes(&vertex, length: MemoryLayout<RectVertexData>.stride, index: 10)
    let glyphBuffer = Self.device.makeBuffer(bytes: &glyphs, length: MemoryLayout<SDFGlyph>.stride * glyphs.count)
    glyphBuffer?.label = "Glyph Buffer"
    encoder.setVertexBuffer(glyphBuffer, offset: 0, index: 11)

    encoder.setFragmentSamplerState(Renderer.textSampler, index: 0)
    encoder.setFragmentTexture(texture, index: 0)

    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Self.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: glyphs.count
    )
  }
  
  static func drawVectorTextInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, glyphs: inout [Glyph], pathElemBuffer: MTLBuffer, subPathBuffer: MTLBuffer) {
    guard !glyphs.isEmpty else { return }
    
    encoder.setRenderPipelineState(Renderer.vectorTextPipelineState)
    
    encoder.setVertexBuffer(
      Self.rect.vertexBuffer,
      offset: 0,
      index: 0
    )
    encoder.setVertexBuffer(
      Self.rect.uvBuffer,
      offset: 0,
      index: 1
    )
    
    encoder.setVertexBytes(&vertex, length: MemoryLayout<RectVertexData>.stride, index: 10)
    let glyphBuffer = Self.device.makeBuffer(bytes: &glyphs, length: MemoryLayout<Glyph>.stride * glyphs.count)
    glyphBuffer?.label = "Glyph Buffer"
    encoder.setVertexBuffer(glyphBuffer, offset: 0, index: 11)
    
    encoder.setFragmentBuffer(pathElemBuffer, offset: 0, index: 0)
    encoder.setFragmentBuffer(subPathBuffer, offset: 0, index: 1)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Self.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: glyphs.count
    )
  }
  
  static func drawSDFVectorTextInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, glyphs: inout [Glyph], pathElemBuffer: MTLBuffer, subPathBuffer: MTLBuffer) {
    guard !glyphs.isEmpty else { return }
    
    encoder.setRenderPipelineState(Renderer.sdfTexturePipelineState)
    
    encoder.setVertexBuffer(
      Self.rect.vertexBuffer,
      offset: 0,
      index: 0
    )
    encoder.setVertexBuffer(
      Self.rect.uvBuffer,
      offset: 0,
      index: 1
    )
    
    encoder.setVertexBytes(&vertex, length: MemoryLayout<RectVertexData>.stride, index: 10)
    let glyphBuffer = Self.device.makeBuffer(bytes: &glyphs, length: MemoryLayout<Glyph>.stride * glyphs.count)
    glyphBuffer?.label = "Glyph Buffer"
    encoder.setVertexBuffer(glyphBuffer, offset: 0, index: 11)
    
    encoder.setFragmentBuffer(pathElemBuffer, offset: 0, index: 0)
    encoder.setFragmentBuffer(subPathBuffer, offset: 0, index: 1)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Self.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: glyphs.count
    )
  }
}

// draw debug
extension Renderer {
  static let linePipelineState: MTLRenderPipelineState = {
    let library = Renderer.library
    let vertexFunction = library?.makeFunction(name: "vertex_debug")
    let fragmentFunction = library?.makeFunction(name: "fragment_debug_line")
    let psoDescriptor = MTLRenderPipelineDescriptor()
    psoDescriptor.vertexFunction = vertexFunction
    psoDescriptor.fragmentFunction = fragmentFunction
    psoDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    psoDescriptor.depthAttachmentPixelFormat = .depth32Float
    let pipelineState: MTLRenderPipelineState
    do {
      pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: psoDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }()
  
  static let pointPipelineState: MTLRenderPipelineState = {
    let library = Renderer.library
    let vertexFunction = library?.makeFunction(name: "vertex_debug")
    let fragmentFunction = library?.makeFunction(name: "fragment_debug_point")
    let psoDescriptor = MTLRenderPipelineDescriptor()
    psoDescriptor.vertexFunction = vertexFunction
    psoDescriptor.fragmentFunction = fragmentFunction
    psoDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    psoDescriptor.depthAttachmentPixelFormat = .depth32Float
    let pipelineState: MTLRenderPipelineState
    do {
      pipelineState = try Renderer.device.makeRenderPipelineState(
        descriptor: psoDescriptor
      )
    } catch let error {
      fatalError(error.localizedDescription)
    }
    return pipelineState
  }()
  
  static func drawPoint(
    at encoder: MTLRenderCommandEncoder,
    uniforms: Uniforms,
    position: float3,
    color: float3
  ) {
    var vertices = [position]
    encoder.setVertexBytes(&vertices, length: MemoryLayout<float3>.stride, index: 0)
    var uniforms = uniforms
//    uniforms.modelMatrix = .identity
    encoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index)
    var lightColor = color
    encoder.setFragmentBytes(
      &lightColor,
      length: MemoryLayout<float3>.stride,
      index: 1)
    encoder.setRenderPipelineState(pointPipelineState)
    encoder.drawPrimitives(
      type: .point,
      vertexStart: 0,
      vertexCount: vertices.count)
  }

  static func drawLine(
    at renderEncoder: MTLRenderCommandEncoder,
    uniforms: Uniforms,
    position: float3,
    direction: float3,
    color: float3
  ) {
    var vertices: [float3] = []
    vertices.append(position)
    vertices.append(float3(
      position.x + direction.x,
      position.y + direction.y,
      position.z + direction.z))
    
    renderEncoder.setVertexBytes(&vertices, length: MemoryLayout<float3>.stride * vertices.count, index: 0)
    var lightColor = color
    renderEncoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
    
    var uniforms = uniforms
//    uniforms.modelMatrix = .identity
    renderEncoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index
    )
    
    // render line
    renderEncoder.setRenderPipelineState(linePipelineState)
    renderEncoder.drawPrimitives(
      type: .line,
      vertexStart: 0,
      vertexCount: vertices.count)
    // render starting point
    renderEncoder.setRenderPipelineState(pointPipelineState)
    renderEncoder.drawPrimitives(
      type: .point,
      vertexStart: 0,
      vertexCount: 1)
  }
  
  static func drawLine(
    at renderEncoder: MTLRenderCommandEncoder,
    uniforms: Uniforms,
    from: float3,
    to: float3,
    color: float3
  ) {
    var vertices: [float3] = [from, to]
    renderEncoder.setVertexBytes(&vertices, length: MemoryLayout<float3>.stride * vertices.count, index: 0)
    var lightColor = color
    renderEncoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
    
    var uniforms = uniforms
//    uniforms.modelMatrix = .identity
    renderEncoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index
    )
    
    // render line
    renderEncoder.setRenderPipelineState(linePipelineState)
    renderEncoder.drawPrimitives(
      type: .line,
      vertexStart: 0,
      vertexCount: vertices.count)
    
    // render starting point
    renderEncoder.setRenderPipelineState(pointPipelineState)
    renderEncoder.drawPrimitives(
      type: .point,
      vertexStart: 0,
      vertexCount: 1)
  }
}
