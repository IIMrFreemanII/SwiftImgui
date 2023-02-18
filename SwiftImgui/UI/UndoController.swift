//
//  UndoController.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 18.02.2023.
//

struct UndoController {
  private static var cursor = 0
  private static var actions: [VoidFunc] = []
  private static var clearActions: [VoidFunc] = []
  
  static func perform(action: @escaping VoidFunc, clear: @escaping VoidFunc) {
    if Self.cursor < Self.actions.count {
      Self.actions.removeSubrange(Self.cursor..<Self.actions.count)
      Self.clearActions.removeSubrange(Self.cursor..<Self.clearActions.count)
    }
    
    action()
    Self.actions.append(action)
    Self.clearActions.append(clear)
    Self.cursor += 1
  }
  
  static func undo() {
    guard Self.cursor >= 0 else { return }
    cursor -= 1
    Self.clearActions[cursor]()
  }
  
  static func redo() {
    guard Self.cursor <= Self.actions.count else { return }
    Self.actions[cursor]()
    cursor += 1
  }
}
