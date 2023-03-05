//
//  Scroll.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 30.01.2023.
//

struct ScrollState {
  var offset = float2()
  var dragScrollOffset = float2()
  var lastDragPos = float2()
}

struct ScrollBarStyle {
  var size = Float(8)
  var color: Color = .gray
  var borderRadius: float4 = float4(repeating: 0)
}

struct ScrollStyle {
  var scrollBar = ScrollBarStyle()
  var borderRadius: float4 = .zero
}
 
/// cb: passes offset to position its content
@discardableResult
func scroll(
  state: inout ScrollState,
  _ r: Rect,
  contentSize: float2,
  style: ScrollStyle = ScrollStyle(),
  showScrollBars: Bool = true,
  _ cb: (float2, inout ScrollState) -> Void
) -> Rect {
  let mouseInScrollArea = pointInAABBoxTopLeftOrigin(point: Input.mousePosition, position: r.position, size: r.size)
  var lastDragPos = state.lastDragPos
  
  var newOffset = state.offset
  
  let deltaSize = min((r.size - contentSize), float2())
  let scrollBarSize = (r.size / (r.size + abs(deltaSize))) * r.size
  
  if mouseInScrollArea {
    if Input.drag {
      var temp = r
      let dragDir = dragDirection(point: Input.dragGesture.location, rect: &temp)
      // may have bugs when after this scroll with mouse (fix lastDragPos)
      let currentScroll = newOffset
      newOffset -= dragDir * 0.5
      newOffset = newOffset.clamped(
        lowerBound: deltaSize,
        upperBound: float2()
      )
      let deltaScroll = currentScroll - newOffset
      state.dragScrollOffset -= deltaScroll
    }
    
    
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
  
  Input.dragEnd { _ in
    state.dragScrollOffset = float2()
  }
  
  let horizontal = showScrollBars && deltaSize.x < 0 && mouseInScrollArea && Input.hScrolling
  var hScrollBarRect = Rect()
  var hColor = Color()
  
  let vertical = showScrollBars && deltaSize.y < 0 && mouseInScrollArea && Input.vScrolling
  var vScrollBarRect = Rect()
  var vColor = Color()
  
  if horizontal {
    var normalizedXOffset = abs(newOffset.x / deltaSize.x)
    let xScrollOffset = (r.size.x - scrollBarSize.x) * normalizedXOffset
    let xScrollSize = float2(scrollBarSize.x, style.scrollBar.size)
    
    let scrollBarRectPosition = r.position + r.size - float2(r.size.x, style.scrollBar.size) + float2(xScrollOffset, 0)
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
        scrollBarRect.position = r.position + r.size - float2(r.size.x, style.scrollBar.size) + float2(xScrollOffset, 0)
      }
    }
    Input.dragEnd { value in
      lastDragPos.x = newOffset.x
    }
    
    hScrollBarRect = scrollBarRect
    
    var color = style.scrollBar.color
    scrollBarRect
      .mouseOver {
        color.w = UInt8(Float(color.w) * 0.9)
      }
      .mousePress {
        color.w  = UInt8(Float(color.w) * 0.7)
      }
    hColor = color
  }
  
  if vertical {
    var normalizedYOffset = abs(newOffset.y / deltaSize.y)
    let yScrollOffset = (r.size.y - scrollBarSize.y) * normalizedYOffset
    let yScrollSize = float2(style.scrollBar.size, scrollBarSize.y)
    
    let scrollBarRectPosition = r.position + r.size - float2(style.scrollBar.size, r.size.y) + float2(0, yScrollOffset)
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
        scrollBarRect.position = r.position + r.size - float2(style.scrollBar.size, r.size.y) + float2(0, yScrollOffset)
      }
    }
    Input.dragEnd { value in
      lastDragPos.y = newOffset.y
    }
    
    vScrollBarRect = scrollBarRect
    
    var color = style.scrollBar.color
    scrollBarRect
      .mouseOver {
        color.w = UInt8(Float(color.w) * 0.9)
      }
      .mousePress {
        color.w = UInt8(Float(color.w) * 0.7)
      }
    vColor = color
  }
  
  newOffset = newOffset.clamped(
    lowerBound: deltaSize,
    upperBound: float2()
  )
  state.lastDragPos = lastDragPos
  state.offset = newOffset
  
  clip(rect: r, borderRadius: style.borderRadius) { _ in
    cb(r.position + newOffset, &state)
  }
  
  if horizontal {
    rect(
      hScrollBarRect,
      style: RectStyle(color: hColor)
    )
  }
  
  if vertical {
    rect(
      vScrollBarRect,
      style: RectStyle(color: vColor)
    )
  }
  
  return r
}
