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
