import Foundation

/// The design system's animated glyphs, as the Claude Design template "Animated icons" draws
/// them: each its own box and stroke, the size of the static `ThemeIcon` of the same name, on one
/// spring. `AnimatedIcon` draws one: it plays as its host (the row, button or link it sits in) is
/// hovered and pressed, holds a state while `active`, loops, and plays an entrance.
///
/// A glyph is data: its markup and CSS, as the template writes them
/// (`AnimatedGlyph+Template.swift`), read once into an `AnimatedGlyphStyle`. The web mirror is
/// generated from the same source (`DesignSystemWeb/generated/animated-icons.json`).
public enum AnimatedGlyph: String, CaseIterable, Sendable {
  case chevronRight, chevronDown, chevronLeft, upDown, checkmark, folder, document, magnifier, xmark, plus, trash, gear
  case searchClear, spinner, copyCheck, bell, lock, eye, playPause, refresh, menuX, warning, error, note, pin, sort
  case stepperMinus, stepperPlus, splitRight, splitBottom, splitLeft, splitTop, sidebarLeft, sidebarRight
  /// A document with its type: Swift's bird, a picture, a film, sound, an archive, code, JSON, a
  /// sheet, a PDF, a font.
  case swift, fileImage, fileVideo, fileAudio, fileArchive, fileCode, fileJSON, fileSheet, filePDF, fileFont
  /// A document with a language's badge.
  case langJS, langTS, langPY, langRS, langGO, langC, langCPP, langRB, langKT, langJava, langMetal, langShell
  /// Ours, in the template's manner: the pickers', the slider's, the toggle's, the editor's, the dock's.
  case calendar, clock, color, slider, toggle, code, dock

  /// The animated glyph of a static icon: the one of the same name.
  public init(_ icon: ThemeIcon) {
    self = AnimatedGlyph(rawValue: "\(icon)")!
  }

  public var source: AnimatedGlyphSource { AnimatedGlyphSource.all[self]! }

  /// Its markup and CSS, read. Built once, on first use.
  public var style: AnimatedGlyphStyle { AnimatedGlyphStyle.all[self.index] }

  /// The glyph's own box, in its units: its size in points at scale 1.
  public var box: SIMD2<Float> { self.source.box }

  /// The components it belongs to, as the Storybook and the web docs name them; empty when none.
  public var component: String { self.source.component }

  /// Whether `active` changes how it looks: a chevron turned, a folder open, a lock undone.
  public var isStateful: Bool { self.source.triggers.contains(.state) }

  var index: Int { Self.indices[self]! }
  private static let indices: [AnimatedGlyph: Int] = Dictionary(uniqueKeysWithValues: allCases.enumerated().map { ($1, $0) })
}

/// What plays a glyph, as the template lists it.
public enum GlyphTrigger: String, Sendable {
  /// Its host's hover: a one-shot as the pointer enters, and a pose held while it stays.
  case hover
  /// Its host's press: the squash, and the glyph's own press motion.
  case press
  /// `active`: an end state held while it is set.
  case state
  /// `loop`: a motion repeated for as long as it is set.
  case loop
  /// `mount`: an entrance as it appears.
  case mount
}

/// A glyph as the template writes it: a box, a stroke width, its SVG parts and its CSS.
public struct AnimatedGlyphSource: Sendable {
  /// The view box, which is also its size in points at scale 1.
  public var box: SIMD2<Float>
  /// The stroke width, in box units; 0 for a glyph only filled (drawn at 1, as the template does).
  public var weight: Float
  public var triggers: [GlyphTrigger]
  /// What `active` means for it ("expanded", "open"); nil when it has no state.
  public var state: String?
  /// Whether the template shows it active by default (the checkmark).
  public var defaultActive: Bool
  public var component: String
  /// SVG elements, inside the template's three groups: `press` > `st` > `hov`.
  public var markup: String
  /// CSS rules for its classes, conditioned on the svg's `data-hover`, `data-hovering`,
  /// `data-press`, `data-active`, `data-to`, `data-loop` and `data-mount`.
  public var css: [String]
  /// For a part whose outline changes with `active`: its class and the outline when active.
  public var morphs: [String: String]
  /// CSS the snippet adds for the web alone (a morph written as a `d` transition).
  public var snippetCSS: [String]
  /// For a part that follows the pointer (the eye's pupil): its reach in box units, x and y.
  public var pointer: SIMD2<Float>?

  init(
    box: SIMD2<Float>, weight: Float, triggers: [GlyphTrigger], state: String? = nil, defaultActive: Bool = false,
    component: String = "", markup: String, css: [String], morphs: [String: String] = [:],
    snippetCSS: [String] = [], pointer: SIMD2<Float>? = nil
  ) {
    self.box = box; self.weight = weight; self.triggers = triggers; self.state = state
    self.defaultActive = defaultActive; self.component = component; self.markup = markup; self.css = css
    self.morphs = morphs; self.snippetCSS = snippetCSS; self.pointer = pointer
  }
}

// MARK: - Values

/// A 2D transform in the order CSS writes it: translate, then rotate, then skew along x, then
/// scale, all about the element's origin. Interpolated component by component, as CSS does
/// between two transform lists of the same functions — which every glyph's are.
public struct GlyphTransform: Equatable, Sendable {
  public var tx: Float = 0, ty: Float = 0
  /// Degrees, clockwise (y points down).
  public var rotation: Float = 0
  /// Degrees.
  public var skewX: Float = 0
  public var sx: Float = 1, sy: Float = 1

