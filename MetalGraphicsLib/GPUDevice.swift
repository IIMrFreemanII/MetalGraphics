import MetalKit

public class GPUDevice {
  public static var main: MTLDevice = {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Metal is not supported on this device")
    }

    return device
  }()
}
