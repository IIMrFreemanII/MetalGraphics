import simd

/// A glyph's markup and CSS, read: its elements as a flat tree (parents first), and its rules in
/// cascade order, with the keyframes they name. `AnimatedIcon` evaluates them as a browser would
/// the template's: the rules that match the icon's state give each element its values, a
/// changed value moves by its transition, and an animation plays over it.
///
/// Only what the glyphs use is read: `transform`, `transform-origin`, `transform-box`,
/// `opacity`, `stroke-dasharray`, `stroke-dashoffset`, `stroke`, `transition` (and its duration
/// and delay) and `animation`, on selectors of the svg's `data-*` flags and one class.
public final class AnimatedGlyphStyle: @unchecked Sendable {
  public let glyph: AnimatedGlyph
  public let box: SIMD2<Float>
  let nodes: [GlyphNode]
  /// Sorted by specificity, then by order: applying them in turn leaves the winning values.
  let rules: [GlyphRule]
  /// For the eye's pupil: how far it follows the pointer, in box units.
  let pointerReach: SIMD2<Float>?
  /// Nodes whose outline changes with `active` (the play/pause halves).
  let hasMorph: Bool

  static let all: [AnimatedGlyphStyle] = AnimatedGlyph.allCases.map { AnimatedGlyphStyle($0) }

  static let keyframes: [String: GlyphKeyframes] = Dictionary(
    uniqueKeysWithValues: AnimatedGlyphSource.keyframes.map { ($0.name, GlyphKeyframes(name: $0.name, css: $0.body)) }
  )

  init(_ glyph: AnimatedGlyph) {
    let source = glyph.source
    self.glyph = glyph
    self.box = source.box
    self.pointerReach = source.pointer
    let markup = #"<g class="press"><g class="st"><g class="hov">"# + source.markup + "</g></g></g>"
    var nodes = GlyphMarkup.parse(markup, weight: source.weight == 0 ? 1 : source.weight)
    for i in nodes.indices {
      if let cls = nodes[i].classes.first(where: { source.morphs[$0] != nil }) { nodes[i].morph = source.morphs[cls] }
    }
    self.nodes = nodes
    self.hasMorph = nodes.contains { $0.morph != nil }

    var rules: [GlyphRule] = []
    for css in AnimatedGlyphSource.base + source.css {
      rules += GlyphCSS.rules(css, box: source.box, order: rules.count)
    }
    self.rules = rules.sorted { ($0.specificity, $0.order) < ($1.specificity, $1.order) }
  }
}

// MARK: - The tree

/// One element of a glyph: a group or a shape, with its presentation attributes resolved
/// through its ancestors.
struct GlyphNode {
  enum Shape {
    case group
    case path(String)
    case circle(center: SIMD2<Float>, radius: Float)
    case rect(origin: SIMD2<Float>, size: SIMD2<Float>, radius: Float)
    case text(GlyphText)
  }

  var shape: Shape
  var classes: [String]
  var parent: Int
  /// Its fill and stroke paint; `.current` resolved to its colour, so only the icon's own colour
  /// and the theme are left to resolve when drawn.
  var fill: GlyphColor
  var stroke: GlyphColor
  var strokeWidth: Float
  /// The `opacity` attribute: what CSS starts from.
  var opacity: Float
  /// The `transform` attribute, as a map of box units: used unless CSS sets a transform.
  var attrTransform: (linear: simd_float2x2, translation: SIMD2<Float>)?
  var pathLength: Float?
  /// The outline when active, for a node that morphs.
  var morph: String?
  /// Its own box, for `transform-box: fill-box`.
  var bounds: (min: SIMD2<Float>, max: SIMD2<Float>)

  var isGroup: Bool { if case .group = self.shape { true } else { false } }
}

/// A line of text in a glyph (a PDF's, a language's badge): drawn as its outline.
struct GlyphText: Hashable {
  var string: String
  /// Where its middle and its central baseline meet.
  var anchor: SIMD2<Float>
  var size: Float
  var serif: Bool
}

