//
//  FontAtlas.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 02.01.2023.
//

import Foundation
import AppKit
import CoreText

struct GlyphDescriptor {
  var glyphIndex: CGGlyph
  var topLeftTexCoord: CGPoint
  var bottomRightTexCoord: CGPoint
}

class FontAtlas {
  var parentFont: NSFont
  var fontPointSize: CGFloat
  var spread: CGFloat
  var textureSize: Int
  var glyphDescriptors = [GlyphDescriptor]()
  var textureData: Data
  
  init(font: NSFont, textureSize: Int) {
    self.parentFont = font
    self.fontPointSize = font.pointSize
    self.textureSize = textureSize
    self.spread = 0
    self.textureData = Data()
    
    self.spread = estimatedLineWidthForFont(font: font) * 0.5
    
    self.createTextureData()
  }
  
  func estimatedGlyphSizeForFont(font: NSFont) -> CGSize {
    let exampleString = NSString(string: "{ǺOJMQYZa@jmqyw")
    let exampleStringSize: CGSize = exampleString.size(withAttributes: [NSAttributedString.Key.font : font])
    let averageGlyphWidth: CGFloat = CGFloat(ceilf(Float(exampleStringSize.width) / Float(exampleString.length)))
    let maxGlyphHeight: CGFloat = CGFloat(ceilf(Float(exampleStringSize.height)))
    
    return CGSizeMake(averageGlyphWidth, maxGlyphHeight)
  }
  
  func estimatedLineWidthForFont(font: NSFont) -> CGFloat {
    let estimatedStrokeWidth = NSString(string: "!").size(withAttributes: [NSAttributedString.Key.font: font]).width
    return CGFloat(ceilf(Float(estimatedStrokeWidth)))
  }
  
  func font(_ font: NSFont, atSize size: CGFloat, isLikelyToFitInAtlasRect rect: CGRect) -> Bool {
    let textureArea = rect.size.width * rect.size.height
    let trialFont = NSFont(name: font.fontName, size: size)!
    let trialCTFont = CTFontCreateWithName(font.fontName as CFString, size, nil)
    let fontGlyphCount = CTFontGetGlyphCount(trialCTFont)
    let glyphMargin = self.estimatedLineWidthForFont(font: trialFont)
    let averageGlyphSize = self.estimatedGlyphSizeForFont(font: trialFont)
    let estimatedGlyphTotalArea = (averageGlyphSize.width + CGFloat(glyphMargin)) * (averageGlyphSize.height + CGFloat(glyphMargin)) * CGFloat(Int(fontGlyphCount))
    
    let fits = estimatedGlyphTotalArea < textureArea
    return fits
  }
  
  func pointSizeThatFitsForFont(_ font: NSFont, inAtlasRect rect: CGRect) -> CGFloat {
    var fittedSize = font.pointSize
    
    while (self.font(font, atSize: fittedSize, isLikelyToFitInAtlasRect: rect)) {
      fittedSize += 1
    }
    
    while (!self.font(font, atSize: fittedSize, isLikelyToFitInAtlasRect: rect)) {
      fittedSize -= 1
    }
    
    return fittedSize
  }
  
  func createAtlasForFont(font: NSFont, width: Int, height: Int) -> [UInt8] {
    var imageData = [UInt8](repeating: 0, count: width * height)
    
    let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)!
    let bitmapInfo = CGBitmapInfo.alphaInfoMask.rawValue & CGImageAlphaInfo.none.rawValue
    let context = CGContext(
      data: &imageData,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: width,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    )!
    
    // Turn off antialiasing so we only get fully-on or fully-off pixels.
    // This implicitly disables subpixel antialiasing and hinting.
    context.setShouldAntialias(false)
    
    // Flip context coordinate space so y increases downward
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    
    // Fill the context with an opaque black color
    context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
    context.fill([CGRect(x: 0, y: 0, width: width, height: height)])
    
