//
//  Input.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 26.01.2023.
//

import GameController

struct Drag {
  var start = float2()
  var location = float2()
  var translation = float2()
}

extension Drag: CustomStringConvertible {
  var description: String {
    return """
Drag:
  start: (\(start.x), \(start.y))
  location: (\(location.x), \(location.y))
  translation: (\(translation.x), \(translation.y))
"""
  }
}

struct Input {
  static let returnOrEnterKey = "\r".uint32[0]
  static let deleteKey = "\u{7F}".uint32[0]
  static let newLine = "\n".uint32[0]
  static let topArrow = UInt32(63232)
  static let downArrow = UInt32(63233)
  static let leftArrow = UInt32(63234)
  static let rightArrow = UInt32(63235)
  
  static var characters: String? = nil
  static var charactersCode: UInt32? = nil
  
  static var keysPressed: Set<GCKeyCode> = []
  static var keysDown: Set<GCKeyCode> = []
  static var keysUp: Set<GCKeyCode> = []
  
  static var dragGesture = Drag()
  static var drag = false
  static var dragEnded = false
  
  static var leftMousePressed = false
  static var rightMousePressed = false
  static var leftMouseDown = false
  static var rightMouseDown = false
  static var leftMouseUp = false
  static var rightMouseUp = false
  
  static var prevMousePosition = float2()
  static var mousePosition = float2()
  static var mouseDelta = float2()
  static var mouseScroll = float2()
  
  static var hScrollTimer: Timer?
  static var vScrollTimer: Timer?
  static let delay: Double = 1.5
  static var hScrolling = false
  static var vScrolling = false
  
  static func hideHScrollDebounced() {
    Self.hScrollTimer?.invalidate()
    Self.hScrollTimer = Timer.scheduledTimer(withTimeInterval: Self.delay, repeats: false) { _ in
      Self.hScrolling = false
    }
  }
  
  static func hideVScrollDebounced() {
    Self.vScrollTimer?.invalidate()
    Self.vScrollTimer = Timer.scheduledTimer(withTimeInterval: Self.delay, repeats: false) { _ in
      Self.vScrolling = false
    }
  }
  
  static var magnification = Float()
  static var rotation = Float()
  
  static var windowSize = float2()
  static var framebufferSize = float2()
  static var windowPosition = float2()
  
  static func endFrame() {
    Self.charactersCode = nil
    Self.characters = nil
    
    Self.dragEnded = false
    
    Self.mouseDelta = float2()
    Self.mouseScroll = float2()
    
    Self.keysDown.removeAll(keepingCapacity: true)
    Self.keysUp.removeAll(keepingCapacity: true)
    
    Self.leftMouseDown = false
    Self.leftMouseUp = false
    
    Self.rightMouseDown = false
    Self.rightMouseUp = false
    
    Self.magnification = 0
    Self.rotation = 0
  }
  
  static func initialize() {
    let center = NotificationCenter.default
    
    center.addObserver(
      forName: .GCKeyboardDidConnect,
      object: nil,
      queue: nil
    ) { notification in
      let keyboard = notification.object as? GCKeyboard
      keyboard?.keyboardInput?.keyChangedHandler = { _, _, keyCode, pressed in
        if pressed {
          Self.keysDown.insert(keyCode)
          Self.keysPressed.insert(keyCode)
        } else {
          Self.keysPressed.remove(keyCode)
          Self.keysUp.insert(keyCode)
        }
      }
    }
    
//#if os(macOS)
//    NSEvent.addLocalMonitorForEvents(
//      matching: [.keyDown]) { event in
//        return NSApp.keyWindow?.firstResponder is NSTextView ? event : nil
//      }
//#endif
  }
}

typealias VoidFunc = () -> Void

extension Input {
  static func charactersCode(_ cb: (UInt32) -> Void) -> Void {
    if let charsCode = Input.charactersCode {
      cb(charsCode)
    }
  }
  
  static func characters(_ cb: (String) -> Void) -> Void {
    if let chars = Input.characters {
      cb(chars)
    }
  }
  
  static func dragChange(_ cb: (Drag) -> Void) -> Void {
    if Self.drag {
      cb(Self.dragGesture)
    }
  }
  static func dragEnd(_ cb: (Drag) -> Void) -> Void {
    if Self.dragEnded {
      cb(Self.dragGesture)
    }
  }
  static var mouseDown: Bool {
    get {
      return Self.leftMouseDown || Self.rightMouseDown
    }
  }
  static var mousePressed: Bool {
    get {
      return Self.leftMousePressed || Self.rightMousePressed
    }
  }
  static var mouseUp: Bool {
    get {
      return Self.leftMouseUp || Self.rightMouseUp
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
  
  static func leftMouseDown(cb: VoidFunc) {
    if Self.leftMouseDown
    {
      cb()
    }
  }
  static func leftMousePressed(cb: VoidFunc) {
    if Self.leftMousePressed
    {
      cb()
    }
  }
  static func leftMouseUp(cb: VoidFunc) {
    if Self.leftMouseUp
    {
      cb()
    }
  }
  
  static func rightMouseDown(cb: VoidFunc) {
    if Self.rightMouseDown
    {
      cb()
    }
  }
  static func rightMousePressed(cb: VoidFunc) {
    if Self.rightMousePressed
    {
      cb()
    }
  }
  static func rightMouseUp(cb: VoidFunc) {
    if Self.rightMouseUp
    {
      cb()
    }
  }
  
  static func keyPress(_ key: GCKeyCode, cb: VoidFunc) {
    if Self.keysPressed.contains(key)
    {
      cb()
    }
  }
  
  static func keyDown(_ key: GCKeyCode, cb: VoidFunc) {
    if Self.keysDown.contains(key)
    {
      cb()
    }
  }
  
  static func keyUp(_ key: GCKeyCode, cb: VoidFunc) {
    if Self.keysUp.contains(key)
    {
      cb()
    }
  }
}
