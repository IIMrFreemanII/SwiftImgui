//
//  ImageDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

import MetalKit

class ImageDemoView : ViewRenderer {
  override func draw(in view: MTKView) {
    super.draw(in: view)
    let windowRect = Rect(position: Input.windowPosition, size: Input.windowSize)
    
    startFrame()
    
    clip(rect: windowRect) { r in
      image(Rect(position: float2(0, 0), size: float2(100, 100)), texture: TextureController.texture(filename: "image1.jpeg")!)
      image(Rect(position: float2(100, 0), size: float2(100, 100)), texture: TextureController.texture(filename: "image2.jpeg")!)
      image(Rect(position: float2(0, 100), size: float2(100, 100)), texture: TextureController.texture(filename: "image3.jpeg")!)
      image(Rect(position: float2(100, 100), size: float2(100, 100)), texture: TextureController.texture(filename: "image4.jpeg")!)
    }
    
    endFrame()
    
    drawData(at: view)
  }
}