/// A glyph's paint.
public indirect enum GlyphColor: Equatable, Sendable {
  case none
  /// `currentColor`: the icon's colour, or an ancestor's `color`.
  case current
  case hue(ThemeHue)
  case role(ThemeColor)
  /// A colour the template writes out: a language badge's letters.
  case literal(SIMD4<Float>)
  /// A colour the page can set on the icon (`--mgi-fill` and the rest), else `fallback`.
  case tint(GlyphTint, fallback: GlyphColor)

  /// With `.current` replaced by `color`.
  func resolvingCurrent(_ color: GlyphColor) -> GlyphColor {
    switch self {
    case .current: color
    case .tint(let t, let fallback): .tint(t, fallback: fallback.resolvingCurrent(color))
    default: self
    }
  }
}

/// The colours a page can give an icon's parts, as the template's CSS variables: a split's or a
/// dock's fill (`--mgi-fill`), the bell's badge (`--mgi-badge`), the copied check
/// (`--mgi-check`), the Swift bird (`--mgi-swift`), a document's type (`--mgi-ft`).
public enum GlyphTint: Int, CaseIterable, Sendable {
  case fill, badge, check, swift, fileType

  var variable: String {
    switch self {
    case .fill: "--mgi-fill"
    case .badge: "--mgi-badge"
    case .check: "--mgi-check"
    case .swift: "--mgi-swift"
    case .fileType: "--mgi-ft"
    }
  }
}

// MARK: - Rules

/// The svg's flags a selector reads.
enum GlyphFlag: Int, CaseIterable {
  case hover, hovering, press, active, to, loop, mount
}

enum GlyphCondition: Equatable {
  case has(GlyphFlag)
  case lacks(GlyphFlag)
  /// `[data-active="v"]`, `[data-to="v"]`.
  case equals(GlyphFlag, String)
  /// `:not([data-active="v"])`.
  case differs(GlyphFlag, String)
}

/// The properties that change over time.
enum GlyphProperty: Int, CaseIterable {
  case transform, opacity, dashOffset, dashArray
}

enum GlyphLength: Equatable {
  case px(Float)
  case percent(Float)
}

enum GlyphDeclaration {
  case transform(GlyphTransform)
  /// `translate(var(--mgi-px), var(--mgi-py))`: the pointer's offset.
  case pointerTransform
  case origin(GlyphLength, GlyphLength)
  case fillBox(Bool)
  case opacity(Float)
  case dashOffset(Float)
  case dashArray(SIMD2<Float>)
  case stroke(GlyphColor)
  /// The shorthand: properties (nil for one not animated here), durations and delays in seconds.
  case transition(properties: [GlyphProperty?], durations: [Float], easings: [GlyphEasing], delays: [Float])
  case transitionDuration([Float])
  case transitionDelay([Float])
  case animation(GlyphAnimation?)
}

struct GlyphRule {
  enum Target: Equatable {
    case any
    case group
    case className(String)
  }

  var conditions: [GlyphCondition]
  var target: Target
  var declarations: [GlyphDeclaration]
  var specificity: Int
  var order: Int

  func matches(_ node: GlyphNode) -> Bool {
    switch self.target {
    case .any: true
    case .group: node.isGroup
    case .className(let name): node.classes.contains(name)
    }
  }
}

/// An `animation` shorthand, its keyframes looked up. Times in seconds at speed 1.
struct GlyphAnimation {
  var keyframes: GlyphKeyframes
  var duration: Float
  var delay: Float
  var easing: GlyphEasing
  var iterations: Float
  var fillsBackwards: Bool
  var fillsForwards: Bool
}

/// `@keyframes`, per property: its stops, in offset order.
final class GlyphKeyframes: @unchecked Sendable {
  let name: String
  /// Indexed by `GlyphProperty`: (offset, packed value).
  let stops: [[(offset: Float, value: SIMD8<Float>)]]

