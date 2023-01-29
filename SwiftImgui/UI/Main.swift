import MetalKit

var depth: Float = 0
let maxDepth: Float = 100_000

func incrementDepth() {
  depth += 1
}
func resetDepth() {
  depth = 0
}
func getDepth() -> Float {
  let result = depth
  
  incrementDepth()
  
  return result
}

func startFrame() {
  startRectFrame()
  startImageFrame()
  startTextFrame()
  
  resetDepth()
}

func endFrame() {
  endRectFrame()
  endImageFrame()
  endTextFrame()
  Input.shared.endFrame()
}

func drawData(at encoder: MTLRenderCommandEncoder) {
  drawRectData(at: encoder)
  drawImageData(at: encoder)
  drawTextData(at: encoder)
}
