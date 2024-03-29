//
//  ContentView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import SwiftUI
import Inject

struct ContentView: View {
  @ObserveInjection private var inject
  
  // MARK: make switching between scenes in runtime
//  private var scene = ImageDemoView()
//  private var scene = TextDemoView()
//  private var scene = ScrollDemoView()
//  private var scene = SDBoxIntersectionDemoView()
//  private var scene = PointBoxIntersectionDemoView()
//  private var scene = TextFieldDemoView()
//  private var scene = ButtonDemoView()
//  private var scene = CheckboxDemoView()
//  private var scene = DemoViewRenderer()
//    private var scene = SimulationDemoView()
//  private var scene = UIElementsDemoView()
  private var scene = ComputeView()
  
  var body: some View {
    MetalView(viewRenderer: scene)
      .onReceive(inject.observer.objectWillChange) {
//          Renderer.initialize()
      }
      .enableInjection()
//      .ignoresSafeArea()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
