import MetalKit

func startFrame() {
  startRectFrame()
  startImageFrame()
  startTextFrame()
}

func endFrame() {
  endRectFrame()
  endImageFrame()
  endTextFrame()
}

func drawData(at encoder: MTLRenderCommandEncoder) {
  drawRectData(at: encoder)
  drawImageData(at: encoder)
  drawTextData(at: encoder)
}
