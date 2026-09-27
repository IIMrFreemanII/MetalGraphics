import simd

/// The size a container offers a child, one axis at a time, as SwiftUI's `ProposedViewSize`.
///
/// Along each axis, nil asks for the child's ideal length, `0` for its smallest and `.infinity`
/// for its largest; any other length is the space there is. A child answers with the size it
/// takes, which may be anything: the container decides what to do with a child that does not
/// fit.
public struct ProposedSize: Equatable, Sendable {
  public var width: Float?
  public var height: Float?

  public init(width: Float?, height: Float?) {
    self.width = width
    self.height = height
  }

  public init(_ size: float2) {
    self.width = size.x
    self.height = size.y
  }

  /// The ideal size along both axes.
  public static let unspecified = ProposedSize(width: nil, height: nil)
  public static let zero = ProposedSize(width: 0, height: 0)
  public static let infinity = ProposedSize(width: .infinity, height: .infinity)

  /// The length along `axis`: 0 for x, 1 for y.
  public subscript(axis: Int) -> Float? {
    get { axis == 0 ? self.width : self.height }
    set {
      if axis == 0 { self.width = newValue } else { self.height = newValue }
    }
  }

  /// Nil lengths replaced by `size`'s.
  public func replacingUnspecified(with size: float2) -> float2 {
    float2(self.width ?? size.x, self.height ?? size.y)
  }

  /// This proposal with `length` along `axis`.
  public func with(_ axis: Int, _ length: Float?) -> ProposedSize {
    var proposal = self
    proposal[axis] = length
    return proposal
  }
}

/// A few proposals an element was measured at in the current layout pass, and what it answered.
///
/// Stacks measure each child at its smallest and largest before sharing space, and a stack in a
/// stack is measured the same way by its own parent, so without this nested stacks cost
/// exponential time. It is stored inline, four entries replaced round robin, and cleared by
/// moving to a new pass: every change that could alter a size invalidates layout, and every
/// layout pass has a generation of its own.
struct MeasureCache {
  private var generation: UInt32 = .max
  private var count: UInt8 = 0
  private var next: UInt8 = 0
  private var proposals: (ProposedSize, ProposedSize, ProposedSize, ProposedSize) =
    (.unspecified, .unspecified, .unspecified, .unspecified)
  private var sizes: (float2, float2, float2, float2) = (.zero, .zero, .zero, .zero)

  func lookup(_ proposal: ProposedSize, _ generation: UInt32) -> float2? {
    guard generation == self.generation else { return nil }
    if self.count > 0, self.proposals.0 == proposal { return self.sizes.0 }
    if self.count > 1, self.proposals.1 == proposal { return self.sizes.1 }
    if self.count > 2, self.proposals.2 == proposal { return self.sizes.2 }
    if self.count > 3, self.proposals.3 == proposal { return self.sizes.3 }
    return nil
  }

  mutating func store(_ proposal: ProposedSize, _ size: float2, _ generation: UInt32) {
    if generation != self.generation {
      self.generation = generation
      self.count = 0
      self.next = 0
    }
    switch self.next {
    case 0: (self.proposals.0, self.sizes.0) = (proposal, size)
    case 1: (self.proposals.1, self.sizes.1) = (proposal, size)
    case 2: (self.proposals.2, self.sizes.2) = (proposal, size)
    default: (self.proposals.3, self.sizes.3) = (proposal, size)
    }
    self.next = (self.next + 1) & 3
    self.count = min(self.count + 1, 4)
  }
}
