import MetalKit

public class GPUDevice {
  /// Every window renders with it, each from its own thread.
  public static let main: MTLDevice = {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Metal is not supported on this device")
    }

    return device
  }()
}
