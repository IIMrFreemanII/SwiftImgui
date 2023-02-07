//
//  BlurPass.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 05.02.2023.
//

import MetalKit

struct BlurRect {
  var rect = Rect()
  var blurSize: Float = 0
  var depth: Float = 0
}

var blurRects = Array(repeating: BlurRect(), count: 10)
var blurRectsCount = 0

func blur(_ rect: Rect, blurSize: Float = 0) {
  blurRects.withUnsafeMutableBufferPointer { buffer in
    buffer[blurRectsCount] = BlurRect(
      rect: rect,
      blurSize: blurSize
    )
    blurRectsCount += 1
  }
  copy(rect: rect)
}

struct BlurPass {
  static var label = "Blur Pass"
  static var descriptor: MTLRenderPassDescriptor!
  static var pipelineState: MTLRenderPipelineState!
  
  static var sourceTexture: MTLTexture!
  static var outputTexture: MTLTexture!
  
  static var rectsBuffer: MTLBuffer!
  static var rectsCount: Int = 1
  
  static func initialize() {
    let descriptor = MTLRenderPassDescriptor()
    
    descriptor.colorAttachments[0].loadAction = .clear
    descriptor.colorAttachments[0].storeAction = .store
    descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    
    Self.descriptor = descriptor
    
//    Self.depthStencilState = buildDepthStencilState()
    Self.pipelineState = Self.createBlurRectPSO()
    
    Self.rectsBuffer = Renderer.device.makeBuffer(length: MemoryLayout<BlurRect>.stride * Self.rectsCount)
  }
  
  static func createBlurRectPSO() -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library.makeFunction(name: "vertex_blur")
    let fragmentFunction = Renderer.library.makeFunction(name: "fragment_blur")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Blur Pipeline State"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = .invalid
    pipelineDescriptor.vertexDescriptor = .rectLayout
    
    do {
      return try Renderer.device.makeRenderPipelineState(
        descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
  }
  
  static func resize(view: MTKView, size: CGSize) {
    Self.outputTexture = Renderer.makeTexture(size: size, pixelFormat: Renderer.colorPixelFormat, label: "Blur Texture")
  }
  
  static func draw(commandBuffer: MTLCommandBuffer, uniforms vertex: inout RectVertexData, blurRects: inout [BlurRect], count: Int) {
    if Self.rectsCount < count {
      Self.rectsCount = count * 2
      Self.rectsBuffer = Renderer.device.makeBuffer(length: MemoryLayout<BlurRect>.stride * Self.rectsCount)
      Self.rectsBuffer?.label = "Blur Rect Buffer"
    }
    
    Self.descriptor.colorAttachments[0].texture = Self.outputTexture
    
    guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: Self.descriptor) else {
      return
    }
    encoder.label = Self.label
    
    // back to front
    encoder.setRenderPipelineState(pipelineState)
    
    encoder.setVertexBuffer(
      Renderer.rect.vertexBuffer,
      offset: 0,
      index: 0
    )
    encoder.setVertexBuffer(
      Renderer.rect.uvBuffer,
      offset: 0,
      index: 1
    )
    encoder.setVertexBytes(&vertex, length: MemoryLayout<RectVertexData>.stride, index: 10)
    
    Self.rectsBuffer.contents().copyMemory(from: &blurRects, byteCount: MemoryLayout<BlurRect>.stride * count)
    encoder.setVertexBuffer(Self.rectsBuffer, offset: 0, index: 11)
    
    encoder.setFragmentTexture(Self.sourceTexture, index: 0)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Renderer.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Renderer.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: count
    )
    
    // front to back
    
    encoder.endEncoding()
  }
}
