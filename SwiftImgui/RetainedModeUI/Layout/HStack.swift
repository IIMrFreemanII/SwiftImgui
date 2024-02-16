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
    var totalWidth = Float()
    var maxHeight = Float()
    
    for child in self.children {
      child.calcSize(size)
      totalWidth += child.box.width
      maxHeight = max(maxHeight, child.box.height)
    }
    
    self.box.size.x = self.hAlighnment == .start ? totalWidth : size.width
    self.box.size.y = maxHeight
  }
  
  override func calcPosition(_ position: float2) {
    self.box.position = position
    let lastChildIndex = self.children.count - 1
    
    var xOffset = position.x
    var totalWidth = Float()
    var maxHeight = Float()
    
    for child in self.children {
      totalWidth += child.box.width + self.spacing
      maxHeight = max(maxHeight, child.box.height)
    }
    totalWidth -= self.spacing
    
    let betweenSpacing = (self.box.width - totalWidth) / Float(lastChildIndex)
    
    switch self.hAlighnment {
    case .center:
      let halfOfTotalWidth = totalWidth * 0.5
      let halfOfSelfWidth = self.box.width * 0.5
      xOffset += halfOfSelfWidth - halfOfTotalWidth
    case .end:
      let difference = self.box.width - totalWidth
      xOffset += difference
    default:
      break
    }
    
    for (index, child) in self.children.enumerated() {
      let lastChild = index == lastChildIndex
      var yOffset = position.y
      
      switch self.vAlighnment {
      case .center:
        let halfOfMaxHeight = maxHeight * 0.5
        let halfOfSelfHeight = child.box.height * 0.5
        yOffset += halfOfMaxHeight - halfOfSelfHeight
      case .end:
        let difference = maxHeight - child.box.height
        yOffset += difference
      default:
        break
      }
      
      child.calcPosition(float2(x: xOffset, y: yOffset))
      
      switch self.hAlighnment {
      case .start, .center, .between, .end:
        xOffset += child.box.width + self.spacing
        
        if lastChild {
          xOffset -= self.spacing
        }
      }
      
      if self.hAlighnment == .between {
        xOffset += betweenSpacing
        
        if lastChild {
          xOffset -= betweenSpacing
        }
      }
    }
  }
}
