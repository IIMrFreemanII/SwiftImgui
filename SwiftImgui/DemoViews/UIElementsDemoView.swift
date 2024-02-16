//
//  UIElementsDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 11.02.2024.
//

import MetalKit

class UIElementsDemoView : ViewRenderer {
  var root: UIElement?
  
  override func start() {
    let vStack = VStack()
    vStack.spacing = 10
    
    for _ in 0..<3 {
      let hStack = HStack()
      hStack.spacing = 10
      
      for _ in 0..<3 {
        let padding = Padding()
        padding.inset = Inset(left: Float(), top: Float(), right: Float(), bottom: Float())
        
        let box = Box()
        box.box = Rect(size: float2(100, 100))
        box.color = Color.red
        
        padding.appendChild(box)
        hStack.appendChild(padding)
      }
      
      vStack.appendChild(hStack)
    }
    
    self.root = vStack
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    ui(in: view) { r in
      if let root = self.root {
        root.calcSize(r.size)
        root.calcPosition(r.position)
        root.render()
      }
    }
  }
}
