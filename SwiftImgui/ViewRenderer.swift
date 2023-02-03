import MetalKit
import GameController

class MyMTKView: MTKView {
  
  override func magnify(with event: NSEvent) {
    Input.magnification += Float(event.magnification)
  }
  
  override func rotate(with event: NSEvent) {
    Input.rotation += Float(event.rotation)
  }
  
  override func scrollWheel(with event: NSEvent) {
    let scroll = float2(Float(event.deltaX), Float(event.deltaY))
    Input.mouseScroll += scroll
  }
  
  override func mouseMoved(with event: NSEvent) {
    let position = event.locationInWindow
    
    let newX = Float(position.x.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude))
    // flip because origin in bottom-left corner
    let newY = -Float(position.y.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude)) + Input.windowSize.y
    
    let newMousePos = float2(newX, newY)
    Input.mousePosition = newMousePos
    
    let mouseDelta = float2(newX, newY) - Input.prevMousePosition
    Input.mouseDelta += float2(mouseDelta.x, -mouseDelta.y)
    Input.prevMousePosition = newMousePos
  }
  
  override func updateTrackingAreas() {
    self.trackingAreas.forEach { item in
      self.removeTrackingArea(item)
    }

    self.addTrackingArea(
      NSTrackingArea(
        rect: self.frame,
        options: [.activeInActiveApp, .mouseMoved],
        owner: self
      )
    )
  }
}

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
    
    let center = NotificationCenter.default
    
    center.addObserver(
      forName: .GCMouseDidConnect,
      object: nil,
      queue: nil
    ) { notification in
      let mouse = notification.object as? GCMouse
      // 1
      mouse?.mouseInput?.leftButton.pressedChangedHandler = { _, _, pressed in
        Input.leftMousePressed = pressed
        
        if pressed {
          Input.leftMouseDown = true
        } else {
          Input.leftMouseUp = true
        }
      }
      mouse?.mouseInput?.rightButton?.pressedChangedHandler = { _, _, pressed in
        Input.rightMousePressed = pressed
        
        if pressed {
          Input.rightMouseDown = true
        } else {
          Input.rightMouseUp = true
        }
      }
      // 3
//      mouse?.mouseInput?.scroll.valueChangedHandler = { _, xValue, yValue in
//        Input.mouseScroll = float2(xValue, -yValue)
//
//        self.metalView.draw()
//      }
    }
    
    self.metalView.addTrackingArea(
      NSTrackingArea(
        rect: metalView.frame,
        options: [.activeInActiveApp, .mouseMoved],
        owner: self.metalView
      )
    )
    
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
    
    Input.windowSize = float2(width, height)
    
    // view frame size should be passed
    let projectionMatrix = float4x4(left: 0, right: width, bottom: height, top: 0, near: -maxDepth, far: 0)
    setProjectionMatrix(matrix: projectionMatrix)
    setViewMatrix(matrix: float4x4.identity)
  }
  
  func draw(in view: MTKView) {
    updateTime()
//    print("draw: \(deltaTime)")
  }
}
