extension UIElement {
  public func padding(_ inset: Inset) -> Padding {
    Padding(inset) {
      self
    }
  }

  /// `length` on every edge; 16 points, as SwiftUI's default, when not given.
  public func padding(_ length: Float = Inset.defaultLength) -> Padding {
    Padding(Inset(all: length)) {
      self
    }
  }

  /// `length` on each edge in `edges`: `.padding(.horizontal, 8)`.
  public func padding(_ edges: Edge.Set, _ length: Float = Inset.defaultLength) -> Padding {
    Padding(Inset(edges, length)) {
      self
    }
  }

  /// Sizes this element at its ideal size along the fixed axes, whatever it is offered: a text
  /// stays on one line. See `FixedSizeElement`.
  public func fixedSize(horizontal: Bool = true, vertical: Bool = true) -> FixedSizeElement {
    FixedSizeElement(horizontal: horizontal, vertical: vertical) {
      self
    }
  }

  /// Takes all the space offered and centres this element on the point. See `PositionElement`.
  public func position(x: Float = 0, y: Float = 0) -> PositionElement {
    PositionElement(float2(x, y)) {
      self
    }
  }

  public func position(_ point: float2) -> PositionElement {
    PositionElement(point) {
      self
    }
  }

  /// Cuts off what this element draws outside its bounds.
  public func clipped() -> ClipElement {
    ClipElement {
      self
    }
  }

  /// Cuts off what this element draws outside `shape` fitted to its bounds:
  /// `.clipShape(.rect(cornerRadius: 12))`, `.clipShape(.capsule)`, `.clipShape(.circle)`.
  /// Anti-aliased. Hit-testing is cut to the bounds only, not the rounded corners.
  public func clipShape(_ shape: UIShape) -> ClipElement {
    ClipElement(shape) {
      self
    }
  }

  /// Rounds this element's corners by clipping it: `.clipShape(.rect(cornerRadius: radius))`.
  public func cornerRadius(_ radius: Float) -> ClipElement {
    self.clipShape(.rect(cornerRadius: radius))
  }

  /// A line `width` wide along the inside of this element's bounds, over it, rounded like
  /// `shape`. Changes no size.
  public func border(_ color: float4, width: Float = 1, in shape: UIShape = .rect) -> BorderElement {
    BorderElement(color, width: width, in: shape) {
      self
    }
  }

  /// A soft shadow under everything this element draws, blurred by `radius` and moved by `x`
  /// and `y`. Each shape under it casts its own. Changes no size. See `ShadowElement`.
  public func shadow(color: float4 = ShadowElement.defaultColor, radius: Float, x: Float = 0, y: Float = 0) -> ShadowElement {
    ShadowElement(color: color, radius: radius, x: x, y: y) {
      self
    }
  }

  /// Blurs everything this element draws by `radius`, about a standard deviation in points.
  /// Each shape under it blurs on its own. Changes no size. See `BlurElement`.
  public func blur(radius: Float) -> BlurElement {
    BlurElement(radius: radius) {
      self
    }
  }

  /// A frosted glass panel behind this element, fitted to it and cut to `shape`: what is drawn
  /// below, blurred and tinted by `material`. See `GlassBackground`.
  public func glass(_ material: GlassMaterial = .regular, in shape: UIShape = .rect) -> GlassBackground {
    GlassBackground(material, in: shape) {
      self
    }
  }

  /// A fixed width, height or both; a nil side takes this element's. See `Frame`.
  public func frame(width: Float? = nil, height: Float? = nil, alignment: Alignment = .center) -> Frame {
    Frame(width: width, height: height, alignment: alignment) {
      self
    }
  }

  /// Bounds on this element's width and height; `maxWidth: .infinity` fills the width offered.
  /// See `FlexFrame`.
  public func frame(
    minWidth: Float? = nil, idealWidth: Float? = nil, maxWidth: Float? = nil,
    minHeight: Float? = nil, idealHeight: Float? = nil, maxHeight: Float? = nil,
    alignment: Alignment = .center
  ) -> FlexFrame {
    FlexFrame(
      minWidth: minWidth, idealWidth: idealWidth, maxWidth: maxWidth,
      minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight, alignment: alignment
    ) {
      self
    }
  }

  public func background(_ color: float4) -> Background {
    Background(color) {
      self
    }
  }

  /// `shape` fitted to this element's bounds, filled with `color`, behind it:
  /// `.background(.blue, in: .capsule)`.
  public func background(_ color: float4, in shape: UIShape) -> Background {
    Background(color, in: shape) {
      self
    }
  }

  /// `content` behind this element, offered its size and aligned in it.
  public func background(
    alignment: Alignment = .center, @UIElementBuilder content: () -> [UIElement] = { [] }
  ) -> OverlayElement {
    OverlayElement(self, alignment: alignment, isBackground: true, content: content)
  }

  /// `content` in front of this element, offered its size and aligned in it.
  public func overlay(
    alignment: Alignment = .center, @UIElementBuilder content: () -> [UIElement] = { [] }
  ) -> OverlayElement {
    OverlayElement(self, alignment: alignment, content: content)
  }

  /// How this element enters and leaves when its insertion or removal is animated.
  public func transition(_ transition: UITransition) -> TransitionElement {
    TransitionElement(transition) {
      self
    }
  }

  /// Plays `keyframes` on this element's opacity, offset and scale each time `trigger` changes.
  /// Like an effect, it moves only what is drawn.
  public func keyframes<V: Equatable>(_ keyframes: UIKeyframes, trigger: V) -> KeyframeElement {
    KeyframeElement(keyframes, trigger: trigger) {
      self
    }
  }

