import SwiftUI
import MetalGraphicsLib

@main
struct GPURayMarchingApp: App {
  init() {
    // MARK: make use of lazy initializing
    Input.initialize()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
