//
//  ComputeView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 24.03.2024.
//

import MetalKit

func fromPixelCoordToGridIndex(_ pixelCoord: SIMD2<Float>, _ textureSize: SIMD2<Float>, _ gridSize: SIMD2<Float>) -> SIMD2<Int> {
  let x = Int(floor(remap(pixelCoord.x, float2(0, textureSize.x), float2(0, gridSize.x))))
  let y = Int(floor(remap(pixelCoord.y, float2(0, textureSize.y), float2(0, gridSize.y))))
  
  return [x, y]
}

func from2DTo1DArray(_ index: SIMD2<Int>, _ size: SIMD2<Int>) -> Int {
  return index.y * size.x + index.x
}

func from1DTo2DArray(_ index: Int, _ size: SIMD2<Int>) -> SIMD2<Int> {
  let y = index / size.x
  let x = index - y * size.x
  
  return [x, y]
}

struct BoundingBox {
  var center: float2 = float2()
  var left: Float = -1
  var right: Float = 1
  var top: Float = 1
  var bottom: Float = -1
  
  init(center: float2, radius: Float) {
    self.center = center
    self.left = -radius
    self.right = radius
    self.top = radius
    self.bottom = -radius
  }
  
  var width: Float {
    return abs(left) + abs(right)
  }
  var height: Float {
    return abs(top) + abs(bottom)
  }
  var topLeft: float2 {
    return center + float2(left, top)
  }
  var bottomRight: float2 {
    return center + float2(right, bottom)
  }
}

struct ComputeCircle {
  var color = float4(1, 1, 1, 1)
  var position = float2(0, 0)
  var radius = Float(1)
  
  var boundingBox: BoundingBox {
    return BoundingBox(center: position, radius: radius)
  }
}

struct ComputeData {
  var projMat = float4x4()
  var sceneGridSize = SIMD2<Int32>()
  var windowSize = SIMD2<Float>()
  var deltaTime = Float()
  var time = Float()
};

struct GridElem: CustomDebugStringConvertible {
  var debugDescription: String {
    return String(self.itemIndex)
  }
  
  // -1 means empty (no items inside grid elem)
  var itemIndex: Int32 = -1
}

struct ComputeRenderer {
  static var data = ComputeData()
  static var drawCirlcesPSO: MTLComputePipelineState!
  static var clearColorPSO: MTLComputePipelineState!
  static var circleBuffer: MTLBuffer!
  static var circles: [ComputeCircle] = []
  static var sceneGridSize: SIMD2<Int> = [20, 20]
  static var gridElemSize: Float = 1
  static var scene1DGrid: [GridElem] = Array(repeating: GridElem(), count: Self.sceneGridSize.x * Self.sceneGridSize.y)
  static var scene1DGridBuffer: MTLBuffer!
  
  static func makeComputePSO(from funcName: String) -> MTLComputePipelineState? {
    guard let kernelFunction =
            Renderer.library.makeFunction(name: funcName) else {
      fatalError("Failed to create kernel function: \(funcName)")
    }
    let pipeline = try? Renderer.device.makeComputePipelineState(
      function: kernelFunction
    )
    return pipeline
  }
  
  private static func printGrid() {
    for i in 0..<Self.sceneGridSize.y {
      let arr = Self.scene1DGrid[(i * Self.sceneGridSize.x)..<(i * Self.sceneGridSize.x + Self.sceneGridSize.y)]
      print(arr.map { $0.itemIndex == -1 ? GridElem(itemIndex: 0) : $0})
    }
  }
  
  private static func mapBoundingBoxToGrid(_ box: BoundingBox, _ itemIndex: Int) {
    let width = Int(ceil(box.width))
    let height = Int(ceil(box.height))
    
    for y in 0..<height {
      let yIndex = Int(box.center.y) + y - Int(box.height) / 2 + Self.sceneGridSize.y / 2
      for x in 0..<width {
        let xIndex = Int(box.center.x) + x - Int(box.width) / 2 + Self.sceneGridSize.x / 2
        
        let index = from2DTo1DArray(SIMD2<Int>(xIndex, yIndex), Self.sceneGridSize)
        self.scene1DGrid[index].itemIndex = Int32(itemIndex)
      }
    }
  }
  
  static func initCompute() {
    //    Self.drawCirlcesPSO = Self.makeComputePSO(from: "drawCircles")
    Self.clearColorPSO = Self.makeComputePSO(from: "clearScreen")
    
    Self.circles = Array(repeating: ComputeCircle(), count: 1)
    
    let posValue = Float(0)
    let positionRange = -posValue...posValue
    let colorRange = Float(0)...Float(1)
    for i in 0..<Self.circles.count {
      let color = float4(Float.random(in: colorRange), Float.random(in: colorRange), Float.random(in: colorRange), Float.random(in: colorRange))
      let position = float2(Float.random(in: positionRange), Float.random(in: positionRange))
      let circle = ComputeCircle(color: color, position: position, radius: 1)
      Self.circles[i] = circle
      
      Self.mapBoundingBoxToGrid(circle.boundingBox, i)
    }
    
    //    Self.printGrid()
    
    Self.scene1DGridBuffer = Renderer.device.makeBuffer(length: MemoryLayout<GridElem>.stride * Self.scene1DGrid.count)
    Self.scene1DGridBuffer.contents().copyMemory(from: &Self.scene1DGrid, byteCount: MemoryLayout<GridElem>.stride * Self.scene1DGrid.count)
    
    Self.circleBuffer = Renderer.device.makeBuffer(length: MemoryLayout<ComputeCircle>.stride * Self.circles.count)
    Self.circleBuffer.contents().copyMemory(from: &Self.circles, byteCount: MemoryLayout<ComputeCircle>.stride * Self.circles.count)
  }
  
