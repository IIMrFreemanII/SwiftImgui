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
  var crispness: Float = 0;
  // start of the SubPath range
  var start: UInt32 = 0
  // end of the SubPath range
  var end: UInt32 = 0
}

struct SDFGlyph {
  var color = float4(0, 0, 0, 1)
  var position = float3()
  var size = float2()
  var topLeftUv = float2()
  var bottomRightUv = float2()
  var crispness: Float = 0;
  var clipId: UInt32 = 0;
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

// MARK: Temporary unused!
//struct GlyphsData {
//  var glyphs: [SDFGlyph]
//  var fittedRect: CGRect
//}
//var glyphsCache = LRUCache<Int, GlyphsData>(countLimit: 1000)
//
//func offsetGlyphs(_ glyphs: inout [SDFGlyph], by rect: CGRect) {
//  glyphs.withUnsafeMutableBufferPointer { buffer in
//    for i in buffer.indices {
//      buffer[i].position.x += Float(rect.minX)
//      buffer[i].position.y += Float(rect.minY)
//    }
//  }
//}

let newLine = "\n".uint32[0]
func index(of value: UInt32, from buffer: UnsafeBufferPointer<UInt32>, range: Range<Int>) -> Int? {
  for i in range {
    if buffer[i] == value {
      return i
    }
  }
  
  return nil
}

func enumerateLines(for string: UnsafeBufferPointer<UInt32>, cb: (Range<Int>) -> Bool) {
  var startIndex = string.startIndex
  let endIndex = string.endIndex
  
  while true {
    if let lineEnd = index(of: newLine, from: string, range: startIndex..<endIndex) {
      let shouldStop = cb(startIndex..<lineEnd)
      if shouldStop {
        return
      }
      
      // offsetBy 1 to skip \n
      startIndex = lineEnd + 1
    } else {
      _ = cb(startIndex..<endIndex)
      return
    }
  }
}

func buildSDFGlyphsFromString(
  _ string: inout [UInt32],
  inRect rect: CGRect,
  color: float4,
  withFont fontAtlas: Font,
  atSize fontSize: Int,
  glyphs: inout [SDFGlyph],
  glyphsCount: inout Int
) -> CGRect {
//  let shouldCache = string.count > 100
//  var hasher = Hasher()
//  hasher.combine(string)
//  hasher.combine(fontSize)
//  hasher.combine(rect.size)
//  hasher.combine(fontAtlas.fontName)
//  hasher.combine(color)
//  let hashCode = hasher.finalize()
//
//  // Caching
//  if
//    shouldCache,
//    var cachedGlyphsData = glyphsCache.value(forKey: hashCode)
//  {
//    offsetGlyphs(&cachedGlyphsData.glyphs, by: rect)
//    glyphs.append(contentsOf: cachedGlyphsData.glyphs)
//    return cachedGlyphsData.fittedRect
//  }
  
//  var newGlyphs = [SDFGlyph]()
//  newGlyphs.reserveCapacity(string.count)
//  let glyphsBuffer = glyphs.withUnsafeMutableBufferPointer { $0 }
  
  var maxXOffset: CGFloat = 0
  var maxYOffset: CGFloat = 0
  
  let fontSize = CGFloat(fontSize)
  
  glyphs.withUnsafeMutableBufferPointer { glyphsBuffer in
    string.withUnsafeBufferPointer { buffer in
      enumerateLines(for: buffer) { range in
        if (maxYOffset + fontSize) > rect.height {
          return true
        }
        
        var xOffset: CGFloat = 0
        
        for i in range {
          let char = buffer[i]
          let metrics = fontAtlas.charToSDFGlyphMetricsMap[char]!
          
          let scaledSize = CGSize(width: metrics.size.width * fontSize, height: metrics.size.height * fontSize)
          let scaledBearing = CGSize(width: metrics.bearing.width * fontSize, height: metrics.bearing.height * fontSize)
          let scaledAdvance = metrics.advance * fontSize
          
          xOffset += scaledBearing.width
          
          if xOffset > rect.width {
            break
          }
          
          var glyphBounds = CGRect(
            origin: CGPoint(x: xOffset, y: -scaledSize.height + fontSize + (scaledSize.height - scaledBearing.height) + maxYOffset),
            size: scaledSize
          )
          glyphBounds.origin = CGPoint(x: glyphBounds.origin.x + rect.origin.x, y: glyphBounds.origin.y + rect.origin.y)
          
          glyphsBuffer[glyphsCount] = SDFGlyph(
            color: color,
            position: float3(Float(glyphBounds.minX), Float(glyphBounds.minY), Float(depth)),
            size: float2(Float(glyphBounds.width), Float(glyphBounds.height)),
            topLeftUv: metrics.topLeftUv,
            bottomRightUv: metrics.bottomRightUv,
            crispness: 0.01,
            clipId: UInt32(clipRectsCount)
          )
          glyphsCount += 1
          
          xOffset += scaledAdvance - scaledBearing.width
          
          if xOffset > maxXOffset {
            maxXOffset = xOffset
          }
        }
        
        let yOffset = CGFloat(fontSize)
        maxYOffset += yOffset + yOffset / 3
        
        return false
      }
    }
  }
  
  incrementDepth()
  let fittedRect = CGRect(x: 0, y: 0, width: maxXOffset, height: maxYOffset)
  // Caching
//  if (shouldCache)
//  {
//    glyphsCache.setValue(GlyphsData(glyphs: newGlyphs, fittedRect: fittedRect), forKey: hashCode)
//  }
//  offsetGlyphs(&newGlyphs, by: rect)
//  glyphs.append(contentsOf: newGlyphs)
  
  return fittedRect
}
