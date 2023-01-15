//
//  FontAtlas.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 02.01.2023.
//

import Foundation
import MetalKit
import CoreText

struct GlyphMetrics: Codable {
  // with origin in bottom left, and going from left to right and bottom to top
  var glyphImageBounds = CGRect()
  var size = CGSize()
  var bearing = CGSize()
  var advance: CGFloat = 0 // Offset to advance to next glyph
  var subPathsRange: Range<UInt32> = 0..<0
}

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

struct SubPath: Codable {
  var start: UInt32 = 0;
  var end: UInt32 = 0;
}

// type
// 0 - moveToPoint, starts new path
// 1 - addLineToPoint, adds line from current point to a new point. Element holds 1 point for destination
// 2 - addQuadCurveToPoint, adds a quadratice curve from current point to the specified point.
//     Element holds control point (point0) and a destination point (point1).
// 3 - addCurveToPoint, adds a quadratic curve from current point to the specified point.
//     Element holds 2 control points (point0, point1) and a destination point (point3).
// 4 - closePath, path element that closes and completes a subpath. The element does not contain any points.
struct PathElement: Codable {
  var point0 = float2();
  var point1 = float2();
//  var point2 = float2();
  var type: UInt8 = 0;
}

// 1024 & 2048 & 4096
private let FontAtlasSize = 4096

