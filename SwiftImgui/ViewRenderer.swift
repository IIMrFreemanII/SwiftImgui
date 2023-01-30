import MetalKit
import GameController

class ViewRenderer: NSObject {
  var metalView: MTKView!
  var clearColor = MTLClearColor(
    red: 0.93,
    green: 0.97,
    blue: 1.0,
    alpha: 1.0
  )
  
  var lastTime: Double = CFAbsoluteTimeGetCurrent()
  var deltaTime: Float = 0
  var time: Float = 0
  
  func updateTime() {
    let currentTime = CFAbsoluteTimeGetCurrent()
    deltaTime = Float(currentTime - lastTime)
    time += deltaTime
    lastTime = currentTime
    
    setTime(value: time)
  }
  
  override init() {
    super.init()
  }
  
  func initialize(metalView: MTKView) {
    self.metalView = metalView
    self.metalView.device = Renderer.device
    self.metalView.delegate = self
    self.metalView.clearColor = clearColor
    self.metalView.depthStencilPixelFormat = .depth32Float
    
    mtkView(
      metalView,
      drawableSizeWillChange: metalView.drawableSize
    )
    
    setFont(FontManager.load(font: "JetBrains Mono NL"))
    start()
  }
  
  func start() {}
}

extension ViewRenderer: MTKViewDelegate {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    ClipRectPass.resize(view: view, size: size)
    
    let width = Float(view.frame.width)
    let height = Float(view.frame.height)
    
    Input.shared.windowSize = float2(width, height)
    
    // view frame size should be passed
    let projectionMatrix = float4x4(left: 0, right: width, bottom: height, top: 0, near: -maxDepth, far: 0)
    setProjectionMatrix(matrix: projectionMatrix)
    setViewMatrix(matrix: float4x4.identity)
  }
  
  func draw(in view: MTKView) {
    updateTime()
  }
}
