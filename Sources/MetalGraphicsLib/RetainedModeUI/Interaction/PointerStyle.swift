import simd

/// The pointer's shape over an element, as SwiftUI's `PointerStyle`: `.pointerStyle(.link)`.
///
/// Resolved from what is under the pointer — the topmost element that sets one, or one it sits
/// in — and kept while a press that started on an element lasts, so a drag keeps its hand.
/// `UIContext.pointerStyle` is the result; the view shows it as an `NSCursor`.
public struct PointerStyle: Hashable, Sendable {
  enum Kind: Hashable, Sendable {
    case `default`, link, horizontalText, verticalText, rectSelection, grabIdle, grabActive, zoomIn, zoomOut
    case columnResize(HorizontalDirection.Set)
    case rowResize(VerticalDirection.Set)
    case frameResize(FrameResizePosition, FrameResizeDirection.Set)
  }

  let kind: Kind

  /// The arrow.
  public static let `default` = PointerStyle(kind: .default)
  /// A pointing hand, over something that follows a link or acts when clicked.
  public static let link = PointerStyle(kind: .link)
  /// An I-beam, over text that can be selected or edited.
  public static let horizontalText = PointerStyle(kind: .horizontalText)
  public static let verticalText = PointerStyle(kind: .verticalText)
  /// A crosshair, for picking a point or dragging out a selection.
  public static let rectSelection = PointerStyle(kind: .rectSelection)
  /// An open hand, over something that can be dragged.
  public static let grabIdle = PointerStyle(kind: .grabIdle)
  /// A closed hand, while dragging it.
  public static let grabActive = PointerStyle(kind: .grabActive)
  public static let zoomIn = PointerStyle(kind: .zoomIn)
  public static let zoomOut = PointerStyle(kind: .zoomOut)
  /// Over a divider between columns, that resizes them.
  public static let columnResize = PointerStyle(kind: .columnResize(.all))
  /// Over a divider between rows, that resizes them.
  public static let rowResize = PointerStyle(kind: .rowResize(.all))

  public static func columnResize(directions: HorizontalDirection.Set) -> PointerStyle {
    PointerStyle(kind: .columnResize(directions))
  }

  public static func rowResize(directions: VerticalDirection.Set) -> PointerStyle {
    PointerStyle(kind: .rowResize(directions))
  }

  /// Over an edge or corner of something that can be resized from it.
  public static func frameResize(
    position: FrameResizePosition, directions: FrameResizeDirection.Set = .all
  ) -> PointerStyle {
    PointerStyle(kind: .frameResize(position, directions))
  }
}

public enum HorizontalDirection: Hashable, Sendable {
  case leading, trailing

  public struct Set: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let leading = Set(rawValue: 1 << 0)
    public static let trailing = Set(rawValue: 1 << 1)
    public static let all: Set = [.leading, .trailing]
  }
}

public enum VerticalDirection: Hashable, Sendable {
  case up, down

  public struct Set: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let up = Set(rawValue: 1 << 0)
    public static let down = Set(rawValue: 1 << 1)
    public static let all: Set = [.up, .down]
  }
}

/// The edge or corner a frame is resized from.
public enum FrameResizePosition: Hashable, Sendable {
  case top, leading, bottom, trailing, topLeading, topTrailing, bottomLeading, bottomTrailing
}

public enum FrameResizeDirection: Hashable, Sendable {
  case inward, outward

  public struct Set: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let inward = Set(rawValue: 1 << 0)
    public static let outward = Set(rawValue: 1 << 1)
    public static let all: Set = [.inward, .outward]
  }
}

/// Where the pointer is over an element, as `.onContinuousHover` reports it. Frozen, as SwiftUI's,
/// so a switch over its two cases is exhaustive outside the library too.
@frozen public enum HoverPhase: Equatable, Sendable {
  /// Over it, at a location in the coordinate space asked for.
  case active(float2)
  /// No longer over it.
  case ended
}
