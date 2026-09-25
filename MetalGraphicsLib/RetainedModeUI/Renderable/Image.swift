import AppKit
import simd

/// How `aspectRatio(_:contentMode:)` fits an image into the space it is offered.
public enum ContentMode {
  /// As large as fits entirely.
  case fit
  /// As small as covers it all. The image is cropped to the space offered, as though
  /// SwiftUI's `.clipped()` followed.
  case fill
}

/// A bitmap, or an SVG baked into a distance field.
///
/// Laid out like SwiftUI's: at its natural size, until `resizable()` lets it take the size it is
/// offered, which `aspectRatio(_:contentMode:)`, `scaledToFit()` and `scaledToFill()` then
/// shape to its proportions.
public final class Image : UIRenderableElement {
  public enum TemplateRenderingMode {
    /// Drawn in the foreground color, with its own alpha as a mask.
    case template
    /// Drawn in its own colors. An SVG's `currentColor` is still the foreground color.
    case original
  }

  public enum Interpolation {
    /// Nearest neighbour: pixel art stays blocky.
    case none
    case low
    case medium
    case high
  }

  enum Content {
    case bitmap(BitmapTexture)
    case svg(SVGIcon)
    case missing
  }

  private(set) var content: Content = .missing
  /// Set by `.resizable()`.
  public private(set) var isResizable = false
  /// Set by `.aspectRatio(_:contentMode:)`, `.scaledToFit()` and `.scaledToFill()`. A nil ratio
  /// is the image's own.
  public private(set) var aspectRatio: Float? = nil
  public private(set) var contentMode: ContentMode? = nil
  /// Set by `.renderingMode(_:)`; nil is `.original`.
  public private(set) var renderingMode: TemplateRenderingMode? = nil
  /// Set by `.interpolation(_:)`. Only bitmaps are filtered; SVGs are sharp at any size.
  public private(set) var interpolation: Interpolation = .high
  /// Set by `.foregroundColor(_:)`: the color of a template, and of an SVG's `currentColor`.
  public internal(set) var color: float4 = .black

  public var position: float2 = .init()
  public var size: float2 = .init()
  /// Where the image itself is drawn, relative to `position`: larger than `size` when it fills
  /// it, smaller when it fits in a space of another shape.
  private var imageOrigin: float2 = .init()
  private var imageSize: float2 = .init()

  /// An SVG or bitmap image named `name` in `bundle`, the main bundle when nil. An SVG is looked
  /// for first — a data asset in the asset catalog, or a `.svg` resource — then an image asset or
  /// an image file.
  public init(_ name: String, bundle: Bundle? = nil) {
    self.bundle = bundle ?? .main
    super.init()
    self.load(name: name)
  }

  public init(nsImage: NSImage) {
    self.bundle = .main
    super.init()
    self.load(nsImage: nsImage)
  }

  /// An SVG from its markup. Not in SwiftUI.
  public init(svg source: String) {
    self.bundle = .main
    super.init()
    self.load(svg: source)
  }

  private let bundle: Bundle

  // MARK: - Content

  func load(name: String) {
    if let icon = SVGIcon.named(name, bundle: self.bundle) {
      self.content = .svg(icon)
    } else if let texture = ImageManager.shared.texture(named: name, bundle: self.bundle) {
      self.content = .bitmap(texture)
    } else {
      self.content = .missing
    }
  }

  func load(nsImage: NSImage) {
    self.content = ImageManager.shared.texture(for: nsImage).map { .bitmap($0) } ?? .missing
  }

  func load(svg source: String) {
    self.content = SVGIcon.source(source).map { .svg($0) } ?? .missing
  }

  /// The size it is drawn at unless resized.
  private var naturalSize: float2 {
    switch self.content {
    case .bitmap(let texture): texture.pointSize
    case .svg(let icon): icon.naturalSize
    case .missing: .zero
    }
  }

  // MARK: - Element