  init(name: String, css: String) {
    self.name = name
    var stops = [[(offset: Float, value: SIMD8<Float>)]](repeating: [], count: GlyphProperty.allCases.count)
    for block in GlyphCSS.blocks(css) {
      let offsets = block.selector.split(separator: ",").map { s -> Float in
        let s = s.trimmingCharacters(in: .whitespaces)
        if s == "from" { return 0 }
        if s == "to" { return 1 }
        return (Float(s.dropLast()) ?? 0) / 100
      }
      for decl in GlyphCSS.declarations(block.body, box: .zero) {
        let (property, value): (GlyphProperty, SIMD8<Float>)
        switch decl {
        case .transform(let t): (property, value) = (.transform, t.packed)
        case .opacity(let o): (property, value) = (.opacity, SIMD8(repeating: 0).replacing(with: o, at: 0))
        case .dashOffset(let o): (property, value) = (.dashOffset, SIMD8(repeating: 0).replacing(with: o, at: 0))
        case .dashArray(let a): (property, value) = (.dashArray, SIMD8(a.x, a.y, 0, 0, 0, 0, 0, 0))
        default: continue
        }
        for offset in offsets { stops[property.rawValue].append((offset, value)) }
      }
    }
    self.stops = stops.map { $0.sorted { $0.offset < $1.offset } }
  }
}

extension SIMD8<Float> {
  fileprivate func replacing(with value: Float, at index: Int) -> Self {
    var copy = self
    copy[index] = value
    return copy
  }
}

// MARK: - Reading the markup

enum GlyphMarkup {
  /// Parses the template's SVG elements into nodes, inheriting paint as SVG does: fill none,
  /// stroke `currentColor` at `weight`, from the svg.
  static func parse(_ markup: String, weight: Float) -> [GlyphNode] {
    var nodes: [GlyphNode] = []
    // what each open element passes to its children
    struct Inherited { var fill: GlyphColor; var stroke: GlyphColor; var width: Float; var color: GlyphColor }
    var stack: [(index: Int, inherited: Inherited)] = []
    let root = Inherited(fill: .none, stroke: .current, width: weight, color: .current)

    var scanner = Substring(markup)
    while let open = scanner.firstIndex(of: "<") {
      scanner = scanner[open...]
      guard let close = scanner.firstIndex(of: ">") else { break }
      let tag = scanner[scanner.index(after: scanner.startIndex)..<close]
      scanner = scanner[scanner.index(after: close)...]
      if tag.hasPrefix("/") {
        _ = stack.popLast()
        continue
      }
      let selfClosing = tag.hasSuffix("/")
      let body = selfClosing ? tag.dropLast() : tag
      let name = body.prefix { !$0.isWhitespace }
      let attrs = Self.attributes(body.dropFirst(name.count))
      let inherited = stack.last?.inherited ?? root
      var style: [String: String] = [:]
      for decl in (attrs["style"] ?? "").split(separator: ";") {
        let pair = decl.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        if pair.count == 2 { style[pair[0]] = pair[1] }
      }

      let color = (style["color"]).map(GlyphCSS.color) ?? inherited.color
      let fill = (style["fill"] ?? attrs["fill"]).map(GlyphCSS.color) ?? inherited.fill
      let stroke = (style["stroke"] ?? attrs["stroke"]).map(GlyphCSS.color) ?? inherited.stroke
      let width = attrs["stroke-width"].flatMap { Float($0) } ?? inherited.width
      func f(_ key: String) -> Float { attrs[key].flatMap { Float($0) } ?? 0 }

      var text: GlyphText? = nil
      if name == "text", !selfClosing, let end = scanner.range(of: "</text>") {
        text = GlyphText(
          string: String(scanner[..<end.lowerBound]).replacingOccurrences(of: "&gt;", with: ">"),
          anchor: SIMD2(f("x"), f("y")), size: f("font-size"),
          serif: (attrs["font-family"] ?? "").hasPrefix("Georgia")
        )
        scanner = scanner[end.upperBound...]
      }

      let shape: GlyphNode.Shape
      var bounds = (min: SIMD2<Float>(0, 0), max: SIMD2<Float>(0, 0))
      switch name {
      case "path":
        shape = .path(attrs["d"] ?? "")
      case "circle":
        let c = SIMD2(f("cx"), f("cy")), r = f("r")
        shape = .circle(center: c, radius: r)
        bounds = (c - r, c + r)
      case "rect":
        let o = SIMD2(f("x"), f("y")), s = SIMD2(f("width"), f("height"))
        shape = .rect(origin: o, size: s, radius: f("rx"))
        bounds = (o, o + s)
      case "text":
        shape = .text(text ?? GlyphText(string: "", anchor: .zero, size: 0, serif: false))
      default:
        shape = .group
      }

      let node = GlyphNode(
        shape: shape,
        classes: (attrs["class"] ?? "").split(separator: " ").map(String.init),
        parent: stack.last?.index ?? -1,
        fill: fill.resolvingCurrent(color),
        stroke: stroke.resolvingCurrent(color),
        strokeWidth: width,
        opacity: attrs["opacity"].flatMap { Float($0) } ?? 1,
        attrTransform: attrs["transform"].map(GlyphCSS.matrix),
        pathLength: attrs["pathLength"].flatMap { Float($0) },
        morph: nil,
        bounds: bounds
      )
      nodes.append(node)
      if !selfClosing, name != "text" {
        // children inherit the specified paint, currentColor unresolved
        stack.append((nodes.count - 1, Inherited(fill: fill, stroke: stroke, width: width, color: color)))
      }
    }
    return nodes
  }

