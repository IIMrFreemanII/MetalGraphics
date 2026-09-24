import AppKit
import simd

/// An SVG baked into the shared SDF atlas, one region per run of shapes painted alike, so it
/// draws crisp at any size, the way text does.
///
/// Its em is the longer side of its view box: em space runs from the view box's top left
/// corner, x right and y up, so the view box spans `0...viewBoxSize.x` by `-viewBoxSize.y...0`.
@MainActor public final class SVGIcon {
  /// One baked region: a union of fills and strokes that share a paint.
  struct Layer {
    /// Em space bounds of the baked region, y up. The outline plus padding.
    var boundsMin = float2()
    var boundsMax = float2()
    /// Atlas uv of the centers of the region's top left and bottom right texels.
    var uvMin = float2()
    var uvMax = float2()
    /// Nil for `currentColor`, which is the image's foreground color.
    var color: float4?
    /// What `currentColor` is multiplied by: fill or stroke opacity times group opacity.
    var opacity: Float = 1

    /// The color to draw with, given the image's foreground color and whether it is a template,
    /// which draws everything in the foreground color.
    func resolvedColor(foreground: float4, template: Bool) -> float4 {
      if let color = self.color, !template {
        return color
      }
      let alpha = self.color.map(\.w) ?? self.opacity
      return float4(foreground.x, foreground.y, foreground.z, foreground.w * alpha)
    }
  }

  /// Resolution of the baked distance field: twice what glyphs get, as icons are drawn larger.
  static let texelsPerEm: Float = 128
  /// Largest region a layer may take in the atlas, per axis; a layer can reach a little past
  /// the view box.
  private static let maxRegionTexels = 1024
  /// How far, in em, a curve may stray from the cubic it approximates: a quarter texel.
  private static let curveTolerance: Float = 0.25 / texelsPerEm

  /// The size it is drawn at unless resized: its root's `width` and `height`, or else its view
  /// box's.
  public let naturalSize: float2
  /// In em.
  let viewBoxSize: float2
  let layers: [Layer]

  private init(naturalSize: float2, viewBoxSize: float2, layers: [Layer]) {
    self.naturalSize = naturalSize
    self.viewBoxSize = viewBoxSize
    self.layers = layers
  }

  // MARK: - Loading

  private static var named: [String: SVGIcon] = [:]
  private static var sources: [String: SVGIcon] = [:]
  private static var missing: Set<String> = []

  /// The SVG named `name` in `bundle`: a data asset in its asset catalog, or a `.svg` file
  /// among its resources. Nil when there is neither, so the name can be looked for as a bitmap.
  static func named(_ name: String, bundle: Bundle) -> SVGIcon? {
    let key = bundle.bundlePath + "|" + name
    if let icon = self.named[key] { return icon }
    guard !self.missing.contains(key) else { return nil }

    var data: Data? = nil
    if let asset = NSDataAsset(name: name, bundle: bundle), self.looksLikeSVG(asset.data) {
      data = asset.data
    } else {
      let resource = name.hasSuffix(".svg") ? String(name.dropLast(4)) : name
      if let url = bundle.url(forResource: resource, withExtension: "svg") {
        data = try? Data(contentsOf: url)
      }
    }
    guard let data, let icon = self.make(data, label: name) else {
      self.missing.insert(key)
      return nil
    }
    self.named[key] = icon
    return icon
  }

  /// The SVG whose markup is `source`, baked once however many images draw it.
  static func source(_ source: String) -> SVGIcon? {
    if let icon = self.sources[source] { return icon }
    guard let icon = self.make(Data(source.utf8), label: "inline source") else { return nil }
    self.sources[source] = icon
    return icon
  }

  private static func looksLikeSVG(_ data: Data) -> Bool {
    data.prefix(4096).range(of: Data("<svg".utf8)) != nil
  }

  // MARK: - Baking

