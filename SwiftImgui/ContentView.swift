//
//  ContentView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import SwiftUI

struct ContentView: View {
  // MARK: make switching between scenes in runtime
//  private var scene = ImageDemoView()
//  private var scene = TextDemoView()
//  private var scene = ScrollDemoView()
//  private var scene = SDBoxIntersectionDemoView()
//  private var scene = PointBoxIntersectionDemoView()
  private var scene = TextFieldDemoView()
//  private var scene = ButtonDemoView()
//  private var scene = DemoViewRenderer()
  
  var body: some View {
    MetalView(viewRenderer: scene)
//      .ignoresSafeArea()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
