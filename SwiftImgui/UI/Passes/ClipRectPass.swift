//
//  ClipRectPass.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.01.2023.
//

import MetalKit

struct ClipRectPass {
  static var label = "Clip Rect Pass"
  static var descriptor: MTLRenderPassDescriptor!
//  static var depthStencilState: MTLDepthStencilState!
  static var pipelineState: MTLRenderPipelineState!
  
  static var clipIdTexture: MTLTexture!
  static var opacityTexture: MTLTexture!
  
  static var rectsBuffer: MTLBuffer!
  static var rectsCount: Int = 1
  
  static func initialize() {
    let descriptor = MTLRenderPassDescriptor()
    descriptor.colorAttachments[0].loadAction = .clear
    descriptor.colorAttachments[0].storeAction = .store
    descriptor.colorAttachments[1].loadAction = .clear
    descriptor.colorAttachments[1].storeAction = .store
    
    Self.descriptor = descriptor
    
//    Self.depthStencilState = buildDepthStencilState()
    Self.pipelineState = createClipRectPSO()
    
    Self.rectsBuffer = Renderer.device.makeBuffer(length: MemoryLayout<ClipRect>.stride * Self.rectsCount)
  }
  
//  static func buildDepthStencilState() -> MTLDepthStencilState {
//    let descriptor = MTLDepthStencilDescriptor()
//    descriptor.label = "Clip Rect Depth Stencil State"
//    descriptor.depthCompareFunction = .lessEqual
//    descriptor.isDepthWriteEnabled = true
//    return Renderer.device.makeDepthStencilState(
//      descriptor: descriptor)!
//  }
  
  static func createClipRectPSO() -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library.makeFunction(name: "vertex_clip_rect")
    let fragmentFunction = Renderer.library.makeFunction(name: "fragment_clip_rect")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Clip Rect Pipeline State"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .r16Uint
    pipelineDescriptor.colorAttachments[1].pixelFormat = .r8Unorm
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
    Self.clipIdTexture = Renderer.makeTexture(size: size, pixelFormat: .r16Uint, label: "Clip Id Texture")
    Self.opacityTexture = Renderer.makeTexture(size: size, pixelFormat: .r8Unorm, label: "Clip Id Opacity Texture")
  }
  
  static func draw(commandBuffer: MTLCommandBuffer, uniforms vertex: inout RectVertexData, clipRects: inout [ClipRect], count: Int) {
    guard count != 0 else { return }
    
    if Self.rectsCount < count {
      Self.rectsCount = count * 2
      Self.rectsBuffer = Renderer.device.makeBuffer(length: MemoryLayout<ClipRect>.stride * Self.rectsCount)
      Self.rectsBuffer?.label = "Clip Rect Buffer"
    }
    
    descriptor.colorAttachments[0].texture = clipIdTexture
    descriptor.colorAttachments[1].texture = opacityTexture
    
    guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }
    encoder.label = Self.label
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
    
    Self.rectsBuffer.contents().copyMemory(from: &clipRects, byteCount: MemoryLayout<ClipRect>.stride * count)
    encoder.setVertexBuffer(Self.rectsBuffer, offset: 0, index: 11)
    
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: Renderer.rect.indices.count,
      indexType: .uint16,
      indexBuffer: Renderer.rect.indexBuffer,
      indexBufferOffset: 0,
      instanceCount: count
    )
    
    encoder.endEncoding()
  }
}
