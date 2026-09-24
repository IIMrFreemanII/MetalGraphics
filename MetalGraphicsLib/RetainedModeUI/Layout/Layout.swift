import simd

/// A layout of your own, as SwiftUI's `Layout`: how large a container is for a proposal, and
/// where it puts its subviews.
///
/// ```swift
/// struct Diagonal: Layout {
///   func sizeThatFits(proposal: ProposedSize, subviews: LayoutSubviews, cache: inout Void) -> float2 {
///     subviews.reduce(.zero) { $0 + $1.sizeThatFits(.unspecified) }
///   }
///   func placeSubviews(in bounds: ClipRect, proposal: ProposedSize, subviews: LayoutSubviews, cache: inout Void) {
///     var point = bounds.min
///     for subview in subviews {
///       subview.place(at: point, proposal: .unspecified)
///       point += subview.sizeThatFits(.unspecified)
///     }
///   }
/// }
///
/// LayoutView(Diagonal()) { … }     // in a body
/// Diagonal() { … }                 // built by hand
/// ```
///
/// `sizeThatFits` may be called several times per layout pass with different proposals, and
/// `placeSubviews` once, with the size the container settled on. A subview that is not placed
/// sits in the middle at its ideal size.
@MainActor
public protocol Layout {
  associatedtype Cache = Void

  func makeCache(subviews: LayoutSubviews) -> Cache
  /// Called once per layout pass before the others; by default makes a new cache.
  func updateCache(_ cache: inout Cache, subviews: LayoutSubviews)
  func sizeThatFits(proposal: ProposedSize, subviews: LayoutSubviews, cache: inout Cache) -> float2
  func placeSubviews(in bounds: ClipRect, proposal: ProposedSize, subviews: LayoutSubviews, cache: inout Cache)
}

extension Layout where Cache == Void {
  public func makeCache(subviews: LayoutSubviews) -> Void {}
}

extension Layout {
  public func updateCache(_ cache: inout Cache, subviews: LayoutSubviews) {
    cache = self.makeCache(subviews: subviews)
  }

  /// A container laid out by this layout, holding `content`.
  public func callAsFunction(@UIElementBuilder _ content: () -> [UIElement]) -> LayoutView {
    LayoutView(self, content: content)
  }
}

/// One child of a `LayoutView`, as its layout sees it.
@MainActor
public struct LayoutSubview {
  unowned let element: UIElement
  unowned let host: LayoutView
  let index: Int

  /// The size the subview takes when offered `proposal`. Remembered for the layout pass.
  public func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.element.measure(proposal)
  }

  public func dimensions(in proposal: ProposedSize) -> ViewDimensions {
    ViewDimensions(self.element.measure(proposal))
  }

  /// Set by `.layoutPriority(_:)`; 0 by default.
  public var priority: Float {
    self.element.layoutPriority
  }

  /// Puts the subview's `anchor` point at `point`, in the container's coordinates, sized for
  /// `proposal`.
  public func place(at point: float2, anchor: Alignment = .topLeading, proposal: ProposedSize) {
    self.host.record(self.index, point, anchor, proposal)
  }
}

/// The children of a `LayoutView`, in order, those leaving left out. Indexing makes no copies.
@MainActor
public struct LayoutSubviews: @MainActor RandomAccessCollection {
  unowned let host: LayoutView

  public var startIndex: Int { 0 }
  public var endIndex: Int { self.host.live.count }

  public subscript(index: Int) -> LayoutSubview {
    LayoutSubview(element: self.host.live[index], host: self.host, index: index)
  }
}

/// Any layout, its concrete type hidden, as SwiftUI's `AnyLayout`: what lets a `LayoutView`
/// switch between layouts, with what moves sliding to its new place when it is animated.
///
/// ```swift
/// LayoutView(self.wide ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())) { … }
/// ```
public struct AnyLayout: Layout {
  let box: AnyLayoutBox

  public init<L: Layout>(_ layout: L) {
    if let any = layout as? AnyLayout {
      self.box = any.box
    } else {
      self.box = LayoutBox(layout)
    }
  }

  public func sizeThatFits(proposal: ProposedSize, subviews: LayoutSubviews, cache: inout Void) -> float2 {
    self.box.sizeThatFits(proposal, subviews)
  }

  public func placeSubviews(in bounds: ClipRect, proposal: ProposedSize, subviews: LayoutSubviews, cache: inout Void) {
    self.box.placeSubviews(bounds, proposal, subviews)
  }
}

