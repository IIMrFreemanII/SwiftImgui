//
//  SimulationDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 07.11.2023.
//

import MetalKit

func from2DTo1D(point: int2, width: Int) -> Int {
  return point.x + (point.y * width)
}

func from1DTo2D(point: int2, width: Int) -> int2 {
  return int2();
}

func sdCircle(p: float2, r: Float) -> Float {
  return length(p) - r;
}

class SimulationDemoView : ViewRenderer {
  static let divider = 4;
  static var width = 28;
  static var height = 28;
  var pixels = [Float](repeating: 0, count: width * height);
  
  var position = float2();
  var radius = Float(0.1);
  
  var center = int2();
  var dir = float2(0, 1);
  var deltaDir = float2();
  
  func calcFieldDir() {
    let points: [int2] = [
      center &+ int2(-1, 1),  center &+ int2(0, 1),  center &+ int2(1, 1),
      center &+ int2(-1, 0),  center,                center &+ int2(1, 0),
      center &+ int2(-1, -1), center &+ int2(0, -1), center &+ int2(1, -1),
    ]
    
    var globalDir = float2()
    var contributeCount = 0;
    for point in points {
      if (point.x >= Self.width || point.x < 0 || point.y >= Self.height || point.y < 0) {
        continue
      }
      
      let index = from2DTo1D(point: point, width: Self.width)
      let centerIndex = from2DTo1D(point: center, width: Self.width)
      
      let value = pixels[index]
      let centerValue = pixels[centerIndex]
      let diff = max(0, centerValue - value)
      if diff > 0 {
        contributeCount += 1
        
        let dir = point &- center
        globalDir += float2(Float(dir.x), Float(dir.y)) * diff
      }
    }
    
    var result = normalize(globalDir)
    if (result.x.isNaN || result.y.isNaN) {
      result = float2();
    }
    self.deltaDir = globalDir
    print(globalDir)
    print(contributeCount)
    self.dir = result
  }
  
  override func start() {
    for y in 0..<Self.height {
      for x in 0..<Self.width {
        let point = int2(x, y);
        var uv = float2(Float(x) / Float(Self.width), Float(y) / Float(Self.height));
        uv = uv * 2 - 1;
        var color = Float(1);
        let circleColor = Float(0);
        let crispness = Float(1.5);
        
        let dist = sdCircle(p: uv, r: radius);
        color = mix(x: color, y: circleColor, t: 1.0 - smoothstep(edge0: 0, edge1: crispness, x: dist));
        
        let index = from2DTo1D(point: point, width: Self.width);
        pixels[index] = color.clamped(to: 0...1);
      }
    }
    
    //----------
    
//    for y in 0..<3 {
//      for x in 0..<3 {
//        let point = int2(x, y);
//        let index = from2DTo1D(point: point, width: 3);
//
//
//        let value = arr[index]
//      }
//    }
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    let size = float2(20, 20);
    let offset = float2(5, 5);
    
    Input.leftMouseDown {
      start();
    }
    
    ui(in: view) { r in
      for y in 0..<Self.height {
        for x in 0..<Self.width {
          let index = from2DTo1D(point: int2(x, y), width: Self.width);
          var color: Color = .black;
          color.w = UInt8(pixels[index] * 255);
          let temp = Rect(position: float2(Float(x) * 25, Float(y) * 25) + offset, size: size);
          temp.mouseDown {
            print(pixels[index])
          }
          temp.mouseOver {
            center = int2(x: x, y: y)
            print("Center: \(center)")
            calcFieldDir()
          }
          rect(temp, style: RectStyle(color: color))
        }
      }
      
      let start = float2(Float(center.x), Float(center.y)) * 25 + offset + float2(25, 25) * 0.5;
      let end = start + self.dir * 30;
      line(start, end, .red, 4)
      
//      for y in 0..<(Self.height / Self.divider) {
//        for x in 0..<(Self.width / Self.divider) {
//          let index = from2DTo1D(point: int2(x, y), width: Self.width / Self.divider);
//          var color: Color = .blue;
//          var position = float2(Float(x) * 25 * Float(Self.divider), Float(y) * 25 * Float(Self.divider)) + offset + (size + offset) * 1.5;
//          let temp = Rect(position: position, size: size);
////          temp.mouseDown {
////            print(pixels[index])
////          }
//          rect(temp, style: RectStyle(color: color))
//        }
//      }
    }
  }
}
