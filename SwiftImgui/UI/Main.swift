import MetalKit
import MetalPerformanceShaders

var depth: Float = 1
let maxDepth: Float = 100_000
//let maxDepth: Float = 10

func incrementDepth() {
  depth += 1
}
func resetDepth() {
  depth = 1
}
func getDepth() -> Float {
  let result = depth
  
  incrementDepth()
  
  return result
}

func startFrame() {
  startCircleFrame()
  startLineFrame()
  startRectFrame()
  startImageFrame()
  startTextFrame()
  
  resetDepth()
}

func endFrame() {
  endRectFrame()
  endImageFrame()
  endTextFrame()
  Input.endFrame()
}

func drawData(at view: MTKView) {
  guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else {
    print("failed to draw")
    return
  }
  
  // clip rect ui pass
  ClipRectPass.draw(commandBuffer: commandBuffer, uniforms: &vertexData, clipRects: &clipRects, count: clipRectsCount)
  
  // ui pass
  guard
    let descriptor = view.currentRenderPassDescriptor,
    let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
    print("failed to draw")
    return
  }
  encoder.label = "UI Pass"
  
  drawLineData(at: encoder)
  drawCircleData(at: encoder)
  drawRectData(at: encoder)
  drawImageData(at: encoder)
  drawTextData(at: encoder)
  
  encoder.endEncoding()
  
  guard let drawable = view.currentDrawable else {
    return
  }
  
//  benchmark(title: "Blur") {
//    for _ in 0..<1 {
//      BlurPass.sourceTexture = drawable.texture
//      BlurPass.draw(commandBuffer: commandBuffer, uniforms: &vertexData, blurRects: &blurRects, count: blurRectsCount)
//      
//      CopyPass.sourceTexture = BlurPass.outputTexture
//      CopyPass.outputTexture = drawable.texture
//      CopyPass.draw(commandBuffer: commandBuffer, uniforms: &vertexData, copyRects: &copyRects, count: copyRectsCount)
//    }
//  }
  
  commandBuffer.present(drawable)
  commandBuffer.commit()
  commandBuffer.waitUntilCompleted()
}
