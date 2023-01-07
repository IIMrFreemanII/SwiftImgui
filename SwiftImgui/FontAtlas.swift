//
//  FontAtlas.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 02.01.2023.
//

import Foundation
import MetalKit
import CoreText

extension Character: Codable {
  enum CodingKeys: CodingKey {
    case value
  }
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let value = try container.decode(UInt32.self)
    
    var string = ""
    if let scalar = UnicodeScalar(value) {
      string.append(Character(scalar))
    }
    
    guard !string.isEmpty else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Decoder expected a Character but found an empty string.")
    }
    guard string.count == 1 else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Decoder expected a Character but found a string: \(string)")
    }
    self = string[string.startIndex]
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for element in self.unicodeScalars {
      try container.encode(element.value)
    }
  }
}

struct GlyphDescriptor: Codable {
  var glyphIndex: CGGlyph
  var topLeftTexCoord: CGPoint
  var bottomRightTexCoord: CGPoint
}

// 1024 & 2048 & 4096
private let FontAtlasSize = 4096

func buildFontAtlas(fontName: String, fontAtlasSize: Int) -> FontAtlas {
  let fontUrl = documentsUrl().appendingPathComponent(fontName).appendingPathExtension("sdf")
 
  let decoder = PropertyListDecoder()
  if
    let fontAtlasData = try? Data(contentsOf: fontUrl),
    let fontAtlas = try? decoder.decode(FontAtlas.self, from: fontAtlasData)
  {
    print("Loaded cached font atlas for font: '\(fontAtlas.fontName!)'")
    return fontAtlas
  } else {
    print("Didn't find cached font atlas font for '\(fontName)', creating new one")
  }
  
  let fontAtlas = FontAtlas(fontName: fontName, textureSize: fontAtlasSize)
  do {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    try encoder.encode(fontAtlas).write(to: fontUrl)
    print("Cached font atlas for font: '\(fontAtlas.fontName!)'")
  } catch let error {
    fatalError(error.localizedDescription)
  }
  
  return fontAtlas
}

private func documentsUrl() -> URL {
  let candidates = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
  let documentsPath = candidates.first!
  return URL(filePath: documentsPath, directoryHint: .isDirectory)
}

class FontAtlas: Codable {
  enum CodingKeys: CodingKey {
    case fontName
    case fontPointSize
    case glyphDescriptors
    case textureSize
    case textureData
    case spread
  }
  
  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    
    let fontName = try values.decode(String.self, forKey: .fontName)
    self.fontName = fontName
    
    let fontPointSize = try values.decode(CGFloat.self, forKey: .fontPointSize)
    self.fontPointSize = fontPointSize
    
    let spread = try values.decode(CGFloat.self, forKey: .spread)
    self.spread = spread
    
    self.parentFont = CTFontCreateWithName(fontName as CFString, fontPointSize, nil)
    
    let glyphDescriptors = try values.decode([Character: GlyphDescriptor].self, forKey: .glyphDescriptors)
    self.glyphDescriptors = glyphDescriptors
    
    let textureSize = try values.decode(Int.self, forKey: .textureSize)
    self.textureSize = textureSize
    
    let textureData = try values.decode(Data.self, forKey: .textureData)
    self.textureData = textureData
    
