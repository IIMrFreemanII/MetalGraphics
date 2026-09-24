import Foundation
import simd

/// An affine transform, SVG's `matrix(a b c d e f)`: `x' = a x + c y + e`, `y' = b x + d y + f`.
struct SVGTransform: Equatable {
  var a: Double = 1, b: Double = 0, c: Double = 0, d: Double = 1, e: Double = 0, f: Double = 0

  static let identity = SVGTransform()

  /// `other` first, then `self`: how a child's `transform` composes with its parent's.
  func concatenating(_ other: SVGTransform) -> SVGTransform {
    SVGTransform(
      a: self.a * other.a + self.c * other.b,
      b: self.b * other.a + self.d * other.b,
      c: self.a * other.c + self.c * other.d,
      d: self.b * other.c + self.d * other.d,
      e: self.a * other.e + self.c * other.f + self.e,
      f: self.b * other.e + self.d * other.f + self.f
    )
  }

  func apply(_ point: SIMD2<Double>) -> SIMD2<Double> {
    SIMD2(self.a * point.x + self.c * point.y + self.e, self.b * point.x + self.d * point.y + self.f)
  }

  /// How much the transform scales lengths, on average over directions.
  var lengthScale: Double {
    abs(self.a * self.d - self.b * self.c).squareRoot()
  }

  /// Parses a `transform` attribute: a list of `matrix`, `translate`, `scale`, `rotate`, `skewX`
  /// and `skewY`, applied right to left. Stops at the first thing it cannot read.
  static func parse(_ string: String) -> SVGTransform {
    var result = SVGTransform.identity
    var scanner = SVGScanner(string)
    while true {
      scanner.skipSeparators()
      guard let name = scanner.identifier() else { break }
      scanner.skipSeparators()
      guard scanner.consume("(") else { break }
      var args: [Double] = []
      while let value = scanner.number() {
        args.append(value)
      }
      scanner.skipSeparators()
      guard scanner.consume(")") else { break }

      let degrees = Double.pi / 180
      var step: SVGTransform
      switch (name, args.count) {
      case ("matrix", 6):
        step = SVGTransform(a: args[0], b: args[1], c: args[2], d: args[3], e: args[4], f: args[5])
      case ("translate", 1), ("translate", 2):
        step = SVGTransform(e: args[0], f: args.count > 1 ? args[1] : 0)
      case ("scale", 1), ("scale", 2):
        step = SVGTransform(a: args[0], d: args.count > 1 ? args[1] : args[0])
      case ("rotate", 1), ("rotate", 3):
        let angle = args[0] * degrees
        step = SVGTransform(a: cos(angle), b: sin(angle), c: -sin(angle), d: cos(angle))
        if args.count == 3 {
          // about (cx, cy): translate there, rotate, translate back
          step = SVGTransform(e: args[1], f: args[2])
            .concatenating(step)
            .concatenating(SVGTransform(e: -args[1], f: -args[2]))
        }
      case ("skewX", 1):
        step = SVGTransform(c: tan(args[0] * degrees))
      case ("skewY", 1):
        step = SVGTransform(b: tan(args[0] * degrees))
      default:
        return result
      }
      result = result.concatenating(step)
    }
    return result
  }
}

/// An absolute path command, in user space. Arcs are already cubics, and `H`, `V`, `S` and `T`
/// already their plain forms.
enum SVGPathCommand: Equatable {
  case move(SIMD2<Double>)
  case line(SIMD2<Double>)
  case quad(SIMD2<Double>, SIMD2<Double>)
  case cubic(SIMD2<Double>, SIMD2<Double>, SIMD2<Double>)
  case close
}

/// Reads numbers, flags and names out of SVG attribute text, the way the SVG grammar allows
/// them to run together: `1.5.5` is two numbers, `-1-2` is two, and so is `1e2.5`.
struct SVGScanner {
  private let bytes: [UInt8]
  private(set) var index = 0

  init(_ string: String) {
    self.bytes = Array(string.utf8)
  }

  var isAtEnd: Bool { self.index >= self.bytes.count }

  var peek: UInt8? { self.isAtEnd ? nil : self.bytes[self.index] }

  mutating func skipWhitespace() {
    while let byte = self.peek, byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D || byte == 0x0C {
      self.index += 1
    }
  }

  /// Whitespace, and at most one comma.
  mutating func skipSeparators() {
    self.skipWhitespace()
    if self.peek == UInt8(ascii: ",") {
      self.index += 1
      self.skipWhitespace()
    }
  }

  mutating func consume(_ character: Character) -> Bool {
    guard let ascii = character.asciiValue, self.peek == ascii else { return false }
    self.index += 1
    return true
  }

  mutating func identifier() -> String? {
    let start = self.index
    while let byte = self.peek, (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) || byte == UInt8(ascii: "-") {
      self.index += 1
    }
    guard self.index > start else { return nil }
    return String(decoding: self.bytes[start..<self.index], as: UTF8.self)
  }