func buildFontAtlas(fontName: String) -> FontAtlas {
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
  
  let fontAtlas = FontAtlas(fontName: fontName)
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

class FontAtlas: Codable {
  enum CodingKeys: CodingKey {
    case fontName
    case pathElements
    case subPaths
    case charToSubPathsRangeMap
  }
  
  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    
    let fontName = try values.decode(String.self, forKey: .fontName)
    self.fontName = fontName
    self.font = CTFontCreateWithName(fontName as CFString, 1, nil)
    
    var pathElements = try values.decode([PathElement].self, forKey: .pathElements)
    self.pathElements = pathElements
    self.pathElementBuffer = Renderer.device.makeBuffer(bytes: &pathElements, length: MemoryLayout<PathElement>.stride * pathElements.count)
    
    var subPaths = try values.decode([SubPath].self, forKey: .subPaths)
    self.subPaths = subPaths
    self.subPathBuffer = Renderer.device.makeBuffer(bytes: &subPaths, length: MemoryLayout<SubPath>.stride * subPaths.count)
    
    let charToSubPathsRangeMap = try values.decode([Character: GlyphMetrics].self, forKey: .charToSubPathsRangeMap)
    self.charToGlyphMetricsMap = charToSubPathsRangeMap
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.fontName, forKey: .fontName)
    try container.encode(self.pathElements, forKey: .fontName)
    try container.encode(self.subPaths, forKey: .fontName)
    try container.encode(self.charToGlyphMetricsMap, forKey: .charToSubPathsRangeMap)
  }
  
  var fontName: String!
  var font: CTFont
  var pathElements = [PathElement]();
  var pathElementBuffer: MTLBuffer!
  var subPaths = [SubPath]();
  var subPathBuffer: MTLBuffer!
  var charToGlyphMetricsMap = [Character: GlyphMetrics]();
  
  init(fontName: String) {
    self.font = CTFontCreateWithName(
      fontName as CFString,
      1,
      nil
    )
    self.fontName = fontName
    
    generateVectorPaths()
  }
  
  func generateVectorPaths() {
    let entire = CFRangeMake(0, 0)
    let rect = CGRect(
      origin: CGPoint(),
      size:  CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    )
    let fontCharacterSet = CTFontCopyCharacterSet(font) as CharacterSet
    let charaters = fontCharacterSet.characters()
    
    let attributes = [NSAttributedString.Key.font : font]

    var pathElements = [PathElement]()
    pathElements.reserveCapacity(charaters.count)
    var subPaths = [SubPath]()
    subPaths.reserveCapacity(charaters.count)
    var charToGlyphMetricsMap = [Character: GlyphMetrics]();
    charToGlyphMetricsMap.reserveCapacity(charaters.count)
    
    var subPathStart: UInt32 = 0
    var subPathEnd: UInt32 = 0
    for i in charaters.indices {
      let char = charaters[i];
      
      let attrString = NSAttributedString(string: String(char), attributes: attributes)
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
      let frame = CTFramesetterCreateFrame(framesetter, fittedRange, rectPath, nil)
      let lines = CTFrameGetLines(frame) as! [CTLine]
      var lineOriginBuffer = [CGPoint](repeating: CGPoint(), count: lines.count)
      CTFrameGetLineOrigins(frame, entire, &lineOriginBuffer)
      
      let line = lines[0]
      let lineOrigin = lineOriginBuffer[0]
      let runs = CTLineGetGlyphRuns(line) as! [CTRun]
      let run = runs[0]
      let glyphCount = CTRunGetGlyphCount(run)
      
      var advanceBuffer = [CGSize](repeating: CGSize(), count: glyphCount)
      CTRunGetAdvances(run, entire, &advanceBuffer)
      var glyphBuffer = [CGGlyph](repeating: CGGlyph(), count: glyphCount)
      CTRunGetGlyphs(run, entire, &glyphBuffer)
      
      let glyph = glyphBuffer[0]
      let advance = advanceBuffer[0]
      let glyphRect = CTRunGetImageBounds(run, nil, CFRangeMake(0, 1))
      
      var glyphMetrics = GlyphMetrics()
      glyphMetrics.size = glyphRect.size
      
      // offset to align to the baseline
      let temp = glyphRect.offsetBy(dx: lineOrigin.x, dy: lineOrigin.y)
      let bearingX = temp.origin.x - lineOrigin.x
      let bearingY = temp.size.height - (lineOrigin.y - temp.origin.y)
      glyphMetrics.bearing = CGSize(width: bearingX, height: bearingY)
      glyphMetrics.glyphImageBounds = glyphRect
      glyphMetrics.advance = advance.width
      
      guard let path: CGPath = CTFontCreatePathForGlyph(font, glyph, nil) else {
        print("Path is not found for glyph: '\(char)' in font: '\(fontName ?? "")!");
        charToGlyphMetricsMap[char] = glyphMetrics
        continue;
      };
      
      let start = pathElements.count
      var pathElemsStart = start
      subPathStart = subPathEnd
      
      path.applyWithBlock { pointer in
        let item = pointer.pointee
        let type = item.type
        
        var pathElem = PathElement()
        pathElem.type = UInt8(type.rawValue)
        
        switch type {
        case .moveToPoint:
          pathElemsStart = pathElements.count
          
          let point0 = item.points[0]
          pathElem.point0 = float2(Float(point0.x), Float(point0.y))
          
        case .addLineToPoint:
          let point0 = item.points[0]
          pathElem.point0 = float2(Float(point0.x), Float(point0.y))
          
        case .addQuadCurveToPoint:
          let point0 = item.points[0]
          let point1 = item.points[1]
          pathElem.point0 = float2(Float(point0.x), Float(point0.y))
          pathElem.point1 = float2(Float(point1.x), Float(point1.y))
          
//        case .addCurveToPoint:
//          let point0 = item.points[0]
//          let point1 = item.points[1]
//          let point2 = item.points[2]
//          pathElem.point0 = float2(Float(point0.x), Float(point0.y))
//          pathElem.point1 = float2(Float(point1.x), Float(point1.y))
//          pathElem.point2 = float2(Float(point2.x), Float(point2.y))
//          print("\(char) has cubic bezier")
          
        case .closeSubpath:
          subPathEnd += 1
          
          subPaths.append(SubPath(start: UInt32(pathElemsStart), end: UInt32(pathElements.count + 1)))
        @unknown default:
          fatalError("Unknown type: \(type.rawValue)!")
        }
        
        pathElements.append(pathElem)
      }
      
      glyphMetrics.subPathsRange = subPathStart..<subPathEnd
      charToGlyphMetricsMap[char] = glyphMetrics
    }
    
    self.pathElements = pathElements
    self.subPaths = subPaths
    self.charToGlyphMetricsMap = charToGlyphMetricsMap
    
    let commandBuffer = Renderer.commandQueue.makeCommandBuffer()!
    let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
    
    let pathElementBuffer = Renderer.device.makeBuffer(bytes: &self.pathElements, length: MemoryLayout<PathElement>.stride * self.pathElements.count)!
    let privatePathElementBuffer = Renderer.device.makeBuffer(length: pathElementBuffer.length, options: .storageModePrivate)!
    privatePathElementBuffer.label = "PathElementBuffer"
    blitCommandEncoder.copy(from: pathElementBuffer, sourceOffset: 0, to: privatePathElementBuffer, destinationOffset: 0, size: pathElementBuffer.length)
    
    let subPathBuffer = Renderer.device.makeBuffer(bytes: &self.subPaths, length: MemoryLayout<SubPath>.stride * self.subPaths.count)!
    let privateSubPathBuffer = Renderer.device.makeBuffer(length: subPathBuffer.length, options: .storageModePrivate)!
    privateSubPathBuffer.label = "SubPathBuffer"
    blitCommandEncoder.copy(from: subPathBuffer, sourceOffset: 0, to: privateSubPathBuffer, destinationOffset: 0, size: subPathBuffer.length)
    
    blitCommandEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    
    self.pathElementBuffer = privatePathElementBuffer
    self.subPathBuffer = privateSubPathBuffer
  }
}
