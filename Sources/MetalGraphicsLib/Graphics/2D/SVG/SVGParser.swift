import Foundation
import simd

/// What a fill or stroke is painted with.
enum SVGPaint: Equatable {
  case none
  /// The element's foreground color, which `Image.foregroundColor` sets.
  case currentColor
  case color(float4)
}

/// One `path`, `rect`, `circle`, `ellipse`, `line`, `polyline` or `polygon`, with the style it
/// ended up with after inheritance.
struct SVGShape {
  /// In the shape's own user space; `transform` takes it to the root's.
  var commands: [SVGPathCommand]
  var transform: SVGTransform
  var fill: SVGPaint
  var fillEvenOdd: Bool
  /// Fill opacity times the opacity of the shape and every group around it.
  var fillOpacity: Float
  var stroke: SVGPaint
  var strokeWidth: Double
  var strokeOpacity: Float
  /// `line` has no inside to fill.
  var canFill: Bool
}

struct SVGDocument {
  /// In root user units: x, y, width, height.
  var viewBox: SIMD4<Double>
  /// The size the root asks to be drawn at, in points.
  var size: SIMD2<Double>
  var shapes: [SVGShape]
}

/// The presentation attributes that inherit, as they stand at one element.
private struct SVGStyle {
  var fill: SVGPaint = .color(float4(0, 0, 0, 1))
  var fillEvenOdd = false
  var fillOpacity: Float = 1
  var stroke: SVGPaint = .none
  var strokeWidth: Double = 1
  var strokeOpacity: Float = 1
  /// `opacity` does not inherit, but a group's applies to all it holds, so it multiplies down.
  var opacity: Float = 1
  var transform = SVGTransform.identity
  /// `display: none` hides everything under it, whatever it says.
  var displayNone = false
  var visible = true
}

/// Parses the subset of SVG that icons use: shapes and paths, groups, transforms, solid fills
/// and strokes. Whatever else there is — gradients, `use`, clipping, masks, text, `<style>` —
/// is skipped, and said once per document.
final class SVGParser: NSObject, XMLParserDelegate {
  private var styles: [SVGStyle] = [SVGStyle()]
  /// Depth inside an element whose content is skipped, 0 outside one.
  private var skipDepth = 0
  private var sawRoot = false
  private var viewBox: SIMD4<Double>? = nil
  private var width: Double? = nil
  private var height: Double? = nil
  private var shapes: [SVGShape] = []
  private(set) var unsupported: Set<String> = []

  /// Elements whose content is never drawn directly: definitions, and metadata.
  private static let skippedSilently: Set<String> = ["title", "desc", "metadata", "defs", "symbol"]
  private static let skipped: Set<String> = [
    "linearGradient", "radialGradient", "pattern", "clipPath", "mask", "filter", "marker",
    "style", "text", "image", "foreignObject", "script", "switch",
  ]

  static func parse(_ data: Data, label: String) -> SVGDocument? {
    let delegate = SVGParser()
    let parser = XMLParser(data: data)
    parser.shouldProcessNamespaces = true
    parser.delegate = delegate
    guard parser.parse(), delegate.sawRoot else {
      print("SVG '\(label)' could not be read: \(parser.parserError.map(String.init(describing:)) ?? "no <svg> element")")
      return nil
    }
    if !delegate.unsupported.isEmpty {
      print("SVG '\(label)' uses what icons are not drawn with, which is skipped: \(delegate.unsupported.sorted().joined(separator: ", "))")
    }

    var viewBox = delegate.viewBox
    if viewBox == nil, let width = delegate.width, let height = delegate.height {
      viewBox = SIMD4(0, 0, width, height)
    }
    guard let viewBox, viewBox.z > 0, viewBox.w > 0 else {
      print("SVG '\(label)' has neither a viewBox nor a width and height; drawing it as 24x24")
      return SVGDocument(viewBox: SIMD4(0, 0, 24, 24), size: SIMD2(24, 24), shapes: delegate.shapes)
    }
    let size = SIMD2(delegate.width ?? viewBox.z, delegate.height ?? viewBox.w)
    return SVGDocument(viewBox: viewBox, size: size, shapes: delegate.shapes)
  }

  // MARK: - XMLParserDelegate