  public static let identity = GlyphTransform()

  public init(tx: Float = 0, ty: Float = 0, rotation: Float = 0, skewX: Float = 0, sx: Float = 1, sy: Float = 1) {
    self.tx = tx; self.ty = ty; self.rotation = rotation; self.skewX = skewX; self.sx = sx; self.sy = sy
  }

  public static func translate(_ x: Float, _ y: Float) -> Self { .init(tx: x, ty: y) }
  public static func rotate(_ degrees: Float) -> Self { .init(rotation: degrees) }
  public static func scale(_ x: Float, _ y: Float) -> Self { .init(sx: x, sy: y) }

  public func mix(_ other: Self, _ t: Float) -> Self {
    func m(_ a: Float, _ b: Float) -> Float { a + (b - a) * t }
    return .init(
      tx: m(tx, other.tx), ty: m(ty, other.ty), rotation: m(rotation, other.rotation),
      skewX: m(skewX, other.skewX), sx: m(sx, other.sx), sy: m(sy, other.sy)
    )
  }

  public var isIdentity: Bool { self == .identity }

  /// Packed for interpolation with the other animated values.
  var packed: SIMD8<Float> { SIMD8(tx, ty, rotation, skewX, sx, sy, 0, 0) }
  init(packed v: SIMD8<Float>) { self.init(tx: v[0], ty: v[1], rotation: v[2], skewX: v[3], sx: v[4], sy: v[5]) }
}

/// A glyph's timing curve: a cubic Bézier as CSS writes one, or the template's spring.
public enum GlyphEasing: Equatable, Sendable {
  case linear
  case cubic(Float, Float, Float, Float)
  /// The template's spring, `spring(210, .38)`: under-damped, over its settle time.
  case spring

  public static let ease = GlyphEasing.cubic(0.25, 0.1, 0.25, 1)
  public static let easeIn = GlyphEasing.cubic(0.42, 0, 1, 1)
  public static let easeOut = GlyphEasing.cubic(0, 0, 0.58, 1)
  public static let easeInOut = GlyphEasing.cubic(0.42, 0, 0.58, 1)

  /// The spring the template samples into CSS `linear()`: stiffness and damping ratio.
  public static let springStiffness: Float = 210
  public static let springDamping: Float = 0.38

  /// The spring's settle time in seconds, found as the template's `spring()` finds it: the first
  /// moment it stays within 0.001 of rest, moving under 0.01 a second, for 20 ms (1.338 s).
  public static let springDuration: Float = {
    let k = Double(springStiffness), c = 2 * Double(springDamping) * k.squareRoot(), dt = 1.0 / 2000
    var x = 0.0, v = 0.0, t = 0.0, settle = 0.0
    while t < 3 {
      v += (-k * (x - 1) - c * v) * dt; x += v * dt; t += dt
      if abs(x - 1) < 0.001 && abs(v) < 0.01 {
        if settle == 0 { settle = t }
        if t - settle > 0.02 { break }
      } else {
        settle = 0
      }
    }
    return Float((t * 1000).rounded() / 1000)
  }()

  /// The eased progress at `t` in 0...1.
  public func callAsFunction(_ t: Float) -> Float {
    if t <= 0 { return 0 }
    if t >= 1 { return 1 }
    switch self {
    case .linear:
      return t
    case .spring:
      return Self.spring(t * Self.springDuration, from: 0, velocity: 0, to: 1).x
    case .cubic(let x1, let y1, let x2, let y2):
      // Solve x(u) = t for u by Newton's method, falling back to bisection, then return y(u).
      func bez(_ u: Float, _ a: Float, _ b: Float) -> Float {
        let v = 1 - u
        return 3 * v * v * u * a + 3 * v * u * u * b + u * u * u
      }
      func dbez(_ u: Float, _ a: Float, _ b: Float) -> Float {
        let v = 1 - u
        return 3 * v * v * a + 6 * v * u * (b - a) + 3 * u * u * (1 - b)
      }
      var u = t
      for _ in 0..<6 {
        let d = dbez(u, x1, x2)
        guard abs(d) > 1e-5 else { break }
        u -= (bez(u, x1, x2) - t) / d
      }
      if u < 0 || u > 1 || abs(bez(u, x1, x2) - t) > 1e-4 {
        var lo: Float = 0, hi: Float = 1
        u = t
        for _ in 0..<24 {
          if bez(u, x1, x2) < t { lo = u } else { hi = u }
          u = (lo + hi) / 2
        }
      }
      return bez(u, y1, y2)
    }
  }

  /// An under-damped spring's position and velocity `t` seconds after it left `from` at
  /// `velocity`, heading for `to`.
  static func spring(
    _ t: Float, from: Float, velocity: Float, to: Float,
    stiffness: Float = springStiffness, damping: Float = springDamping
  ) -> (x: Float, v: Float) {
    let w = stiffness.squareRoot(), zw = damping * w, wd = w * (1 - damping * damping).squareRoot()
    let x0 = from - to
    let a = x0, b = (velocity + zw * x0) / wd
    let e = exp(-zw * t), c = cos(wd * t), s = sin(wd * t)
    let x = e * (a * c + b * s)
    let v = e * ((b * wd - zw * a) * c - (a * wd + zw * b) * s)
    return (to + x, v)
  }
}