  /// `name="value"` pairs. A repeated attribute keeps its first value, as an HTML parser does
  /// (the font glyph's second `font-family` is ignored in the browser too).
  private static func attributes(_ s: Substring) -> [String: String] {
    var attrs: [String: String] = [:]
    var rest = s
    while let eq = rest.firstIndex(of: "=") {
      let key = rest[..<eq].trimmingCharacters(in: .whitespaces)
      rest = rest[rest.index(after: eq)...]
      guard let q1 = rest.firstIndex(of: "\"") else { break }
      rest = rest[rest.index(after: q1)...]
      guard let q2 = rest.firstIndex(of: "\"") else { break }
      if attrs[key] == nil { attrs[key] = String(rest[..<q2]) }
      rest = rest[rest.index(after: q2)...]
    }
    return attrs
  }
}

// MARK: - Reading the CSS

enum GlyphCSS {
  /// `selector{body}` blocks, in order.
  static func blocks(_ css: String) -> [(selector: String, body: String)] {
    var out: [(String, String)] = []
    var rest = Substring(css)
    while let open = rest.firstIndex(of: "{") {
      // the body ends at the brace that closes this one
      var depth = 0
      var end = open
      for i in rest[open...].indices {
        if rest[i] == "{" { depth += 1 }
        if rest[i] == "}" { depth -= 1; if depth == 0 { end = i; break } }
      }
      out.append((rest[..<open].trimmingCharacters(in: .whitespaces), String(rest[rest.index(after: open)..<end])))
      rest = rest[rest.index(after: end)...]
    }
    return out
  }

