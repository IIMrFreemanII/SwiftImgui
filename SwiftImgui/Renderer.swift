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
  static var linePipelineState: MTLRenderPipelineState!
  static var circlePipelineState: MTLRenderPipelineState!
  static var imagePipelineState: MTLRenderPipelineState!
  static var vectorTextPipelineState: MTLRenderPipelineState!
  static var textPipelineState: MTLRenderPipelineState!
  static var sdfTexturePipelineState: MTLRenderPipelineState!
  
  static var textSampler: MTLSamplerState!
  static var depthStencilState: MTLDepthStencilState!
  
  static func initialize() -> Void {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
      fatalError("GPU not available")
    }
    Self.device = device
    Self.commandQueue = commandQueue
    
    // create the shader function library
    benchmark(title: "Build shaders") {
      Self.library = Self.device.makeDefaultLibrary()
    }
    Self.colorPixelFormat = .bgra8Unorm
    
    Self.depthStencilState = buildDepthStencilState()
    Self.rectPipelineState = buildRectPipelineState()
    Self.linePipelineState = buildLinePipelineState()
    Self.circlePipelineState = buildCirclePipelineState()
    Self.imagePipelineState = buildImagePipelineState()
    Self.vectorTextPipelineState = buildVectorTextPipelineState()
    Self.textPipelineState = buildTextPipelineState()
    Self.sdfTexturePipelineState = buildSDFTexturePSO()
    
    Self.textSampler = buildTextSampler()
    
    Self.rectBuffer = Self.device.makeBuffer(length: MemoryLayout<RectProps>.stride * Self.rectsCount)
    Self.clipRectBuffer = Self.device.makeBuffer(length: MemoryLayout<ClipRect>.stride * Self.clipRecstCount)
    Self.circleBuffer = Self.device.makeBuffer(length: MemoryLayout<Circle>.stride * Self.circlesCount)
    Self.lineBuffer = Self.device.makeBuffer(length: MemoryLayout<Line>.stride * Self.linesCount)
    Self.glyphsBuffer = Self.device.makeBuffer(length: MemoryLayout<SDFGlyph>.stride * Self.glyphsCount)
    Self.glyphsStyleBuffer = Self.device.makeBuffer(length: MemoryLayout<SDFGlyphStyle>.stride * Self.glyphsStyleCount)
    
