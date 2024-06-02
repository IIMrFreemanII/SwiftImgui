//
//  ComputeView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 24.03.2024.
//

import MetalKit

func from2DTo1DArray(_ index: SIMD2<Int>, _ size: SIMD2<Int>) -> Int {
  return index.y * size.x + index.x
}

func from1DTo2DArray(_ index: Int, _ size: SIMD2<Int>) -> SIMD2<Int> {
  let y = index / size.x
  let x = index - y * size.x
  
  return int2(x, y)
}

private struct ComputeCircle {
  var color = float4(1, 1, 1, 1)
  var position = float2(0, 0)
  var radius = Float(1)
  
  var boundingBox: BoundingBox {
    return BoundingBox(center: position, radius: radius)
  }
}

private struct ComputeData {
  var projMat = float4x4()
  var sceneGridSize = SIMD2<Int32>()
  var windowSize = SIMD2<Float>()
  var deltaTime = Float()
  var time = Float()
  var gridElemSize = Float()
  var gridBounds = BoundingBox()
};

struct GridElem: CustomDebugStringConvertible {
  var debugDescription: String {
    return String(self.itemIndex)
  }
  
  // -1 means empty (no items inside grid elem)
  var itemIndex: Int32 = -1
}

private struct ComputeRenderer {
  static var data = ComputeData()
  static var drawCirlcesPSO: MTLComputePipelineState!
  static var clearColorPSO: MTLComputePipelineState!
  static var circleBuffer: MTLBuffer!
  static var circles: [ComputeCircle] = []
  static var sceneGridSize: SIMD2<Int> = [20, 20]
  static var gridElemSize: Float = 1
  static var gridBounds = BoundingBox(center: float2(), size: float2(Float(Self.sceneGridSize.x), Float(Self.sceneGridSize.y)) * Self.gridElemSize)
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
      print(arr.map { $0.itemIndex == -1 ? "-1" : " \($0)"}.joined(separator: " "))
      //      print(arr)
    }
  }
  
  private static func mapBoundingBoxToGrid(_ box: BoundingBox, _ itemIndex: Int) {
    for y in stride(from: box.bottomRight.y, through: box.topLeft.y, by: box.height / 2) {
      let yIndex = floor(remap(y, float2(Self.gridBounds.bottom, Self.gridBounds.top), float2(0, Float(Self.sceneGridSize.y))))
      for x in stride(from: box.topLeft.x, through: box.bottomRight.x, by: box.width / 2) {
        let xIndex = floor(remap(x, float2(Self.gridBounds.left, Self.gridBounds.right), float2(0, Float(Self.sceneGridSize.x))))
        let index = from2DTo1DArray(SIMD2<Int>(Int(xIndex), Int(yIndex)), Self.sceneGridSize)
        self.scene1DGrid[index].itemIndex = Int32(itemIndex)
      }
    }
  }
  
  static func initCompute() {
    //    Self.drawCirlcesPSO = Self.makeComputePSO(from: "drawCircles")
    Self.clearColorPSO = Self.makeComputePSO(from: "clearScreen")
    
    Self.circles = Array(repeating: ComputeCircle(), count: 5)
    
    let posValue = Float(Self.gridElemSize * Float(Self.sceneGridSize.x) / 3)
    let positionRange = -posValue...posValue
    let colorRange = Float(0)...Float(1)
    for i in 0..<Self.circles.count {
      let color = float4(Float.random(in: colorRange), Float.random(in: colorRange), Float.random(in: colorRange), Float.random(in: colorRange))
      let position = float2(Float.random(in: positionRange), Float.random(in: positionRange))
      let circle = ComputeCircle(color: color, position: position, radius: 0.5)
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
//    print(projectionMatrix.formated)
//    print(projectionMatrix * float4(1, 1, 0, 1))
    ComputeRenderer.data.projMat = projectionMatrix
    ComputeRenderer.data.sceneGridSize = SIMD2<Int32>(Int32(ComputeRenderer.sceneGridSize.x), Int32(ComputeRenderer.sceneGridSize.y))
    ComputeRenderer.data.deltaTime = Time.deltaTime
    ComputeRenderer.data.time = Time.time
    ComputeRenderer.data.gridElemSize = ComputeRenderer.gridElemSize
    ComputeRenderer.data.gridBounds = ComputeRenderer.gridBounds
    
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
  }
  //  }
}
