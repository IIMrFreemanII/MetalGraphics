import MetalKit

public class GPUDevice {
  @MainActor public static var main: MTLDevice = {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Metal is not supported on this device")
    }

    return device
  }()
}
