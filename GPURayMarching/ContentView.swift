import MetalGraphicsLib
import SwiftUI

struct ContentView: View {
  var renderer: ViewRenderer = TestViewRenderer()

  var body: some View {
    Editor(renderer: self.renderer)
  }
}

#Preview {
  ContentView()
}
