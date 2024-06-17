import SwiftUI
import MetalGraphicsLib

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

#Preview {
  ContentView()
}
