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
//    self.metalView.
    
    let vStack = VStack()
    vStack.vAlighnment = .between
    
    for _ in 0..<5 {
      let hStack = HStack()
      hStack.hAlighnment = .between
      
      for _ in 0..<5 {
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
        //        benchmark(title: "size") {
        root.calcSize(r.size)
        //        }
        
        //        benchmark(title: "position") {
        root.calcPosition(r.position)
        //        }
        
        //        benchmark(title: "render") {
        root.render()
        //        }
        //        print("-------------------")
      }
    }
  }
}
