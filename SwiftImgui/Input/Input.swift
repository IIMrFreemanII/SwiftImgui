//
//  Input.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

import GameController

class Input {
  static let shared = Input()
  
  private var keysPressed: Set<GCKeyCode> = []
  private var keysDown: Set<GCKeyCode> = []
  private var keysUp: Set<GCKeyCode> = []
  
  private var leftMousePressed = false
  private var rightMousePressed = false
  private var leftMouseDown = false
  private var rightMouseDown = false
  private var leftMouseUp = false
  private var rightMouseUp = false
  
  private var mousePosition = float2()
  private var mouseDelta = float2()
  private var mouseScroll = float2()
  
  private var magnification = Float()
  private var rotation = Float()
  
  var windowSize = float2()
  var windowPosition = float2()
  
  func endFrame() {
    self.mouseDelta = float2()
    self.mouseScroll = float2()
    
    self.keysDown.removeAll(keepingCapacity: true)
    self.keysUp.removeAll(keepingCapacity: true)
    
    self.leftMouseDown = false
    self.leftMouseUp = false
    
    self.rightMouseDown = false
    self.rightMouseUp = false
    
    self.magnification = 0
    self.rotation = 0
  }
  
  private init() {
    let center = NotificationCenter.default
    
    center.addObserver(
      forName: .GCKeyboardDidConnect,
      object: nil,
      queue: nil
    ) { notification in
      let keyboard = notification.object as? GCKeyboard
      keyboard?.keyboardInput?.keyChangedHandler = { _, _, keyCode, pressed in
        if pressed {
          self.keysDown.insert(keyCode)
          self.keysPressed.insert(keyCode)
        } else {
          self.keysPressed.remove(keyCode)
          self.keysUp.insert(keyCode)
        }
      }
    }
    
#if os(macOS)
    NSEvent.addLocalMonitorForEvents(
      matching: [.keyDown]) { event in
        return NSApp.keyWindow?.firstResponder is NSTextView ? event : nil
      }
    
    NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
      let position = event.locationInWindow
      let newX = Float(position.x.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude)).rounded()
      // flip because origin in bottom-left corner
      let newY = -Float(position.y.clamped(to: 0.0...CGFloat.greatestFiniteMagnitude)).rounded() + self.windowSize.y
      self.mousePosition = float2(newX, newY)

      return event
    }
    
    NSEvent.addLocalMonitorForEvents(matching: [.magnify]) { event in
      self.magnification = Float(event.magnification)
      return event
    }
    
    NSEvent.addLocalMonitorForEvents(matching: [.rotate]) { event in
      self.rotation = event.rotation
      return event
    }
#endif
    
    center.addObserver(
      forName: .GCMouseDidConnect,
      object: nil,
      queue: nil
    ) { notification in
      let mouse = notification.object as? GCMouse
      // 1
      mouse?.mouseInput?.leftButton.pressedChangedHandler = { _, _, pressed in
        self.leftMousePressed = pressed
        
        if pressed {
          self.leftMouseDown = true
        } else {
          self.leftMouseUp = true
        }
      }
      mouse?.mouseInput?.rightButton?.pressedChangedHandler = { _, _, pressed in
        self.rightMousePressed = pressed
        
        if pressed {
          self.rightMouseDown = true
        } else {
          self.rightMouseUp = true
        }
      }
      // 2
      mouse?.mouseInput?.mouseMovedHandler = { _, deltaX, deltaY in
        self.mouseDelta = float2(deltaX, deltaY)
      }
      // 3
      mouse?.mouseInput?.scroll.valueChangedHandler = { _, xValue, yValue in
        self.mouseScroll = float2(xValue, yValue)
      }
    }
  }
}

typealias VoidFunc = () -> Void

extension Input {
  static var magnification: Float {
    get {
      return shared.magnification
    }
  }
  static var rotation: Float {
    get {
      return shared.rotation
    }
  }
  static var windowPosition: float2 {
    get {
      return shared.windowPosition
    }
  }
  static var windowSize: float2 {
    get {
      return shared.windowSize
    }
  }
  static var mousePosition: float2 {
    get {
      return shared.mousePosition
    }
  }
  static var mouseDelta: float2 {
    get {
      return shared.mouseDelta
    }
  }
  static var mouseScroll: float2 {
    get {
      return shared.mouseScroll
    }
  }
  
  static func magnify(cb: (Float) -> Void) -> Void {
    if magnification != 0 {
      cb(magnification)
    }
  }
  
  static func rotate(cb: (Float) -> Void) -> Void {
    if rotation != 0 {
      cb(rotation)
    }
  }
  
  static func keyPress(_ key: GCKeyCode, cb: VoidFunc) {
    if shared.keysPressed.contains(key)
    {
      cb()
    }
  }
  
  static func keyDown(_ key: GCKeyCode, cb: VoidFunc) {
    if shared.keysDown.contains(key)
    {
      cb()
    }
  }
  
  static func keyUp(_ key: GCKeyCode, cb: VoidFunc) {
    if shared.keysUp.contains(key)
    {
      cb()
    }
  }
}
