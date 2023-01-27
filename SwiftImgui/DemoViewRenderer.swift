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
var intTextValue = [UInt32]()

class DemoViewRenderer : ViewRenderer {
  override func start() {
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
    intTextValue = textValue.uint32
    print(textValue.count)
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    guard
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let descriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      print("failed to draw")
      return
    }
    
//    renderEncoder.setCullMode(.back)
    
    startFrame()
    
//    rect(
//      position: float2(repeating: 0),
//      size: float2(repeating: 100),
//      color: float4(0, 0, 1, 1)
//    )
//    .mouseOver { $0.color.w = 0.75 }
//    .mousePress { $0.color.w = 0.5 }
    
    benchmark(title: "Block") {
      for y in 0..<10 {
        for x in 0..<10 {
          let size = 50
          let color = ((x + y) % 2) == 0 ? float4(1, 0, 0, 1) : float4(0, 0, 1, 1)
          rect(
            position: float2(Float(x * size), Float(y * size)),
            size: float2(Float(size), Float(size)),
            color: color
          )
          .mouseOver { $0.color.w = 0.75 }
          .mousePress { $0.color.w = 0.5 }
        }
      }
    }
    
//    image(position: float2(0, 0), size: float2(100, 100), texture: TextureController.texture(filename: "image1.jpeg")!)
//    image(position: float2(100, 0), size: float2(100, 100), texture: TextureController.texture(filename: "image2.jpeg")!)
//    image(position: float2(0, 100), size: float2(100, 100), texture: TextureController.texture(filename: "image3.jpeg")!)
//    image(position: float2(100, 100), size: float2(100, 100), texture: TextureController.texture(filename: "image4.jpeg")!)
//    let size = Int(1 + (1000 * remap(value: sin(time), inMinMax: float2(-1, 1), outMinMax: float2(0, 1))))
//    let time = formatter().string(from: time as NSNumber)!
//    let size = 1 + 1000 * remap(value: sin(time), inMinMax: float2(-1, 1), outMinMax: float2(0, 1))
//    setFontSize(16)
//    var string = "Hello,. world!".uint32
//    benchmark(title: "Build text") {
//      text(
//        position: float2(),
//        size: float2(1000, 800),
//        text: &string
//      )
//    }
//    text(position: float2(0, 0), size: float2(500, 200), text: "How are you?", fontSize: 64)
    
    endFrame()
    drawData(at: renderEncoder)
    
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
