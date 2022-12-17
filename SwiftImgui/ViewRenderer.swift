import MetalKit
import GameController

class ViewRenderer: NSObject, ObservableObject {
  var metalView: MTKView!
  
  override init() {
    super.init()
//    let center = NotificationCenter.default
//    center.addObserver(
//      forName: .GCKeyboardDidConnect,
//      object: nil,
//      queue: nil
//    ) { notification in
//      let keyboard = notification.object as? GCKeyboard
//      keyboard?.keyboardInput?.keyChangedHandler = { _, _, keyCode, pressed in
//        if keyCode == .keyR && pressed {
//          self.objectWillChange.send()
//          print("reload")
//        }
//      }
//    }
  }
  
  func initialize(metalView: MTKView) {
    self.metalView = metalView
    self.metalView.device = Renderer.device
    self.metalView.delegate = self
    
    mtkView(
      metalView,
      drawableSizeWillChange: metalView.drawableSize
    )
  }
  
  func update(deltaTime: Float) {}
}

extension ViewRenderer: MTKViewDelegate {
  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    
  }
  
  func draw(in view: MTKView) {
    
  }
}
