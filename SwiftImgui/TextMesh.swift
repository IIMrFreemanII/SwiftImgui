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

func enumerateGlyphsInFrame(frame: CTFrame, cb: (_ glyph: CGGlyph, _ glyphIndex: Int, _ glyphBounds: CGRect) -> Void) {
  let entire = CFRangeMake(0, 0)
  let framePath = CTFrameGetPath(frame)
  let frameBoundingRect = framePath.boundingBoxOfPath
  let lines = CTFrameGetLines(frame) as! [CTLine]
  
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

func buildGlyphsFromString(
  _ string: String,
  inRect rect: CGRect,
  withFont fontAtlas: FontAtlas,
  atSize fontSize: CGFloat,
  glyphs: inout [Glyph]
) -> CGRect {
  var hasher = Hasher()
  hasher.combine(string)
  hasher.combine(fontSize)
  hasher.combine(rect.size)
  hasher.combine(fontAtlas.fontName)
  let hashCode = hasher.finalize()
  if var cachedGlyphsData = glyphsCache.value(forKey: hashCode) {
    offsetGlyphs(&cachedGlyphsData.glyphs, by: rect)
    glyphs.append(contentsOf: cachedGlyphsData.glyphs)
    return cachedGlyphsData.fittedRect
  }
  
  let font: CTFont = CTFontCreateWithName(fontAtlas.fontName as CFString, fontSize, nil)
  let attributes = [NSAttributedString.Key.font : font]
  let attrString = NSAttributedString(string: string, attributes: attributes)
  let stringRange = CFRange(location: 0, length: attrString.length)
  let framesetter = CTFramesetterCreateWithAttributedString(attrString)
  
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
  let frame = CTFramesetterCreateFrame(framesetter, fittedRange, rectPath, nil)
  
  var frameGlyphCount: CFIndex = 0
  let lines = CTFrameGetLines(frame) as! [CTLine]
  for line in lines {
    frameGlyphCount += CTLineGetGlyphCount(line)
  }
  
  var newGlyphs = [Glyph]()
  newGlyphs.reserveCapacity(frameGlyphCount)
  
  enumerateGlyphsInFrame(frame: frame) { glyph, glyphIndex, glyphBounds in
    if (glyph >= fontAtlas.glyphDescriptors.count) {
      print("Font atlas has no entry corresponding to glyph \(glyph); Skipping...")
      return
    }
    let glyphInfo = fontAtlas.glyphDescriptors[Int(glyph)]
    newGlyphs.append(Glyph(
      position: float3(Float(glyphBounds.minX), Float(glyphBounds.minY), 0),
      size: float2(Float(glyphBounds.width), Float(glyphBounds.height)),
      topLeftTexCoord: float2(Float(glyphInfo.topLeftTexCoord.x), Float(glyphInfo.topLeftTexCoord.y)),
      bottomRightTexCoord: float2(Float(glyphInfo.bottomRightTexCoord.x), Float(glyphInfo.bottomRightTexCoord.y))
    ))
  }
  
  let fittedRect = CGRect(origin: CGPoint(), size: frameSizeForString)
  glyphsCache.setValue(GlyphsData(glyphs: newGlyphs, fittedRect: fittedRect), forKey: hashCode)
  offsetGlyphs(&newGlyphs, by: rect)
  glyphs.append(contentsOf: newGlyphs)
  
  return fittedRect
}
