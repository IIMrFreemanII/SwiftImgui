//
//  Scroll.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.01.2023.
//

struct ScrollState {
  var offset = float2()
  var lastDragPos = float2()
}

let scrollbarSize = Float(8)
let scrollbarColor: float4 = .gray
 
/// cb: passes offset to position its content
@discardableResult
func scroll(
  _ state: inout ScrollState,
  _ r: Rect,
  _ contentSize: float2,
  _ showScrollBars: Bool = true,
  _ cb: (float2) -> Void
) -> Rect {
  let mouseInScrollArea = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: r.position, size: r.size)
  var lastDragPos = state.lastDragPos
  
  var newOffset = state.offset
  
  let deltaSize = min((r.size - contentSize), float2())
  let scrollBarSize = (r.size / (r.size + abs(deltaSize))) * r.size
  
  if mouseInScrollArea {
    let mouseScroll = Input.mouseScroll
    
    newOffset += mouseScroll
    newOffset = newOffset.clamped(
      lowerBound: deltaSize,
      upperBound: float2()
    )
    lastDragPos += mouseScroll
    lastDragPos = lastDragPos.clamped(
      lowerBound: deltaSize,
      upperBound: float2()
    )
  }
  
  let horizontal = showScrollBars && deltaSize.x < 0 && mouseInScrollArea && Input.hScrolling
  var hScrollBarRect = Rect()
  var hColor = float4()
  
  let vertical = showScrollBars && deltaSize.y < 0 && mouseInScrollArea && Input.vScrolling
  var vScrollBarRect = Rect()
  var vColor = float4()
  
  if horizontal {
    var normalizedXOffset = abs(newOffset.x / deltaSize.x)
    let xScrollOffset = (r.size.x - scrollBarSize.x) * normalizedXOffset
    let xScrollSize = float2(scrollBarSize.x, scrollbarSize)
    
    let scrollBarRectPosition = r.position + r.size - float2(r.size.x, scrollbarSize) + float2(xScrollOffset, 0)
    var scrollBarRect = Rect(
      position: scrollBarRectPosition,
      size: xScrollSize
    )
    
    if Input.drag {
      Input.hideHScrollDebounced()
    }
    scrollBarRect.mousePress {
      Input.dragChange { value in
        newOffset.x = (lastDragPos.x - value.translation.x * (contentSize.x / r.size.x))
        newOffset.x = newOffset.x.clamped(to: deltaSize.x...0)
        
        normalizedXOffset = abs(newOffset.x / deltaSize.x)
        scrollBarRect.position = r.position + r.size - float2(r.size.x, scrollbarSize) + float2(xScrollOffset, 0)
      }
    }
    Input.dragEnd { value in
      lastDragPos.x = newOffset.x
    }
    
    hScrollBarRect = scrollBarRect
    
    var color = scrollbarColor
    scrollBarRect
      .mouseOver {
        color.xyz *= 1.3
      }
      .mousePress {
        color.xyz *= 0.9
      }
    hColor = color
  }
  
  if vertical {
    var normalizedYOffset = abs(newOffset.y / deltaSize.y)
    let yScrollOffset = (r.size.y - scrollBarSize.y) * normalizedYOffset
    let yScrollSize = float2(scrollbarSize, scrollBarSize.y)
    
    let scrollBarRectPosition = r.position + r.size - float2(scrollbarSize, r.size.y) + float2(0, yScrollOffset)
    var scrollBarRect = Rect(
      position: scrollBarRectPosition,
      size: yScrollSize
    )
    
    if Input.drag {
      Input.hideVScrollDebounced()
    }
    scrollBarRect.mousePress {
      Input.dragChange { value in
        newOffset.y = (lastDragPos.y - value.translation.y * (contentSize.y / r.size.y))
        newOffset.y = newOffset.y.clamped(to: deltaSize.y...0)
        
        normalizedYOffset = abs(newOffset.y / deltaSize.y)
        scrollBarRect.position = r.position + r.size - float2(scrollbarSize, r.size.y) + float2(0, yScrollOffset)
      }
    }
    Input.dragEnd { value in
      lastDragPos.y = newOffset.y
    }
    
    vScrollBarRect = scrollBarRect
    
    var color = scrollbarColor
    scrollBarRect
      .mouseOver {
        color.xyz *= 1.3
      }
      .mousePress {
        color.xyz *= 0.9
      }
    vColor = color
  }
  
  newOffset = newOffset.clamped(
    lowerBound: deltaSize,
    upperBound: float2()
  )
  state.lastDragPos = lastDragPos
  state.offset = newOffset
  
  clip(rect: r) { _ in
    cb(r.position + newOffset)
  }
  
  if horizontal {
    rect(
      hScrollBarRect,
      color: hColor
    )
  }
  
  if vertical {
    rect(
      vScrollBarRect,
      color: vColor
    )
  }
  
  return r
}
