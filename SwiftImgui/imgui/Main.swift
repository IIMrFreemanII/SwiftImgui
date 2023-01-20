import MetalKit

struct Rect {
  var position: float3
  var size: float2
  var color: float4
}

struct Image {
  var position: float3
  var size: float2
  var textureSlot: Int32
}

struct RectVertexData {
  var viewMatrix: float4x4 = float4x4.identity
  var projectionMatrix: float4x4 = float4x4.identity
  var time: Float = 0;
}

private struct ImageBatch {
  var batchIndex: Int
  var textureSlot: Int
}
private var images = [[Image]]()
private var textures = [[MTLTexture]]()
private var textureToBatchMap = [UInt64:ImageBatch]()
private var currentTextureSlot = 0
private var currentBatchIndex = 0
private var maxTextureSlotsPerBatch = 31

private var glyphs = [SDFGlyph](repeating: SDFGlyph(), count: 100_000)
private var glyphsCount = 0
private var fontAtlas: Font!
private var fontSize: Int = 16

private var rects = [Rect]()
private var vertexData = RectVertexData()

func setProjectionMatrix(matrix: float4x4) {
  vertexData.projectionMatrix = matrix
}

func setViewMatrix(matrix: float4x4) {
  vertexData.viewMatrix = matrix
}

func setTime(value: Float) {
  vertexData.time = value
}

func setFont(_ value: Font) {
  fontAtlas = value
}

func setFontSize(_ value: Int) {
  fontSize = value
}

func text(
  position: float2,
  size: float2 = float2(),
  color: float4 = float4(0, 0, 0, 1),
  text: inout [UInt32]
) {
  _ = buildSDFGlyphsFromString(
    &text,
    inRect: CGRect(
      x: CGFloat(position.x),
      y: CGFloat(position.y),
      width: size.x != 0 ? CGFloat(size.x) : CGFloat.greatestFiniteMagnitude,
      height: size.y != 0 ? CGFloat(size.y) : CGFloat.greatestFiniteMagnitude
    ),
    color: color,
    withFont: fontAtlas,
    atSize: fontSize,
    glyphs: &glyphs,
    glyphsCount: &glyphsCount
  )
}

func image(position: float2, size: float2, texture: MTLTexture) {
  let address = texture.gpuResourceID._impl
  var imageBatch = textureToBatchMap[address]
  
  if imageBatch == nil {
    let batch = ImageBatch(batchIndex: currentBatchIndex, textureSlot: currentTextureSlot)
    textures[batch.batchIndex].append(texture)
    
    textureToBatchMap[address] = batch
    imageBatch = batch
    currentTextureSlot += 1
    
    if (currentTextureSlot > maxTextureSlotsPerBatch - 1) {
      currentTextureSlot = 0
      currentBatchIndex += 1
      
      images.append([Image]())
      textures.append([MTLTexture]())
    }
  }
  
  images[imageBatch!.batchIndex].append(Image(position: float3(position.x, position.y, 0), size: size, textureSlot: Int32(imageBatch!.textureSlot)))
}

func rect(position: float2, size: float2, color: float4 = float4(repeating: 1)) {
  rects.append(Rect(position: float3(position.x, position.y, 0), size: size, color: color))
}

func startFrame() {
  rects.removeAll(keepingCapacity: true)
  
  images.removeAll(keepingCapacity: true)
  images.append([Image]())
  
  textures.removeAll(keepingCapacity: true)
  textures.append([MTLTexture]())
  
  textureToBatchMap.removeAll(keepingCapacity: true)
  
//  glyphs.removeAll(keepingCapacity: true)
  glyphsCount = 0
  
  currentTextureSlot = 0
  currentBatchIndex = 0
}

func endFrame() {
  
}

func drawData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawRectsInstanced(at: encoder, uniforms: &vertexData, rects: &rects)
  
  for i in images.indices {
    Renderer.drawImagesInstanced(at: encoder, uniforms: &vertexData, images: &images[i], textures: &textures[i])
  }
  
//  Renderer.drawVectorTextInstanced(at: encoder, uniforms: &vertexData, glyphs: &glyphs, pathElemBuffer: fontAtlas.pathElementBuffer, subPathBuffer: fontAtlas.subPathBuffer)
  Renderer.drawTextInstanced(at: encoder, uniforms: &vertexData, glyphs: &glyphs, glyphsCount: glyphsCount, texture: fontAtlas.sdfTexture)
}
