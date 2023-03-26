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
  var argsIndex = UInt32()
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

class Font {
  var fontName: String!
  var font: CTFont
  
  var charToSDFGlyphMetricsMap = [UInt32: SDFGlyphMetrics]()
  var sdfGlyphTextures = [MTLTexture]()
  var glyphSDFBuffer: MTLBuffer!
  var glyphSDFCount = 32
  private var encoder: MTLArgumentEncoder!
  private var descriptor: MTLRenderPassDescriptor!
  
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
    
    guard let fragment = Renderer.library.makeFunction(name: "fragment_text") else {
      fatalError("Fragment function does not exist")
    }
    self.encoder = fragment.makeArgumentEncoder(bufferIndex: 9)
    glyphSDFBuffer = Renderer.device.makeBuffer(length: self.encoder.encodedLength * self.glyphSDFCount)
    glyphSDFBuffer.label = "SDF Glyph Args"
  }
  
  func getGlyphMetrics(_ value: UInt32) -> SDFGlyphMetrics {
    if let data = self.charToSDFGlyphMetricsMap[value] {
      return data
    }
    
    self.generateGlyphSDF(from: value)
    return self.charToSDFGlyphMetricsMap[value].unsafelyUnwrapped
  }
  
  public func generateGlyphSDF(from charCode: UInt32) {
    let entire = CFRangeMake(0, 0)
    let rect = CGRect(
      origin: CGPoint(),
      size:  CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    )
    
    let attributes = [NSAttributedString.Key.font : font]
    
    var pathElements = [PathElement]()
    var subPaths = [SubPath]()
    
    var subPathStart: UInt32 = 0
    var subPathEnd: UInt32 = 0
    
    let char = String(values: [charCode])
    
    let attrString = NSAttributedString(string: char, attributes: attributes)
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
      self.charToSDFGlyphMetricsMap[charCode] = SDFGlyphMetrics(
        size: glyphMetrics.size,
        bearing: glyphMetrics.bearing,
        advance: glyphMetrics.advance,
        argsIndex: UInt32(self.sdfGlyphTextures.count)
      )
      let sdfGlyphTexture = Renderer.makeTexture(size: CGSize(width: CGFloat(2), height: CGFloat(2)), pixelFormat: .r32Float, label: "SDF Glyph '\(char)'")!
      self.sdfGlyphTextures.append(sdfGlyphTexture)
      return
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
    
    let pathElementBuffer = Renderer.device.makeBuffer(bytes: &pathElements, length: MemoryLayout<PathElement>.stride * pathElements.count)!
    pathElementBuffer.label = "PathElementBuffer"
    let subPathBuffer = Renderer.device.makeBuffer(bytes: &subPaths, length: MemoryLayout<SubPath>.stride * subPaths.count)!
    subPathBuffer.label = "SubPathBuffer"
    
    //------------------------------------
    
    let fontSize = Float(64)
//    let padding = Float(1)
    let crispness = Float(0.03)
    let scalar = Float(15);
    let scale = Float((1 + crispness))
    
    var glyphs = [Glyph]()
    
    var scaledSize = float2(glyphMetrics.size.x * fontSize, glyphMetrics.size.y * fontSize)
    let newSize = float2(scaledSize.x * scale, scaledSize.y * scale)
    let deltaSize = float2(newSize.x - scaledSize.x, newSize.y - scaledSize.y)
    scaledSize.x += deltaSize.x * scalar
    scaledSize.y += deltaSize.y * scalar
    
    let glyphBounds = Rect(size: scaledSize)
    
    let newGlyphBounds = glyphBounds
    let halfOfDelta = float2(deltaSize.x * 0.5 * scalar, deltaSize.y * 0.5 * scalar)
    
    var topLeftUv = float2(newGlyphBounds.minX + halfOfDelta.x, newGlyphBounds.minY + halfOfDelta.y) / scaledSize
    var bottomRightUv = float2(newGlyphBounds.maxX - halfOfDelta.x, newGlyphBounds.maxY - halfOfDelta.y) / scaledSize
    self.charToSDFGlyphMetricsMap[charCode] = SDFGlyphMetrics(
      size: glyphMetrics.size,
      bearing: glyphMetrics.bearing,
      advance: glyphMetrics.advance,
      topLeftUv: topLeftUv,
      bottomRightUv: bottomRightUv,
      argsIndex: UInt32(self.sdfGlyphTextures.count)
    )
    
    let glyphImageBounds = glyphMetrics.glyphImageBounds
    let newImageSize = float2(x: glyphImageBounds.width * scale, y: glyphImageBounds.height * scale)
    let deltaImageSize = float2(x: (newImageSize.width - glyphImageBounds.width) * 0.5 * scalar, y: (newImageSize.height - glyphImageBounds.height) * 0.5 * scalar)
    
    let topLeft = float2(glyphImageBounds.minX - deltaImageSize.width, glyphImageBounds.maxY + deltaImageSize.height)
    let bottomRight = float2(glyphImageBounds.maxX + deltaImageSize.width, glyphImageBounds.minY - deltaImageSize.height)
    
    glyphs.append(Glyph(
      position: float3(glyphBounds.minX, glyphBounds.minY, 0),
      size: float2(glyphBounds.width, glyphBounds.height),
      topLeftUv: topLeft,
      bottomRightUv: bottomRight,
      crispness: crispness,
      start: glyphMetrics.subPathsRange.lowerBound,
      end: glyphMetrics.subPathsRange.upperBound
    ))
    
    //------------- rendering ------------------------
    
    let width = Int(glyphBounds.width)
    let height = Int(glyphBounds.height)
    
    let sdfGlyphTexture = Renderer.makeTexture(
      size: CGSize(width: CGFloat(width), height: CGFloat(height)),
      pixelFormat: .r32Float,
      label: "'\(String(describing: self.fontName))': '\(char)'"
    )!
    
    if self.glyphSDFCount <= self.sdfGlyphTextures.count {
      self.glyphSDFCount += 32
      let buffer = Renderer.device.makeBuffer(length: self.encoder.encodedLength * self.glyphSDFCount)!
      buffer.label = "SDF Glyph Args"
      buffer.contents().copyMemory(from: self.glyphSDFBuffer.contents(), byteCount: (self.sdfGlyphTextures.count - 1) * self.encoder.encodedLength)
      self.glyphSDFBuffer = buffer
    }
    
    self.encoder.setArgumentBuffer(self.glyphSDFBuffer, startOffset: 0, arrayElement: self.sdfGlyphTextures.count)
    self.encoder.constantData(at: 0).copyMemory(from: &topLeftUv, byteCount: MemoryLayout<float2>.stride)
    self.encoder.constantData(at: 1).copyMemory(from: &bottomRightUv, byteCount: MemoryLayout<float2>.stride)
    self.encoder.setTexture(sdfGlyphTexture, index: 2)
    
    self.sdfGlyphTextures.append(sdfGlyphTexture)
    
    descriptor.colorAttachments[0].texture = sdfGlyphTexture
    
    let commandBuffer = Renderer.commandQueue.makeCommandBuffer()!
    commandBuffer.label = "SDF Texture Command Buffer"
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
    renderEncoder.label = "SDF Texture Render Encoder"
    
    var vertexData = RectVertexData(
      viewMatrix: float4x4.identity,
      projectionMatrix: float4x4(left: 0, right: Float(width), bottom: Float(height), top: 0, near: -1, far: 1),
      time: 0
    )
    
    Renderer.drawSDFVectorTextInstanced(
      at: renderEncoder,
      uniforms: &vertexData,
      glyphs: &glyphs,
      pathElemBuffer: pathElementBuffer,
      subPathBuffer: subPathBuffer
    )
    
    renderEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
}