//    BlurPass.initialize()
//    CopyPass.initialize()
  }
  
  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.label = "Depth Stencil State"
    descriptor.depthCompareFunction = .lessEqual
    descriptor.isDepthWriteEnabled = true
    return Renderer.device.makeDepthStencilState(
      descriptor: descriptor)
  }
  
  static func buildCirclePipelineState() -> MTLRenderPipelineState {
    let vertexFunction = library?.makeFunction(name: "vertex_circle")
    let fragmentFunction = library?.makeFunction(name: "fragment_circle")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Circle Pipeline State"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat =
      Self.colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled =
      true
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
    pipelineDescriptor.vertexDescriptor =
      MTLVertexDescriptor.rectLayout
    
    do {
      return try Self.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }

  static func buildLinePipelineState() -> MTLRenderPipelineState {
    let vertexFunction = library?.makeFunction(name: "vertex_line")
    let fragmentFunction = library?.makeFunction(name: "fragment_line")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Line Pipeline State"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat =
      Self.colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.vertexDescriptor =
      MTLVertexDescriptor.rectLayout
    
    do {
      return try Self.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
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
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled =
      true
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
    pipelineDescriptor.vertexDescriptor =
      MTLVertexDescriptor.rectLayout
    
    do {
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
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
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
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
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
  static var clipRectBuffer: MTLBuffer!
  static var clipRecstCount: Int = 1
  
  static func bindClipRects(at encoder: MTLRenderCommandEncoder, rects: inout [ClipRect], rectsCount: Int) {
    if Self.clipRecstCount < rectsCount {
      Self.clipRecstCount = rectsCount * 2
      Self.clipRectBuffer = Self.device.makeBuffer(length: MemoryLayout<ClipRect>.stride * Self.clipRecstCount)
      Self.clipRectBuffer?.label = "Clip Rect Buffer"
    }
    
    Self.clipRectBuffer.contents().copyMemory(from: &rects, byteCount: MemoryLayout<ClipRect>.stride * rectsCount)
  }
  
  static var circleBuffer: MTLBuffer!
  static var circlesCount: Int = 1
  
  static func drawCirclesInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, circles: inout [Circle], circlesCount: Int) {
    guard circlesCount != 0 else { return }
      
    if Self.circlesCount < circlesCount {
      Self.circlesCount = circlesCount * 2
      Self.circleBuffer = Self.device.makeBuffer(length: MemoryLayout<Circle>.stride * Self.circlesCount)
      Self.circleBuffer?.label = "Circle Buffer"
    }
    
    encoder.setRenderPipelineState(Self.circlePipelineState)
    encoder.setDepthStencilState(Self.depthStencilState)
    
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
    
    Self.circleBuffer.contents().copyMemory(from: &circles, byteCount: MemoryLayout<Circle>.stride * circlesCount)
    encoder.setVertexBuffer(Self.circleBuffer, offset: 0, index: 11)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Self.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: circlesCount
    )
  }
  
  static var lineBuffer: MTLBuffer!
  static var linesCount: Int = 1
  
  static func drawLinesInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, lines: inout [Line], linesCount: Int) {
    guard linesCount != 0 else { return }
      
    if Self.linesCount < linesCount {
      Self.linesCount = linesCount * 2
      Self.lineBuffer = Self.device.makeBuffer(length: MemoryLayout<Line>.stride * Self.linesCount)
      Self.lineBuffer?.label = "Line Buffer"
    }
    
    encoder.setRenderPipelineState(Self.linePipelineState)
    encoder.setDepthStencilState(Self.depthStencilState)
    
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
    
    Self.lineBuffer.contents().copyMemory(from: &lines, byteCount: MemoryLayout<Line>.stride * linesCount)
    encoder.setVertexBuffer(Self.lineBuffer, offset: 0, index: 11)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Self.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: linesCount
    )
  }
  
  
  static var rectBuffer: MTLBuffer!
  static var rectsCount: Int = 1
  static func drawRectsInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, rects: inout [RectProps], rectsCount: Int) {
    guard rectsCount != 0 else { return }
      
    if Self.rectsCount < rectsCount {
      Self.rectsCount = rectsCount * 2
      Self.rectBuffer = Self.device.makeBuffer(length: MemoryLayout<RectProps>.stride * Self.rectsCount)
      Self.rectBuffer?.label = "Rect Buffer"
    }
    encoder.setRenderPipelineState(Self.rectPipelineState)
    encoder.setDepthStencilState(Self.depthStencilState)
    
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
    
    Self.rectBuffer.contents().copyMemory(from: &rects, byteCount: MemoryLayout<RectProps>.stride * rectsCount)
    encoder.setVertexBuffer(Self.rectBuffer, offset: 0, index: 11)
    
    encoder.setFragmentBuffer(Self.clipRectBuffer, offset: 0, index: 11)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Self.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: rectsCount
    )
  }
  
  static func drawImagesInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, images: inout [Image], textures: inout [MTLTexture]) {
    guard images.count != 0 else { return }
    
    encoder.setRenderPipelineState(Self.imagePipelineState)
    encoder.setDepthStencilState(Self.depthStencilState)
    
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
    
    encoder.setFragmentBuffer(Self.clipRectBuffer, offset: 0, index: 11)
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
  
  static var glyphsBuffer: MTLBuffer!
  static var glyphsCount: Int = 1
  static var glyphsStyleBuffer: MTLBuffer!
  static var glyphsStyleCount: Int = 1
  static func drawTextInstanced(
    at encoder: MTLRenderCommandEncoder,
    uniforms vertex: inout RectVertexData,
    glyphs: inout [SDFGlyph],
    glyphsCount: Int,
    glyphsStyle: inout [SDFGlyphStyle],
    glyphsStyleCount: Int,
    font: Font
  ) {
    guard !glyphs.isEmpty && glyphsCount != 0 else { return }
    if glyphsCount > glyphs.count {
      print("Error: exceeded maximum glyphs count -> \(glyphsCount). Limit: \(glyphs.count)")
    }
    if Self.glyphsCount < glyphsCount {
      Self.glyphsCount = glyphsCount * 2
      Self.glyphsBuffer = Self.device.makeBuffer(length: MemoryLayout<SDFGlyph>.stride * Self.glyphsCount)
      Self.glyphsBuffer!.label = "Glyphs Buffer"
    }
    if Self.glyphsStyleCount < glyphsStyleCount {
      Self.glyphsStyleCount = glyphsStyleCount * 2
      Self.glyphsStyleBuffer = Self.device.makeBuffer(length: MemoryLayout<SDFGlyphStyle>.stride * Self.glyphsStyleCount)
      Self.glyphsStyleBuffer!.label = "Glyphs Style Buffer"
    }
    
    encoder.setRenderPipelineState(Self.textPipelineState)
    encoder.setDepthStencilState(Self.depthStencilState)
    
    encoder.useResources(font.sdfGlyphTextures, usage: .read, stages: [.vertex, .fragment])

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
    
    Self.glyphsBuffer.contents().copyMemory(from: &glyphs, byteCount: MemoryLayout<SDFGlyph>.stride * glyphsCount)
    encoder.setVertexBuffer(Self.glyphsBuffer, offset: 0, index: 11)
    
    Self.glyphsStyleBuffer.contents().copyMemory(from: &glyphsStyle, byteCount: MemoryLayout<SDFGlyphStyle>.stride * glyphsStyleCount)
    encoder.setVertexBuffer(Self.glyphsStyleBuffer, offset: 0, index: 12)
    encoder.setVertexBuffer(font.glyphSDFBuffer, offset: 0, index: 9)

    encoder.setFragmentSamplerState(Renderer.textSampler, index: 0)
    encoder.setFragmentBuffer(font.glyphSDFBuffer, offset: 0, index: 9)

    encoder.setFragmentBuffer(Self.clipRectBuffer, offset: 0, index: 11)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Self.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Self.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: glyphsCount
    )
  }
  
