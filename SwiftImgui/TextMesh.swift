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
  var topLeftTexCoord = float2()
  var bottomRightTexCoord = float2()
}

private var fontMetrics = [Int:[Character: GlyphMetrics]]()

private func fontGlyphMetricsMapFor(fontName: String, fontSize: Int) -> [Character: GlyphMetrics] {
  var hasher = Hasher()
  hasher.combine(fontName)
  hasher.combine(fontSize)
  let hash = hasher.finalize()
  
  guard let metrics = fontMetrics[hash] else {
    let metrics = generateGlyphMetricsForFont(fontName: fontName, fontSize: fontSize)
    fontMetrics[hash] = metrics
    print("Generate glyph metrics for fontName: '\(fontName)', fontSize: \(fontSize)")
    
    return metrics
  }
  
  return metrics
}

private func generateGlyphMetricsForFont(fontName: String, fontSize: Int) -> [Character: GlyphMetrics] {
  var glyphMetricsMap = [Character: GlyphMetrics]()
  let font = CTFont(fontName as CFString, size: CGFloat(fontSize))
  let fontCharacterSet = CTFontCopyCharacterSet(font) as CharacterSet
  let charaters = fontCharacterSet.characters()
  for char in charaters {
    glyphMetricsMap[char] = generateGlyphMetrics(for: char, font: font)
  }
  return glyphMetricsMap
}

private func generateGlyphMetrics(for value: Character, font: CTFont) -> GlyphMetrics {
  let entire = CFRangeMake(0, 0)
  let rect = CGRect(
    origin: CGPoint(),
    size:  CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
  )
  let attributes = [NSAttributedString.Key.font : font]
  
  let attrString = NSAttributedString(string: String(value), attributes: attributes)
  let framesetter = CTFramesetterCreateWithAttributedString(attrString)

  let stringRange = CFRange(location: 0, length: 1)
  var fittedRange = CFRange(location: 0, length: 0)
  let frameSizeForString = CTFramesetterSuggestFrameSizeWithConstraints(
    framesetter,
    stringRange,
    nil,
    rect.size,
    &fittedRange
  )
  let rectPath = CGPath(
    rect: CGRect(origin: CGPoint(), size: frameSizeForString),
    transform: nil
  )
  let frameBoundingRect = rectPath.boundingBoxOfPath

  let frame = CTFramesetterCreateFrame(framesetter, fittedRange, rectPath, nil)

  let lines = CTFrameGetLines(frame) as! [CTLine]

  var lineOriginBuffer = [CGPoint](repeating: CGPoint(), count: lines.count)
  CTFrameGetLineOrigins(frame, entire, &lineOriginBuffer)
  
  var glyphMetrics = GlyphMetrics()
  
  for i in lines.indices {
    let line = lines[i]
    let lineOrigin = lineOriginBuffer[i]

    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    for run in runs {
      let glyphCount = CTRunGetGlyphCount(run)

      var positionBuffer = [CGPoint](repeating: CGPoint(), count: glyphCount)
      CTRunGetPositions(run, entire, &positionBuffer)
      
      var advanceBuffer = [CGSize](repeating: CGSize(), count: glyphCount)
      CTRunGetAdvances(run, entire, &advanceBuffer)


      for i in positionBuffer.indices {
        let glyphOrigin = positionBuffer[i]
        let advance = advanceBuffer[i]
        var glyphRect = CTRunGetImageBounds(run, nil, CFRangeMake(i, 1))

        let boundsTransX = frameBoundingRect.origin.x + lineOrigin.x
        let boundsTransY = frameBoundingRect.height + frameBoundingRect.origin.y - lineOrigin.y + glyphOrigin.y
        let pathTransform = CGAffineTransformMake(1, 0, 0, -1, boundsTransX, boundsTransY)
        glyphRect = CGRectApplyAffineTransform(glyphRect, pathTransform)
        glyphMetrics = GlyphMetrics(
          rect: glyphRect,
          advance: advance.width
        )
      }
    }
  }
  
  return glyphMetrics
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

private struct GlyphMetrics {
  var rect: CGRect = CGRect()
  var advance: CGFloat = 0 // Offset to advance to next glyph
}

func enumerateGlyphsInFrame(frame: CTFrame, lines: inout [CTLine], cb: (_ glyph: CGGlyph, _ glyphIndex: Int, _ glyphBounds: CGRect) -> Void) {
  let entire = CFRangeMake(0, 0)
  let framePath = CTFrameGetPath(frame)
  let frameBoundingRect = framePath.boundingBoxOfPath
  
  var lineOriginBuffer = [CGPoint](repeating: CGPoint(), count: lines.count)
  CTFrameGetLineOrigins(frame, entire, &lineOriginBuffer)
  
  var glyphIndexInFrame: Int = 0
  
  for i in lines.indices {
    let line = lines[i]
    let lineOrigin = lineOriginBuffer[i]
    
    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    for run in runs {
      let glyphCount = CTRunGetGlyphCount(run)
      
      var glyphBuffer = [CGGlyph](repeating: 0, count: glyphCount)
      CTRunGetGlyphs(run, entire, &glyphBuffer)
      
      var positionBuffer = [CGPoint](repeating: CGPoint(), count: glyphCount)
      CTRunGetPositions(run, entire, &positionBuffer)
      
      for glyphIndex in 0..<glyphCount {
        let glyph = glyphBuffer[glyphIndex]
        let glyphOrigin = positionBuffer[glyphIndex]
        var glyphRect = CTRunGetImageBounds(run, nil, CFRangeMake(glyphIndex, 1))
        
        let boundsTransX = frameBoundingRect.origin.x + lineOrigin.x
        let boundsTransY = CGRectGetHeight(frameBoundingRect) + frameBoundingRect.origin.y - lineOrigin.y + glyphOrigin.y
        let pathTransform = CGAffineTransformMake(1, 0, 0, -1, boundsTransX, boundsTransY)
        glyphRect = CGRectApplyAffineTransform(glyphRect, pathTransform)
        
        cb(glyph, glyphIndexInFrame, glyphRect)
        glyphIndexInFrame += 1
      }
    }
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
      _ = cb(string[string.startIndex..<string.endIndex])
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
  
  // generating glyph metrics for font with font size
  let glyphMetricsMap = fontGlyphMetricsMapFor(fontName: fontAtlas.fontName, fontSize: fontSize)
  
  var maxXOffset: CGFloat = 0
  var maxYOffset: CGFloat = 0
  
  enumerateLines(for: string) { line in
    if maxYOffset > rect.height {
      return true
    }
    
    var xOffset: CGFloat = 0
    
    for char in line {
      let metrics = glyphMetricsMap[char]!
      
      xOffset += metrics.rect.origin.x
      
      if xOffset > rect.width {
        break
      }
      
      let glyphBounds = CGRect(
        origin: CGPoint(x: xOffset, y: metrics.rect.origin.y + maxYOffset),
        size: metrics.rect.size
      )
      let glyphInfo = fontAtlas.glyphDescriptors[char]!
      newGlyphs.append(Glyph(
        position: float3(Float(glyphBounds.minX), Float(glyphBounds.minY), 0),
        size: float2(Float(glyphBounds.width), Float(glyphBounds.height)),
        topLeftTexCoord: float2(Float(glyphInfo.topLeftTexCoord.x), Float(glyphInfo.topLeftTexCoord.y)),
        bottomRightTexCoord: float2(Float(glyphInfo.bottomRightTexCoord.x), Float(glyphInfo.bottomRightTexCoord.y))
      ))
      
      xOffset += metrics.advance - metrics.rect.origin.x
      
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