  func parser(
    _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?, attributes: [String: String] = [:]
  ) {
    if self.skipDepth > 0 {
      self.skipDepth += 1
      return
    }
    if Self.skippedSilently.contains(elementName) || Self.skipped.contains(elementName) {
      if Self.skipped.contains(elementName) {
        self.unsupported.insert("<\(elementName)>")
      }
      self.skipDepth = 1
      return
    }

    var style = self.styles.last!
    self.apply(attributes, to: &style)
    self.styles.append(style)
    guard !style.displayNone, style.visible || elementName == "g" || elementName == "svg" else { return }

    switch elementName {
    case "svg":
      if !self.sawRoot {
        self.sawRoot = true
        self.width = attributes["width"].flatMap(Self.length)
        self.height = attributes["height"].flatMap(Self.length)
        if let viewBox = attributes["viewBox"] {
          var scanner = SVGScanner(viewBox)
          if let x = scanner.number(), let y = scanner.number(), let w = scanner.number(), let h = scanner.number() {
            self.viewBox = SIMD4(x, y, w, h)
          }
        }
      }
    case "g", "a":
      break
    case "path":
      self.add(SVGPathData.parse(attributes["d"] ?? ""), style)
    case "rect":
      self.add(Self.rect(attributes), style)
    case "circle":
      let r = Self.number(attributes["r"])
      self.add(SVGPathData.ellipse(center: Self.point(attributes, "cx", "cy"), radii: SIMD2(r, r)), style)
    case "ellipse":
      let radii = SIMD2(Self.number(attributes["rx"]), Self.number(attributes["ry"]))
      self.add(SVGPathData.ellipse(center: Self.point(attributes, "cx", "cy"), radii: radii), style)
    case "line":
      let commands: [SVGPathCommand] = [.move(Self.point(attributes, "x1", "y1")), .line(Self.point(attributes, "x2", "y2"))]
      self.add(commands, style, canFill: false)
    case "polyline", "polygon":
      var scanner = SVGScanner(attributes["points"] ?? "")
      var commands: [SVGPathCommand] = []
      while let x = scanner.number(), let y = scanner.number() {
        commands.append(commands.isEmpty ? .move(SIMD2(x, y)) : .line(SIMD2(x, y)))
      }
      if elementName == "polygon", !commands.isEmpty {
        commands.append(.close)
      }
      self.add(commands, style)
    default:
      self.unsupported.insert("<\(elementName)>")
    }
  }

  func parser(
    _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?
  ) {
    if self.skipDepth > 0 {
      self.skipDepth -= 1
      return
    }
    if self.styles.count > 1 {
      self.styles.removeLast()
    }
  }

  // MARK: - Shapes

  private func add(_ commands: [SVGPathCommand], _ style: SVGStyle, canFill: Bool = true) {
    guard !commands.isEmpty else { return }
    self.shapes.append(SVGShape(
      commands: commands, transform: style.transform,
      fill: style.fill, fillEvenOdd: style.fillEvenOdd, fillOpacity: style.fillOpacity * style.opacity,
      stroke: style.stroke, strokeWidth: style.strokeWidth, strokeOpacity: style.strokeOpacity * style.opacity,
      canFill: canFill
    ))
  }

  private static func rect(_ attributes: [String: String]) -> [SVGPathCommand] {
    let origin = self.point(attributes, "x", "y")
    let size = SIMD2(self.number(attributes["width"]), self.number(attributes["height"]))
    guard size.x > 0, size.y > 0 else { return [] }
    // A missing radius takes the other's value, and neither may pass the middle of its side.
    var rx = attributes["rx"].flatMap(self.length)
    var ry = attributes["ry"].flatMap(self.length)
    rx = rx ?? ry
    ry = ry ?? rx
    let radii = SIMD2(min(max(rx ?? 0, 0), size.x / 2), min(max(ry ?? 0, 0), size.y / 2))

    let x0 = origin.x, y0 = origin.y, x1 = origin.x + size.x, y1 = origin.y + size.y
    guard radii.x > 0, radii.y > 0 else {
      return [.move(SIMD2(x0, y0)), .line(SIMD2(x1, y0)), .line(SIMD2(x1, y1)), .line(SIMD2(x0, y1)), .close]
    }
    func corner(_ from: SIMD2<Double>, _ to: SIMD2<Double>) -> [SVGPathCommand] {
      SVGPathData.arc(from: from, radii: radii, rotation: 0, largeArc: false, sweep: true, to: to)
    }
    var commands: [SVGPathCommand] = [.move(SIMD2(x0 + radii.x, y0)), .line(SIMD2(x1 - radii.x, y0))]
    commands += corner(SIMD2(x1 - radii.x, y0), SIMD2(x1, y0 + radii.y))
    commands.append(.line(SIMD2(x1, y1 - radii.y)))
    commands += corner(SIMD2(x1, y1 - radii.y), SIMD2(x1 - radii.x, y1))
    commands.append(.line(SIMD2(x0 + radii.x, y1)))
    commands += corner(SIMD2(x0 + radii.x, y1), SIMD2(x0, y1 - radii.y))
    commands.append(.line(SIMD2(x0, y0 + radii.y)))
    commands += corner(SIMD2(x0, y0 + radii.y), SIMD2(x0 + radii.x, y0))
    commands.append(.close)
    return commands
  }

  // MARK: - Style

