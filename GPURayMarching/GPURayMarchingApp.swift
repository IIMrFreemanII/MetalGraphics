import SwiftUI
import MetalGraphicsLib

@main
struct GPURayMarchingApp: App {
  init() {
    Input.initialize()
  }
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
