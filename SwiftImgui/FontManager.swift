//
//  FontManager.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 18.01.2023.
//

import Foundation

func buildFontAtlas(fontName: String) -> Font {
//  let fontUrl = documentsUrl().appendingPathComponent(fontName).appendingPathExtension("sdf")
 
//  let decoder = PropertyListDecoder()
//  if
//    let fontAtlasData = try? Data(contentsOf: fontUrl),
//    let fontAtlas = try? decoder.decode(FontAtlas.self, from: fontAtlasData)
//  {
//    print("Loaded cached font atlas for font: '\(fontAtlas.fontName!)'")
//    return fontAtlas
//  } else {
//    print("Didn't find cached font atlas font for '\(fontName)', creating new one")
//  }
  
  let fontAtlas = Font(fontName: fontName)
//  do {
//    let encoder = PropertyListEncoder()
//    encoder.outputFormat = .binary
//    try encoder.encode(fontAtlas).write(to: fontUrl)
//    print("Cached font atlas for font: '\(fontAtlas.fontName!)'")
//  } catch let error {
//    fatalError(error.localizedDescription)
//  }
  
  return fontAtlas
}

private func documentsUrl() -> URL {
  let candidates = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
  let documentsPath = candidates.first!
  return URL(filePath: documentsPath, directoryHint: .isDirectory)
}

class FontManager {
  static var fonts = [String: Font]()
  
  static func load(font fontName: String) -> Font {
    guard let font = fonts[fontName] else {
      let font = Font(fontName: fontName)
      fonts[fontName] = font
      return font
    }
    
    return font
  }
}
