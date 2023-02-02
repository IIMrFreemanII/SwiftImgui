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
  var clipId: UInt32
}

struct ImageBatch {
  var batchIndex: Int
  var textureSlot: Int
}

var images = [[Image]]()
var textures = [[MTLTexture]]()
var textureToBatchMap = [UInt64:ImageBatch]()
var currentTextureSlot = 0
var currentBatchIndex = 0
var maxTextureSlotsPerBatch = 30

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
        clipId: UInt32(clipRectsCount)
      )
    )
}

func drawImageData(at encoder: MTLRenderCommandEncoder) {
  for i in images.indices {
    Renderer.drawImagesInstanced(at: encoder, uniforms: &vertexData, images: &images[i], textures: &textures[i])
  }
}