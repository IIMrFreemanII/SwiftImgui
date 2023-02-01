//
//  Scroll.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.01.2023.
//

struct ScrollState {
  var offset = float2()
}

let scrollbarSize = Float(8)
let scrollbarColor: float4 = .gray

@discardableResult
func scroll(
  _ state: inout ScrollState,
  _ r: Rect,
  _ contentSize: float2,
  _ cb: (float2) -> Void
) -> Rect {
  let mouseScroll = Input.mouseScroll
  let mouseDelta = Input.mouseDelta
//  print("mouse position \(Input.mousePosition)")
//  print("mouseScroll \(mouseScroll)")
//  print("mouseDelta \(mouseDelta)")
  var newOffset = state.offset
  let deltaSize = min((r.size - contentSize), float2())
  let scrollBarSize = (r.size / (r.size + abs(deltaSize))) * r.size
  
  newOffset += mouseScroll
  newOffset = newOffset.clamped(
    lowerBound: deltaSize,
    upperBound: float2()
  )
  state.offset = newOffset
  
  cb(r.position + newOffset)
  
  if deltaSize.x < 0 {
    let normalizedXOffset = abs(newOffset.x / deltaSize.x)
    let xScrollOffset = (r.size.x - scrollBarSize.x) * normalizedXOffset
    let xScrollSize = float2(scrollBarSize.x, scrollbarSize)
    
    var color = scrollbarColor
    let scrollBarRect = Rect(
      position: r.position + r.size - float2(r.size.x, scrollbarSize) + float2(xScrollOffset, 0),
      size: xScrollSize
    )
    scrollBarRect
      .mouseOver {
        color.xyz *= 1.2
      }
      .mousePress {
        color.xyz *= 0.9
        
        newOffset.x -= mouseDelta.x
      }
    
    rect(
      scrollBarRect,
      color: color
    )
  }
  
  if deltaSize.y < 0 {
    let normalizedYOffset = abs(newOffset.y / deltaSize.y)
    let yScrollOffset = (r.size.y - scrollBarSize.y) * normalizedYOffset
    let yScrollSize = float2(scrollbarSize, scrollBarSize.y)
    
    var color = scrollbarColor
    let scrollBarRect = Rect(
      position: r.position + r.size - float2(scrollbarSize, r.size.y) + float2(0, yScrollOffset),
      size: yScrollSize
    )
    scrollBarRect
      .mouseOver {
        color.xyz *= 1.2
      }
      .mousePress {
        color.xyz *= 0.9
        
        newOffset.y += mouseDelta.y
      }
    
    rect(
      scrollBarRect,
      color: color
    )
  }
  
  newOffset = newOffset.clamped(
    lowerBound: deltaSize,
    upperBound: float2()
  )
  state.offset = newOffset
  
  return r
}