//  static func drawVectorTextInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, glyphs: inout [Glyph], pathElemBuffer: MTLBuffer, subPathBuffer: MTLBuffer) {
//    guard !glyphs.isEmpty else { return }
//
//    encoder.setRenderPipelineState(Renderer.vectorTextPipelineState)
//
//    encoder.setVertexBuffer(
//      Self.rect.vertexBuffer,
//      offset: 0,
//      index: 0
//    )
//    encoder.setVertexBuffer(
//      Self.rect.uvBuffer,
//      offset: 0,
//      index: 1
//    )
//
//    encoder.setVertexBytes(&vertex, length: MemoryLayout<RectVertexData>.stride, index: 10)
//    let glyphBuffer = Self.device.makeBuffer(bytes: &glyphs, length: MemoryLayout<Glyph>.stride * glyphs.count)
//    glyphBuffer?.label = "Glyph Buffer"
//    encoder.setVertexBuffer(glyphBuffer, offset: 0, index: 11)
//
//    encoder.setFragmentBuffer(pathElemBuffer, offset: 0, index: 0)
//    encoder.setFragmentBuffer(subPathBuffer, offset: 0, index: 1)
//
//    encoder.drawIndexedPrimitives(
//      type: .triangle,
//      indexCount: Self.rect.indices.count,
//      indexType: .uint16,
//      indexBuffer: Self.rect.indexBuffer,
//      indexBufferOffset: 0,
//      instanceCount: glyphs.count
//    )
//  }
  
  static func drawSDFVectorTextInstanced(at encoder: MTLRenderCommandEncoder, uniforms vertex: inout RectVertexData, glyphs: inout [Glyph], pathElemBuffer: MTLBuffer, subPathBuffer: MTLBuffer) {
    guard !glyphs.isEmpty else { return }
    
    encoder.setRenderPipelineState(Self.sdfTexturePipelineState)
    
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
    glyphBuffer?.label = "SDF Vector Glyph Buffer"
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
