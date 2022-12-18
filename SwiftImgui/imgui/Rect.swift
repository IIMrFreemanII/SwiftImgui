import MetalKit

//private var positions = [float2]()
//private var sizes = [float2]()
private var colors = [float4]()
private var transforms = [Transform]()
//private var projectionMatrix = float4x4.identity
//private var viewMatrix = float4x4.identity
private var vertexData = Uniforms()

func setProjectionMatrix(matrix: float4x4) {
//  projectionMatrix = matrix
  vertexData.projectionMatrix = matrix
}

func setViewMatrix(matrix: float4x4) {
  vertexData.viewMatrix = matrix
}

func rect(transform: Transform, color: float4) {
  transforms.append(transform)
  colors.append(color)
}

func drawData(at encoder: MTLRenderCommandEncoder) {
  for i in transforms.indices {
    vertexData.modelMatrix = transforms[i].modelMatrix
    var quadMaterial = QuadMaterial()
    quadMaterial.color = colors[i]
    Renderer.draw(at: encoder, uniforms: &vertexData, quadMaterial: &quadMaterial)
  }
}
