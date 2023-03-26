//
//  TextDemoView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

import MetalKit

class TextDemoView : ViewRenderer {
  var textValue =
  """
  ----------------------------------------------------------------------------------------------------------
  """
  var intTextValue = [UInt32]()
  
  override func start() {
    for _ in 0..<20 {
      textValue +=
      """
      \nLorem Ipsum is simply dummy text of the printing and typesetting industry.
      Lorem Ipsum has been the industry's standard dummy text ever since the 1500s,
      when an unknown printer took a galley of type and scrambled it to make a type specimen book.
      It has survived not only five centuries, but also the leap into electronic typesetting,
      remaining essentially unchanged.
      It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages,
      and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
      ----------------------------------------------------------------------------------------------------------
      """
    }
    intTextValue = textValue.uint32
    print(intTextValue.count)
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    ui(in: view) { r in
      benchmark(title: "Text") {
        text(position: r.position, text: &intTextValue)
      }
    }
  }
}
