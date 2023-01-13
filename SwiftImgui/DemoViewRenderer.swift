//
//  DemoViewRenderer.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import MetalKit
import Foundation

let formatter = {
  var value = NumberFormatter()
  value.maximumFractionDigits = 1
  value.minimumFractionDigits = 1
  return value
}

var textValue =
"""
----------------------------------------------------------------------------------------------------------
"""

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
    
    fontAtlas = buildFontAtlas(fontName: fontName)
    setFontAtlas(fontAtlas)
    
    initScene()
  }
  
  func updateTime() {
    let currentTime = CFAbsoluteTimeGetCurrent()
    deltaTime = Float(currentTime - lastTime)
    time += deltaTime
    lastTime = currentTime
    
    setTime(value: time)
  }
  
  func updateUniforms() {
    metalView.clearColor = clearColor
    
    //    uniforms.viewMatrix = camera.viewMatrix
    //    params.cameraPosition = camera.position
  }
  
  var fontAtlas: FontAtlas!
  let fontName = "JetBrains Mono NL"
  
  // 1024 & 2048 & 4096
  let fontAtlasSize = 2048
  var textBuffer: MTLBuffer!
  var fontTexture: MTLTexture!
  
  func initScene() {
    print("init")
    for _ in 0..<20 {
      textValue +=
      """
      \nLorem Ipsum is simply dummy text of the printing and typesetting industry.
      Lorem Ipsum has been the industry's standard dummy text ever since the 1500s,
      when an unknown printer took a galley of type and scrambled it to make a type specimen book.
      It has survived not only five centuries, but also the leap into electronic typesetting,
      remaining essentially unchanged.
      It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages,
      and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
      ----------------------------------------------------------------------------------------------------------
      """
    }
    print(textValue.count)
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
    
//    image(position: float2(0, 0), size: float2(100, 100), texture: TextureController.texture(filename: "image1.jpeg")!)
//    image(position: float2(100, 0), size: float2(100, 100), texture: TextureController.texture(filename: "image2.jpeg")!)
//    image(position: float2(0, 100), size: float2(100, 100), texture: TextureController.texture(filename: "image3.jpeg")!)
//    image(position: float2(100, 100), size: float2(100, 100), texture: TextureController.texture(filename: "image4.jpeg")!)
//    let size = Int(1 + (1000 * remap(value: sin(time), inMinMax: float2(-1, 1), outMinMax: float2(0, 1))))
//    let time = formatter().string(from: time as NSNumber)!
//    let size = 1 + 1000 * remap(value: sin(time), inMinMax: float2(-1, 1), outMinMax: float2(0, 1))
    setFontSize(100)
    benchmark(title: "Build text") {
      text(
        position: float2(),
        size: float2(),
        text: "Hello world!"
      )
    }
//    text(position: float2(0, 0), size: float2(500, 200), text: "How are you?", fontSize: 64)
    
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