  /// The next number, after separators. Leaves the position alone when there is none.
  mutating func number() -> Double? {
    let saved = self.index
    self.skipSeparators()
    let start = self.index
    if self.peek == UInt8(ascii: "+") || self.peek == UInt8(ascii: "-") {
      self.index += 1
    }
    var digits = 0
    while let byte = self.peek, byte >= 0x30 && byte <= 0x39 {
      self.index += 1
      digits += 1
    }
    if self.peek == UInt8(ascii: ".") {
      self.index += 1
      while let byte = self.peek, byte >= 0x30 && byte <= 0x39 {
        self.index += 1
        digits += 1
      }
    }
    guard digits > 0 else {
      self.index = saved
      return nil
    }
    // An exponent only counts when digits follow it, so `2em` is still the number 2.
    if self.peek == UInt8(ascii: "e") || self.peek == UInt8(ascii: "E") {
      var lookahead = self.index + 1
      if lookahead < self.bytes.count, self.bytes[lookahead] == UInt8(ascii: "+") || self.bytes[lookahead] == UInt8(ascii: "-") {
        lookahead += 1
      }
      if lookahead < self.bytes.count, self.bytes[lookahead] >= 0x30 && self.bytes[lookahead] <= 0x39 {
        self.index = lookahead
        while let byte = self.peek, byte >= 0x30 && byte <= 0x39 {
          self.index += 1
        }
      }
    }
    return Double(String(decoding: self.bytes[start..<self.index], as: UTF8.self))
  }

  /// An arc flag: a single `0` or `1`, which may run straight into what follows.
  mutating func flag() -> Bool? {
    let saved = self.index
    self.skipSeparators()
    switch self.peek {
    case UInt8(ascii: "0"):
      self.index += 1
      return false
    case UInt8(ascii: "1"):
      self.index += 1
      return true
    default:
      self.index = saved
      return nil
    }
  }

  /// A path command letter, after separators.
  mutating func command() -> UInt8? {
    self.skipSeparators()
    guard let byte = self.peek, (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) else {
      return nil
    }
    self.index += 1
    return byte
  }
}

enum SVGPathData {
  /// Parses a path's `d` attribute into absolute commands. As SVG asks, a malformed path is
  /// drawn up to the error.
  static func parse(_ d: String) -> [SVGPathCommand] {
    var scanner = SVGScanner(d)
    var commands: [SVGPathCommand] = []
    var current = SIMD2<Double>(0, 0)
    var subPathStart = current
    // the control point `S` and `T` reflect, when the previous command left one
    var lastCubicControl: SIMD2<Double>? = nil
    var lastQuadControl: SIMD2<Double>? = nil
    var command: UInt8? = nil

    func point(_ scanner: inout SVGScanner, relative: Bool) -> SIMD2<Double>? {
      guard let x = scanner.number(), let y = scanner.number() else { return nil }
      return relative ? current + SIMD2(x, y) : SIMD2(x, y)
    }

    parsing: while true {
      if let letter = scanner.command() {
        command = letter
      } else if scanner.isAtEnd {
        break
      } else if command == nil || command == UInt8(ascii: "Z") || command == UInt8(ascii: "z") {
        // numbers with no command to repeat
        break
      }
      guard let letter = command else { break }
      let relative = letter >= 0x61
      var cubicControl: SIMD2<Double>? = nil
      var quadControl: SIMD2<Double>? = nil

      switch letter | 0x20 {
      case UInt8(ascii: "m"):
        guard let p = point(&scanner, relative: relative) else { break parsing }
        commands.append(.move(p))
        current = p
        subPathStart = p
        // further pairs are implicit line-tos
        command = relative ? UInt8(ascii: "l") : UInt8(ascii: "L")
      case UInt8(ascii: "l"):
        guard let p = point(&scanner, relative: relative) else { break parsing }
        commands.append(.line(p))
        current = p
      case UInt8(ascii: "h"):
        guard let x = scanner.number() else { break parsing }
        let p = SIMD2(relative ? current.x + x : x, current.y)
        commands.append(.line(p))
        current = p
      case UInt8(ascii: "v"):
        guard let y = scanner.number() else { break parsing }
        let p = SIMD2(current.x, relative ? current.y + y : y)
        commands.append(.line(p))
        current = p
      case UInt8(ascii: "c"):
        guard
          let c1 = point(&scanner, relative: relative),
          let c2 = point(&scanner, relative: relative),
          let p = point(&scanner, relative: relative)
        else { break parsing }
        commands.append(.cubic(c1, c2, p))
        cubicControl = c2
        current = p
      case UInt8(ascii: "s"):
        guard let c2 = point(&scanner, relative: relative), let p = point(&scanner, relative: relative)
        else { break parsing }
        let c1 = lastCubicControl.map { 2 * current - $0 } ?? current
        commands.append(.cubic(c1, c2, p))
        cubicControl = c2
        current = p
      case UInt8(ascii: "q"):
        guard let c = point(&scanner, relative: relative), let p = point(&scanner, relative: relative)
        else { break parsing }
        commands.append(.quad(c, p))
        quadControl = c
        current = p
      case UInt8(ascii: "t"):
        guard let p = point(&scanner, relative: relative) else { break parsing }
        let c = lastQuadControl.map { 2 * current - $0 } ?? current
        commands.append(.quad(c, p))
        quadControl = c
        current = p
      case UInt8(ascii: "a"):
        guard
          let rx = scanner.number(), let ry = scanner.number(), let rotation = scanner.number(),
          let largeArc = scanner.flag(), let sweep = scanner.flag(),
          let p = point(&scanner, relative: relative)
        else { break parsing }
        commands += self.arc(
          from: current, radii: SIMD2(rx, ry), rotation: rotation, largeArc: largeArc, sweep: sweep, to: p
        )
        current = p
      case UInt8(ascii: "z"):
        commands.append(.close)
        current = subPathStart
      default:
        break parsing
      }
      lastCubicControl = cubicControl
      lastQuadControl = quadControl
    }

    return commands
  }

