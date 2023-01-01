//
//  DemoViewRenderer.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import MetalKit
import Foundation

class DemoViewRenderer : ViewRenderer {
  // scene data
  
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
  var time: Float = 0
  
  // uniforms and params
  var uniforms = Uniforms()
  var params = Params()
  
  override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    //    camera.update(size: size)
    params.width = UInt32(size.width)
    params.height = UInt32(size.height)
    let width = view.frame.width
    let height = view.frame.height
    // view frame size should be passed
    uniforms.projectionMatrix = float4x4(left: 0, right: Float(width), bottom: Float(height), top: 0, near: -1, far: 1)
    setProjectionMatrix(matrix: uniforms.projectionMatrix)
    setViewMatrix(matrix: float4x4.identity)
  }
  
  override func initialize(metalView: MTKView) {
    super.initialize(metalView: metalView)
    initScene()
  }
  
  func updateTime() {
    let currentTime = CFAbsoluteTimeGetCurrent()
    deltaTime = Float(currentTime - lastTime)
    time += deltaTime
    lastTime = currentTime
  }
  
  func updateUniforms() {
    metalView.clearColor = clearColor
    
    //    uniforms.viewMatrix = camera.viewMatrix
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
    
    startFrame()
    
//    renderEncoder.setCullMode(.back)
//    for y in 0..<10 {
//      for x in 0..<10 {
//        let size = 50
//        let color = ((x + y) % 2) == 0 ? float4(1, 0, 0, 1) : float4(0, 1, 0, 0)
//        rect(position: float2(Float(x * size), Float(y * size)), size: float2(Float(size), Float(size)), color: color)
//      }
//    }
    
    for _ in 0..<1000 {
      image(position: float2(0, 0), size: float2(100, 100), texture: TextureController.texture(filename: "image1.jpeg")!)
      image(position: float2(100, 0), size: float2(100, 100), texture: TextureController.texture(filename: "image2.jpeg")!)
      image(position: float2(0, 100), size: float2(100, 100), texture: TextureController.texture(filename: "image3.jpeg")!)
      image(position: float2(100, 100), size: float2(100, 100), texture: TextureController.texture(filename: "image4.jpeg")!)
    }
    
//    rect(position: float2(200 + cos(time * 5) * 100, 200 + sin(time * 5) * 100), size: float2(100, 100), color: float4(0, 1, 0, 1))
    
    endFrame()
    
    drawData(at: renderEncoder)
    //    var quadMaterial = QuadMaterial()
    //    quadMaterial.color = [1, 0, 0, 1]
    //    Renderer.draw(at: renderEncoder, quadMaterial: &quadMaterial)
    
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
