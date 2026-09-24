import simd

/// When a scroll view shows its scroll bars.
public enum ScrollIndicatorVisibility: Sendable {
  /// While scrolling, fading out shortly after.
  case automatic
  /// Whenever there is something to scroll.
  case visible
  case hidden
  /// Hidden, as SwiftUI spells it for indicators that must not appear even on request.
  case never
}

/// Shows content larger than itself, and moves it with the scroll wheel or trackpad.
///
/// Like SwiftUI's, it fills the space it is offered and lets its content take as much as it
/// needs along `axes`. Everything under it is clipped to its bounds, drawn and hit alike.
///
/// The wheel goes to the innermost scroll view under the pointer; whatever it cannot use — past
/// its end, or along an axis it does not scroll — goes on to the scroll views around it.
public final class ScrollView : SingleChildElement {
  public var axes: Axis
  public var showsIndicators: Bool
  public var indicatorVisibility: ScrollIndicatorVisibility = .automatic
  public var isScrollDisabled: Bool = false

  /// How far the content is scrolled from its top left, in points. Always within
  /// `0...scrollableSize`.
  public private(set) var offset: float2 = .zero

  public private(set) var position: float2 = .zero
  public private(set) var size: float2 = .zero
  public private(set) var contentSize: float2 = .zero

  /// How far the content can scroll along each axis.
  public var scrollableSize: float2 {
    simd_max(self.contentSize - self.size, .zero) * self.axes.size
  }

  // Visited after the content, so it is drawn on top of it.
  private lazy var indicator = ScrollIndicator(self)

  public init(
    _ axes: Axis = .vertical, showsIndicators: Bool = true,
    @UIElementBuilder content: () -> [UIElement] = { [] }
  ) {
    self.axes = axes
    self.showsIndicators = showsIndicators

    super.init()

    self.applyContent(content())
  }

  public override func mount(_ context: UIContext) {
    context.registerScrollView(self)
  }

  public override func unmount(_ context: UIContext) {
    context.unregisterScrollView(self)
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    super.forEachChild(body)
    body(self.indicator)
  }

  override var clipRect: ClipRect? {
    ClipRect(position: self.position, size: self.size)
  }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "ScrollView(size: \(self.size), content: \(self.contentSize), offset: \(self.offset))")
    self.child?.debugHierarchy(offset + "  ")
  }

  // MARK: - Layout

  public override func getSize() -> float2 {
    self.size
  }

  // Asks its content for its ideal length along the axes it scrolls, so the content takes what
  // it needs there: a `Rectangle` its ideal 10 points, not forever.
  private func contentProposal(_ proposal: ProposedSize) -> ProposedSize {
    ProposedSize(
      width: self.axes.horizontal != 0 ? nil : proposal.width,
      height: self.axes.vertical != 0 ? nil : proposal.height
    )
  }

  // Fills what it is offered; asked for its ideal, it is its content's.
  public override func sizeThatFits(_ proposal: ProposedSize) -> float2 {
    if let width = proposal.width, let height = proposal.height {
      return float2(width, height)
    }
    let contentSize = self.child?.measure(self.contentProposal(proposal)) ?? .zero
    return proposal.replacingUnspecified(with: contentSize)
  }

  public override func calcSize(_ proposal: ProposedSize) -> float2 {
    let wasInScrollView = LazyStackViewport.inScrollView
    LazyStackViewport.inScrollView = true
    defer { LazyStackViewport.inScrollView = wasInScrollView }
    self.contentSize = self.child?.calcSize(self.contentProposal(proposal)) ?? .zero
    self.size = proposal.replacingUnspecified(with: self.contentSize)
    return self.size
  }

  // Its content moves as it scrolls, so what the content defines is not passed on.
  public override func guideValue(_ key: AlignmentKey, _ proposal: ProposedSize, _ size: float2) -> Float? {
    self.explicitGuide(key, size)
  }

  public override func calcPosition(_ position: float2) {
    self.position = position
    self.offset = simd_clamp(self.offset, .zero, self.scrollableSize)
    self.positionContent()
  }

  // Scrolling moves the content without sizing anything, so it skips the layout pass.
  //
  // Not through `place`: that would slide the content to every new offset in an animated pass.
  // Its placement stays put — scrolling is not the content moving within its container.
  private func positionContent() {
    guard let child = self.child else { return }
    // Content smaller than the scroll view sits in its middle across the axes it does not
    // scroll, as in SwiftUI.
    let slack = simd_max(self.size - self.contentSize, .zero) * 0.5 * (1 - self.axes.size)
    child.placement = .zero
    // What this scroll view shows, within what the ones around it do, for lazy stacks inside.
    let outer = LazyStackViewport.current
    let shown = ClipRect(position: self.position, size: self.size)
    LazyStackViewport.current = outer.map { $0.intersection(shown) } ?? shown
    defer { LazyStackViewport.current = outer }
    child.calcPosition(self.position + slack - self.offset)
  }


  // MARK: - Scrolling

  /// Scrolls to `offset`, clamped to what can scroll.
  public func scrollTo(offset: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    // Reaches only what the last layout pass measured.
    let target = simd_clamp(offset, .zero, self.scrollableSize)
    self.indicator.flash(context)
    context.animator.set(self, .offset, from: self.offset, to: target, animation, context) { element, value, context in
      unsafeDowncast(element, to: ScrollView.self).setOffset(float2(packed: value), context)
    }
  }

  private func setOffset(_ value: float2, _ context: UIContext) -> Void {
    let clamped = simd_clamp(value, .zero, self.scrollableSize)
    guard clamped != self.offset else { return }
    self.offset = clamped
    self.positionContent()
    context.invalidate([.hitGrid, .render])
  }

  /// Moves the content by `delta` — positive y moves it down — and returns what is left of
  /// `delta` for the scroll views around this one.
  func scroll(by delta: float2, _ context: UIContext) -> float2 {
    guard !self.isScrollDisabled else { return delta }
    let old = self.offset
    let target = simd_clamp(old - delta * self.axes.size, .zero, self.scrollableSize)
    // A wheel cancels a running `scrollTo`.
    context.animator.cancel(self, .offset)
    self.setOffset(target, context)
    let used = old - target
    if used != .zero {
      self.indicator.flash(context)
    }
    var remaining = delta - used
    // Less than a point left over is rounding, not a push past the end.
    remaining.replace(with: 0, where: abs(remaining) .< 0.5)
    return remaining
  }

  /// Scrolls so the part of the content from `origin`, `size` long, lines up with the scroll
  /// view at `anchor` — or, without one, by as little as it takes to show it whole.
  func scrollTo(contentRect origin: float2, size: float2, anchor: Alignment?, _ context: UIContext, animation: UIAnimation?) {
    var target = self.offset
    if let anchor {
      target = origin + (size - self.size) * anchor.offset
    } else {
      let end = origin + size - self.size
      // Past the end: bring the end in. Before the start, or larger than the view: the start.
      target = simd_max(target, end)
      target = simd_min(target, origin)
    }
    target.replace(with: self.offset, where: self.axes.size .== 0)
    self.scrollTo(offset: target, context, animation: animation)
  }

  // MARK: - Modifiers

  /// Stops the wheel scrolling this view; it goes on to the scroll views around it instead.
  /// Sets this view's own flag and returns it.
  public func scrollDisabled(_ disabled: Bool) -> Self {
    self.isScrollDisabled = disabled
    return self
  }

  /// When the scroll bars show. Sets this view's own visibility and returns it.
  public func scrollIndicators(_ visibility: ScrollIndicatorVisibility) -> Self {
    self.indicatorVisibility = visibility
    return self
  }

  /// Where the content's top left corner is laid out, in the window.
  var contentOrigin: float2 {
    self.position - self.offset
  }
}