  private func apply(_ attributes: [String: String], to style: inout SVGStyle) {
    if let transform = attributes["transform"] {
      style.transform = style.transform.concatenating(SVGTransform.parse(transform))
    }

    // `style=""` declarations win over presentation attributes.
    var properties = attributes
    if let declarations = attributes["style"] {
      for declaration in declarations.split(separator: ";") {
        let parts = declaration.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { continue }
        properties[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
      }
    }

    for (name, rawValue) in properties {
      let value = rawValue.trimmingCharacters(in: .whitespaces)
      guard value != "inherit" else { continue }
      switch name {
      case "fill":
        if let paint = self.paint(value) { style.fill = paint }
      case "stroke":
        if let paint = self.paint(value) { style.stroke = paint }
      case "fill-rule":
        style.fillEvenOdd = value == "evenodd"
      case "stroke-width":
        if let width = Self.length(value) { style.strokeWidth = max(width, 0) }
      case "fill-opacity":
        if let opacity = Self.opacity(value) { style.fillOpacity = opacity }
      case "stroke-opacity":
        if let opacity = Self.opacity(value) { style.strokeOpacity = opacity }
      case "opacity":
        if let opacity = Self.opacity(value) { style.opacity *= opacity }
      case "display":
        if value == "none" { style.displayNone = true }
      case "visibility":
        style.visible = value != "hidden" && value != "collapse"
      case "stroke-dasharray":
        if value != "none" { self.unsupported.insert("stroke-dasharray") }
      default:
        break
      }
    }
  }

  private func paint(_ value: String) -> SVGPaint? {
    if value == "none" || value == "transparent" { return SVGPaint.none }
    if value == "currentColor" { return .currentColor }
    if value.hasPrefix("url(") {
      self.unsupported.insert("gradient and pattern paint (drawn in currentColor)")
      return .currentColor
    }
    if let color = Self.color(value) { return .color(color) }
    self.unsupported.insert("color '\(value)'")
    return nil
  }

  // MARK: - Values

  private static func number(_ value: String?) -> Double {
    value.flatMap(self.length) ?? 0
  }

  private static func point(_ attributes: [String: String], _ x: String, _ y: String) -> SIMD2<Double> {
    SIMD2(self.number(attributes[x]), self.number(attributes[y]))
  }

  /// A length in user units. Units other than `px` are taken as user units too, and
  /// percentages are not supported.
  static func length(_ value: String) -> Double? {
    guard !value.hasSuffix("%") else { return nil }
    var scanner = SVGScanner(value)
    return scanner.number()
  }

  private static func opacity(_ value: String) -> Float? {
    if value.hasSuffix("%") {
      return self.length(String(value.dropLast())).map { Float(min(max($0 / 100, 0), 1)) }
    }
    return self.length(value).map { Float(min(max($0, 0), 1)) }
  }

  static func color(_ value: String) -> float4? {
    let value = value.lowercased()
    if value.hasPrefix("#") {
      let hex = Array(value.dropFirst())
      guard hex.allSatisfy(\.isHexDigit) else { return nil }
      func channel(_ digits: ArraySlice<Character>) -> Float {
        let string = digits.count == 1 ? String(digits) + String(digits) : String(digits)
        return Float(UInt8(string, radix: 16) ?? 0) / 255
      }
      switch hex.count {
      case 3, 4:
        return float4(channel(hex[0...0]), channel(hex[1...1]), channel(hex[2...2]), hex.count == 4 ? channel(hex[3...3]) : 1)
      case 6, 8:
        return float4(channel(hex[0...1]), channel(hex[2...3]), channel(hex[4...5]), hex.count == 8 ? channel(hex[6...7]) : 1)
      default:
        return nil
      }
    }
    if value.hasPrefix("rgb"), let open = value.firstIndex(of: "("), let close = value.lastIndex(of: ")") {
      let parts = value[value.index(after: open)..<close]
        .split(whereSeparator: { $0 == "," || $0 == " " || $0 == "/" })
        .map { $0.trimmingCharacters(in: .whitespaces) }
      guard parts.count == 3 || parts.count == 4 else { return nil }
      var channels: [Float] = []
      for (i, part) in parts.enumerated() {
        let isPercent = part.hasSuffix("%")
        guard let number = Double(isPercent ? String(part.dropLast()) : part) else { return nil }
        let scale: Double = isPercent ? 100 : (i < 3 ? 255 : 1)
        channels.append(Float(min(max(number / scale, 0), 1)))
      }
      return float4(channels[0], channels[1], channels[2], channels.count == 4 ? channels[3] : 1)
    }
    return self.namedColors[value]
  }

  private static let namedColors: [String: float4] = {
    let hex: [String: UInt32] = [
      "black": 0x000000, "white": 0xFFFFFF, "red": 0xFF0000, "green": 0x008000, "blue": 0x0000FF,
      "yellow": 0xFFFF00, "cyan": 0x00FFFF, "aqua": 0x00FFFF, "magenta": 0xFF00FF, "fuchsia": 0xFF00FF,
      "gray": 0x808080, "grey": 0x808080, "silver": 0xC0C0C0, "maroon": 0x800000, "olive": 0x808000,
      "lime": 0x00FF00, "navy": 0x000080, "purple": 0x800080, "teal": 0x008080, "orange": 0xFFA500,
      "pink": 0xFFC0CB, "brown": 0xA52A2A, "gold": 0xFFD700, "indigo": 0x4B0082, "violet": 0xEE82EE,
    ]
    return hex.mapValues {
      float4(Float(($0 >> 16) & 0xFF) / 255, Float(($0 >> 8) & 0xFF) / 255, Float($0 & 0xFF) / 255, 1)
    }
  }()
}
