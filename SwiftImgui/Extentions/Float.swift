//
//  Float.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 12.02.2023.
//

extension Float {
  init(_ boolean: Bool) {
    self = boolean ? 1 : 0
  }
}

extension Float {
    func isBetween(_ range: ClosedRange<Float>) -> Bool {
        return range.contains(self)
    }
}
