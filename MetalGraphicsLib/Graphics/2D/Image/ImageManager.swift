import AppKit
import MetalKit

// Bitmaps are drawn from textures of their own, one per image, which `compute2D` reaches
// through a table of texture handles (see `Graphics2D`). Each is uploaded once, with every mip
// level, so it can be drawn at any size without shimmering. Like the SDF bakes, the upload is
// queued and encoded into the next frame's command buffer, ahead of `compute2D`.

/// A bitmap on the GPU, premultiplied, with every mip level.
@MainActor public final class BitmapTexture {
  let texture: MTLTexture
  public let pixelSize: SIMD2<Int>
  /// The size it is drawn at unless resized: its pixels over its scale.
  public let pointSize: float2

  fileprivate init(texture: MTLTexture, pixelSize: SIMD2<Int>, pointSize: float2) {
    self.texture = texture
    self.pixelSize = pixelSize
    self.pointSize = pointSize
  }
}

/// One bitmap quad, laid out in the same memory as `ImageQuad` in Shaders.metal.
struct ImageQuad {
  /// Top left corner, y down.
  var position = float2()
  var size = float2()
  /// Region of the texture, in uv.
  var uvMin = float2()
  var uvMax = float2()
  /// A template image's color. An original image only takes its alpha, as opacity.
  var tint = float4(0, 0, 0, 1)
  var depth = Float()
  /// Index into the frame's texture table.
  var textureIndex = Int32()
  var flags = UInt32()
  /// Mip level to sample: log2 of texels per pixel.
  var lod = Float()

  static let templateFlag: UInt32 = 1 << 0
  static let nearestFlag: UInt32 = 1 << 1
  /// A shadow: sampled with nothing past the texture's edges, so a blurred mip fades out there.
  static let shadowFlag: UInt32 = 1 << 2

  var bounds: BoundingBox2D {
    BoundingBox2D(center: self.position + self.size * 0.5, size: self.size)
  }
}

private struct PendingUpload {
  var staging: MTLBuffer
  var bytesPerRow: Int
  var texture: MTLTexture
}

@MainActor public final class ImageManager {
  public static let shared = ImageManager()

  /// Scale an image without bitmaps of its own, such as a PDF, is drawn at.
  static let vectorScale: CGFloat = 2
  /// Largest texture edge Metal allows on every Mac.
  private static let maxPixels = 16384

  let device: MTLDevice
  private var named: [String: BitmapTexture] = [:]
  private var missing: Set<String> = []
  private var pendingUploads: [PendingUpload] = []

  private init() {
    self.device = GPUDevice.main
  }

  /// The image named `name` in `bundle` — an asset catalog image, or an image file among its
  /// resources — uploaded once and shared by everything that draws it. Nil, said once, when
  /// there is no such image.
  func texture(named name: String, bundle: Bundle) -> BitmapTexture? {
    let key = bundle.bundlePath + "|" + name
    if let texture = self.named[key] {
      return texture
    }
    guard !self.missing.contains(key) else { return nil }

    let image = bundle == .main ? NSImage(named: name) : bundle.image(forResource: name)
    guard let image, let texture = self.texture(for: image) else {
      self.missing.insert(key)
      print("Image '\(name)' was not found in \(bundle.bundlePath)")
      return nil
    }
    self.named[key] = texture
    return texture
  }

  /// Uploads `image` at the resolution of its largest bitmap. Not cached: whoever holds the
  /// image holds its texture.
  func texture(for image: NSImage) -> BitmapTexture? {
    let pointSize = image.size
    guard pointSize.width > 0, pointSize.height > 0 else { return nil }

    var pixels = SIMD2<Int>(0, 0)
    for rep in image.representations where rep.pixelsWide > 0 && rep.pixelsHigh > 0 {
      if rep.pixelsWide * rep.pixelsHigh > pixels.x * pixels.y {
        pixels = SIMD2(rep.pixelsWide, rep.pixelsHigh)
      }
    }
    if pixels.x == 0 {
      pixels = SIMD2(
        Int((pointSize.width * Self.vectorScale).rounded(.up)),
        Int((pointSize.height * Self.vectorScale).rounded(.up))
      )
    }
    pixels = SIMD2(min(pixels.x, Self.maxPixels), min(pixels.y, Self.maxPixels))

    return self.upload(pixels: pixels, pointSize: float2(Float(pointSize.width), Float(pointSize.height))) { context in
      let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
      NSGraphicsContext.saveGraphicsState()
      NSGraphicsContext.current = graphicsContext
      image.draw(
        in: NSRect(x: 0, y: 0, width: pixels.x, height: pixels.y),
        from: .zero, operation: .copy, fraction: 1
      )
      NSGraphicsContext.restoreGraphicsState()
    }
  }

  /// Uploads `image`, which is `scale` pixels per point.
  func texture(for image: CGImage, scale: Float = 1) -> BitmapTexture? {
    let pixels = SIMD2<Int>(min(image.width, Self.maxPixels), min(image.height, Self.maxPixels))
    let pointSize = float2(Float(pixels.x), Float(pixels.y)) / max(scale, 1e-3)
    return self.upload(pixels: pixels, pointSize: pointSize) { context in
      context.draw(image, in: CGRect(x: 0, y: 0, width: pixels.x, height: pixels.y))
    }
  }

  /// Encodes every upload queued since the last frame, and fills in their mip levels.
  func encodePendingUploads(into commandBuffer: MTLCommandBuffer) {
    guard !self.pendingUploads.isEmpty, let encoder = commandBuffer.makeBlitCommandEncoder() else {
      return
    }
    encoder.label = "Image uploads"
    for upload in self.pendingUploads {
      let texture = upload.texture
      encoder.copy(
        from: upload.staging, sourceOffset: 0,
        sourceBytesPerRow: upload.bytesPerRow, sourceBytesPerImage: upload.bytesPerRow * texture.height,
        sourceSize: MTLSize(width: texture.width, height: texture.height, depth: 1),
        to: texture, destinationSlice: 0, destinationLevel: 0,
        destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
      )
      if texture.mipmapLevelCount > 1 {
        encoder.generateMipmaps(for: texture)
      }
    }
    encoder.endEncoding()
    self.pendingUploads.removeAll(keepingCapacity: true)
  }

  /// Draws into a premultiplied sRGB RGBA8 bitmap of `pixels`, whose first row is the top of
  /// the image, and queues it for upload.
  private func upload(
    pixels: SIMD2<Int>, pointSize: float2, draw: (CGContext) -> Void
  ) -> BitmapTexture? {
    guard pixels.x > 0, pixels.y > 0 else { return nil }
    let bytesPerRow = pixels.x * 4
    guard
      let staging = self.device.makeBuffer(length: bytesPerRow * pixels.y, options: .storageModeShared),
      let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
      let context = CGContext(
        data: staging.contents(), width: pixels.x, height: pixels.y,
        bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      print("Could not allocate a \(pixels.x)x\(pixels.y) image")
      return nil
    }
    staging.label = "Image staging"
    context.interpolationQuality = .high
    draw(context)

    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba8Unorm, width: pixels.x, height: pixels.y, mipmapped: true
    )
    descriptor.storageMode = .private
    descriptor.usage = [.shaderRead]
    guard let texture = self.device.makeTexture(descriptor: descriptor) else {
      print("Could not create a \(pixels.x)x\(pixels.y) texture")
      return nil
    }
    texture.label = "Image"

    self.pendingUploads.append(PendingUpload(staging: staging, bytesPerRow: bytesPerRow, texture: texture))
    return BitmapTexture(texture: texture, pixelSize: pixels, pointSize: pointSize)
  }
}
