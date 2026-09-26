import AppKit
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

/// A glyph of a concrete face: the run font CoreText picked, which may be a fallback, as
/// `FontManager.faceKey` names it.
private struct GlyphKey: Hashable {
  var face: Int32
  var glyph: CGGlyph
}

@MainActor public final class FontManager {
  public static let shared = FontManager()
  /// TrueType, so its outlines are quadratic, and present on every Mac. What `SDFFont`s fall back
  /// to; `.system` text is San Francisco.
  public static var defaultFontName = "Menlo"

  public lazy var defaultFont: SDFFont = self.font(named: Self.defaultFontName)

  /// Resolution of the baked distance field.
  static let texelsPerEm: Float = 64
  /// Largest region a glyph may take in the atlas, per axis. A real glyph at 64 texels per em
  /// is well under this; anything bigger means CoreText handed back a bogus outline.
  private static let maxRegionTexels = 512
  /// How far an oblique face leans: x moves this much per unit of y, as a synthesized italic.
  static let obliqueShear: CGFloat = 0.2
  /// Faces kept resolved. Sizes vary without bound — `minimumScaleFactor` shapes at sizes of its
  /// own — so the memo is dropped whole when it grows past this.
  private static let maxFaces = 256

  private var fonts: [String: SDFFont] = [:]
  private var glyphs: [GlyphKey: GlyphMetrics] = [:]
  private var faces: [TextFont: ResolvedFace] = [:]
  /// Face keys by run font, looked up once per CoreText run. The font is held so its identifier
  /// stays its own.
  private var runFaces: [ObjectIdentifier: (font: CTFont, oblique: Int32, upright: Int32)] = [:]
  private var faceKeys: [String: Int32] = [:]

  private init() {}

  public func font(named name: String) -> SDFFont {
    if let font = self.fonts[name] {
      return font
    }

    let font = SDFFont(name: name)
    self.fonts[name] = font
    return font
  }

  // MARK: - Faces

  /// The CoreText font `font` draws with.
  func face(for font: TextFont) -> ResolvedFace {
    if let face = self.faces[font] {
      return face
    }
    if self.faces.count >= Self.maxFaces {
      self.faces.removeAll(keepingCapacity: true)
    }
    let face = Self.makeFace(font)
    self.faces[font] = face
    return face
  }

