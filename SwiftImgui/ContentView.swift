//
//  ContentView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 14.12.2022.
//

import SwiftUI

struct ContentView: View {
  private var scene = DemoViewRenderer()
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
