import simd

/// A shape that fills whatever rect it is given, for `.clipShape(_:)`, `.border(_:width:in:)` and
/// `.background(_:in:)`. Spelled like SwiftUI's shape members: `.rect(cornerRadius: 12)`,
/// `.capsule`, `.circle`.
///
/// Every one of them is a rounded rect once resolved against a rect, which is what lets clips,
/// borders and backgrounds share one analytic distance in `compute2D`.
public struct UIShape: Equatable, Sendable {
  public enum Kind: Equatable, Sendable {
    case rect
    /// Corners rounded by half the shorter side.
    case capsule
    /// The largest circle centred in the rect.
    case circle
  }

  public var kind: Kind
  /// A `.rect`'s corner radii, in `sdRoundedBox`'s order (Shaders/SDF.metal), y down:
  /// x bottom trailing, y top trailing, z bottom leading, w top leading. Unused by the others.
  public var radii: float4

  public init(kind: Kind, radii: float4 = .zero) {
    self.kind = kind
    self.radii = radii
  }

  public static let rect = UIShape(kind: .rect)
  public static let capsule = UIShape(kind: .capsule)
  public static let circle = UIShape(kind: .circle)

  public static func rect(cornerRadius: Float) -> UIShape {
    UIShape(kind: .rect, radii: float4(repeating: cornerRadius))
  }

  public static func rect(
    topLeadingRadius: Float = 0, bottomLeadingRadius: Float = 0,
    bottomTrailingRadius: Float = 0, topTrailingRadius: Float = 0
  ) -> UIShape {
    UIShape(kind: .rect, radii: float4(bottomTrailingRadius, topTrailingRadius, bottomLeadingRadius, topLeadingRadius))
  }

  /// A rect with square corners: what every existing unrounded path draws.
  public var isPlainRect: Bool {
    self.kind == .rect && self.radii == .zero
  }

  /// The rounded rect this shape is in `rect`: its own rect, and its corner radii, each clamped
  /// to half the shorter side.
  public func resolve(in rect: ClipRect) -> (rect: ClipRect, radii: float4) {
    let size = simd_max(rect.max - rect.min, .zero)
    let half = min(size.x, size.y) * 0.5
    switch self.kind {
    case .rect:
      return (rect, simd_clamp(self.radii, .zero, float4(repeating: half)))
    case .capsule:
      return (rect, float4(repeating: half))
    case .circle:
      let center = (rect.min + rect.max) * 0.5
      return (ClipRect(min: center - half, max: center + half), float4(repeating: half))
    }
  }
}
