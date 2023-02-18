//
//  Theme.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 17.02.2023.
//

struct Theme {
  static var active = Self.dark
  
  var cursorColor: float4 = .black
  var textField = TextFieldStyle()
  var textFieldError = TextFieldStyle()
  
//  var button
}

extension Theme {
  static var dark = Theme(
    cursorColor: .white,
    textField: TextFieldStyle(
      rect: RectStyle(color: .gray, borderRadius: float4(repeating: 0.25)),
      text: TextStyle(color: .white, font: defaultFont, fontSize: defaultFontSize),
      outline: Outline(size: 2, color: .blue),
      width: 80
    ),
    textFieldError: TextFieldStyle(
      rect: RectStyle(color: .gray, borderRadius: float4(repeating: 0.25)),
      text: TextStyle(color: .white, font: defaultFont, fontSize: defaultFontSize),
      outline: Outline(size: 2, color: .red),
      width: 80
    )
  )
}
