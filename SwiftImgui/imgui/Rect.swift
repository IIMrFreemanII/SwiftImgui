import MetalKit

struct Rect {
  var position: float3
  var size: float2
  var color: float4
}

private var rects = [Rect]()
private var colors = [float4]()
private var transforms = [Transform]()
private var vertexData = Uniforms()

func setProjectionMatrix(matrix: float4x4) {
  vertexData.projectionMatrix = matrix
}

func setViewMatrix(matrix: float4x4) {
  vertexData.viewMatrix = matrix
}

func rect(position: float2, size: float2, color: float4 = float4(repeating: 1)) {
  rects.append(Rect(position: float3(position.x, position.y, 0), size: size, color: color))
}

func startFrame() {
  rects.removeAll(keepingCapacity: true)
}

func endFrame() {
  
}

func drawData(at encoder: MTLRenderCommandEncoder) {
  Renderer.drawRectsInstanced(at: encoder, uniforms: &vertexData, rects: &rects)
}