// MARK: - Indicators

/// A scroll view's scroll bars. Drawn over its content, inside its clip.
final class ScrollIndicator : UIRenderableElement {
  private unowned let scrollView: ScrollView
  private var opacity: Float = 0

  private static let thickness: Float = 5
  private static let inset: Float = 2
  private static let minLength: Float = 20
  private static let color = float4(0, 0, 0, 0.45)

  init(_ scrollView: ScrollView) {
    self.scrollView = scrollView
    super.init()
  }

  override func mount(_ context: UIContext) {
    context.registerRenderableView(self)
  }

  override func unmount(_ context: UIContext) {
    context.unregisterRenderableView(self)
  }

  private var visibility: ScrollIndicatorVisibility {
    self.scrollView.showsIndicators ? self.scrollView.indicatorVisibility : .hidden
  }

  /// Shows the bars, then fades them out once scrolling stops — when they come and go.
  func flash(_ context: UIContext) {
    guard self.visibility == .automatic else { return }
    context.animator.set(self, .opacity, from: self.opacity, to: 1, nil, context) { element, value, context in
      unsafeDowncast(element, to: ScrollIndicator.self).opacity = value.x
      context.invalidate()
    }
    context.animator.run(
      self, .opacity, from: SIMD4(1, 0, 0, 0), to: .zero, UIAnimation.easeOut(0.3).delay(0.8), context,
      restart: true, group: nil,
      apply: { element, value, context in
        unsafeDowncast(element, to: ScrollIndicator.self).opacity = value.x
        context.invalidate()
      },
      completion: nil
    )
  }

  override func render(_ renderer: Graphics2D, _ effect: EffectState) {
    let opacity: Float
    switch self.visibility {
    case .automatic: opacity = self.opacity
    case .visible: opacity = 1
    case .hidden, .never: return
    }
    guard opacity * effect.opacity > 0 else { return }

    let view = self.scrollView
    var color = Self.color
    color.w *= opacity * effect.opacity
    let both = view.scrollableSize.x > 0 && view.scrollableSize.y > 0
    // Each bar stops short of the corner the other one runs into.
    let corner = both ? Self.thickness + Self.inset : 0

    for axis in 0..<2 where view.scrollableSize[axis] > 0 {
      let cross = 1 - axis
      let track = view.size[axis] - Self.inset * 2 - corner
      guard track > 0 else { continue }
      let length = min(max(track * view.size[axis] / view.contentSize[axis], Self.minLength), track)
      let progress = view.offset[axis] / view.scrollableSize[axis]

      var origin = float2()
      origin[axis] = view.position[axis] + Self.inset + (track - length) * progress
      origin[cross] = view.position[cross] + view.size[cross] - Self.inset - Self.thickness
      var size = float2()
      size[axis] = length
      size[cross] = Self.thickness

      let drawn = effect.apply(to: origin)
      let drawnSize = size * effect.scale
      // origin -> top left
      renderer.draw(square: Square(position: drawn - renderer.size * 0.5 + drawnSize * 0.5, size: drawnSize, color: color))
    }
  }
}
