import MetalKit
import SwiftUI

public struct MetalView: View {
  @State private var metalView = MyMTKView()
  public let viewRenderer: ViewRenderer
  
  public init(viewRenderer: ViewRenderer) {
    self.viewRenderer = viewRenderer
  }
  
  public var body: some View {
    MetalViewRepresentable(metalView: self.$metalView)
      .onAppear {
        self.viewRenderer.initialize(metalView: self.metalView)
      }
    //      .gesture(
    //        DragGesture(minimumDistance: 0)
    //          .onChanged { gesture in
    //            let startLocation = float2(Float(gesture.startLocation.x), Float(gesture.startLocation.y))
    //            let location = float2(Float(gesture.location.x), Float(gesture.location.y))
    //            let delta = location - Input.prevMousePosition
    //            Input.mouseDelta = float2(delta.x, -delta.y)
    //            Input.prevMousePosition = location
    //            let translation = location - startLocation
    //
    //            Input.drag = true
    //            Input.dragGesture = Drag(
    //              start: startLocation,
    //              location: location,
    //              translation: translation
    //            )
    //          }
    //          .onEnded { gesture in
    //            Input.dragGesture = Drag(
    //              start: float2(Float(gesture.startLocation.x), Float(gesture.startLocation.y)),
    //              location: float2(Float(gesture.location.x), Float(gesture.location.x)),
    //              translation: float2(Float(gesture.translation.width), Float(gesture.translation.height))
    //            )
    //            Input.dragEnded = true
    //            Input.drag = false
    //          }
    //      )
  }
}

#if os(macOS)
public typealias ViewRepresentable = NSViewRepresentable
#elseif os(iOS)
public typealias ViewRepresentable = UIViewRepresentable
#endif

public struct MetalViewRepresentable: ViewRepresentable {
  @Binding var metalView: MyMTKView
  
#if os(macOS)
  public func makeNSView(context: Context) -> some NSView {
    return self.metalView
  }
  
  public func updateNSView(_ nsView: NSViewType, context: Context) {
    self.updateMetalView()
  }

//  public func makeNSView(context: Context) -> NSView {
//    //      print("makeMetalView")
//    return self.metalView
//  }
//  
//  public func updateNSView(nsView: NSView, context: Context) {
//    self.updateMetalView()
//  }
  
#elseif os(iOS)
  func makeUIView(context: Context) -> MTKView {
    //      print("makeMetalView")
    return self.metalView
  }
  
  func updateUIView(view: MTKView, context: Context) {
    self.updateMetalView()
  }
#endif
  
  func updateMetalView() {
    //    print("updateMetalView")
  }
}
