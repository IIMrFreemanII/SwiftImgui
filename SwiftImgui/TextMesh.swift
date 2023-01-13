//
//  TextMesh.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 03.01.2023.
//

import Foundation
import MetalKit
import LRUCache

extension CGSize: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.width)
    hasher.combine(self.height)
  }
}

struct Glyph {
  var position = float3()
  var size = float2()
  var topLeftUv = float2()
  var bottomRightUv = float2()
  var fontSize: UInt32 = 1;
  // start of the SubPath range
  var start: UInt32 = 0
  // end of the SubPath range
  var end: UInt32 = 0
}

extension CharacterSet {
    func characters() -> [Character] {
        // A Unicode scalar is any Unicode code point in the range U+0000 to U+D7FF inclusive or U+E000 to U+10FFFF inclusive.
        return codePoints().compactMap { UnicodeScalar($0) }.map { Character($0) }
    }
    
    func codePoints() -> [Int] {
        var result: [Int] = []
        var plane = 0
        // following documentation at https://developer.apple.com/documentation/foundation/nscharacterset/1417719-bitmaprepresentation
        for (i, w) in bitmapRepresentation.enumerated() {
            let k = i % 0x2001
            if k == 0x2000 {
                // plane index byte
                plane = Int(w) << 13
                continue
            }
            let base = (plane + k) << 3
            for j in 0 ..< 8 where w & 1 << j != 0 {
                result.append(base + j)
            }
        }
        return result
    }
}

struct GlyphsData {
  var glyphs: [Glyph]
  var fittedRect: CGRect
}
var glyphsCache = LRUCache<Int, GlyphsData>(countLimit: 1000)

func offsetGlyphs(_ glyphs: inout [Glyph], by rect: CGRect) {
  glyphs.withUnsafeMutableBufferPointer { buffer in
    for i in buffer.indices {
      buffer[i].position.x += Float(rect.minX)
      buffer[i].position.y += Float(rect.minY)
    }
  }
}

func enumerateLines(for string: String, cb: (Substring) -> Bool) {
  var startIndex = string.startIndex
  let endIndex = string.endIndex
  
  while true {
    if let lineEnd = string.range(of: "\n", range: startIndex..<endIndex) {
      // offsetBy -1 not to include \n to substring result
      let lineEndIndex = string.index(lineEnd.upperBound, offsetBy: -1)
      
      let shouldStop = cb(string[startIndex..<lineEndIndex])
      if shouldStop {
        return
      }
      
      // offsetBy 1 to skip \n
      startIndex = string.index(lineEndIndex, offsetBy: 1)
    } else {
      _ = cb(string[startIndex..<string.endIndex])
      return
    }
  }
}

func buildGlyphsFromString(
  _ string: String,
  inRect rect: CGRect,
  withFont fontAtlas: FontAtlas,
  atSize fontSize: Int,
  glyphs: inout [Glyph]
) -> CGRect {
  let shouldCache = string.count > 100
  var hasher = Hasher()
  hasher.combine(string)
  hasher.combine(fontSize)
  hasher.combine(rect.size)
  hasher.combine(fontAtlas.fontName)
  let hashCode = hasher.finalize()
  
  // Caching
  if
    shouldCache,
    var cachedGlyphsData = glyphsCache.value(forKey: hashCode)
  {
    offsetGlyphs(&cachedGlyphsData.glyphs, by: rect)
    glyphs.append(contentsOf: cachedGlyphsData.glyphs)
    return cachedGlyphsData.fittedRect
  }
  
  var newGlyphs = [Glyph]()
  newGlyphs.reserveCapacity(string.count)
  
  var maxXOffset: CGFloat = 0
  var maxYOffset: CGFloat = 0
  
  let fontSize = CGFloat(fontSize)
  
  enumerateLines(for: string) { line in
    if (maxYOffset + fontSize) > rect.height {
      return true
    }
    
    var xOffset: CGFloat = 0
    
    for char in line {
      let metrics = fontAtlas.charToGlyphMetricsMap[char]!
      let scaledSize = CGSize(width: metrics.size.width * fontSize, height: metrics.size.height * fontSize)
      let scaledBearing = CGSize(width: metrics.bearing.width * fontSize, height: metrics.bearing.height * fontSize)
      let scaledAdvance = metrics.advance * fontSize
      
      xOffset += scaledBearing.width
      
      if xOffset > rect.width {
        break
      }
      
      let glyphBounds = CGRect(
        origin: CGPoint(x: xOffset, y: -scaledSize.height + fontSize + (scaledSize.height - scaledBearing.height) + maxYOffset),
        size: scaledSize
      )
      let glyphImageBounds = metrics.glyphImageBounds
      newGlyphs.append(Glyph(
        position: float3(Float(glyphBounds.minX), Float(glyphBounds.minY), 0),
        size: float2(Float(glyphBounds.width), Float(glyphBounds.height)),
        topLeftUv: float2(Float(glyphImageBounds.minX), Float(glyphImageBounds.maxY)),
        bottomRightUv: float2(Float(glyphImageBounds.maxX), Float(glyphImageBounds.minY)),
        fontSize: UInt32(fontSize),
        start: metrics.subPathsRange.lowerBound,
        end: metrics.subPathsRange.upperBound
      ))
      
      xOffset += scaledAdvance - scaledBearing.width
      
      if xOffset > maxXOffset {
        maxXOffset = xOffset
      }
    }
    
    let yOffset = CGFloat(fontSize)
    maxYOffset += yOffset + yOffset / 3
    
    return false
  }
  
  let fittedRect = CGRect(x: 0, y: 0, width: maxXOffset, height: maxYOffset)
  // Caching
  if (shouldCache)
  {
    glyphsCache.setValue(GlyphsData(glyphs: newGlyphs, fittedRect: fittedRect), forKey: hashCode)
  }
  offsetGlyphs(&newGlyphs, by: rect)
  glyphs.append(contentsOf: newGlyphs)
  
  return fittedRect
}
