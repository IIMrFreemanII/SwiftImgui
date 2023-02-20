//
//  UndoController.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 18.02.2023.
//

//class UndoController<T: Any> {
//  private var cursor = 0
//  private var cache: [T] = []
//
//  func save(value: T) {
//    if self.cursor < self.cache.count {
//      self.cache.removeSubrange(self.cursor..<self.cache.count)
//    }
//
//    self.cache.append(value)
//    self.cursor += 1
//  }
//
//  func undo(_ cb: (T) -> Void) {
//    guard self.cursor > 0 else { return }
//    cursor -= 1
//    cb(cache[cursor])
//  }
//
//  func redo(_ cb: (T) -> Void) {
//    guard self.cursor < self.cache.count else { return }
//    cb(cache[cursor])
//    cursor += 1
//  }
//}

class Ref<T: Any> {
  var value: T
  
  init(value: T) {
    self.value = value
  }
}

class CommandController {
  static private var cursor = 0
  static private var actions: [VoidFunc] = []
  static private var clears: [VoidFunc] = []
  
  static func perform(action: @escaping VoidFunc, clear: @escaping VoidFunc) {
    if Self.cursor < Self.actions.count {
      Self.actions.removeSubrange(Self.cursor..<Self.actions.count)
      Self.clears.removeSubrange(Self.cursor..<Self.clears.count)
    }
    
    action()
    
    Self.actions.append(action)
    Self.clears.append(clear)
    Self.cursor += 1
  }
  
  static func undo() {
    guard Self.cursor > 0 else { return }
    Self.cursor -= 1
    Self.clears[Self.cursor]()
  }
  
  static func redo() {
    guard Self.cursor < Self.actions.count else { return }
    Self.actions[Self.cursor]()
    cursor += 1
  }
}
