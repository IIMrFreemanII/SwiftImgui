//
//  Theme.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 17.02.2023.
//

struct Theme {
  static var active = Self.dark
  static var defaultFont = FontManager.load(font: "JetBrains Mono")
  static let defaultFontSize = Float(16)
  
  var cursorColor: Color = .black
  var textField = TextFieldStyle()
  var textFieldFocused = TextFieldStyle()
  var textFieldMouseOver = TextFieldStyle()
  var textFieldError = TextFieldStyle()
  
  var numberFieldMouseOver = TextFieldStyle()
  
  var button = ButtonStyle()
  var text = TextStyle()
  var checkbox = CheckboxStyle()
}

extension Theme {
  static var dark = Theme(
    cursorColor: .white,
    textField: TextFieldStyle(
      rect: RectStyle(color: .gray, borderRadius: uchar4(repeating: 25)),
      text: TextStyle(color: .white, font: defaultFont, fontSize: defaultFontSize),
      outline: Outline(size: 2, color: .transparent),
      width: 80
    ),
    textFieldFocused: TextFieldStyle(
      rect: RectStyle(color: .gray, borderRadius: uchar4(repeating: 25)),
      text: TextStyle(color: .white, font: defaultFont, fontSize: defaultFontSize),
      outline: Outline(size: 2, color: .blue),
      width: 80
    ),
    textFieldMouseOver: TextFieldStyle(
      rect: RectStyle(color: .gray, borderRadius: uchar4(repeating: 25)),
      text: TextStyle(color: .white, font: defaultFont, fontSize: defaultFontSize),
      outline: Outline(size: 2, color: .transparent),
      width: 80
    ),
    textFieldError: TextFieldStyle(
      rect: RectStyle(color: .gray, borderRadius: uchar4(repeating: 25)),
      text: TextStyle(color: .white, font: defaultFont, fontSize: defaultFontSize),
      outline: Outline(size: 2, color: .red),
      width: 80
    ),
    numberFieldMouseOver: TextFieldStyle(
      rect: RectStyle(color: .lightGray, borderRadius: uchar4(repeating: 25)),
      text: TextStyle(color: .white, font: defaultFont, fontSize: defaultFontSize),
      outline: Outline(size: 2, color: .transparent),
      width: 80
    ),
    button: ButtonStyle(
      rect: RectStyle(color: .gray, borderRadius: uchar4(repeating: 25)),
      text: TextStyle(color: .white, font: defaultFont, fontSize: defaultFontSize)
    ),
    text: TextStyle(color: .black, font: defaultFont, fontSize: defaultFontSize),
    checkbox: CheckboxStyle(
      rect: RectStyle(
        color: .gray,
        borderRadius: uchar4(repeating: 25)
      ),
      innerRect: RectStyle(
        color: Color(255, 255, 255, UInt8(255 * 0.8)),
        borderRadius: uchar4(repeating: 25)
      )
    )
  )
}
