/// The small glyphs the design system draws with: disclosure chevrons, a folder, a document, a
/// magnifier, a cross. Each is an SVG in `currentColor`, baked once into the distance-field atlas
/// the first time any window shows it, so it is sharp at any size and tinted like text:
/// `Image(icon: .folder).foregroundColor(.secondaryLabel)`.
public enum ThemeIcon: String, CaseIterable, Sendable {
  /// 10 × 10, stroked.
  case chevronRight, chevronDown, chevronLeft
  /// 10 × 10: a pop-up button's up and down arrows.
  case upDown
  /// 12 × 12: a menu item's check.
  case checkmark
  /// 16 × 13, filled.
  case folder
  /// 13 × 15, outlined.
  case document
  /// 12 × 12.
  case magnifier
  /// 8 × 8.
  case xmark

  /// The icon's markup.
  public var svg: String {
    switch self {
    case .chevronRight:
      Self.stroked(10, 10, "M3.5 2 L6.5 5 L3.5 8", width: 1.4)
    case .chevronDown:
      Self.stroked(10, 10, "M2 3.5 L5 6.5 L8 3.5", width: 1.4)
    case .chevronLeft:
      Self.stroked(10, 10, "M6.5 2 L3.5 5 L6.5 8", width: 1.4)
    case .upDown:
      Self.stroked(10, 10, "M3 4 L5 2 L7 4 M3 6 L5 8 L7 6", width: 1.2)
    case .checkmark:
      Self.stroked(12, 12, "M2.5 6.5 L5 9 L9.5 3", width: 1.5)
    case .folder:
      """
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="13" viewBox="0 0 16 13">\
      <path d="M1 2.5 A1.5 1.5 0 0 1 2.5 1 H6 L7.6 2.6 H13.5 A1.5 1.5 0 0 1 15 4.1 V10.5 \
      A1.5 1.5 0 0 1 13.5 12 H2.5 A1.5 1.5 0 0 1 1 10.5 Z" fill="currentColor"/></svg>
      """
    case .document:
      Self.stroked(
        13, 15, "M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z",
        width: 1.1
      )
    case .magnifier:
      """
      <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12">\
      <circle cx="5" cy="5" r="3.8" fill="none" stroke="currentColor" stroke-width="1.3"/>\
      <path d="M8 8 L11 11" fill="none" stroke="currentColor" stroke-width="1.3"/></svg>
      """
    case .xmark:
      Self.stroked(8, 8, "M1 1 L7 7 M7 1 L1 7", width: 1.3)
    }
  }

  private static func stroked(_ width: Int, _ height: Int, _ path: String, width strokeWidth: Float) -> String {
    """
    <svg xmlns="http://www.w3.org/2000/svg" width="\(width)" height="\(height)" viewBox="0 0 \(width) \(height)">\
    <path d="\(path)" fill="none" stroke="currentColor" stroke-width="\(strokeWidth)"/></svg>
    """
  }
}

extension Image {
  /// One of the design system's glyphs, at its natural size, in the foreground colour
  /// (`.label` unless `.foregroundColor(_:)` says otherwise). Not in SwiftUI.
  public convenience init(icon: ThemeIcon) {
    self.init(svg: icon.svg)
  }
}
