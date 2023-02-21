//
//  CheckboxDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 21.02.2023.
//

import MetalKit

class CheckboxDemoView : ViewRenderer {
  var boolean = false
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    ui(in: view) { r in
      checkbox(
        Rect(position: r.position + float2(10, 10), size: float2(30, 30)),
        value: &self.boolean,
        style: Theme.active.checkbox
      )
    }
  }
}
