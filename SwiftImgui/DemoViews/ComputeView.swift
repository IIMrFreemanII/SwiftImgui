//
//  ComputeView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 24.03.2024.
//

import MetalKit

class ComputeView : ViewRenderer {
  override func start() {
    print("start compute")
  }
  
  override func draw(in view: MTKView) {
    print("draw")
  }
}
