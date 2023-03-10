//
//  FontAtlas.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 02.01.2023.
//

import Foundation
import MetalKit
import CoreText

struct GlyphMetrics {
  // with origin in bottom left, and going from left to right and bottom to top
  var glyphImageBounds = Rect()
  var size = float2()
  var bearing = float2()
  var advance: Float = 0 // Offset to advance to next glyph
  var subPathsRange: Range<UInt32> = 0..<0
}

struct SDFGlyphMetrics {
  var size = float2()
  var bearing = float2()
  var advance: Float = 0 // Offset to advance to next glyph
  var topLeftUv = float2()
  var bottomRightUv = float2()
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

class Font {
//  enum CodingKeys: CodingKey {
//    case fontName
//    case pathElements
//    case subPaths
//    case charToSubPathsRangeMap
//  }
  
//  required init(from decoder: Decoder) throws {
//    let values = try decoder.container(keyedBy: CodingKeys.self)
//
//    let fontName = try values.decode(String.self, forKey: .fontName)
//    self.fontName = fontName
//    self.font = CTFontCreateWithName(fontName as CFString, 1, nil)
//
//    var pathElements = try values.decode([PathElement].self, forKey: .pathElements)
//    self.pathElements = pathElements
//    self.pathElementBuffer = Renderer.device.makeBuffer(bytes: &pathElements, length: MemoryLayout<PathElement>.stride * pathElements.count)
//
//    var subPaths = try values.decode([SubPath].self, forKey: .subPaths)
//    self.subPaths = subPaths
//    self.subPathBuffer = Renderer.device.makeBuffer(bytes: &subPaths, length: MemoryLayout<SubPath>.stride * subPaths.count)
//
//    let charToSubPathsRangeMap = try values.decode([Character: GlyphMetrics].self, forKey: .charToSubPathsRangeMap)
//    self.charToGlyphMetricsMap = charToSubPathsRangeMap
//  }
  
//  func encode(to encoder: Encoder) throws {
//    var container = encoder.container(keyedBy: CodingKeys.self)
//    try container.encode(self.fontName, forKey: .fontName)
//    try container.encode(self.pathElements, forKey: .fontName)
//    try container.encode(self.subPaths, forKey: .fontName)
//    try container.encode(self.charToGlyphMetricsMap, forKey: .charToSubPathsRangeMap)
//  }
  
  var fontName: String!
  var font: CTFont
  private var pathElements = [PathElement]();
  private var pathElementBuffer: MTLBuffer!
  private var subPaths = [SubPath]();
  private var subPathBuffer: MTLBuffer!
  private var charToGlyphMetricsMap = [UInt32: GlyphMetrics]();
  var charToSDFGlyphMetricsMap = [UInt32: SDFGlyphMetrics]();
  
  init(fontName: String) {
    self.font = CTFontCreateWithName(
      fontName as CFString,
      1,
      nil
    )
    self.fontName = fontName
    
    let descriptor = MTLRenderPassDescriptor()
    descriptor.colorAttachments[0].loadAction = .clear
    descriptor.colorAttachments[0].storeAction = .store
    self.descriptor = descriptor

    generateVectorPaths()
    generateSDFTexture()
  }
  
