//
//  DemoViewRenderer.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import MetalKit
import Foundation

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
  
  var states = Array(repeating: ScrollState(), count: 1)
  var contentSize = float2(400, 400)
  override func draw(in view: MTKView) {
    super.draw(in: view)
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    
//    renderEncoder.setCullMode(.back)
    
    startFrame()
    
    contentSize += Input.magnification * 50
    
    clip(rect: windowRect, borderRadius: float4(1, 1, 1, 1), crispness: 0.005) { r in
//      text(position: float2(), text: &intTextValue)
//      rect(r, color: .red)
//      image(r, texture: TextureController.texture(filename: "image1.jpeg")!)
//      shadow(
//        content: Rect(position: float2(100, 100), size: float2(100, 100)),
////        borderRadius: float4(remap(sin(time), float2(-1, 1), float2(0, 1))),
//        color: .black,
//        offset: float2(0, 0),
////        blurRadius: 1,
//        blurRadius: remap(sin(time), float2(-1, 1), float2(0, 1)),
//        spreadRadius: 0
//      ) { r, borderRadius in
//        border(
//          content: r,
//          color: .blue,
//          radius: borderRadius,
//          size: 10
//        ) { r, radius in
//          rect(
//            r,
//            color: .red,
//            borderRadius: radius
//          )
//        }
//      }
//      clip(rect: Rect(position: r.position, size: float2(300, 300))) { r in
//        //        let contentSize = float2(400, 400)
//        scroll(&states[0], r, contentSize) { p in
//          rect(Rect(position: p + float2(0, 0), size: float2(100, 100)), color: .red)
//          rect(Rect(position: p + float2(100, 0), size: float2(100, 100)), color: .green)
//          rect(Rect(position: p + float2(200, 0), size: float2(100, 100)), color: .blue)
//          rect(Rect(position: p + float2(300, 0), size: float2(100, 100)), color: .black)
//
//          rect(Rect(position: p + float2(0, 100), size: float2(100, 100)), color: .black)
//          rect(Rect(position: p + float2(100, 100), size: float2(100, 100)), color: .blue)
//          rect(Rect(position: p + float2(200, 100), size: float2(100, 100)), color: .green)
//          rect(Rect(position: p + float2(300, 100), size: float2(100, 100)), color: .red)
//
//          rect(Rect(position: p + float2(0, 200), size: float2(100, 100)), color: .red)
//          rect(Rect(position: p + float2(100, 200), size: float2(100, 100)), color: .green)
//          rect(Rect(position: p + float2(200, 200), size: float2(100, 100)), color: .blue)
//          rect(Rect(position: p + float2(300, 200), size: float2(100, 100)), color: .black)
//
//          rect(Rect(position: p + float2(0, 300), size: float2(100, 100)), color: .black)
//          rect(Rect(position: p + float2(100, 300), size: float2(100, 100)), color: .blue)
//          rect(Rect(position: p + float2(200, 300), size: float2(100, 100)), color: .green)
//          rect(Rect(position: p + float2(300, 300), size: float2(100, 100)), color: .red)
//        }
//      }
    }
    
//    let size = float2(repeating: 100 )
//    let spacing: Float = 0
//    let gridSize = 5
//    benchmark(title: "Layout") {
//      hStack(position: windowRect.position, spacing: spacing) { cursor, temp in
//        for _ in 0..<gridSize {
//          temp = vStack(position: cursor.position, spacing: spacing) { cursor, temp in
//            for _ in 0..<gridSize {
//              temp = padding(rect: Rect(position: cursor.position, size: size), by: Inset(all: 10)) {
//                  rect($0, color: .red)
//                }
//              cursor.offset(by: &temp)
//            }
//          }
//          cursor.offset(by: &temp)
//        }
//      }
//    }
    
//    benchmark(title: "Block") {
//      for y in 0..<10 {
//        for x in 0..<10 {
//          let size = 50
//          let color = ((x + y) % 2) == 0 ? float4(1, 0, 0, 1) : float4(0, 0, 1, 1)
//          rect(
//            Rect(
//              position: float2(Float(x * size), Float(y * size)),
//              size: float2(Float(size), Float(size))
//            ),
//            color: color
//          )
//        }
//      }
//    }
    
//    image(Rect(position: float2(0, 0), size: float2(100, 100)), texture: TextureController.texture(filename: "image1.jpeg")!)
//    image(Rect(position: float2(100, 0), size: float2(100, 100)), texture: TextureController.texture(filename: "image2.jpeg")!)
//    image(Rect(position: float2(0, 100), size: float2(100, 100)), texture: TextureController.texture(filename: "image3.jpeg")!)
//    image(Rect(position: float2(100, 100), size: float2(100, 100)), texture: TextureController.texture(filename: "image4.jpeg")!)
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
    
    drawData(at: view)
  }
}
