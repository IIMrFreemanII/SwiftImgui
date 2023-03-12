//
//  Image.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

import MetalKit

struct Image {
  var rect: Rect
  var depth: Float
  var textureSlot: Int32
  var clipRectIndex: UInt16
}

struct ImageBatch {
  var batchIndex: Int
  var textureSlot: Int
}

var images = [[Image]]()
var textures = [[MTLTexture]]()
// MARK: Figure out how to handle it using plain array, because dictionary is much slower
var textureToBatchMap = [UInt64:ImageBatch]()
var currentTextureSlot = 0
var currentBatchIndex = 0
var maxTextureSlotsPerBatch = 31

func startImageFrame() {
  images.removeAll(keepingCapacity: true)
  images.append([Image]())
  
  textures.removeAll(keepingCapacity: true)
  textures.append([MTLTexture]())
  
  textureToBatchMap.removeAll(keepingCapacity: true)
  
  currentTextureSlot = 0
  currentBatchIndex = 0
}

func endImageFrame() {
  
}

func image(_ rect: Rect, texture: MTLTexture) {
  // MARK: Dont access texture.gpuResourceID._impl because it is reference type (cache miss, slower)
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
  
  images[imageBatch!.batchIndex]
    .append(
      Image(
        rect: rect,
        depth: getDepth(),
        textureSlot: Int32(imageBatch!.textureSlot),
        clipRectIndex: getClipRectIndex()
      )
    )
}

func drawImageData(at encoder: MTLRenderCommandEncoder) {
  for i in images.indices {
    Renderer.drawImagesInstanced(at: encoder, uniforms: &vertexData, images: &images[i], textures: &textures[i])
  }
}
