//
//  Box.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 16.02.2024.
//

class Box : SingleChildElement {
  var color = Color.white
  
  override func render() {
    rect(self.box, style: RectStyle(color: self.color))
    
    super.render()
  }
  
  override func calcSize(_ size: float2) {
    self.child?.calcSize(self.box.size)
  }
  
  override func calcPosition(_ position: float2) {
    self.box.position = position
    self.child?.calcPosition(position)
  }
}
