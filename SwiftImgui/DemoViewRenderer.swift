//
//  DemoViewRenderer.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import MetalKit

class DemoViewRenderer : ViewRenderer {
  // scene data
  lazy var quad: Quad = {
    Quad(scale: 0.8)
  }()
//  var camera = FPCamera()
  
  // -
  var clearColor = MTLClearColor(
    red: 0.93,
    green: 0.97,
    blue: 1.0,
    alpha: 1.0
  )
  
  // time
  var lastTime: Double = CFAbsoluteTimeGetCurrent()
  var deltaTime: Float!
  
  // uniforms and params
  var uniforms = Uniforms()
  var params = Params()
  
  override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//    camera.update(size: size)
    params.width = UInt32(size.width)
    params.height = UInt32(size.height)
  }
  
  override func initialize(metalView: MTKView) {
    super.initialize(metalView: metalView)
    initScene()
  }
  
  func updateTime() {
    let currentTime = CFAbsoluteTimeGetCurrent()
    deltaTime = Float(currentTime - lastTime)
    lastTime = currentTime
  }
  
  func updateUniforms() {
    metalView.clearColor = clearColor
    
//    uniforms.viewMatrix = camera.viewMatrix
//    uniforms.projectionMatrix = camera.projectionMatrix
//
//    params.cameraPosition = camera.position
  }
  
  func initScene() {
    print("init")
  }
  
  override func draw(in view: MTKView) {
    guard
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let descriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
        print("failed to draw")
      return
    }
    
    updateTime()
    update(deltaTime: deltaTime)
    updateUniforms()
    
    renderEncoder.setRenderPipelineState(Renderer.pipelineState)
    
    renderEncoder.setVertexBuffer(
      quad.vertexBuffer,
      offset: 0,
      index: 0)

    renderEncoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: quad.indices.count,
      indexType: .uint16,
      indexBuffer: quad.indexBuffer,
      indexBufferOffset: 0
    )
    
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
