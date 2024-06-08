import SwiftUI
import MetalKit

public struct MetalView: View {
  @State private var metalView: MTKView = MyMTKView()
  public let viewRenderer: ViewRenderer
  
  public init(viewRenderer: ViewRenderer) {
    self.viewRenderer = viewRenderer
  }
  
  public var body: some View {
    MetalViewRepresentable(metalView: $metalView)
      .onAppear {
        viewRenderer.initialize(metalView: metalView)
      }
      .gesture(
        DragGesture(minimumDistance: 1)
          .onChanged { gesture in
            let startLocation = float2(Float(gesture.startLocation.x), Float(gesture.startLocation.y))
            let location = float2(Float(gesture.location.x), Float(gesture.location.y))
            let delta = location - Input.prevMousePosition
            Input.mouseDelta += float2(delta.x, -delta.y)
            Input.prevMousePosition = location
            let translation = location - startLocation
            
            Input.drag = true
            Input.dragGesture = Drag(
              start: startLocation,
              location: location,
              translation: translation
            )
          }
          .onEnded { gesture in
            Input.dragGesture = Drag(
              start: float2(Float(gesture.startLocation.x), Float(gesture.startLocation.y)),
              location: float2(Float(gesture.location.x), Float(gesture.location.x)),
              translation: float2(Float(gesture.translation.width), Float(gesture.translation.height))
            )
            Input.dragEnded = true
            Input.drag = false
          }
      )
  }
}

#if os(macOS)
public typealias ViewRepresentable = NSViewRepresentable
#elseif os(iOS)
public typealias ViewRepresentable = UIViewRepresentable
#endif

public struct MetalViewRepresentable: ViewRepresentable {
  @Binding var metalView: MTKView
  
#if os(macOS)
  public func makeNSView(context: Context) -> some NSView {
    print("makeMetalView")
    return metalView
  }
  public func updateNSView(_ uiView: NSViewType, context: Context) {
    updateMetalView()
  }
#elseif os(iOS)
  func makeUIView(context: Context) -> MTKView {
    print("makeMetalView")
    return metalView
  }
  
  func updateUIView(_ uiView: MTKView, context: Context) {
    updateMetalView()
  }
#endif
  
  func updateMetalView() {
    print("updateMetalView")
  }
}
