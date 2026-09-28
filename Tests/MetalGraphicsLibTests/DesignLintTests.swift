import Foundation
import XCTest

// The design system's one rule a compiler cannot check: UI draws with the theme's roles and palette
// hues (`.secondaryLabel`, `.hue(.orange)`), never a colour written out, so it follows light and dark
// and the canvas. This reads the sources and fails on a colour literal outside the files that
// define the tokens (docs/DesignSystem.md, and the design-system skill).
//
// A deliberate exception keeps its literal with a reason on the same line:
//
//     case .close: float4(1, 0.37, 0.34, 1)  // design: the macOS traffic lights

final class DesignLintTests: XCTestCase {
  /// Where UI is built. The Demo is held to the literal rule only: its pages show `.white` text on
  /// coloured swatches.
  private static let roots: [(path: String, namedColours: Bool)] = [
    ("Sources/MetalGraphicsLib/RetainedModeUI", true),
    ("Sources/Editor", true),
    ("Sources/Demo", false),
  ]

  /// The files that define the tokens: colours are written out there and nowhere else.
  private static let tokenFiles = [
    "RetainedModeUI/Theme/",
    "RetainedModeUI/TextEditor/Styling/EditorTheme.swift",
  ]

  private static let number = #"\s*-?\d+(?:\.\d+)?\s*"#
  /// `float4(r, g, b[, a])` or `SIMD4<Float>(…)` with number literals.
  private static let literal = try! NSRegularExpression(
    pattern: #"(?:float4|SIMD4<Float>)\((\#(number),\#(number),\#(number)(?:,\#(number))?)\)"#
  )
  /// A literal on a line like this is a colour, whatever its values.
  private static let colourContext = try! NSRegularExpression(
    pattern: #"(?i)colou?r|foreground|background|tint|fill|stroke|border|shadow|glyph|swatch|Rectangle\(|Circle\(|Capsule\(|Ellipse\("#
  )
  private static let hex = try! NSRegularExpression(pattern: #"float4\(hex:"#)
  /// A fixed named colour where a role belongs: `.foregroundColor(.white)`, `Rectangle(.black)`.
  private static let named = try! NSRegularExpression(
    pattern: #"(?:foregroundColor|foregroundStyle|background|fill|stroke|border|tint|Rectangle|color:)\s*\(?\s*\.(?:white|black|red|green|blue)\b"#
  )

  private static var packageRoot: URL {
    URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
  }

  func testUIDrawsWithThemeColours() throws {
    var violations: [String] = []
    let fm = FileManager.default
    for root in Self.roots {
      let dir = Self.packageRoot.appendingPathComponent(root.path)
      guard let files = fm.enumerator(at: dir, includingPropertiesForKeys: nil) else {
        XCTFail("no \(root.path)")
        continue
      }
      for case let url as URL in files where url.pathExtension == "swift" {
        let relative = String(url.path.dropFirst(Self.packageRoot.path.count + 1))
        guard !Self.tokenFiles.contains(where: { relative.contains($0) }) else { continue }
        let source = try String(contentsOf: url, encoding: .utf8)
        for (index, line) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
          if let problem = Self.check(String(line), namedColours: root.namedColours) {
            violations.append("\(relative):\(index + 1): \(problem)\n    \(line.trimmingCharacters(in: .whitespaces))")
          }
        }
      }
    }
    XCTAssert(
      violations.isEmpty,
      """
      \(violations.count) colour(s) written out where a theme role or palette hue belongs \
      (`.secondaryLabel`, `.separator`, `.hover`, `.hue(.orange)`; docs/DesignSystem.md). \
      Keep a deliberate one with `// design: <reason>` on its line.

      \(violations.joined(separator: "\n"))
      """
    )
  }

  /// What is wrong with `line`, if anything.
  static func check(_ line: String, namedColours: Bool) -> String? {
    guard !line.contains("// design:") else { return nil }
    // The code, not a comment after it or a doc comment.
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard !trimmed.hasPrefix("//") else { return nil }
    let code = line.range(of: "//").map { String(line[..<$0.lowerBound]) } ?? line
    let range = NSRange(code.startIndex..., in: code)
    if Self.hex.firstMatch(in: code, range: range) != nil {
      return "a hex colour"
    }
    let isColourLine = Self.colourContext.firstMatch(in: code, range: range) != nil
    for match in Self.literal.matches(in: code, range: range) {
      guard let group = Range(match.range(at: 1), in: code) else { continue }
      let parts = code[group].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
      let values = parts.compactMap(Float.init)
      // Colours have fractions in 0...1; rects, insets and masks are whole numbers.
      let looksLikeColour = parts.contains { $0.contains(".") } && values.allSatisfy { (0...1).contains($0) }
      if isColourLine || looksLikeColour {
        return "an RGB literal"
      }
    }
    if namedColours, Self.named.firstMatch(in: code, range: range) != nil {
      return "a fixed named colour"
    }
    return nil
  }

  /// The rule itself, on lines it must and must not flag.
  func testTheRule() {
    let flagged = [
      "  .foregroundColor(float4(0.6, 0.6, 0.63, 1))",
      "  private static let amber = float4(0.85, 0.6, 0.1, 1)",
      "  Rectangle(float4(1, 0, 0, 1))",
      "  let c = float4(hex: 0x007AFF)",
      "  .background(.black)",
      "  theme[.output] = SpanStyle(foreground: SIMD4<Float>(0.6, 0.6, 0.63, 1))",
    ]
    for line in flagged {
      XCTAssertNotNil(Self.check(line, namedColours: true), line)
    }
    let allowed = [
      "  .foregroundColor(.secondaryLabel)",
      "  private static let amber: float4 = .hue(.orange)",
      "  radii: float4(5, 5, 0, 0) * scale,",
      "  (float4(1, 0, 0, 0), .frameResize(position: .leading)),",
      "  case .close: float4(1, 0.37, 0.34, 1)  // design: the macOS traffic lights",
      "  /// e.g. `.foregroundColor(float4(1, 0, 0, 1))`",
      "  public var color: SIMD4<Float> = .black",
    ]
    for line in allowed {
      XCTAssertNil(Self.check(line, namedColours: true), line)
    }
    XCTAssertNil(Self.check("  .foregroundColor(.white)", namedColours: false), "the Demo's text on swatches")
  }
}