  public override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last! + "(position: \(position), size: \(size))")
  }

  public override func getSize() -> float2 {
    self.size
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.fit(proposal).size
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    (self.size, self.imageOrigin, self.imageSize) = self.fit(proposal)
    return self.size
  }

  /// The size the image takes when offered `proposal`, and where within it the image is drawn.
  private func fit(_ proposal: ProposedSize) -> (size: float2, imageOrigin: float2, imageSize: float2) {
    let natural = self.naturalSize
    // an axis offered no bound, or asked for its ideal, takes the image's own length
    let available = proposal.replacingUnspecified(with: natural)
    let offered = float2(
      available.x.isFinite && available.x < 1e7 ? max(available.x, 0) : natural.x,
      available.y.isFinite && available.y < 1e7 ? max(available.y, 0) : natural.y
    )

    guard self.isResizable else {
      return (natural, .zero, natural)
    }

    guard let contentMode = self.contentMode else {
      return (offered, .zero, offered)
    }

    let ratio = self.aspectRatio ?? (natural.y > 0 ? natural.x / natural.y : 1)
    guard ratio > 0, ratio.isFinite, offered.x > 0, offered.y > 0 else {
      return (.zero, .zero, .zero)
    }
    let widthFirst = float2(offered.x, offered.x / ratio)
    let heightFirst = float2(offered.y * ratio, offered.y)
    switch contentMode {
    case .fit:
      let size = widthFirst.y <= offered.y ? widthFirst : heightFirst
      return (size, .zero, size)
    case .fill:
      // Takes the space offered, and draws the image covering it, centered and cropped.
      let imageSize = widthFirst.y >= offered.y ? widthFirst : heightFirst
      return (offered, (offered - imageSize) * 0.5, imageSize)
    }
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
  }

  public override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    guard effect.opacity > 0, self.size.x > 0, self.size.y > 0 else { return }
    let template = self.renderingMode == .template
    // origin -> top left
    let clipMin = effect.apply(to: self.position) - renderer.size * 0.5
    let clipMax = clipMin + self.size * effect.scale
    let origin = clipMin + self.imageOrigin * effect.scale
    let size = self.imageSize * effect.scale

    switch self.content {
    case .bitmap(let texture):
      // what of the image lands inside the element
      let visibleMin = simd_max(origin, clipMin)
      let visibleMax = simd_min(origin + size, clipMax)
      guard visibleMin.x < visibleMax.x, visibleMin.y < visibleMax.y else { return }
      var tint = self.color
      tint.w = (template ? tint.w : 1) * effect.opacity
      renderer.draw(
        image: texture, at: visibleMin, size: visibleMax - visibleMin,
        uvMin: (visibleMin - origin) / size, uvMax: (visibleMax - origin) / size,
        tint: tint, template: template, nearest: self.interpolation == .none
      )

    case .svg(let icon):
      let foreground = self.color
      renderer.draw(icon: icon, at: origin, size: size, clipMin: clipMin, clipMax: clipMax) { layer in
        var color = layer.resolvedColor(foreground: foreground, template: template)
        color.w *= effect.opacity
        return color
      }

    case .missing:
      break
    }
  }

  // MARK: - Modifiers

  /// Lets the image take the size it is offered, rather than its own. Sets this image and
  /// returns it.
  public func resizable() -> Self {
    self.isResizable = true
    return self
  }

  /// Keeps the image at `ratio` of width to height, its own when nil, and fits it to or fills
  /// the space it is offered with it. Only a resizable image changes size.
  public func aspectRatio(_ ratio: Float? = nil, contentMode: ContentMode) -> Self {
    self.aspectRatio = ratio
    self.contentMode = contentMode
    return self
  }

  public func scaledToFit() -> Self {
    self.aspectRatio(nil, contentMode: .fit)
  }

  /// Scales the image to cover the space it is offered, cropping what falls outside it.
  public func scaledToFill() -> Self {
    self.aspectRatio(nil, contentMode: .fill)
  }

  /// Whether the image is drawn in its own colors or as a mask in the foreground color. SVG
  /// paints of `currentColor` take the foreground color either way.
  public func renderingMode(_ renderingMode: TemplateRenderingMode?) -> Self {
    self.renderingMode = renderingMode
    return self
  }

  /// How a bitmap is filtered when drawn at other than its own size.
  public func interpolation(_ interpolation: Interpolation) -> Self {
    self.interpolation = interpolation
    return self
  }

  /// The color a template, and an SVG's `currentColor`, is drawn in; black when never set.
  public func foregroundColor(_ color: float4) -> Self {
    self.color = color
    return self
  }
}
