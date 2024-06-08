//
//  ContentView.swift
//  GPURayMarching
//
//  Created by Nikolay Diahovets on 08.06.2024.
//

import SwiftUI
import MetalGraphicsLib
import MetalKit

class TestViewRenderer : ViewRenderer {
  override func start() {
  }
  
  override func draw(in view: MTKView) {
    super.draw(in: view)
    
    guard let drawable = view.currentDrawable,
          let descriptor = view.currentRenderPassDescriptor else { return }
    
    let commandQueue = view.device?.makeCommandQueue()
    let commandBuffer = commandQueue?.makeCommandBuffer()
    
    let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
    renderEncoder?.endEncoding()
    
    commandBuffer?.present(drawable)
    commandBuffer?.commit()
  }
}

struct ContentView: View {
  private var renderer = TestViewRenderer()
  
  var body: some View {
    HStack {
      VStack {
        Text("Hello, world!")
        Spacer()
      }
      .padding()
      MetalView(viewRenderer: self.renderer)
    }
  }
}

//#Preview {
//  ContentView()
//}
