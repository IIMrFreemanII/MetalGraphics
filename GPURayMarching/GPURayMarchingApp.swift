import SwiftUI
import MetalGraphicsLib

@main
struct GPURayMarchingApp: App {
  init() {
    Input.initialize()
    
//    var arr: [Float] = [3, 5, 6, 2, 1]
//    print("before: \(arr)")
////    arr.sort(by: { $0 > $1 })
//    print("after: \(arr)")
  }
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