    self.fontPointSize = self.pointSizeThatFitsForFont(font, inAtlasRect: CGRect(x: 0, y: 0, width: width, height: height))
    let ctFont = CTFontCreateWithName(font.fontName as CFString, self.fontPointSize, nil)
    self.parentFont = NSFont(name: font.fontName, size: self.fontPointSize)!
    
    let fontGlyphCount = CTFontGetGlyphCount(ctFont)
    
    let glyphMargin = self.estimatedLineWidthForFont(font: self.parentFont)
    
    // Set fill color so that glyphs are solid white
    context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
    
    glyphDescriptors.removeAll()
    
    let fontAscent: CGFloat = CTFontGetAscent(ctFont)
    let fontDescent: CGFloat = CTFontGetDescent(ctFont)
    
    var origin = CGPoint(x: 0, y: fontAscent)
    var maxYCoordForLine: CGFloat = -1
    
    for var glyph in 0..<UInt16(fontGlyphCount) {
      var boundingRect: CGRect = CGRect()
      CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, &glyph, &boundingRect, 1)
      
      if (Float(origin.x + CGRectGetMaxX(boundingRect) + glyphMargin) > Float(width))
      {
          origin.x = 0;
          origin.y = maxYCoordForLine + glyphMargin + fontDescent;
          maxYCoordForLine = -1;
      }
      
      if (origin.y + CGRectGetMaxY(boundingRect) > maxYCoordForLine)
      {
          maxYCoordForLine = origin.y + CGRectGetMaxY(boundingRect);
      }
      
      let glyphOriginX: CGFloat = origin.x - boundingRect.origin.x + (glyphMargin * 0.5);
      let glyphOriginY: CGFloat = origin.y + (glyphMargin * 0.5);
      
      var glyphTransform = CGAffineTransformMake(1, 0, 0, -1, glyphOriginX, glyphOriginY);
      
      let path: CGPath = CTFontCreatePathForGlyph(ctFont, glyph, &glyphTransform) ?? CGPath(rect: CGRectNull, transform: nil);
      context.addPath(path)
      context.fillPath()
      
      var glyphPathBoundingRect: CGRect = path.boundingBoxOfPath;
      
      // The null rect (i.e., the bounding rect of an empty path) is problematic
      // because it has its origin at (+inf, +inf); we fix that up here
      if (CGRectEqualToRect(glyphPathBoundingRect, CGRectNull))
      {
          glyphPathBoundingRect = CGRectZero;
      }
      
      let texCoordLeft = glyphPathBoundingRect.origin.x / CGFloat(width);
      let texCoordRight = (glyphPathBoundingRect.origin.x + glyphPathBoundingRect.size.width) / CGFloat(width);
      let texCoordTop = (glyphPathBoundingRect.origin.y) / CGFloat(height);
      let texCoordBottom = (glyphPathBoundingRect.origin.y + glyphPathBoundingRect.size.height) / CGFloat(height);
      
      
      let descriptor = GlyphDescriptor(
        glyphIndex: glyph,
        topLeftTexCoord: CGPointMake(texCoordLeft, texCoordTop),
        bottomRightTexCoord: CGPointMake(texCoordRight, texCoordBottom)
      )
      glyphDescriptors.append(descriptor)
      
