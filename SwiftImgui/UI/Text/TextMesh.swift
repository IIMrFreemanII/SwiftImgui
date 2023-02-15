//
//  TextMesh.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 03.01.2023.
//

import MetalKit

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
  var crispness: Float = 0
  // start of the SubPath range
  var start: UInt32 = 0
  // end of the SubPath range
  var end: UInt32 = 0
}

struct SDFGlyph {
  var color = float4(0, 0, 0, 1)
  var position = float2()
  var size = float2()
  var topLeftUv = float2()
  var bottomRightUv = float2()
  var crispness = Float()
  var depth = Float()
  var clipId: UInt16 = 0
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

func index(of value: UInt32, from buffer: UnsafeBufferPointer<UInt32>, range: Range<Int>) -> Int? {
  for i in range {
    if buffer[i] == value {
      return i
    }
  }
  
  return nil
}

func indexOfNewLine(from buffer: UnsafeBufferPointer<UInt32>, range: Range<Int>) -> Int? {
  for i in range {
    let char = buffer[i]
    if char == Input.newLine || char == Input.returnOrEnterKey {
      return i
    }
  }
  
  return nil
}

func enumerateLines(for string: UnsafeBufferPointer<UInt32>, cb: (Range<Int>) -> Bool) {
  var startIndex = string.startIndex
  let endIndex = string.endIndex
  
  while true {
    if let lineEnd = indexOfNewLine(from: string, range: startIndex..<endIndex) {
      let shouldStop = cb(startIndex..<lineEnd)
      if shouldStop {
        return
      }
      
      // offsetBy 1 to skip \n or \r
      startIndex = lineEnd + 1
    } else {
      _ = cb(startIndex..<endIndex)
      return
    }
  }
}

func textSelection(
  _ string: inout [UInt32],
  textSelection: inout TextSelection,
  position: float2,
  fontSize: Float,
  font: Font
) {
  var row = UInt32(1)
  var col = UInt32(1)
  
  let lineHeight = fontSize * 1.333
  
  var xOffset = Float(0)
  var yOffset = Float(0)
  
  let start = textSelection.start
  let end = textSelection.end
  
  string.withUnsafeBufferPointer { buffer in
    enumerateLines(for: buffer) { range in
      if row > end.0 {
        return true
      }
      if row < start.0 {
        row += 1
        yOffset += lineHeight
        return false
      }
      
      col = 1
      xOffset = 0
      var rectStartXPos = Float()
      var rectEndXPos = Float()
      
      // range.upperBound + 1 to take into accound new line or null terminator character
      let plusOneRange = range.lowerBound..<(range.upperBound + 1)
      for i in plusOneRange {
        if col == start.1 {
          rectStartXPos = xOffset
        }
        if col == end.1 {
          rectEndXPos = xOffset
          break
        }
        let char = buffer[i]
        let metrics = font.charToSDFGlyphMetricsMap[char]!
        let scaledAdvance = metrics.advance * fontSize
        
        xOffset += scaledAdvance
        col += 1
      }
      
      rect(
        Rect(
          position: position + float2(rectStartXPos, yOffset),
          size: float2(rectEndXPos - rectStartXPos, yOffset + lineHeight)
        ),
        color: float4(0, 0, 1, 0.5)
      )
      
      row += 1
      yOffset += lineHeight
      
      return false
    }
  }
}

func findRowAndCol(
  from point: float2,
  in rect: Rect,
  _ string: inout [UInt32],
  fontSize: Float,
  font: Font
) -> (UInt32, UInt32) {
  var row = UInt32(1)
  var col = UInt32(1)
  
  let lineHeight = fontSize * 1.333
  let rowsCount = UInt32(rect.height / lineHeight)
  let pointYNorm = normalize(value: point.y, min: 0, max: rect.height)
  let selectedRow = UInt32(floor(lerp(min: 1, max: Float(rowsCount), t: pointYNorm)))
  
  row = selectedRow
  
  var xOffset = Float(0)
  let yOffset = (Float(row) - 1) * lineHeight
  
  var rowIndex = 1
  string.withUnsafeBufferPointer { buffer in
    enumerateLines(for: buffer) { range in
      if rowIndex != row {
        rowIndex += 1
        return false
      }
      
      for i in range {
        let char = buffer[i]
        let metrics = font.charToSDFGlyphMetricsMap[char]!
        
        let scaledAdvance = metrics.advance * fontSize
        
        let charRect = Rect(position: float2(xOffset, yOffset), size: float2(scaledAdvance, lineHeight))
        let hit = pointInAABBox(point: point, position: charRect.position, size: charRect.size)
        
        if hit {
          let pointLocalToCharRect = point - charRect.position
          let cursorAfterChar = pointLocalToCharRect.x > (charRect.width * 0.5)
          
          if cursorAfterChar {
            col += 1
          }
          
          return true
        }
        
        xOffset += scaledAdvance
        col += 1
      }
      
      return true
    }
  }
  
  return (row, col)
}

func calcCursorOffset(
  row: UInt32,
  column: UInt32,
  _ string: inout [UInt32],
  fontSize: Float,
  font: Font
) -> float2 {
  let lineHeight = fontSize * 1.333
  var xOffset: Float = 0
  var yOffset: Float = 0
  
  var rowIndex: UInt32 = 1
  string.withUnsafeBufferPointer { buffer in
    enumerateLines(for: buffer) { range in
      if rowIndex > row {
        return true
      }
      if rowIndex < row {
        rowIndex += 1
        yOffset += lineHeight
        return false
      }
      
      var colIndex: UInt32 = 1
      xOffset = 0
      
      // range.upperBound + 1 to take into accound new line or null terminator character
      let plusOneRange = range.lowerBound..<(range.upperBound + 1)
      for i in plusOneRange {
        if colIndex >= column {
          return true
        }
        
        let char = buffer[i]
        let metrics = font.charToSDFGlyphMetricsMap[char]!
        
        let scaledAdvance = metrics.advance * fontSize
        
        xOffset += scaledAdvance
        colIndex += 1
      }
      
      rowIndex += 1
      yOffset += lineHeight
      return false
    }
  }
  
  return float2(xOffset, yOffset)
}

func calcBoundsForString(_ string: inout [UInt32], fontSize: Float, font: Font) -> Rect {
  let lineHeight = fontSize * 1.333
  var maxXOffset: Float = 0
  var maxYOffset: Float = 0
  
  string.withUnsafeBufferPointer { buffer in
    enumerateLines(for: buffer) { range in
      var xOffset: Float = 0
      
      for i in range {
        let char = buffer[i]
        let metrics = font.charToSDFGlyphMetricsMap[char]!
        
        let scaledAdvance = metrics.advance * fontSize
        
        xOffset += scaledAdvance
        
        if xOffset > maxXOffset {
          maxXOffset = xOffset
        }
      }
      
      maxYOffset += lineHeight
      
      return false
    }
  }
  
  return Rect(size: float2(maxXOffset, maxYOffset))
}

func buildSDFGlyphsFromString(
  _ string: inout [UInt32],
  inRect rect: Rect,
  color: float4,
  withFont fontAtlas: Font,
  atSize fontSize: Float,
  glyphs: inout [SDFGlyph],
  glyphsCount: inout Int
) -> Rect {
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
  
  let lineHeight = fontSize * 1.333
  var maxXOffset: Float = 0
  var maxYOffset: Float = 0
  
  let clipLayerId = clipRectIndices.withUnsafeBufferPointer { $0[clipRectIndicesCount - 1] }
  
  glyphs.withUnsafeMutableBufferPointer { glyphsBuffer in
    string.withUnsafeBufferPointer { buffer in
      enumerateLines(for: buffer) { range in
        if (maxYOffset + fontSize) > rect.size.y {
          return true
        }
        
        var xOffset: Float = 0
        
        for i in range {
          let char = buffer[i]
          let metrics = fontAtlas.charToSDFGlyphMetricsMap[char]!
          
          let scaledSize = float2(metrics.size.x * fontSize, metrics.size.y * fontSize)
          let scaledBearing = float2(metrics.bearing.x * fontSize, metrics.bearing.y * fontSize)
          let scaledAdvance = metrics.advance * fontSize
          
          xOffset += scaledBearing.x
          
          if xOffset > rect.size.x {
            break
          }
          
          var glyphBounds = Rect(
            position: float2(x: xOffset, y: -scaledSize.y + fontSize + (scaledSize.y - scaledBearing.y) + maxYOffset),
            size: scaledSize
          )
          glyphBounds.position = float2(x: glyphBounds.position.x + rect.position.x, y: glyphBounds.position.y + rect.position.y)
          
          glyphsBuffer[glyphsCount] = SDFGlyph(
            color: color,
            position: float2(glyphBounds.position.x, glyphBounds.position.y),
            size: float2(glyphBounds.size.x, glyphBounds.size.y),
            topLeftUv: metrics.topLeftUv,
            bottomRightUv: metrics.bottomRightUv,
            crispness: 0.01,
            depth: Float(depth),
            clipId: UInt16(clipLayerId)
          )
          glyphsCount += 1
          
          xOffset += scaledAdvance - scaledBearing.x
          
          if xOffset > maxXOffset {
            maxXOffset = xOffset
          }
        }
        
        maxYOffset += lineHeight
        
        return false
      }
    }
  }
  
  incrementDepth()
  let fittedRect = Rect(position: rect.position, size: float2(maxXOffset, maxYOffset))
  // Caching
//  if (shouldCache)
//  {
//    glyphsCache.setValue(GlyphsData(glyphs: newGlyphs, fittedRect: fittedRect), forKey: hashCode)
//  }
//  offsetGlyphs(&newGlyphs, by: rect)
//  glyphs.append(contentsOf: newGlyphs)
  
  return fittedRect
}