  private func generateVectorPaths() {
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
    var charToGlyphMetricsMap = [UInt32: GlyphMetrics]();
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
      glyphMetrics.size = float2(Float(glyphRect.size.width), Float(glyphRect.size.height))
      
      // offset to align to the baseline
      let temp = glyphRect.offsetBy(dx: lineOrigin.x, dy: lineOrigin.y)
      let bearingX = Float(temp.origin.x - lineOrigin.x)
      let bearingY = Float(temp.size.height - (lineOrigin.y - temp.origin.y))
      glyphMetrics.bearing = float2(bearingX, bearingY)
      glyphMetrics.glyphImageBounds = Rect(
        position: float2(Float(glyphRect.origin.x), Float(glyphRect.origin.y)),
        size: float2(Float(glyphRect.size.width), Float(glyphRect.height))
      )
      glyphMetrics.advance = Float(advance.width)
      
      guard let path: CGPath = CTFontCreatePathForGlyph(font, glyph, nil) else {
//        print("Path is not found for glyph: '\(char)' in font: '\(fontName ?? "")'!");
        charToGlyphMetricsMap[char.unicodeScalars.first!.value] = glyphMetrics
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
          
        case .addCurveToPoint:
          fatalError("\(type.rawValue) is not supported for performance reason!")
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
      charToGlyphMetricsMap[char.unicodeScalars.first!.value] = glyphMetrics
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
  
  private func buildGlyphsFrom(
    maxSize: float2,
    glyphs: inout [Glyph]
  ) -> Rect {
    let fontSize = Float(32)
    let padding = Float(1)
    let crispness = Float(0.05)
    let scalar = Float(15);
    let scale = Float((1 + crispness))
    
    var newGlyphs = [Glyph]()
    newGlyphs.reserveCapacity(self.charToGlyphMetricsMap.count)

    var charToSDFGlyphMetrics = [UInt32: SDFGlyphMetrics]()
    charToSDFGlyphMetrics.reserveCapacity(self.charToGlyphMetricsMap.count)
    
    let sortedCharToGlyphMetrics = self.charToGlyphMetricsMap.sorted { first, second in
      let metrics0 = first.value
      let metrics1 = second.value
      return (metrics0.size.y > metrics1.size.y)
    }
    
    var maxXOffset: Float = 0
    var maxYOffset: Float = 0 + padding
    
    var xOffset: Float = 0
    
    var maxCharHeightOnLine: Float = 0
    for (char, metrics) in sortedCharToGlyphMetrics {
      if maxYOffset > maxSize.y {
        fatalError("exceeded max height size")
      }
      
      var scaledSize = float2(metrics.size.x * fontSize, metrics.size.y * fontSize)
      let newSize = float2(scaledSize.x * scale, scaledSize.y * scale)
      let deltaSize = float2(newSize.x - scaledSize.x, newSize.y - scaledSize.y)
      scaledSize.x += deltaSize.x * scalar
      scaledSize.y += deltaSize.y * scalar
      if (scaledSize.y > maxCharHeightOnLine) {
        maxCharHeightOnLine = scaledSize.y
      }
      
      xOffset += padding
      if (xOffset + scaledSize.x + padding) > maxSize.x {
        xOffset = padding
        maxYOffset += maxCharHeightOnLine + padding
        maxCharHeightOnLine = 0
      }
      
      let glyphBounds = Rect(
        position: float2(xOffset, maxYOffset),
        size: scaledSize
      )
      
      let newGlyphBounds = glyphBounds
      let halfOfDelta = float2(deltaSize.x * 0.5 * scalar, deltaSize.y * 0.5 * scalar)
      
      charToSDFGlyphMetrics[char] = SDFGlyphMetrics(
        size: metrics.size,
        bearing: metrics.bearing,
        advance: metrics.advance,
        topLeftUv: float2(newGlyphBounds.minX + halfOfDelta.x, newGlyphBounds.minY + halfOfDelta.y),
        bottomRightUv: float2(newGlyphBounds.maxX - halfOfDelta.x, newGlyphBounds.maxY - halfOfDelta.y)
      )
      
      let glyphImageBounds = metrics.glyphImageBounds
      let newImageSize = float2(x: glyphImageBounds.width * scale, y: glyphImageBounds.height * scale)
      let deltaImageSize = float2(x: (newImageSize.width - glyphImageBounds.width) * 0.5 * scalar, y: (newImageSize.height - glyphImageBounds.height) * 0.5 * scalar)
      
      let topLeft = float2(Float(glyphImageBounds.minX - deltaImageSize.width), Float(glyphImageBounds.maxY + deltaImageSize.height))
      let bottomRight = float2(Float(glyphImageBounds.maxX + deltaImageSize.width), Float(glyphImageBounds.minY - deltaImageSize.height))
      
      newGlyphs.append(Glyph(
        position: float3(Float(glyphBounds.minX), Float(glyphBounds.minY), 0),
        size: float2(Float(glyphBounds.width), Float(glyphBounds.height)),
        topLeftUv: topLeft,
        bottomRightUv: bottomRight,
        crispness: crispness,
        start: metrics.subPathsRange.lowerBound,
        end: metrics.subPathsRange.upperBound
      ))
      xOffset += scaledSize.x + padding
      if xOffset > maxXOffset {
        maxXOffset = xOffset
      }
    }
    
    maxYOffset += maxCharHeightOnLine + padding
    
    let fittedRect = Rect(
      x: 0,
      y: 0,
      width: Float(Int(maxXOffset)),
      height: Float(Int(maxYOffset))
    )
    
    for kv in charToSDFGlyphMetrics {
      let char = kv.key
      var metrics = kv.value
      
      // map to uv coordinats 0...1
      let topLeft = float2(metrics.topLeftUv.x / Float(fittedRect.width), metrics.topLeftUv.y / Float(fittedRect.height))
      let bottomRight = float2(metrics.bottomRightUv.x / Float(fittedRect.width), metrics.bottomRightUv.y / Float(fittedRect.height))
      
      metrics.topLeftUv = topLeft
      metrics.bottomRightUv = bottomRight
      
      charToSDFGlyphMetrics[char] = metrics
    }
    
    self.charToSDFGlyphMetricsMap = charToSDFGlyphMetrics
    glyphs.append(contentsOf: newGlyphs)
    
    return fittedRect
  }

  var sdfTexture: MTLTexture!
  private var descriptor: MTLRenderPassDescriptor!
  private func generateSDFTexture() {
    var glyphs = [Glyph]()
    glyphs.reserveCapacity(self.charToGlyphMetricsMap.count)
    
    let fittedRect = buildGlyphsFrom(
      maxSize: float2(Float(FontAtlasSize), Float(FontAtlasSize)),
      glyphs: &glyphs
    )
    self.sdfTexture = Renderer.makeTexture(size: CGSize(width: CGFloat(fittedRect.width), height: CGFloat(fittedRect.height)), pixelFormat: .r32Float, label: "SDF Texture of '\(self.fontName!)'")!
    descriptor.colorAttachments[0].texture = sdfTexture
    
    let commandBuffer = Renderer.commandQueue.makeCommandBuffer()!
    commandBuffer.label = "SDF Texture Command Buffer"
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
    renderEncoder.label = "SDF Texture Render Encoder"
    
    var vertexData = RectVertexData(
      viewMatrix: float4x4.identity,
      projectionMatrix: float4x4(left: 0, right: Float(fittedRect.size.width), bottom: Float(fittedRect.size.height), top: 0, near: -1, far: 1),
      time: 0
    )
    Renderer.drawSDFVectorTextInstanced(at: renderEncoder, uniforms: &vertexData, glyphs: &glyphs, pathElemBuffer: self.pathElementBuffer, subPathBuffer: self.subPathBuffer)
    
    renderEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
}