      origin.x += CGRectGetWidth(boundingRect) + glyphMargin;
    }
    
    // Break here to view the generated font atlas bitmap
    #if false
    var contextImage = context.makeImage()!
    #endif
    
    return imageData
  }
  
  /// Compute signed-distance field for an 8-bpp grayscale image (values greater than 127 are considered "on")
  /// For details of this algorithm, see "The 'dead reckoning' signed distance transform" [Grevera 2004]
  func createSignedDistanceFieldForGrayscaleImage(imageData: inout [UInt8], width: Int, height: Int) -> [Float] {
    if imageData.count == 0, width == 0, height == 0 {
      return [Float]()
    }
    
    struct intpoint_t {
      var x: UInt16
      var y: UInt16
    }
    
    let maxDist: Float = hypotf(Float(width), Float(height))
    let distUnit: Float = 1
    let distDiag: Float = sqrtf(2)
    
    // Initialization phase: set all distances to "infinity"; zero out nearest boundary point map
    var distanceMap = [Float](repeating: maxDist, count: width * height) // distance to nearest boundary point map
    var boundaryPointMap = [intpoint_t](repeating: intpoint_t(x: 0, y: 0), count: width * height) // nearest boundary point map
    
    func image(_ x: Int, _ y: Int) -> Bool {
      return imageData[y * width + x] > 0x7f
    }
    func getDistance(_ x: Int, _ y: Int) -> Float {
      return distanceMap[y * width + x]
    }
    func setDistance(_ x: Int, _ y: Int, _ value: Float) {
      distanceMap[y * width + x] = value
    }
    func getNearestpt(_ x: Int, _ y: Int) -> intpoint_t {
      return boundaryPointMap[y * width + x]
    }
    func setNearestpt(_ x: Int, _ y: Int, _ value: intpoint_t) {
      boundaryPointMap[y * width + x] = value
    }
    
    // Immediate interior/exterior phase: mark all points along the boundary as such
    for y in 1..<(height - 1) {
      for x in 1..<(width - 1) {
        let inside = image(x, y)
        if (
          image(x - 1, y) != inside ||
          image(x + 1, y) != inside ||
          image(x, y - 1) != inside ||
          image(x, y + 1) != inside
        ) {
          setDistance(x, y, 0)
          setNearestpt(x, y, intpoint_t(x: UInt16(x), y: UInt16(y)))
        }
      }
    }
    
    // Forward dead-reckoning pass
    for y in 1..<(height - 2) {
      for x in 1..<(width - 2) {
        if (distanceMap[(y - 1) * width + (x - 1)] + distDiag < getDistance(x, y)) {
          setNearestpt(x, y, getNearestpt(x - 1, y - 1))
          setDistance(x, y, hypotf(Float(x - Int(getNearestpt(x, y).x)), Float(y - Int(getNearestpt(x, y).y))))
        }
        if (getDistance(x, y - 1) + distUnit < getDistance(x, y)) {
          setNearestpt(x, y, getNearestpt(x, y - 1))
          setDistance(x, y, hypotf(Float(x - Int(getNearestpt(x, y).x)), Float(y - Int(getNearestpt(x, y).y))))
        }
        if (getDistance(x + 1, y - 1) + distDiag < getDistance(x, y)) {
          setNearestpt(x, y, getNearestpt(x + 1, y - 1))
          setDistance(x, y, hypotf(Float(x - Int(getNearestpt(x, y).x)), Float(y - Int(getNearestpt(x, y).y))))
        }
        if (getDistance(x - 1, y) + distUnit < getDistance(x, y)) {
          setNearestpt(x, y, getNearestpt(x - 1, y))
          setDistance(x, y, hypotf(Float(x - Int(getNearestpt(x, y).x)), Float(y - Int(getNearestpt(x, y).y))))
        }
      }
    }
    
    // Backward dead-reckoning pass
    for y in stride(from: height - 2, through: 1, by: -1) {
      for x in stride(from: width - 2, through: 1, by: -1) {
        if (getDistance(x + 1, y) + distUnit < getDistance(x, y)) {
          setNearestpt(x, y, getNearestpt(x + 1, y))
          setDistance(x, y, hypotf(Float(x - Int(getNearestpt(x, y).x)), Float(y - Int(getNearestpt(x, y).y))))
        }
        if (getDistance(x - 1, y + 1) + distDiag < getDistance(x, y)) {
          setNearestpt(x, y, getNearestpt(x - 1, y + 1))
          setDistance(x, y, hypotf(Float(x - Int(getNearestpt(x, y).x)), Float(y - Int(getNearestpt(x, y).y))))
        }
        if (getDistance(x, y + 1) + distUnit < getDistance(x, y)) {
          setNearestpt(x, y, getNearestpt(x, y + 1))
          setDistance(x, y, hypotf(Float(x - Int(getNearestpt(x, y).x)), Float(y - Int(getNearestpt(x, y).y))))
        }
        if (getDistance(x + 1, y + 1) + distDiag < getDistance(x, y)) {
          setNearestpt(x, y, getNearestpt(x + 1, y + 1))
          setDistance(x, y, hypotf(Float(x - Int(getNearestpt(x, y).x)), Float(y - Int(getNearestpt(x, y).y))))
        }
      }
    }
    
    // Interior distance negation pass; distances outside the figure are considered negative
    for y in 0..<height {
      for x in 0..<width {
        if (!image(x, y)) {
          setDistance(x, y, -getDistance(x, y))
        }
      }
    }
    
    return distanceMap
  }
  
  func createResampledData(inData: inout [Float], width: Int, height: Int, scaleFactor: Int) -> [Float] {
    let scaledWidth = width / scaleFactor
    let scaledHeight = height / scaleFactor
    var outData = [Float](repeating: 0, count: scaledWidth * scaledHeight)
    
    for y in stride(from: 0, to: height, by: scaleFactor) {
      for x in stride(from: 0, to: width, by: scaleFactor) {
        var accum: Float = 0
        for ky in 0..<scaleFactor {
          for kx in 0..<scaleFactor {
            accum += inData[(y + ky) * width + (x + kx)]
          }
        }
        accum = accum / Float((scaleFactor * scaleFactor))
        
        outData[(y / scaleFactor) * scaledWidth + (x / scaleFactor)] = accum
      }
    }
    
    return outData
  }
  
  func createQuantizedDistanceField(inData: inout [Float], width: Int, height: Int, normalizationFactor: Float) -> [UInt8] {
    var outData = [UInt8](repeating: 0, count: width * height)
    
    for y in 0..<height {
      for x in 0..<width {
        let dist = inData[y * width + x]
        let clampDist = fmaxf(-normalizationFactor, fminf(dist, normalizationFactor))
        let scaledDist = clampDist / normalizationFactor
        let value: UInt8 = UInt8(((scaledDist + 1) / 2) * Float(UInt8.max))
        outData[y * width + x] = value
      }
    }
    
    return outData
  }
  
  func createTextureData() {
    // Generate an atlas image for the font, resizing if necessary to fit in the specified size.
    var atlasData: [UInt8] = createAtlasForFont(font: self.parentFont, width: self.textureSize, height: self.textureSize)
    // Create the signed-distance field representation of the font atlas from the rasterized glyph image.
    var distanceField: [Float] = createSignedDistanceFieldForGrayscaleImage(imageData: &atlasData, width: self.textureSize, height: self.textureSize)
    
//    let scaleFactor = self.textureSize / self.textureSize
    // Downsample the signed-distance field to the expected texture resolution
//    var scaledField: [Float] = createResampledData(inData: &distanceField, width: self.textureSize, height: self.textureSize, scaleFactor: scaleFactor)
    
    let spread: CGFloat = estimatedLineWidthForFont(font: self.parentFont) * 0.5
    var texture: [UInt8] = createQuantizedDistanceField(inData: &distanceField, width: self.textureSize, height: self.textureSize, normalizationFactor: Float(spread))
    
    #if false
    let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)!
    let bitmapInfo = CGBitmapInfo.alphaInfoMask.rawValue & CGImageAlphaInfo.none.rawValue
    let context = CGContext(
      data: &texture,
      width: self.textureSize,
      height: self.textureSize,
      bitsPerComponent: 8,
      bytesPerRow: self.textureSize,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    )!
    let image = context.makeImage()!
    #endif
    
    self.textureData = Data(buffer: texture.withUnsafeMutableBufferPointer { $0 })
  }
}