  /// Animates the changes a write to the states `value` reads makes to this element — to the
  /// modifiers before this one in the chain, and to everything under it — with `animation`.
  ///
  /// A marker for `@Component`, which decides at compile time which updates animate. At runtime
  /// it adds nothing to the tree and returns the element it was called on.
  public func animation<V>(_ animation: UIAnimation?, value: V) -> Self {
    self
  }
}

/// Every element. The modifiers a `VectorShape` redefines to set its own properties, rather than
/// wrap it, live in this protocol's extension instead of `UIElement`'s: a member of a concrete
/// class ranks above a protocol extension's in overload resolution, so on a shape the shape's own
/// win, and on everything else these do.
@MainActor public protocol UIElementWrapping: AnyObject {}

extension UIElement: UIElementWrapping {}

extension UIElementWrapping where Self: UIElement {
  // Each of these sets its handler on the `HittableView` it is called on, when that is a plain
  // one with the slot free, and wraps anything else in one: `.onTap { }.onHover { }` is one
  // view, hit and hovered as one.

  public func onTap(_ callback: @escaping (Input) -> Void) -> HittableView {
    let view = self.hittable { $0.onTap == nil }
    view.onTap = callback
    return view
  }

  public func onHover(_ callback: @escaping (Bool, Input) -> Void) -> HittableView {
    let view = self.hittable { $0.onHover == nil }
    view.onHover = callback
    return view
  }

  /// Calls `callback` with true when the left button goes down on this element, and with false
  /// when it comes up again, wherever the pointer is by then.
  public func onPress(_ callback: @escaping (Bool, Input) -> Void) -> HittableView {
    let view = self.hittable { $0.onPress == nil }
    view.onPress = callback
    return view
  }

  /// This element, when it is a plain `HittableView` that `isFree` accepts, or a new one
  /// around it. A subclass — a draggable, a control's own — is always wrapped.
  func hittable(_ isFree: (HittableView) -> Bool) -> HittableView {
    if let view = self as? HittableView, type(of: view) == HittableView.self, isFree(view) {
      return view
    }
    return HittableView { self }
  }

  /// Sizes this element to a shape: the largest of that shape that fits what it is offered, or
  /// the smallest that covers it. A nil ratio is the element's own. An `Image` does this itself.
  public func aspectRatio(_ ratio: Float? = nil, contentMode: ContentMode) -> AspectRatioElement {
    AspectRatioElement(ratio, contentMode: contentMode) {
      self
    }
  }

  public func scaledToFit() -> AspectRatioElement {
    self.aspectRatio(nil, contentMode: .fit)
  }

  public func scaledToFill() -> AspectRatioElement {
    self.aspectRatio(nil, contentMode: .fill)
  }

  /// Where `guide` lies in this element, overriding its default: a stack aligned on `guide` lines
  /// this element up by it. Wraps nothing: it sets this element's own guide and returns it.
  public func alignmentGuide(_ guide: HorizontalAlignment, computeValue: @escaping (ViewDimensions) -> Float) -> Self {
    self.addGuide(guide.key, computeValue)
    return self
  }

  public func alignmentGuide(_ guide: VerticalAlignment, computeValue: @escaping (ViewDimensions) -> Float) -> Self {
    self.addGuide(guide.key, computeValue)
    return self
  }

  /// How many columns of a `Grid` this cell spans. Sets this element's own cell options and
  /// returns it, as do the other `gridCell…` modifiers.
  public func gridCellColumns(_ count: Int) -> Self {
    self.editGridCell { $0.columns = count }
  }

  /// How every cell in this cell's column is aligned horizontally.
  public func gridColumnAlignment(_ alignment: HorizontalAlignment) -> Self {
    self.editGridCell { $0.columnAlignment = alignment }
  }

  /// Where this cell sits in the space its grid gives it, whatever its column and row say.
  public func gridCellAnchor(_ anchor: Alignment) -> Self {
    self.editGridCell { $0.anchor = anchor }
  }

  /// Axes along which this cell takes its column's width or row's height without affecting it.
  public func gridCellUnsizedAxes(_ axes: Axis) -> Self {
    self.editGridCell { $0.unsizedAxes = axes }
  }

  private func editGridCell(_ edit: (inout GridCellOptions) -> Void) -> Self {
    var cell = self.ownGridCell ?? GridCellOptions()
    edit(&cell)
    self.ownGridCell = cell
    return self
  }

  /// Laid out as usual, but neither drawn nor hit. Wraps nothing: it hides this element and
  /// returns it.
  public func hidden() -> Self {
    self.isHidden = true
    return self
  }

  /// With false, the pointer passes through this element and everything in it — no hover, tap,
  /// press, scroll or drop — to what is underneath. It is still drawn, and still reached with
  /// Tab.
  public func allowsHitTesting(_ enabled: Bool) -> Self {
    self.allowsHitTesting = enabled
    return self
  }

  public func opacity(_ opacity: Float) -> EffectElement {
    EffectElement(opacity: opacity) {
      self
    }
  }

  /// How early a stack gives this element its share of space; 0 by default. Wraps nothing: it
  /// sets this element's own priority, which the wrappers around it pass on, and returns it.
  public func layoutPriority(_ value: Float) -> Self {
    self.ownLayoutPriority = value
    return self
  }

  /// Where this element is drawn among its siblings: higher in front; 0 by default. Wraps
  /// nothing: it sets this element's own index and returns it.
  public func zIndex(_ value: Float) -> Self {
    self.ownZIndex = value
    return self
  }

  /// Moves the drawn content by `offset`. Layout and hit-testing still see it where it was.
  public func offset(_ offset: float2) -> EffectElement {
    EffectElement(offset: offset) {
      self
    }
  }

  public func offset(x: Float = 0, y: Float = 0) -> EffectElement {
    self.offset(float2(x, y))
  }
}
