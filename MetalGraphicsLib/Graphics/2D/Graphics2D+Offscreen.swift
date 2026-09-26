import Metal
import simd

/// Rendering without a view: a texture to draw into and a way to read it back. Used by the
/// headless tests; nothing here runs in the app's frame.
extension Graphics2D {
  /// A texture `render(into:pixelsPerPoint:_:)` can draw a `size`-point window into.
  public static func makeOffscreenTarget(size: float2, pixelsPerPoint: Float) -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm,
      width: max(1, Int((size.x * pixelsPerPoint).rounded())),
      height: max(1, Int((size.y * pixelsPerPoint).rounded())),
      mipmapped: false
    )
    descriptor.usage = [.shaderRead, .shaderWrite]
    descriptor.storageMode = .private
    guard let texture = GPUDevice.main.makeTexture(descriptor: descriptor) else {
      fatalError("Could not create an offscreen target of \(descriptor.width)x\(descriptor.height)")
    }
    return texture
  }

  /// `texture`'s pixels, rows top to bottom, 4 bytes each in BGRA order. Blocks until the GPU
  /// has copied them.
  public func readPixels(_ texture: MTLTexture) -> (width: Int, height: Int, bgra: [UInt8]) {
    let width = texture.width
    let height = texture.height
    let bytesPerRow = width * 4
    guard
      let buffer = self.device.makeBuffer(length: bytesPerRow * height, options: .storageModeShared),
      let commandBuffer = self.commandQueue.makeCommandBuffer(),
      let blit = commandBuffer.makeBlitCommandEncoder()
    else {
      fatalError("Could not read back a \(width)x\(height) texture")
    }
    blit.copy(
      from: texture, sourceSlice: 0, sourceLevel: 0,
      sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0), sourceSize: MTLSize(width: width, height: height, depth: 1),
      to: buffer, destinationOffset: 0,
      destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: bytesPerRow * height
    )
    blit.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    let pointer = buffer.contents().bindMemory(to: UInt8.self, capacity: bytesPerRow * height)
    return (width, height, Array(UnsafeBufferPointer(start: pointer, count: bytesPerRow * height)))
  }
}