  static func clearColor(at encoder: MTLComputeCommandEncoder, texture: MTLTexture) {
    encoder.setComputePipelineState(Self.clearColorPSO)
    
//    let projMat = float4x4(translation: float3(Float(texture.width) * 0.5, Float(texture.height) * 0.5, 0))
    
    encoder.setBytes(&Self.data, length: MemoryLayout<ComputeData>.stride, index: 0)
    encoder.setBuffer(Self.circleBuffer, offset: 0, index: 1)
    encoder.setBuffer(Self.scene1DGridBuffer, offset: 0, index: 2)
    
    encoder.setTexture(texture, index: 0)
    
    let threadsPerGrid = MTLSize(
      width: Int(texture.width),
      height: Int(texture.height),
      depth: 1
    )
    let width = Self.clearColorPSO.threadExecutionWidth
    let threadsPerThreadgroup = MTLSize(
      width: width,
      height: Self.clearColorPSO.maxTotalThreadsPerThreadgroup / width,
      depth: 1
    )
    encoder.dispatchThreads(
      threadsPerGrid,
      threadsPerThreadgroup: threadsPerThreadgroup
    )
  }
  
  //  static func computeDrawCircles(at encoder: MTLComputeCommandEncoder, texture: MTLTexture) {
  //    encoder.setComputePipelineState(Self.drawCirlcesPSO)
  //
  //    var projMat = float4x4(translation: float3(Float(texture.width) * 0.5, Float(texture.height) * 0.5, 0))
  //    encoder.setBytes(&projMat, length: MemoryLayout<float4x4>.stride, index: 0)
  //    encoder.setBuffer(Self.circleBuffer, offset: 0, index: 1)
  //
  //    encoder.setTexture(texture, index: 0)
  //
  //    let threadsPerGroup = MTLSize(
  //      width: Self.drawCirlcesPSO.threadExecutionWidth,
  //      height: 1,
  //      depth: 1
  //    )
  //    let threadsPerGrid = MTLSize(width: Self.circles.count, height: 1, depth: 1)
  //    encoder.dispatchThreads(
  //      threadsPerGrid,
  //      threadsPerThreadgroup: threadsPerGroup
  //    )
  //  }
}

class ComputeView : ViewRenderer {
  override func start() {
    print("start compute")
    ComputeRenderer.initCompute()
    self.metalView.framebufferOnly = false
    
    //    print("remap: \(fromPixelCoordToGridIndex(float2(0, 100), float2(1000, 1000), float2(10, 10)))")
//    print("from2DTo1DArray: index[1, 1] , size[10, 10] -> \(from2DTo1DArray([1, 1] ,[10, 10]))")
//    print("from1DTo2DArray: index[11] , size[10, 10] -> \(from1DTo2DArray(11 ,[10, 10]))")
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    let width = Float(view.frame.width)
    let height = Float(view.frame.height)
    
    let projectionMatrix = float4x4(left: -width * 0.5, right: width * 0.5, bottom: -height * 0.5, top: height * 0.5, near: 10, far: 0)
    ComputeRenderer.data.projMat = projectionMatrix
    ComputeRenderer.data.sceneGridSize = SIMD2<Int32>(Int32(ComputeRenderer.sceneGridSize.x), Int32(ComputeRenderer.sceneGridSize.y))
    ComputeRenderer.data.deltaTime = Time.deltaTime
    ComputeRenderer.data.time = Time.time
    
//    print(projectionMatrix.formated)
//    print("\(float4(0, 0, 0, 1)) -> \(projectionMatrix * float4(0, 0, 0, 1))")
//    print("\(float4(1, 1, 0, 1)) -> \(projectionMatrix * float4(1, 1, 0, 1))")
//    print("\(float4(-1, -1, 0, 1)) -> \(projectionMatrix * float4(-1, -1, 0, 1))")
    
//    print(Time.deltaTime)
    //    benchmark(title: "Compute") {
    guard let commandBuffer =
            Renderer.commandQueue.makeCommandBuffer(),
          let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
          let drawable = view.currentDrawable
    else {
      print("failed to run compute")
      return
    }
    
    ComputeRenderer.clearColor(at: computeEncoder, texture: drawable.texture)
    //      ComputeRenderer.computeDrawCircles(at: computeEncoder, texture: drawable.texture)
    
    computeEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    //    }
  }
}
