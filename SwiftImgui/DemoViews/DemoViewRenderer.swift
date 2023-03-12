//
//  DemoViewRenderer.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import MetalKit

class DemoViewRenderer : ViewRenderer {
  var paragraph = """
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
  CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
  DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
  EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
  """.uint32
  var hoverText = "Hovered\nSome text".uint32
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    ui(in: view) { r in
      var rect1 = Rect(position: Input.mousePosition, size: float2(100, 100))
      //    let point1 = closestPointToSDBox(point: mousePosition, rect: &rect1)
      //    let dist = sdBox(point: mousePosition, rect: &rect1)
      //
      //      let red = UInt8(remap(sin(Time.time * 2), float2(-1, 1), float2(0, 255)))
      //      let green = UInt8(remap(sin(Time.time * 1.5), float2(-1, 1), float2(0, 255)))
      //      let blue = UInt8(remap(sin(Time.time * 3), float2(-1, 1), float2(0, 255)))
      //      let crispness = UInt8(remap(sin(Time.time), float2(-1, 1), float2(0, 255)))
      //      let borderRadius = uchar4(repeating: UInt8(remap(sin(Time.time), float2(-1, 1), float2(0, 100))))
      clip(rect: Rect(position: float2(0, 0), size: float2(100, 100)), borderRadius: float4(repeating: 1)) { _ in
        //        rect(rect1, style: RectStyle(color: Color(0, 0, 0, 255)))
        let r = text(position: float2(), text: &paragraph)
        r.mouseOver {
          rootClip {
            let inset = Inset(vertical: 2, horizontal: 6)
            var temp = calcBoundsForString(&hoverText)
            temp.position = Input.mousePosition + float2(20, -20)
            temp = temp.inflate(by: inset)
            
            rect(temp, style: RectStyle(color: .gray, borderRadius: uchar4(repeating: 25)))
            text(position: temp.position + inset.topLeft, style: TextStyle(color: .white), text: &hoverText)
          }
        }
      }
      //    line(mousePosition, point1, .black)
      //    circle(position: mousePosition, radius: dist, borderSize: 0.01, color: .black)
    }
  }
}