  /// An elliptical arc as cubics of at most a quarter turn each, by the endpoint to center
  /// conversion of the SVG spec (appendix B.2.4).
  static func arc(
    from start: SIMD2<Double>, radii: SIMD2<Double>, rotation: Double,
    largeArc: Bool, sweep: Bool, to end: SIMD2<Double>
  ) -> [SVGPathCommand] {
    guard start != end else { return [] }
    var rx = abs(radii.x)
    var ry = abs(radii.y)
    guard rx > 0, ry > 0 else { return [.line(end)] }

    let phi = rotation * .pi / 180
    let cosPhi = cos(phi)
    let sinPhi = sin(phi)
    let half = (start - end) * 0.5
    let x1 = cosPhi * half.x + sinPhi * half.y
    let y1 = -sinPhi * half.x + cosPhi * half.y

    // radii too small to reach are scaled up until they just do
    let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
    if lambda > 1 {
      rx *= lambda.squareRoot()
      ry *= lambda.squareRoot()
    }

    let numerator = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
    let denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
    let coefficient = (largeArc != sweep ? 1.0 : -1.0) * max(0, numerator / denominator).squareRoot()
    let cx1 = coefficient * rx * y1 / ry
    let cy1 = coefficient * -ry * x1 / rx
    let center = SIMD2(cosPhi * cx1 - sinPhi * cy1, sinPhi * cx1 + cosPhi * cy1) + (start + end) * 0.5

    func angle(_ u: SIMD2<Double>, _ v: SIMD2<Double>) -> Double {
      atan2(u.x * v.y - u.y * v.x, u.x * v.x + u.y * v.y)
    }
    let u = SIMD2((x1 - cx1) / rx, (y1 - cy1) / ry)
    let v = SIMD2((-x1 - cx1) / rx, (-y1 - cy1) / ry)
    let theta = angle(SIMD2(1, 0), u)
    var delta = angle(u, v)
    if !sweep, delta > 0 { delta -= 2 * .pi }
    if sweep, delta < 0 { delta += 2 * .pi }

    // a point of the unit circle, onto the ellipse
    func map(_ p: SIMD2<Double>) -> SIMD2<Double> {
      SIMD2(cosPhi * rx * p.x - sinPhi * ry * p.y, sinPhi * rx * p.x + cosPhi * ry * p.y) + center
    }

    let segments = max(1, Int(ceil(abs(delta) / (.pi / 2) - 1e-9)))
    let step = delta / Double(segments)
    let k = 4.0 / 3.0 * tan(step / 4)
    var commands: [SVGPathCommand] = []
    var angle1 = theta
    for i in 0..<segments {
      let angle2 = angle1 + step
      let e1 = SIMD2(cos(angle1), sin(angle1))
      let e2 = SIMD2(cos(angle2), sin(angle2))
      let c1 = e1 + k * SIMD2(-e1.y, e1.x)
      let c2 = e2 - k * SIMD2(-e2.y, e2.x)
      // the last end is exactly where the arc was asked to end
      commands.append(.cubic(map(c1), map(c2), i == segments - 1 ? end : map(e2)))
      angle1 = angle2
    }
    return commands
  }

  /// An ellipse as four cubics, starting at its rightmost point.
  static func ellipse(center: SIMD2<Double>, radii: SIMD2<Double>) -> [SVGPathCommand] {
    guard radii.x > 0, radii.y > 0 else { return [] }
    let right = center + SIMD2(radii.x, 0)
    return [.move(right)]
      + self.arc(from: right, radii: radii, rotation: 0, largeArc: false, sweep: true, to: center - SIMD2(radii.x, 0))
      + self.arc(from: center - SIMD2(radii.x, 0), radii: radii, rotation: 0, largeArc: false, sweep: true, to: right)
      + [.close]
  }
}
