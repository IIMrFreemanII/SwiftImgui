//
//  Padding.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 16.02.2024.
//

class Padding : SingleChildElement {
  var inset = Inset(all: 0)
  
  override func calcSize(_ size: float2) {
    if let child = self.child {
      child.calcSize(size)
      self.box.size = self.inset.inflate(size: child.box.size)
    }
  }
  
  override func calcPosition(_ position: float2) {
    if let child = self.child {
      var temp = position
      temp += self.inset.topLeft
      
      child.calcPosition(temp)
      self.box.position = position
    }
  }
}
