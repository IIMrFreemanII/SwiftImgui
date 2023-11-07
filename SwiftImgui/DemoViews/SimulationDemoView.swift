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
  static var width = 26;
  static var height = 26;
  var pixels = [Float](repeating: 0, count: width * height);
  
  var position = float2();
  var radius = Float(0.1);
  
  override func start() {
    for y in 0..<Self.height {
      for x in 0..<Self.width {
        let point = int2(x, y);
        var uv = float2(Float(x) / Float(Self.width), Float(y) / Float(Self.height));
        uv = uv * 2 - 1;
        var color = Float(1);
        var circleColor = Float(0);
        var crispness = Float(1.5);
        
        var dist = sdCircle(p: uv, r: radius);
        color = mix(x: color, y: circleColor, t: 1.0 - smoothstep(edge0: 0, edge1: crispness, x: dist));
        
        let index = from2DTo1D(point: point, width: Self.width);
        pixels[index] = color.clamped(to: 0...1);
      }
    }
    print("");
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
          rect(temp, style: RectStyle(color: color))
        }
      }
    }
  }
}