/// Holds a layout and its cache, and keeps the cache current: made on first use, updated once
/// per layout pass.
@MainActor
class AnyLayoutBox {
  func sizeThatFits(_ proposal: ProposedSize, _ subviews: LayoutSubviews) -> float2 { .zero }
  func placeSubviews(_ bounds: ClipRect, _ proposal: ProposedSize, _ subviews: LayoutSubviews) {}
}

final class LayoutBox<L: Layout>: AnyLayoutBox {
  let layout: L
  private var cache: L.Cache? = nil
  private var generation: UInt32 = .max

  init(_ layout: L) {
    self.layout = layout
  }

  private func currentCache(_ subviews: LayoutSubviews) -> L.Cache {
    if var cache = self.cache {
      if self.generation != LayoutPass.generation {
        self.layout.updateCache(&cache, subviews: subviews)
        self.cache = cache
      }
    } else {
      self.cache = self.layout.makeCache(subviews: subviews)
    }
    self.generation = LayoutPass.generation
    return self.cache!
  }

  override func sizeThatFits(_ proposal: ProposedSize, _ subviews: LayoutSubviews) -> float2 {
    var cache = self.currentCache(subviews)
    defer { self.cache = cache }
    return self.layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
  }

  override func placeSubviews(_ bounds: ClipRect, _ proposal: ProposedSize, _ subviews: LayoutSubviews) {
    var cache = self.currentCache(subviews)
    defer { self.cache = cache }
    self.layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
  }
}

/// Children laid out by a `Layout`. Made by calling a layout with content, or written directly in
/// a body, where `setLayout` switches the layout and keeps the children.
public final class LayoutView : MultiChildElement {
  public private(set) var layout: AnyLayout

  /// The children taking part, while the layout runs.
  var live: [UIElement] = []

  // Where the layout placed each child, recorded by `LayoutSubview.place`; nil when it did not.
  private var placedPoints: [float2?] = []
  private var placedAnchors: [Alignment] = []
  private var placedProposals: [ProposedSize] = []
  /// Where each child goes, relative to the container, from the last committed layout.
  private var placed: [float2] = []
  private var size: float2 = .zero

  public init<L: Layout>(_ layout: L, @UIElementBuilder content: () -> [UIElement] = { [] }) {
    self.layout = AnyLayout(layout)
    super.init()
    self.applyContent(content())
  }

  func setLayout(_ layout: AnyLayout) {
    self.layout = layout
  }

  public override func getSize() -> float2 {
    self.size
  }

  private func gatherLive() {
    self.live.removeAll(keepingCapacity: true)
    for child in self.children where !child.isLeaving {
      self.live.append(child)
    }
  }

  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    self.gatherLive()
    defer { self.live.removeAll(keepingCapacity: true) }
    return self.layout.box.sizeThatFits(proposal, LayoutSubviews(host: self))
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    self.gatherLive()
    defer { self.live.removeAll(keepingCapacity: true) }
    let subviews = LayoutSubviews(host: self)
    let size = self.layout.box.sizeThatFits(proposal, subviews)
    self.size = size

    let count = self.live.count
    self.placedPoints.removeAll(keepingCapacity: true)
    self.placedPoints.append(contentsOf: repeatElement(nil, count: count))
    self.placedAnchors.removeAll(keepingCapacity: true)
    self.placedAnchors.append(contentsOf: repeatElement(.topLeading, count: count))
    self.placedProposals.removeAll(keepingCapacity: true)
    self.placedProposals.append(contentsOf: repeatElement(.unspecified, count: count))
    self.layout.box.placeSubviews(ClipRect(position: .zero, size: size), proposal, subviews)

    self.placed.removeAll(keepingCapacity: true)
    for index in 0..<count {
      let childSize = self.live[index].calcSize(self.placedProposals[index])
      if let point = self.placedPoints[index] {
        self.placed.append(point - childSize * self.placedAnchors[index].offset)
      } else {
        // Not placed: in the middle, at its ideal size.
        self.placed.append((size - childSize) * 0.5)
      }
    }
    return size
  }

  func record(_ index: Int, _ point: float2, _ anchor: Alignment, _ proposal: ProposedSize) {
    guard index < self.placedPoints.count else { return }
    self.placedPoints[index] = point
    self.placedAnchors[index] = anchor
    self.placedProposals[index] = proposal
  }

  public override func calcPosition(_ position: float2) {
    var index = 0
    for child in self.children where !child.isLeaving {
      let offset = index < self.placed.count ? self.placed[index] : .zero
      self.place(child, at: position + offset, in: position)
      index += 1
    }
    self.placeLeaving(in: position)
  }
}

