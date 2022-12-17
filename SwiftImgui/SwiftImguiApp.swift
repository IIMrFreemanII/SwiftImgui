//
//  SwiftImguiApp.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import SwiftUI
import Inject

@main
struct SwiftImguiApp: App {
  @ObserveInjection private var inject
  
  init() {
    Renderer.initialize()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .onReceive(inject.observer.objectWillChange) {
          Renderer.initialize()
        }
        .enableInjection()
    }
    .commands {
      SidebarCommands()
    }
//    .windowStyle(.hiddenTitleBar)
  }
}