  private static func makeFace(_ font: TextFont) -> ResolvedFace {
    let size = CGFloat(max(font.size, 0))
    var ctFont: CTFont
    switch font.face {
    case .system(let design):
      let system = NSFont.systemFont(ofSize: size, weight: (font.weight ?? .regular).systemWeight)
      var made: NSFont? = system
      if let systemDesign = design.systemDesign, let descriptor = system.fontDescriptor.withDesign(systemDesign) {
        made = NSFont(descriptor: descriptor, size: size)
      }
      ctFont = (made ?? system) as CTFont
      ctFont = Self.pinnedOpticalSize(ctFont, size: size)
    case .custom(let face):
      ctFont = CTFontCreateWithName(face.name as CFString, size, nil)
      if let weight = font.weight {
        let family = CTFontCopyFamilyName(ctFont) as String
        if let weighted = NSFontManager.shared.font(withFamily: family, traits: [], weight: weight.familyWeight, size: size) {
          ctFont = weighted as CTFont
        }
      }
    }

    var oblique = false
    if font.isItalic, !CTFontGetSymbolicTraits(ctFont).contains(.traitItalic) {
      if let italic = CTFontCreateCopyWithSymbolicTraits(ctFont, size, nil, .traitItalic, .traitItalic),
         CTFontGetSymbolicTraits(italic).contains(.traitItalic) {
        ctFont = italic
      } else {
        oblique = true
      }
    }

    if font.isMonospacedDigit {
      let feature: [CFString: Any] = [
        kCTFontFeatureTypeIdentifierKey: kNumberSpacingType,
        kCTFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector,
      ]
      let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontFeatureSettingsAttribute: [feature]] as CFDictionary)
      ctFont = CTFontCreateCopyWithAttributes(ctFont, size, nil, descriptor)
    }

    return ResolvedFace(font: ctFont, oblique: oblique)
  }

  /// San Francisco's outlines change with size, along its optical size axis, under one PostScript
  /// name. Pinned to two instances — text below 20pt, display from there — so the atlas holds two
  /// of each glyph rather than one per size drawn.
  private static func pinnedOpticalSize(_ font: CTFont, size: CGFloat) -> CTFont {
    let opsz = NSNumber(value: 0x6F70_737A)
    guard var variation = CTFontCopyVariation(font) as? [NSNumber: NSNumber], variation[opsz] != nil else {
      return font
    }
    variation[opsz] = NSNumber(value: size < 20 ? 17 : 28)
    let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontVariationAttribute: variation] as CFDictionary)
    return CTFontCreateCopyWithAttributes(font, size, nil, descriptor)
  }

  /// Names the concrete face `font` draws: its PostScript name, which a variable font shares
  /// between instances, plus its variation, plus the slant. Glyphs are cached by it.
  func faceKey(for font: CTFont, oblique: Bool) -> Int32 {
    let id = ObjectIdentifier(font)
    if let entry = self.runFaces[id] {
      return oblique ? entry.oblique : entry.upright
    }
    if self.runFaces.count >= Self.maxFaces {
      self.runFaces.removeAll(keepingCapacity: true)
    }

    var name = CTFontCopyPostScriptName(font) as String
    if let variation = CTFontCopyVariation(font) as? [NSNumber: NSNumber] {
      for axis in variation.keys.sorted(by: { $0.intValue < $1.intValue }) {
        name += " \(axis)=\(variation[axis]!)"
      }
    }
    let upright = self.intern(name)
    let slanted = self.intern(name + " oblique")
    self.runFaces[id] = (font, slanted, upright)
    return oblique ? slanted : upright
  }

  private func intern(_ name: String) -> Int32 {
    if let key = self.faceKeys[name] {
      return key
    }
    let key = Int32(self.faceKeys.count)
    self.faceKeys[name] = key
    return key
  }

  // MARK: - Glyphs

  /// Metrics of `glyph` in `font`, queueing its bake the first time it is seen. `font` can be at
  /// any size; the outline is scaled to em. `face` is `faceKey(for: font, oblique:)`.
  func glyphMetrics(face: Int32, font: CTFont, glyph: CGGlyph, oblique: Bool) -> GlyphMetrics {
    let key = GlyphKey(face: face, glyph: glyph)
    if let metrics = self.glyphs[key] {
      return metrics
    }

    let metrics = self.makeGlyph(font: font, glyph: glyph, oblique: oblique)
    self.glyphs[key] = metrics
    return metrics
  }

  private func makeGlyph(font: CTFont, glyph: CGGlyph, oblique: Bool) -> GlyphMetrics {
    // the outline in em, whatever size the run font was made at, leaning when synthesized italic
    let scale = 1 / CTFontGetSize(font)
    var transform = CGAffineTransform(a: scale, b: 0, c: oblique ? scale * Self.obliqueShear : 0, d: scale, tx: 0, ty: 0)
    guard let outline = CTFontCreatePathForGlyph(font, glyph, &transform), !outline.isEmpty else {
      return GlyphMetrics()
    }
    // A variable font's contours overlap — San Francisco's B is a stem with two bowls laid over
    // it. The winding rule fills them right, but the distance is to the nearest edge, and edges
    // inside the ink would draw as hairlines: merged into one outline first.
    let path = outline.normalized(using: .winding)
    let (pathElements, subPaths) = Self.flatten(path)
    guard !subPaths.isEmpty else {
      return GlyphMetrics()
    }

    guard let region = SDFBaker.shared.bake(
      [SDFShapeGeometry(mode: .fillNonZero, pathElements: pathElements, subPaths: subPaths)],
      bounds: path.boundingBoxOfPath, texelsPerEm: Self.texelsPerEm,
      maxRegionTexels: Self.maxRegionTexels, label: "glyph \(glyph) of '\(CTFontCopyPostScriptName(font))'"
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

/// An installed face, by name. Draw with it through `TextFont.custom(_:size:)`.
@MainActor public final class SDFFont: nonisolated Hashable, Sendable {
  public let name: String

  fileprivate init(name: String) {
    self.name = name
  }

  nonisolated public static func == (lhs: SDFFont, rhs: SDFFont) -> Bool {
    lhs === rhs
  }

  nonisolated public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

extension TextFont.Design {
  var systemDesign: NSFontDescriptor.SystemDesign? {
    switch self {
    case .default: nil
    case .serif: .serif
    case .rounded: .rounded
    case .monospaced: .monospaced
    }
  }
}