// MARK: - Built-in layouts

/// An `HStack` as a `Layout`, to switch to and from with `AnyLayout`.
public struct HStackLayout: Layout {
  public var alignment: VerticalAlignment
  public var spacing: Float

  public init(alignment: VerticalAlignment = .center, spacing: Float = 0) {
    self.alignment = alignment
    self.spacing = spacing
  }

  /// A stack that never joins the tree, laying the subviews out exactly as an `HStack` would.
  public func makeCache(subviews: LayoutSubviews) -> HStack {
    let stack = HStack(alignment: self.alignment, spacing: self.spacing)
    return stack
  }

  public func updateCache(_ cache: inout HStack, subviews: LayoutSubviews) {
    cache.alignment = self.alignment
    cache.spacing = self.spacing
  }

  public func sizeThatFits(proposal: ProposedSize, subviews: LayoutSubviews, cache: inout HStack) -> float2 {
    cache.load(subviews)
    defer { cache.unload() }
    return cache.sizeThatFits(proposal)
  }

  public func placeSubviews(in bounds: ClipRect, proposal: ProposedSize, subviews: LayoutSubviews, cache: inout HStack) {
    cache.load(subviews)
    defer { cache.unload() }
    _ = cache.arrange(proposal) { index, origin, childProposal in
      subviews[index].place(at: bounds.min + origin, proposal: childProposal)
    }
  }
}

/// A `VStack` as a `Layout`, to switch to and from with `AnyLayout`.
public struct VStackLayout: Layout {
  public var alignment: HorizontalAlignment
  public var spacing: Float

  public init(alignment: HorizontalAlignment = .center, spacing: Float = 0) {
    self.alignment = alignment
    self.spacing = spacing
  }

  public func makeCache(subviews: LayoutSubviews) -> VStack {
    VStack(alignment: self.alignment, spacing: self.spacing)
  }

  public func updateCache(_ cache: inout VStack, subviews: LayoutSubviews) {
    cache.alignment = self.alignment
    cache.spacing = self.spacing
  }

  public func sizeThatFits(proposal: ProposedSize, subviews: LayoutSubviews, cache: inout VStack) -> float2 {
    cache.load(subviews)
    defer { cache.unload() }
    return cache.sizeThatFits(proposal)
  }

  public func placeSubviews(in bounds: ClipRect, proposal: ProposedSize, subviews: LayoutSubviews, cache: inout VStack) {
    cache.load(subviews)
    defer { cache.unload() }
    _ = cache.arrange(proposal) { index, origin, childProposal in
      subviews[index].place(at: bounds.min + origin, proposal: childProposal)
    }
  }
}

/// A `ZStack` as a `Layout`, to switch to and from with `AnyLayout`.
public struct ZStackLayout: Layout {
  public var alignment: Alignment

  public init(alignment: Alignment = .center) {
    self.alignment = alignment
  }

  public func makeCache(subviews: LayoutSubviews) -> ZStack {
    ZStack(alignment: self.alignment)
  }

  public func updateCache(_ cache: inout ZStack, subviews: LayoutSubviews) {
    cache.alignment = self.alignment
  }

  public func sizeThatFits(proposal: ProposedSize, subviews: LayoutSubviews, cache: inout ZStack) -> float2 {
    cache.load(subviews)
    defer { cache.unload() }
    return cache.sizeThatFits(proposal)
  }

  public func placeSubviews(in bounds: ClipRect, proposal: ProposedSize, subviews: LayoutSubviews, cache: inout ZStack) {
    cache.load(subviews)
    defer { cache.unload() }
    _ = cache.arrange(proposal) { index, origin, childProposal in
      subviews[index].place(at: bounds.min + origin, proposal: childProposal)
    }
  }
}

extension MultiChildElement {
  /// Makes this container, which never joins the tree, hold `subviews` as its children, so its
  /// own layout can be run over them.
  func load(_ subviews: LayoutSubviews) {
    self.children.removeAll(keepingCapacity: true)
    for subview in subviews {
      self.children.append(subview.element)
    }
  }

  /// Lets go of what `load` gave it, so it holds no element past the layout.
  func unload() {
    self.children.removeAll(keepingCapacity: true)
  }
}
