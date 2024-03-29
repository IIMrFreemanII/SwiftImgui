//
//  VStack.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 16.02.2024.
//
class VStack : MultiChildElement {
  var hAlighnment = StackAlignment.start
  var vAlighnment = StackAlignment.start
  var spacing = Float()
  
  override func calcSize(_ size: float2) {
    var totalHeight = Float()
    var maxWidth = Float()
    
    for child in self.children {
      child.calcSize(size)
      totalHeight += child.box.height
      maxWidth = max(maxWidth, child.box.width)
    }
    
    self.box.size.x = maxWidth
    self.box.size.y = self.vAlighnment == .start ? totalHeight : size.height
  }
  
  override func calcPosition(_ position: float2) {
    self.box.position = position
    let lastChildIndex = self.children.count - 1
    
    var yOffset = position.y
    var totalHeight = Float()
    var maxWidth = Float()
    
    for child in self.children {
      totalHeight += child.box.height + self.spacing
      maxWidth = max(maxWidth, child.box.width)
    }
    totalHeight -= self.spacing
    
    let betweenSpacing = (self.box.height - totalHeight) / Float(lastChildIndex)
    
    switch self.vAlighnment {
    case .center:
      let halfOfTotalHeight = totalHeight * 0.5
      let halfOfSelfHeight = self.box.height * 0.5
      yOffset += halfOfSelfHeight - halfOfTotalHeight
    case .end:
      let difference = self.box.height - totalHeight
      yOffset += difference
    default:
      break
    }
    
    for (index, child) in self.children.enumerated() {
      let lastChild = index == lastChildIndex
      var xOffset = position.x
      
      switch self.hAlighnment {
      case .center:
        let halfOfMaxWidth = maxWidth * 0.5
        let halfOfSelfWidth = child.box.width * 0.5
        xOffset += halfOfMaxWidth - halfOfSelfWidth
      case .end:
        let difference = maxWidth - child.box.width
        xOffset += difference
      default:
        break
      }
      
      child.calcPosition(float2(x: xOffset, y: yOffset))
      
      switch self.vAlighnment {
      case .start, .center, .between, .end:
        yOffset += child.box.height + self.spacing
        
        if lastChild {
          yOffset -= self.spacing
        }
      }
      
      if self.vAlighnment == .between {
        yOffset += betweenSpacing
        
        if lastChild {
          yOffset -= betweenSpacing
        }
      }
    }
  }
}
