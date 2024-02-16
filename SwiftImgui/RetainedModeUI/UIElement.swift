//
//  View.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 10.02.2024.
//

class UIElement {
  var parent: UIElement? = nil
  var box = Rect()
  
  func mount() -> Void {
    
  }
  
  func unmount() -> Void {
    
  }
  
  func render() -> Void {
    
  }
  
  func calcSize(_ size: float2) {
    
  }
  
  func calcPosition(_ position: float2) {
    
  }
  
  func removeSelf() -> Void {
    
  }
  
  func removeChild(child: UIElement) -> Void {
    
  }
}

// Center, Padding, Container, Box
class SingleChildElement : UIElement {
  var child: UIElement?
  
  override func render() {
    self.child?.render()
  }
  
  func appendChild(_ element: UIElement) -> Void {
    self.child = element
    element.parent = self
  }
  
  override func removeSelf() {
    self.parent?.removeChild(child: self)
    self.parent = nil
  }
  
  override func removeChild(child: UIElement) {
    self.child = nil
  }
}

// VStack, HStack
class MultiChildElement : UIElement {
  var children: [UIElement] = []
  
  override func render() {
    for child in self.children {
      child.render()
    }
  }
  
  func appendChild(_ element: UIElement) -> Void {
    self.children.append(element)
    element.parent = self
  }
  
  override func removeSelf() {
    self.parent?.removeChild(child: self)
    self.parent = nil
  }
  
  override func removeChild(child: UIElement) {
    if let index = self.children.firstIndex(where: { $0 === child }) {
      self.children.remove(at: index)
    }
  }
}

// Text, Image, SVGIcon
class ChildlessElement : UIElement {
  
  override func removeSelf() {
    self.parent?.removeChild(child: self)
    self.parent = nil
  }
}

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

enum StackAlignment {
  case start
  case center
  case end
}

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
