import SwiftUI

// import MetalGraphicsLib

class Reload: ObservableObject {
  @Published private var value = true

  func toggle() {
    self.value.toggle()
  }
}

class Global {
  static let reload = Reload()
}

@main
struct GPURayMarchingApp: App {
  init() {
//    Input.initialize()
//    print(Color.white.resolve(in: EnvironmentValues()).cgColor.components!)
//    print(Color.black.resolve(in: EnvironmentValues()).cgColor.components!)
//    print(Color.red.resolve(in: EnvironmentValues()).cgColor.components!)
//    print(Color.green.resolve(in: EnvironmentValues()).cgColor.components!)
//    print(Color.blue.resolve(in: EnvironmentValues()).cgColor.components!)
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(Global.reload)
    }
  }
}
