//
//  BoundingBox.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 02.06.2024.
//

struct BoundingBox2D {
  var center: float2 = float2()
  var size = float2(1, 1)
  
  init() {
    
  }
  
  init(center: float2, size: float2) {
    self.center = center
    self.size = size
  }
  
  init(center: float2, radius: Float) {
    self.center = center
    self.size = float2(radius, radius)
  }
  
  var left: Float {
    return -self.size.x * 0.5
  }
  var right: Float {
    return self.size.x * 0.5
  }
  var bottom: Float {
    return -self.size.y * 0.5
  }
  var top: Float {
    return self.size.y * 0.5
  }
  
  var width: Float {
    return self.size.x
  }
  var height: Float {
    return self.size.y
  }
  var topLeft: float2 {
    return center + float2(-self.size.x, self.size.y) * 0.5
  }
  var bottomRight: float2 {
    return center + float2(self.size.x, -self.size.y) * 0.5
  }
}

struct BoundingBox3D {
  var center: float3 = float3()
  var size = float3(1, 1, 1)
  
  init() {
    
  }
  
  init(center: float3, size: float3) {
    self.center = center
    self.size = size
  }
  
  init(center: float3, radius: Float) {
    self.center = center
    self.size = float3(radius, radius, radius)
  }
  
  var left: Float {
    return -self.size.x * 0.5
  }
  var right: Float {
    return self.size.x * 0.5
  }
  var bottom: Float {
    return -self.size.y * 0.5
  }
  var top: Float {
    return self.size.y * 0.5
  }
  var back: Float {
    return -self.size.z * 0.5
  }
  var front: Float {
    return self.size.z * 0.5
  }
  
  var width: Float {
    return self.size.x
  }
  var height: Float {
    return self.size.y
  }
  var depth: Float {
    return self.size.z
  }
  var topLeftFront: float3 {
    return self.center + float3(-self.size.x, self.size.y, self.size.z) * 0.5
  }
  var bottomRightBack: float3 {
    return self.center + float3(self.size.x, -self.size.y, -self.size.z) * 0.5
  }
}
