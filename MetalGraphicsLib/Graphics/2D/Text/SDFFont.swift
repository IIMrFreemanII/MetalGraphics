import CoreText
import MetalKit

// Glyph outlines are baked into the shared SDF atlas (see SDFBaker.swift) the first time they are
// laid out. Ported from SwiftImgui's `Font`, with the per-glyph textures replaced by atlas
// regions and the render pass by the `bakeSDF` kernel.

struct GlyphMetrics {
  /// Em space bounds of the baked region, y up, relative to the glyph origin. The glyph outline
  /// plus padding.
  var boundsMin = float2()
  var boundsMax = float2()
  /// Atlas uv of the centers of the region's top left and bottom right texels.
  var uvMin = float2()
  var uvMax = float2()
  /// False for glyphs that only advance the pen, such as a space.
  var hasOutline = false
}

/// A glyph of a concrete font: the run font CoreText picked, which may be a fallback.
private struct GlyphKey: Hashable {
  var fontName: String
  var glyph: CGGlyph
}

@MainActor public final class FontManager {
  public static let shared = FontManager()
  /// TrueType, so its outlines are quadratic, and present on every Mac.
  public static var defaultFontName = "Menlo"

  public lazy var defaultFont: SDFFont = self.font(named: Self.defaultFontName)

  /// Resolution of the baked distance field.
  static let texelsPerEm: Float = 64
  /// Largest region a glyph may take in the atlas, per axis. A real glyph at 64 texels per em
  /// is well under this; anything bigger means CoreText handed back a bogus outline.
  private static let maxRegionTexels = 512

  private var fonts: [String: SDFFont] = [:]
  private var glyphs: [GlyphKey: GlyphMetrics] = [:]

  private init() {}

  public func font(named name: String) -> SDFFont {
    if let font = self.fonts[name] {
      return font
    }

    let font = SDFFont(name: name)
    self.fonts[name] = font
    return font
  }

  /// Metrics of `glyph` in `font`, queueing its bake the first time it is seen. `font` can be at
  /// any size; the outline is scaled to em.
  func glyphMetrics(font: CTFont, glyph: CGGlyph) -> GlyphMetrics {
    let key = GlyphKey(fontName: CTFontCopyPostScriptName(font) as String, glyph: glyph)
    if let metrics = self.glyphs[key] {
      return metrics
    }

    let metrics = self.makeGlyph(font: font, glyph: glyph, name: key.fontName)
    self.glyphs[key] = metrics
    return metrics
  }

  private func makeGlyph(font: CTFont, glyph: CGGlyph, name: String) -> GlyphMetrics {
    // the outline in em, whatever size the run font was made at
    let scale = 1 / CTFontGetSize(font)
    var transform = CGAffineTransform(scaleX: scale, y: scale)
    guard let path = CTFontCreatePathForGlyph(font, glyph, &transform), !path.isEmpty else {
      return GlyphMetrics()
    }
    let (pathElements, subPaths) = Self.flatten(path)
    guard !subPaths.isEmpty else {
      return GlyphMetrics()
    }

    guard let region = SDFBaker.shared.bake(
      [SDFShapeGeometry(mode: .fillNonZero, pathElements: pathElements, subPaths: subPaths)],
      bounds: path.boundingBoxOfPath, texelsPerEm: Self.texelsPerEm,
      maxRegionTexels: Self.maxRegionTexels, label: "glyph \(glyph) of '\(name)'"
    ) else {
      return GlyphMetrics()
    }

    return GlyphMetrics(
      boundsMin: region.boundsMin, boundsMax: region.boundsMax,
      uvMin: region.uvMin, uvMax: region.uvMax, hasOutline: true
    )
  }

  /// Converts a glyph outline into the element list `bakeSDF` walks. Every subpath ends with a
  /// close element, and cubic curves are approximated by two quadratics.
  private static func flatten(_ path: CGPath) -> ([PathElement], [SubPath]) {
    var builder = SDFPathBuilder()

    path.applyWithBlock { pointer in
      let element = pointer.pointee
      let points = element.points
      func point(_ i: Int) -> float2 {
        float2(Float(points[i].x), Float(points[i].y))
      }

      switch element.type {
      case .moveToPoint:
        builder.move(to: point(0))
      case .addLineToPoint:
        builder.line(to: point(0))
      case .addQuadCurveToPoint:
        builder.quad(point(0), point(1))
      case .addCurveToPoint:
        builder.cubic(point(0), point(1), point(2))
      case .closeSubpath:
        builder.close()
      @unknown default:
        break
      }
    }

    return builder.finish()
  }
}

@MainActor public final class SDFFont {
  public let name: String
  /// Layout runs at the real point size, so CoreText applies the tracking and optical size meant
  /// for it. Glyph outlines are scaled back to em when they are baked.
  private var sizedFonts: [Float: CTFont] = [:]

  fileprivate init(name: String) {
    self.name = name
  }

  func ctFont(size: Float) -> CTFont {
    if let font = self.sizedFonts[size] {
      return font
    }

    let font = CTFontCreateWithName(self.name as CFString, CGFloat(size), nil)
    self.sizedFonts[size] = font
    return font
  }
}
