//
//  SwiftImguiApp.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import SwiftUI

@main
struct SwiftImguiApp: App {
  init() {
    Input.initialize()
    Renderer.initialize()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .commands {
      SidebarCommands()
    }
//    .windowStyle(.hiddenTitleBar)
  }
}