  private static func make(_ data: Data, label: String) -> SVGIcon? {
    guard let document = SVGParser.parse(data, label: label) else { return nil }

    let viewBox = document.viewBox
    let em = max(viewBox.z, viewBox.w)
    // root user space to em space: from the view box's top left corner, y up
    let toEm = SVGTransform(a: 1 / em, d: -1 / em, e: -viewBox.x / em, f: viewBox.y / em)

    // Paint runs: consecutive fills and strokes with the same paint bake as one layer.
    var layers: [Layer] = []
    var run: (color: float4?, opacity: Float, shapes: [SDFShapeGeometry], bounds: CGRect)? = nil

    func flush() {
      guard let current = run else { return }
      run = nil
      guard let region = SDFBaker.shared.bake(
        current.shapes, bounds: current.bounds, texelsPerEm: self.texelsPerEm,
        maxRegionTexels: self.maxRegionTexels, label: "layer \(layers.count) of SVG '\(label)'"
      ) else { return }
      layers.append(Layer(
        boundsMin: region.boundsMin, boundsMax: region.boundsMax,
        uvMin: region.uvMin, uvMax: region.uvMax,
        color: current.color, opacity: current.opacity
      ))
    }

    func add(_ paint: SVGPaint, opacity: Float, _ geometry: SDFShapeGeometry, bounds: CGRect) {
      let color: float4?
      switch paint {
      case .none:
        return
      case .currentColor:
        color = nil
      case .color(let value):
        color = float4(value.x, value.y, value.z, value.w * opacity)
      }
      guard (color?.w ?? opacity) > 0, !bounds.isNull else { return }
      if let current = run, current.color == color, current.opacity == opacity {
        run!.shapes.append(geometry)
        run!.bounds = current.bounds.union(bounds)
      } else {
        flush()
        run = (color, opacity, [geometry], bounds)
      }
    }

    for shape in document.shapes {
      let transform = toEm.concatenating(shape.transform)
      if shape.canFill, shape.fill != .none {
        let (elements, subPaths, bounds) = self.flatten(shape.commands, transform, closing: true)
        if !subPaths.isEmpty {
          let mode: SDFShapeMode = shape.fillEvenOdd ? .fillEvenOdd : .fillNonZero
          add(shape.fill, opacity: shape.fillOpacity,
              SDFShapeGeometry(mode: mode, pathElements: elements, subPaths: subPaths), bounds: bounds)
        }
      }
      let halfWidth = Float(shape.strokeWidth * transform.lengthScale * 0.5)
      if shape.stroke != .none, halfWidth > 0 {
        let (elements, subPaths, bounds) = self.flatten(shape.commands, transform, closing: false)
        if !subPaths.isEmpty {
          let inset = -CGFloat(halfWidth)
          add(shape.stroke, opacity: shape.strokeOpacity,
              SDFShapeGeometry(mode: .stroke, halfWidth: halfWidth, pathElements: elements, subPaths: subPaths),
              bounds: bounds.insetBy(dx: inset, dy: inset))
        }
      }
    }
    flush()

    return SVGIcon(
      naturalSize: float2(Float(document.size.x), Float(document.size.y)),
      viewBoxSize: float2(Float(viewBox.z / em), Float(viewBox.w / em)),
      layers: layers
    )
  }

  /// The commands in em space, and the bounds of their points and control points, which hold
  /// the whole path.
  private static func flatten(
    _ commands: [SVGPathCommand], _ transform: SVGTransform, closing: Bool
  ) -> ([PathElement], [SubPath], CGRect) {
    var builder = SDFPathBuilder(closesOpenSubPaths: closing)
    var minPoint = float2(repeating: .greatestFiniteMagnitude)
    var maxPoint = float2(repeating: -.greatestFiniteMagnitude)
    func map(_ point: SIMD2<Double>) -> float2 {
      let p = transform.apply(point)
      let result = float2(Float(p.x), Float(p.y))
      minPoint = simd_min(minPoint, result)
      maxPoint = simd_max(maxPoint, result)
      return result
    }

    for command in commands {
      switch command {
      case .move(let p):
        builder.move(to: map(p))
      case .line(let p):
        builder.line(to: map(p))
      case .quad(let c, let p):
        builder.quad(map(c), map(p))
      case .cubic(let c1, let c2, let p):
        builder.cubic(map(c1), map(c2), map(p), tolerance: self.curveTolerance)
      case .close:
        builder.close()
      }
    }
    let (elements, subPaths) = builder.finish()
    guard !subPaths.isEmpty, minPoint.x <= maxPoint.x else { return ([], [], .null) }
    let bounds = CGRect(
      x: CGFloat(minPoint.x), y: CGFloat(minPoint.y),
      width: CGFloat(maxPoint.x - minPoint.x), height: CGFloat(maxPoint.y - minPoint.y)
    )
    return (elements, subPaths, bounds)
  }
}
