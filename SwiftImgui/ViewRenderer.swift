import MetalKit
import GameController

class ViewRenderer: NSObject {
  var metalView: MTKView!
  var metalLayer: CAMetalLayer!
  
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
    self.metalView.layerContentsPlacement = .scaleAxesIndependently
    
    self.metalView.isPaused = true
    self.metalView.enableSetNeedsDisplay = true
    
    self.metalView.wantsLayer = true
    self.metalLayer = self.metalView.layer as? CAMetalLayer
    
//    self.metalLayer.presentsWithTransaction = true
    
    
    
//    self.metalView.layerContentsRedrawPolicy = .duringViewResize
    
    // to fix jittering on window resize (partially fixes problem)
//    self.metalView.layerContentsPlacement = .topLeft
    
//    let metalLayer = self.metalView.layer as! CAMetalLayer
//    metalLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
//    metalLayer.needsDisplayOnBoundsChange = true
    
    mtkView(
      metalView,
      drawableSizeWillChange: metalView.drawableSize
    )
    
    setFont(FontManager.load(font: "JetBrains Mono NL"))
    start()
    
//    NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
//      self.metalView.draw()
////      print("draw")
//      return event
//    }
  }
  
  func start() {}
  
//  private var prevMousePosition = float2()
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
    
    print("resize")
//    if size.width > 0 && size.height > 0 {
//      self.metalView.draw()
//    }
  }
  
  func draw(in view: MTKView) {
    
//    let mousePos = float2(Float(NSEvent.mouseLocation.x), Float(NSEvent.mouseLocation.y))
//    Input.shared.mouseDelta = mousePos - self.prevMousePosition
//    self.prevMousePosition = mousePos
    
    updateTime()
    print("draw: \(deltaTime)")
  }
}
