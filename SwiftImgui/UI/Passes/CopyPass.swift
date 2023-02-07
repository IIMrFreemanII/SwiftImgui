//
//  CopyPass.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 06.02.2023.
//

import MetalKit

var copyRects = Array(repeating: Rect(), count: 10)
var copyRectsCount: Int = 0

func copy(rect: Rect) {
  copyRects.withUnsafeMutableBufferPointer { buffer in
    buffer[copyRectsCount] = rect
    
    copyRectsCount += 1
  }
}

struct CopyPass {
  static var label = "Copy Pass"
  static var descriptor: MTLRenderPassDescriptor!
  static var pipelineState: MTLRenderPipelineState!
  
  static var sourceTexture: MTLTexture!
  static var outputTexture: MTLTexture!
  
  static var rectsBuffer: MTLBuffer!
  static var rectsCount: Int = 1
  
  static func initialize() {
    let descriptor = MTLRenderPassDescriptor()
    
    descriptor.colorAttachments[0].loadAction = .load
    descriptor.colorAttachments[0].storeAction = .store
    
    Self.descriptor = descriptor
    
//    Self.depthStencilState = buildDepthStencilState()
    Self.pipelineState = Self.createCopyRectPSO()
    
    Self.rectsBuffer = Renderer.device.makeBuffer(length: MemoryLayout<BlurRect>.stride * Self.rectsCount)
  }
  
  static func createCopyRectPSO() -> MTLRenderPipelineState {
    let vertexFunction = Renderer.library.makeFunction(name: "vertex_copy")
    let fragmentFunction = Renderer.library.makeFunction(name: "fragment_copy")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Copy Pipeline State"
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
  
  static func draw(commandBuffer: MTLCommandBuffer, uniforms vertex: inout RectVertexData, copyRects: inout [Rect], count: Int) {
    if Self.rectsCount < count {
      Self.rectsCount = count * 2
      Self.rectsBuffer = Renderer.device.makeBuffer(length: MemoryLayout<Rect>.stride * Self.rectsCount)
      Self.rectsBuffer?.label = "Copy Rect Buffer"
    }
    
    Self.descriptor.colorAttachments[0].texture = Self.outputTexture
    
    guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: Self.descriptor) else {
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
    
    Self.rectsBuffer.contents().copyMemory(from: &copyRects, byteCount: MemoryLayout<Rect>.stride * count)
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
    
    encoder.endEncoding()
  }
}
