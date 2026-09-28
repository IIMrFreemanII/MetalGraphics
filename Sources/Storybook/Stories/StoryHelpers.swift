import MetalGraphicsLib
import simd

/// Swift for a string literal.
func swiftString(_ value: String) -> String {
  "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}

/// A number as Swift writes it.
func swiftNumber(_ value: Double) -> String {
  value.rounded() == value ? "\(Int(value))" : "\(value)"
}

/// A colour role by the name its control shows.
func role(named name: String) -> float4 {
  ThemeColor.allCases.first { "\($0)" == name }.map { .role($0) } ?? .accent
}

/// A palette hue by name.
func hue(named name: String) -> float4 {
  ThemeHue.allCases.first { "\($0)" == name }.map { .hue($0) } ?? .hue(.blue)
}

let roleNames = ThemeColor.allCases.map { "\($0)" }
let hueNames = ThemeHue.allCases.map { "\($0)" }
let iconNames = ThemeIcon.allCases.map { "\($0)" }

/// A caption under a sample in a gallery story.
func caption(_ text: String) -> Text {
  Text(text).font(.system(size: 10)).foregroundColor(.secondaryLabel).lineLimit(1)
}

/// Samples in rows of `columns`.
func gallery(columns: Int, spacing: Float = 14, _ items: [UIElement]) -> UIElement {
  var content: [UIElement] = []
  var index = 0
  while index < items.count {
    let cells = Array(items[index ..< min(index + columns, items.count)])
    content.append(HStack(alignment: .top, spacing: spacing) { () -> [UIElement] in return cells })
    index += columns
  }
  return VStack(alignment: .leading, spacing: spacing) { () -> [UIElement] in return content }
}
