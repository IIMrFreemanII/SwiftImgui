//
//  UIView.swift
//  SwiftImgui
//
//  Created by Nikolay Diahovets on 23.02.2024.
//

protocol UIView : Equatable {
  associatedtype Body : UIView
  
  @UIViewBuilder var body: Self.Body { get }
}

struct TupleUIView<T: Equatable> : UIView {
  var value: T
  
  var body: some UIView {
    EmptyView()
  }
}

@resultBuilder
struct UIViewBuilder {
  static func buildBlock() -> EmptyView {
    return EmptyView()
  }
  
  static func buildBlock<Content>(_ content: Content) -> Content where Content : UIView {
    return content
  }
  
//  static func buildBlock<each Content>(_ content: repeat each Content) -> TupleUIView<(repeat each Content)> where repeat each Content : UIView {
//
//  }
//  static func buildBlock(_ components: [any UIView]...) -> any UIView {
//    return EmptyView()
//  }
}

//func makeUIView(@UIViewBuilder builder: () -> [any UIView]) -> [any UIView] {
//  return builder()
//}

struct TextUIView : UIView {
  var text: String
  
  var body: some UIView {
    EmptyView()
  }
}

struct EmptyView : UIView {
  var body: some UIView {
    self
  }
}

struct AppUIView : UIView {
  var body: some UIView {
    TextUIView(text: "test \(Int.random(in: 1...2))")
  }
}

struct EquatableUIView<Content> : UIView where Content : UIView {
  var content: Content
  
  var body: some UIView {
    content
  }
}

func test(view: some UIView, offset: String = "") {
  print(offset + "\(view.self)")
  if view is EmptyView {
    return
  } else {
    test(view: view.body, offset: "  " + offset)
  }
}

//struct View : UIView {
//  
////  static func == (lhs: View, rhs: View) -> Bool {
////    return lhs.hashValue == rhs.hashValue
////  }
//  
//  var children: [any UIView] = []
//}

//let result = makeUIView {
//  View()
//  View()
//  View()
//}
