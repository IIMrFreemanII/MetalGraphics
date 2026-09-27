import MetalGraphicsLib
import ReactiveUI

// State every window shares: the Windows demo in each Demos window and the Shared State window
// read and write this one instance, and each updates when any of them writes it.
@Model
final class AppModel {
  static let shared = AppModel()

  var count: Int = 0
  var message: String = "Hello from every window"
  var highlighted: Bool = false
  var tint: float4 = float4(0.0, 0.48, 1.0, 1)

  func reset() {
    self.count = 0
    self.message = "Hello from every window"
    self.highlighted = false
    self.tint = float4(0.0, 0.48, 1.0, 1)
  }
}