    self.texture = buildFontAtlasTexture(
      size: textureSize, data: textureData.withUnsafeBytes{$0}.baseAddress!
    )
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.fontName, forKey: .fontName)
    try container.encode(self.fontPointSize, forKey: .fontPointSize)
    try container.encode(self.spread, forKey: .spread)
    try container.encode(self.textureSize, forKey: .textureSize)
    try container.encode(self.glyphDescriptors, forKey: .glyphDescriptors)
    try container.encode(self.textureData, forKey: .textureData)
  }
  
  var fontName: String!
  var fontPointSize: CGFloat
  var parentFont: CTFont
  
  var glyphDescriptors = [Character: GlyphDescriptor]()
  
  var textureSize: Int
  var textureData: Data!
  var texture: MTLTexture!
  
  var spread: CGFloat
  
  init(fontName: String, textureSize: Int) {
    let fontSize: CGFloat = 32
    self.parentFont = CTFontCreateWithName(
      fontName as CFString,
      fontSize,
      nil
    )
    self.fontName = fontName
    self.fontPointSize = fontSize
    self.textureSize = textureSize
    self.spread = 0
    
    self.spread = estimatedLineWidthForFont(font: self.parentFont) * 0.5
    self.createTextureData()
  }
  
  func estimatedGlyphSizeForFont(font: CTFont) -> CGSize {
    let exampleString = NSString(string: "{ǺOJMQYZa@jmqyw")
    let exampleStringSize: CGSize = exampleString.size(withAttributes: [NSAttributedString.Key.font : font])
    let averageGlyphWidth: CGFloat = CGFloat(ceilf(Float(exampleStringSize.width) / Float(exampleString.length)))
    let maxGlyphHeight: CGFloat = CGFloat(ceilf(Float(exampleStringSize.height)))
    
    return CGSizeMake(averageGlyphWidth, maxGlyphHeight)
  }
  
  func estimatedLineWidthForFont(font: CTFont) -> CGFloat {
    let estimatedStrokeWidth = NSString(string: "!").size(withAttributes: [NSAttributedString.Key.font: font]).width
    return CGFloat(ceilf(Float(estimatedStrokeWidth)))
  }
  
  func font(_ font: CTFont, atSize size: CGFloat, isLikelyToFitInAtlasRect rect: CGRect) -> Bool {
    let textureArea = rect.size.width * rect.size.height
//    let trialFont = CTFontCreateWithName(self.fontName as CFString, size, nil)
    let trialCTFont = CTFontCreateWithName(self.fontName as CFString, size, nil)
    let fontGlyphCount = CTFontGetGlyphCount(trialCTFont)
    let glyphMargin = self.estimatedLineWidthForFont(font: trialCTFont)
    let averageGlyphSize = self.estimatedGlyphSizeForFont(font: trialCTFont)
    let estimatedGlyphTotalArea = (averageGlyphSize.width + CGFloat(glyphMargin)) * (averageGlyphSize.height + CGFloat(glyphMargin)) * CGFloat(Int(fontGlyphCount))
    
    let fits = estimatedGlyphTotalArea < textureArea
    return fits
  }
  
  func pointSizeThatFitsForFont(_ font: CTFont, inAtlasRect rect: CGRect) -> CGFloat {
    var fittedSize = CTFontGetSize(font)
    
    while (self.font(font, atSize: fittedSize, isLikelyToFitInAtlasRect: rect)) {
      fittedSize += 1
    }
    
    while (!self.font(font, atSize: fittedSize, isLikelyToFitInAtlasRect: rect)) {
      fittedSize -= 1
    }
    
    return fittedSize
  }
  
  func createAtlasForFont(font: CTFont, width: Int, height: Int) -> [UInt8] {
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
    context.setShouldSmoothFonts(false)
    
    // Flip context coordinate space so y increases downward
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    
    // Fill the context with an opaque black color
    context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
    context.fill([CGRect(x: 0, y: 0, width: width, height: height)])
    
    self.fontPointSize = self.pointSizeThatFitsForFont(font, inAtlasRect: CGRect(x: 0, y: 0, width: width, height: height))
    let ctFont = CTFontCreateWithName(self.fontName as CFString, self.fontPointSize, nil)
    self.parentFont = ctFont
    
//    let fontGlyphCount = CTFontGetGlyphCount(ctFont)
    
    let glyphMargin = self.estimatedLineWidthForFont(font: self.parentFont)
    
    // Set fill color so that glyphs are solid white
    context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
    
    glyphDescriptors.removeAll()
    
    let fontAscent: CGFloat = CTFontGetAscent(ctFont)
    let fontDescent: CGFloat = CTFontGetDescent(ctFont)
    
    var origin = CGPoint(x: 0, y: fontAscent)
    var maxYCoordForLine: CGFloat = -1
    
    let fontCharacterSet = CTFontCopyCharacterSet(font) as CharacterSet
    let charaters = fontCharacterSet.characters()
    
    let attributes = [NSAttributedString.Key.font : ctFont]
    
    for char in charaters {
      let attrString = NSAttributedString(string: String(char), attributes: attributes)
      let line = CTLineCreateWithAttributedString(attrString)
      let runs = CTLineGetGlyphRuns(line) as! [CTRun]
      let run = runs[0]
      var glyphs = Array(repeating: CGGlyph(), count: 1)
      CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
      var glyph = glyphs[0]
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
      glyphDescriptors[char] = descriptor
      
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
    let distanceMapBuffer = distanceMap.withUnsafeMutableBufferPointer{$0}
    var boundaryPointMap = [intpoint_t](repeating: intpoint_t(x: 0, y: 0), count: width * height) // nearest boundary point map
    let boundaryPointMapBuffer = boundaryPointMap.withUnsafeMutableBufferPointer{$0}
    let imageDataBuffer = imageData.withUnsafeMutableBufferPointer{$0}
    
    func image(_ x: Int, _ y: Int) -> Bool {
      return imageDataBuffer[y * width + x] > 0x7f
    }
    func getDistance(_ x: Int, _ y: Int) -> Float {
      return distanceMapBuffer[y * width + x]
    }
    func setDistance(_ x: Int, _ y: Int, _ value: Float) {
      distanceMapBuffer[y * width + x] = value
    }
    func getNearestpt(_ x: Int, _ y: Int) -> intpoint_t {
      return boundaryPointMapBuffer[y * width + x]
    }
    func setNearestpt(_ x: Int, _ y: Int, _ value: intpoint_t) {
      boundaryPointMapBuffer[y * width + x] = value
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
        if (distanceMapBuffer[(y - 1) * width + (x - 1)] + distDiag < getDistance(x, y)) {
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
    let outDataBuffer = outData.withUnsafeMutableBufferPointer{$0}
    let inDataBuffer = inData.withUnsafeMutableBufferPointer{$0}
    
    for y in stride(from: 0, to: height, by: scaleFactor) {
      for x in stride(from: 0, to: width, by: scaleFactor) {
        var accum: Float = 0
        for ky in 0..<scaleFactor {
          for kx in 0..<scaleFactor {
            accum += inDataBuffer[(y + ky) * width + (x + kx)]
          }
        }
        accum = accum / Float((scaleFactor * scaleFactor))
        
        outDataBuffer[(y / scaleFactor) * scaledWidth + (x / scaleFactor)] = accum
      }
    }
    
    return outData
  }
  
  func createQuantizedDistanceField(inData: inout [Float], width: Int, height: Int, normalizationFactor: Float) -> [UInt8] {
    var outData = [UInt8](repeating: 0, count: width * height)
    let outDataBuffer = outData.withUnsafeMutableBufferPointer{$0}
    let inDataBuffer = inData.withUnsafeMutableBufferPointer{$0}
    
    for y in 0..<height {
      for x in 0..<width {
        let dist = inDataBuffer[y * width + x]
        let clampDist = fmaxf(-normalizationFactor, fminf(dist, normalizationFactor))
        let scaledDist = clampDist / normalizationFactor
        let value: UInt8 = UInt8(((scaledDist + 1) / 2) * Float(UInt8.max))
        outDataBuffer[y * width + x] = value
      }
    }
    
    return outData
  }
  
  func createTextureData() {
    // Generate an atlas image for the font, resizing if necessary to fit in the specified size.
    var atlasData: [UInt8] = createAtlasForFont(font: self.parentFont, width: FontAtlasSize, height: FontAtlasSize)
    // Create the signed-distance field representation of the font atlas from the rasterized glyph image.
    var distanceField: [Float] = createSignedDistanceFieldForGrayscaleImage(imageData: &atlasData, width: FontAtlasSize, height: FontAtlasSize)
    
    let scaleFactor = FontAtlasSize / self.textureSize
//     Downsample the signed-distance field to the expected texture resolution
    var scaledField: [Float] = createResampledData(inData: &distanceField, width: FontAtlasSize, height: FontAtlasSize, scaleFactor: scaleFactor)
    
    let spread: CGFloat = estimatedLineWidthForFont(font: self.parentFont) * 0.5
    var texture: [UInt8] = createQuantizedDistanceField(inData: &scaledField, width: self.textureSize, height: self.textureSize, normalizationFactor: Float(spread))
    
    // Break here to view the generated font atlas bitmap
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
    
    self.textureData = Data(texture)
    // build metal texture
    self.texture = buildFontAtlasTexture(
      size: self.textureSize,
      data: texture.withUnsafeBytes{$0}.baseAddress!
    )
  }
}

private func buildFontAtlasTexture(size: Int, data: UnsafeRawPointer) -> MTLTexture {
  let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: size, height: size, mipmapped: false)
  let region = MTLRegionMake2D(0, 0, size, size)
  let texture = Renderer.device.makeTexture(descriptor: textureDescriptor)!
  texture.label = "Font Atlas"
  texture.replace(
    region: region,
    mipmapLevel: 0,
    withBytes: data,
    bytesPerRow: size
  )
  
  return texture
}
