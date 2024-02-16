//
//  HStack.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 16.02.2024.
//

class HStack : MultiChildElement {
  var hAlighnment = StackAlignment.start
  var vAlighnment = StackAlignment.start
  var spacing = Float()
  
  override func calcSize(_ size: float2) {
    self.box.size = size
    var maxSize = float2()
    
    for child in self.children {
      child.calcSize(size)
      maxSize += child.box.size
    }
  }
  
  override func calcPosition(_ position: float2) {
    self.box.position = position
    
    var xOffset = position.x
    var totalWidth = Float()
    var maxHeight = Float()
    
    for child in self.children {
      totalWidth += child.box.width + self.spacing
      maxHeight = max(maxHeight, child.box.height)
    }
    totalWidth -= self.spacing
    
    switch self.hAlighnment {
    case .start:
      break
    case .center:
      let halfOfTotalWidth = totalWidth * 0.5
      let halfOfSelfWidth = self.box.width * 0.5
      xOffset += halfOfSelfWidth - halfOfTotalWidth
    case .end:
      let difference = self.box.width - totalWidth
      xOffset += difference
    }
    
    for (index, child) in self.children.enumerated() {
      var yOffset = position.y
      
      switch self.vAlighnment {
      case .start:
        break
      case .center:
        let halfOfMaxHeight = maxHeight * 0.5
        let halfOfSelfHeight = child.box.height * 0.5
        yOffset += halfOfMaxHeight - halfOfSelfHeight
      case .end:
        let difference = maxHeight - child.box.height
        yOffset += difference
      }
      
      child.calcPosition(float2(x: xOffset, y: yOffset))
      
      switch self.hAlighnment {
      case .start, .center, .end:
        xOffset += child.box.width + self.spacing
        
        if index == self.children.count - 1 {
          xOffset -= self.spacing
        }
      }
    }
  }
}
