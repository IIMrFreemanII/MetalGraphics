/// The four edges of a rectangle, as sets: `.padding(.horizontal, 8)`.
public enum Edge {
  public struct Set: OptionSet, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let top = Set(rawValue: 1 << 0)
    public static let leading = Set(rawValue: 1 << 1)
    public static let bottom = Set(rawValue: 1 << 2)
    public static let trailing = Set(rawValue: 1 << 3)

    public static let horizontal: Set = [.leading, .trailing]
    public static let vertical: Set = [.top, .bottom]
    public static let all: Set = [.top, .leading, .bottom, .trailing]
  }
}

extension Inset {
  /// What `.padding()` pads by when given no length, as SwiftUI does on macOS.
  public static let defaultLength: Float = 16

  /// `length` on each edge in `edges`, zero on the others.
  public init(_ edges: Edge.Set, _ length: Float = Inset.defaultLength) {
    self.init(
      left: edges.contains(.leading) ? length : 0,
      top: edges.contains(.top) ? length : 0,
      right: edges.contains(.trailing) ? length : 0,
      bottom: edges.contains(.bottom) ? length : 0
    )
  }
}