  /// A rule's selectors, one `GlyphRule` each; rules without a descendant (the svg's own) are
  /// dropped, and comments skipped.
  static func rules(_ css: String, box: SIMD2<Float>, order: Int) -> [GlyphRule] {
    guard !css.hasPrefix("/*") else { return [] }
    var out: [GlyphRule] = []
    for block in self.blocks(css) {
      let declarations = self.declarations(block.body, box: box)
      for selector in self.split(block.selector, on: ",") {
        let parts = selector.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count == 2 else { continue }
        var conditions: [GlyphCondition] = []
        var specificity = 100  // .mgi or .mgi-name
        var svg = parts[0].drop { $0 != "[" && $0 != ":" }
        while !svg.isEmpty {
          let negated = svg.hasPrefix(":not(")
          if negated { svg = svg.dropFirst(5) }
          guard svg.hasPrefix("["), let close = svg.firstIndex(of: "]") else { break }
          let attr = svg[svg.index(after: svg.startIndex)..<close]
          svg = svg[svg.index(after: close)...]
          if negated, svg.hasPrefix(")") { svg = svg.dropFirst() }
          specificity += 100
          let pair = attr.split(separator: "=", maxSplits: 1)
          guard let flag = self.flag(String(pair[0])) else { continue }
          if pair.count == 2 {
            let value = pair[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            conditions.append(negated ? .differs(flag, value) : .equals(flag, value))
          } else {
            conditions.append(negated ? .lacks(flag) : .has(flag))
          }
        }
        let target: GlyphRule.Target
        switch parts[1] {
        case "*": target = .any
        case "g": target = .group; specificity += 1
        default: target = .className(String(parts[1].dropFirst())); specificity += 100
        }
        out.append(GlyphRule(conditions: conditions, target: target, declarations: declarations, specificity: specificity, order: order + out.count))
      }
    }
    return out
  }

  private static func flag(_ attribute: String) -> GlyphFlag? {
    switch attribute {
    case "data-hover": .hover
    case "data-hovering": .hovering
    case "data-press": .press
    case "data-active": .active
    case "data-to": .to
    case "data-loop": .loop
    case "data-mount": .mount
    default: nil
    }
  }

  static func declarations(_ body: String, box: SIMD2<Float>) -> [GlyphDeclaration] {
    var out: [GlyphDeclaration] = []
    for decl in self.split(body, on: ";") {
      guard let colon = decl.firstIndex(of: ":") else { continue }
      let name = decl[..<colon].trimmingCharacters(in: .whitespaces)
      let value = decl[decl.index(after: colon)...].trimmingCharacters(in: .whitespaces)
      switch name {
      case "transform":
        out.append(value.contains("--mgi-px") ? .pointerTransform : .transform(self.transform(value)))
      case "transform-origin":
        let parts = value.split(separator: " ").map(String.init)
        if value == "var(--c)" {
          out.append(.origin(.px(box.x / 2), .px(box.y / 2)))
        } else if parts.count == 2 {
          out.append(.origin(self.length(parts[0]), self.length(parts[1])))
        }
      case "transform-box":
        out.append(.fillBox(value == "fill-box"))
      case "opacity":
        out.append(.opacity(Float(value) ?? 1))
      case "stroke-dashoffset":
        out.append(.dashOffset(Float(value) ?? 0))
      case "stroke-dasharray":
        let n = value.split(separator: " ").compactMap { Float($0) }
        if n.count == 2 { out.append(.dashArray(SIMD2(n[0], n[1]))) }
      case "stroke":
        out.append(.stroke(self.color(value)))
      case "transition":
        var properties: [GlyphProperty?] = [], durations: [Float] = [], easings: [GlyphEasing] = [], delays: [Float] = []
        for item in self.split(value, on: ",") {
          let tokens = self.split(item, on: " ")
          properties.append(self.property(tokens.first ?? ""))
          let times = tokens.dropFirst().compactMap(self.time)
          durations.append(times.first ?? 0)
          delays.append(times.count > 1 ? times[1] : 0)
          easings.append(tokens.dropFirst().compactMap(self.easing).first ?? .ease)
        }
        out.append(.transition(properties: properties, durations: durations, easings: easings, delays: delays))
      case "transition-duration":
        out.append(.transitionDuration(self.split(value, on: ",").compactMap(self.time)))
      case "transition-delay":
        out.append(.transitionDelay(self.split(value, on: ",").compactMap(self.time)))
      case "animation":
        out.append(.animation(self.animation(value)))
      default:
        break
      }
    }
    return out
  }

  private static func property(_ name: String) -> GlyphProperty? {
    switch name {
    case "transform": .transform
    case "opacity": .opacity
    case "stroke-dashoffset": .dashOffset
    case "stroke-dasharray": .dashArray
    default: nil
    }
  }

  private static func animation(_ value: String) -> GlyphAnimation? {
    let tokens = self.split(value, on: " ")
    guard let name = tokens.first, name != "none", let keyframes = AnimatedGlyphStyle.keyframes[name] else { return nil }
    let times = tokens.dropFirst().compactMap(self.time)
    let fill = tokens.contains("both") ? "both" : tokens.contains("forwards") ? "forwards" : tokens.contains("backwards") ? "backwards" : "none"
    return GlyphAnimation(
      keyframes: keyframes,
      duration: times.first ?? 0,
      delay: times.count > 1 ? times[1] : 0,
      easing: tokens.dropFirst().compactMap(self.easing).first ?? .ease,
      iterations: tokens.contains("infinite") ? .infinity : 1,
      fillsBackwards: fill == "both" || fill == "backwards",
      fillsForwards: fill == "both" || fill == "forwards"
    )
  }

  /// A time in seconds at speed 1: `calc(560ms*var(--mgi-t,1))`, the spring's
  /// `calc(var(--mgi-sd,…)*…)`, or plain `ms` and `s`.
  static func time(_ token: String) -> Float? {
    if token.hasPrefix("calc(var(--mgi-sd") { return GlyphEasing.springDuration }
    var t = Substring(token)
    if t.hasPrefix("calc(") {
      t = t.dropFirst(5)
      t = t.prefix { $0 != "*" && $0 != ")" }
    }
    if t.hasSuffix("ms"), let v = Float(t.dropLast(2)) { return v / 1000 }
    if t.hasSuffix("s"), let v = Float(t.dropLast()) { return v }
    return nil
  }

  static func easing(_ token: String) -> GlyphEasing? {
    switch token {
    case "linear": return .linear
    case "ease": return .ease
    case "ease-in": return .easeIn
    case "ease-out": return .easeOut
    case "ease-in-out": return .easeInOut
    default:
      if token.hasPrefix("var(--mgi-spring") { return .spring }
      if token.hasPrefix("cubic-bezier(") {
        let n = token.dropFirst(13).dropLast().split(separator: ",").compactMap { Float($0) }
        if n.count == 4 { return .cubic(n[0], n[1], n[2], n[3]) }
      }
      return nil
    }
  }

  private static func length(_ token: String) -> GlyphLength {
    if token.hasSuffix("%") { return .percent((Float(token.dropLast()) ?? 0) / 100) }
    return .px(Float(token.hasSuffix("px") ? String(token.dropLast(2)) : token) ?? 0)
  }

  /// A CSS transform list, written in translate, rotate, skew, scale order (or with an even
  /// scale, which commutes), as one `GlyphTransform`.
  static func transform(_ value: String) -> GlyphTransform {
    var t = GlyphTransform.identity
    for (name, args) in self.functions(value) {
      let a = args.map { Float($0.replacingOccurrences(of: "px", with: "").replacingOccurrences(of: "deg", with: "")) ?? 0 }
      switch name {
      case "translate": t.tx = a.first ?? 0; t.ty = a.count > 1 ? a[1] : 0
      case "translateX": t.tx = a.first ?? 0
      case "translateY": t.ty = a.first ?? 0
      case "rotate": t.rotation = a.first ?? 0
      case "skewX": t.skewX = a.first ?? 0
      case "scale": t.sx = a.first ?? 1; t.sy = a.count > 1 ? a[1] : t.sx
      case "scaleX": t.sx = a.first ?? 1
      case "scaleY": t.sy = a.first ?? 1
      default: break
      }
    }
    return t
  }

  /// An SVG `transform` attribute, composed left to right as SVG does.
  static func matrix(_ value: String) -> (linear: simd_float2x2, translation: SIMD2<Float>) {
    var linear = matrix_identity_float2x2
    var translation = SIMD2<Float>(0, 0)
    func apply(_ l: simd_float2x2, _ t: SIMD2<Float>) {
      // current ∘ (l, t)
      translation = linear * t + translation
      linear = linear * l
    }
    for (name, args) in self.functions(value) {
      let a = args.compactMap { Float($0) }
      switch name {
      case "translate":
        apply(matrix_identity_float2x2, SIMD2(a.first ?? 0, a.count > 1 ? a[1] : 0))
      case "scale":
        let sx = a.first ?? 1, sy = a.count > 1 ? a[1] : sx
        apply(simd_float2x2(diagonal: SIMD2(sx, sy)), .zero)
      case "rotate":
        let r = (a.first ?? 0) * .pi / 180
        let rotation = simd_float2x2(columns: (SIMD2(cos(r), sin(r)), SIMD2(-sin(r), cos(r))))
        let c = a.count == 3 ? SIMD2(a[1], a[2]) : .zero
        apply(rotation, c - rotation * c)
      default:
        break
      }
    }
    return (linear, translation)
  }

  /// `name(args)` pairs; args split on commas and spaces.
  private static func functions(_ value: String) -> [(String, [String])] {
    var out: [(String, [String])] = []
    var rest = Substring(value)
    while let open = rest.firstIndex(of: "(") {
      let name = rest[..<open].trimmingCharacters(in: .whitespaces)
      guard let close = rest[open...].firstIndex(of: ")") else { break }
      let args = rest[rest.index(after: open)..<close].split(whereSeparator: { $0 == "," || $0 == " " }).map(String.init)
      out.append((name, args))
      rest = rest[rest.index(after: close)...]
    }
    return out
  }

  /// A paint: `none`, `currentColor`, a theme variable, a tint variable with its fallback, a hex.
  static func color(_ value: String) -> GlyphColor {
    let v = value.trimmingCharacters(in: .whitespaces)
    if v == "none" { return .none }
    if v == "currentColor" { return .current }
    if v.hasPrefix("var(") {
      let inner = v.dropFirst(4).dropLast()
      let parts = self.split(String(inner), on: ",")
      let name = parts.first ?? ""
      let fallback = parts.count > 1 ? self.color(parts[1...].joined(separator: ",")) : .current
      if let tint = GlyphTint.allCases.first(where: { $0.variable == name }) { return .tint(tint, fallback: fallback) }
      if name.hasPrefix("--mg-hue-") {
        let hue = self.camel(String(name.dropFirst(9)))
        return ThemeHue.allCases.first { "\($0)" == hue }.map(GlyphColor.hue) ?? fallback
      }
      if name.hasPrefix("--mg-color-") {
        let role = self.camel(String(name.dropFirst(11)))
        return ThemeColor.allCases.first { "\($0)" == role }.map(GlyphColor.role) ?? fallback
      }
      return fallback
    }
    if v.hasPrefix("#") {
      var hex = String(v.dropFirst())
      if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
      let n = UInt32(hex, radix: 16) ?? 0
      let c = SIMD4<Float>(Float((n >> 16) & 255), Float((n >> 8) & 255), Float(n & 255), 255) / 255
      return .literal(c)  // design: a language badge's letters, written out by the template
    }
    return .current
  }

  private static func camel(_ kebab: String) -> String {
    let parts = kebab.split(separator: "-")
    return parts.enumerated().map { $0.offset == 0 ? String($0.element) : $0.element.prefix(1).uppercased() + $0.element.dropFirst() }.joined()
  }

  /// Splits on `separator` outside parentheses, trimmed, empties dropped.
  static func split(_ s: String, on separator: Character) -> [String] {
    var out: [String] = []
    var depth = 0
    var current = ""
    for ch in s {
      if ch == "(" { depth += 1 }
      if ch == ")" { depth -= 1 }
      if ch == separator, depth == 0 {
        let t = current.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty { out.append(t) }
        current = ""
      } else {
        current.append(ch)
      }
    }
    let t = current.trimmingCharacters(in: .whitespaces)
    if !t.isEmpty { out.append(t) }
    return out
  }
}
