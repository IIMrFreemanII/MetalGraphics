import AppKit
import simd

// The update door for generated code.
//
// A macro has no cross-file visibility, so it cannot discover that changing `Frame.size` needs
// a re-layout while changing `Rectangle.color` does not. That knowledge lives here instead —
// three lines from the property it invalidates, and checked by the compiler — while the macro
// only needs to know which setter name an argument maps to (see ElementCatalog.swift).
//
// These are also what makes generated code a single direct method call: no key paths, no
// closures, no allocation.
//
// Animatable setters take an optional animation and go through `Animator.set`, which either
// writes straight through or starts an animation that calls the closure given here once per
// frame. The closure is the one place the property is written and invalidated, so an animated
// write invalidates exactly what a plain one would. It captures nothing, so passing it costs
// nothing.
//
// Setters of values that cannot be interpolated — text, alignment, axis — still take an
// animation: their own value snaps, but it is handed to `invalidate`, so whatever the new layout
// moves within its container slides there (see `UIElement.place(_:at:in:)`).

extension Rectangle {
  public func setColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .color, from: self.color, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Rectangle.self).color = float4(packed: value)
      context.invalidate()
    }
  }
}

extension Background {
  public func setColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .color, from: self.color, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Background.self).color = float4(packed: value)
      context.invalidate()
    }
  }
}

extension Frame {
  public func setSize(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .size, from: self.size, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Frame.self).size = float2(packed: value)
      context.invalidate(.layout)
    }
  }

  /// Animates between two widths; to or from nil — the child's width — it snaps, and what the
  /// new layout moves slides.
  public func setWidth(_ value: Float?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard let value, let old = self.width else {
      context.animator.cancel(self, .width)
      self.width = value
      context.invalidate(.layout, animation: animation)
      return
    }
    context.animator.set(self, .width, from: old, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Frame.self).width = value.x
      context.invalidate(.layout)
    }
  }

  /// See `setWidth`.
  public func setHeight(_ value: Float?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard let value, let old = self.height else {
      context.animator.cancel(self, .height)
      self.height = value
      context.invalidate(.layout, animation: animation)
      return
    }
    context.animator.set(self, .height, from: old, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Frame.self).height = value.x
      context.invalidate(.layout)
    }
  }

  public func setAlignment(_ value: Alignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

// A bound snaps; what the new layout moves slides.
extension FlexFrame {
  public func setMinWidth(_ value: Float?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.minWidth = value
    context.invalidate(.layout, animation: animation)
  }

  public func setIdealWidth(_ value: Float?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.idealWidth = value
    context.invalidate(.layout, animation: animation)
  }

  public func setMaxWidth(_ value: Float?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.maxWidth = value
    context.invalidate(.layout, animation: animation)
  }

  public func setMinHeight(_ value: Float?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.minHeight = value
    context.invalidate(.layout, animation: animation)
  }

  public func setIdealHeight(_ value: Float?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.idealHeight = value
    context.invalidate(.layout, animation: animation)
  }

  public func setMaxHeight(_ value: Float?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.maxHeight = value
    context.invalidate(.layout, animation: animation)
  }

  public func setAlignment(_ value: Alignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

extension AspectRatioElement {
  /// A new ratio snaps; what the new layout moves slides.
  public func setRatio(_ value: Float?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.ratio = value
    context.invalidate(.layout, animation: animation)
  }

  public func setContentMode(_ value: ContentMode, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.contentMode = value
    context.invalidate(.layout, animation: animation)
  }
}

extension PositionElement {
  public func setPoint(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .origin, from: self.point, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: PositionElement.self).point = float2(packed: value)
      context.invalidate(.layout)
    }
  }
}

extension Spacer {
  public func setMinLength(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .size, from: self.minLength, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Spacer.self).minLength = value.x
      context.invalidate(.layout)
    }
  }
}

extension Grid {
  public func setAlignment(_ value: Alignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }

  public func setHorizontalSpacing(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .spacing, from: self.horizontalSpacing, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Grid.self).horizontalSpacing = value.x
      context.invalidate(.layout)
    }
  }

  public func setVerticalSpacing(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .lineSpacing, from: self.verticalSpacing, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Grid.self).verticalSpacing = value.x
      context.invalidate(.layout)
    }
  }
}

extension GridRow {
  public func setAlignment(_ value: VerticalAlignment?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

extension LazyGridElement {
  /// New tracks snap; what the new layout moves slides.
  public func setItems(_ value: [GridItem], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.items = value
    context.invalidate(.layout, animation: animation)
  }

  public func setSpacing(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .spacing, from: self.spacing, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: LazyGridElement.self).spacing = value.x
      context.invalidate(.layout)
    }
  }
}

extension LazyVGrid {
  public func setAlignment(_ value: HorizontalAlignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

extension LazyHGrid {
  public func setAlignment(_ value: VerticalAlignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

extension LayoutView {
  /// Keeps the children; with an animation, each slides to where the new layout puts it.
  public func setLayout<L: Layout>(_ value: L, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setLayout(AnyLayout(value))
    context.invalidate(.layout, animation: animation)
  }
}

extension ViewThatFits {
  public func setAxes(_ value: Axis, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.axes = value
    context.invalidate(.layout, animation: animation)
  }
}

extension ZStack {
  public func setAlignment(_ value: Alignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

extension OverlayElement {
  public func setAlignment(_ value: Alignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

extension UIElement {
  /// Grid cell options snap; what the new layout moves slides.
  public func setGridCellColumns(_ value: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setGridCell(context, animation) { $0.columns = value }
  }

  public func setGridColumnAlignment(_ value: HorizontalAlignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setGridCell(context, animation) { $0.columnAlignment = value }
  }

  public func setGridCellAnchor(_ value: Alignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setGridCell(context, animation) { $0.anchor = value }
  }

  public func setGridCellUnsizedAxes(_ value: Axis, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setGridCell(context, animation) { $0.unsizedAxes = value }
  }

  private func setGridCell(_ context: UIContext, _ animation: UIAnimation?, _ edit: (inout GridCellOptions) -> Void) {
    var cell = self.ownGridCell ?? GridCellOptions()
    edit(&cell)
    self.ownGridCell = cell
    context.invalidate(.layout, animation: animation)
  }

  /// Reorders what is drawn and hit; nothing moves.
  public func setZIndex(_ value: Float, _ context: UIContext) -> Void {
    guard self.ownZIndex != value else { return }
    self.ownZIndex = value
    context.invalidate(.treeOrder)
  }

  /// A new priority snaps; what the new layout moves slides.
  public func setLayoutPriority(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard self.ownLayoutPriority != value else { return }
    self.ownLayoutPriority = value
    context.invalidate(.layout, animation: animation)
  }
}

extension Padding {
  public func setInset(_ value: Inset, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .inset, from: self.inset, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Padding.self).inset = Inset(packed: value)
      context.invalidate(.layout)
    }
  }

  /// `.padding(length)`: the same length on every edge.
  public func setInset(_ length: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setInset(Inset(all: length), context, animation: animation)
  }

  /// `.padding(edges)`: the default length on those edges.
  public func setInset(_ edges: Edge.Set, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setInset(Inset(edges), context, animation: animation)
  }
}

extension VStack {
  public func setSpacing(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .spacing, from: self.spacing, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: VStack.self).spacing = value.x
      context.invalidate(.layout)
    }
  }

  public func setAlignment(_ value: HorizontalAlignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

extension HStack {
  public func setSpacing(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .spacing, from: self.spacing, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: HStack.self).spacing = value.x
      context.invalidate(.layout)
    }
  }

  public func setAlignment(_ value: VerticalAlignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

extension ExpandedFrame {
  public func setAxis(_ value: Axis, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.axis = value
    context.invalidate(.layout, animation: animation)
  }
}

// Color and size animate; a new face snaps. See `Text.restyle`. The rest only relayout, and
// skip a value that did not change.
extension Text {
  public func setText(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.text else { return }
    self.text = value
    context.invalidate(.layout, animation: animation)
  }

  public func setFont(_ value: TextFont?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyle(context, animation) { $0.style.font = value }
  }

  public func setForegroundColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyle(context, animation) { $0.style.foreground = value }
  }

  public func setFontWeight(_ value: TextFont.Weight?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.weight, value, context, animation)
  }

  public func setFontDesign(_ value: TextFont.Design?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.design, value, context, animation)
  }

  public func setBold(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.weight, value ? .bold : .regular, context, animation)
  }

  public func setItalic(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.italic, value, context, animation)
  }

  public func setMonospaced(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.monospaced, value, context, animation)
  }

  public func setUnderline(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.underline, TextDecorationStyle(isActive: value, color: self.style.underline?.color), context, animation)
  }

  public func setUnderlineColor(_ value: float4?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.underline, TextDecorationStyle(isActive: self.style.underline?.isActive ?? true, color: value), context, animation)
  }

  public func setStrikethrough(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.strikethrough, TextDecorationStyle(isActive: value, color: self.style.strikethrough?.color), context, animation)
  }

  public func setStrikethroughColor(_ value: float4?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(
      \.strikethrough, TextDecorationStyle(isActive: self.style.strikethrough?.isActive ?? true, color: value), context, animation
    )
  }

  public func setKerning(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.kerning, value, context, animation)
  }

  public func setTracking(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.tracking, value, context, animation)
  }

  public func setBaselineOffset(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.baselineOffset, value, context, animation)
  }

  public func setLineLimit(_ value: Int?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.lineLimit, .some(value), context, animation)
  }

  public func setMultilineTextAlignment(_ value: TextAlignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.alignment, value, context, animation)
  }

  public func setTruncationMode(_ value: TextTruncationMode, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.truncation, value, context, animation)
  }

  public func setLineSpacing(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.lineSpacing, value, context, animation)
  }

  public func setMinimumScaleFactor(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.minimumScaleFactor, value, context, animation)
  }

  public func setTextCase(_ value: TextCase?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.textCase, .some(value), context, animation)
  }
}

// The colour only redraws, and animates; the rest relayout every text under it, and skip a
// value that did not change.
extension TextStyleElement {
  public func setFont(_ value: TextFont?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.font, value, context, animation)
  }

  public func setFontWeight(_ value: TextFont.Weight?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.weight, value, context, animation)
  }

  public func setFontDesign(_ value: TextFont.Design?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.design, value, context, animation)
  }

  public func setBold(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.weight, value ? .bold : .regular, context, animation)
  }

  public func setItalic(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.italic, value, context, animation)
  }

  public func setMonospaced(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.monospaced, value, context, animation)
  }

  public func setUnderline(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.underline, TextDecorationStyle(isActive: value, color: self.overrides.underline?.color), context, animation)
  }

  public func setUnderlineColor(_ value: float4?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(
      \.underline, TextDecorationStyle(isActive: self.overrides.underline?.isActive ?? true, color: value), context, animation
    )
  }

  public func setStrikethrough(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(
      \.strikethrough, TextDecorationStyle(isActive: value, color: self.overrides.strikethrough?.color), context, animation
    )
  }

  public func setStrikethroughColor(_ value: float4?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(
      \.strikethrough, TextDecorationStyle(isActive: self.overrides.strikethrough?.isActive ?? true, color: value),
      context, animation
    )
  }

  public func setKerning(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.kerning, value, context, animation)
  }

  public func setTracking(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.tracking, value, context, animation)
  }

  public func setBaselineOffset(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.baselineOffset, value, context, animation)
  }

  public func setLineLimit(_ value: Int?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.lineLimit, .some(value), context, animation)
  }

  public func setMultilineTextAlignment(_ value: TextAlignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.alignment, value, context, animation)
  }

  public func setTruncationMode(_ value: TextTruncationMode, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.truncation, value, context, animation)
  }

  public func setLineSpacing(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.lineSpacing, value, context, animation)
  }

  public func setMinimumScaleFactor(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.minimumScaleFactor, value, context, animation)
  }

  public func setTextCase(_ value: TextCase?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyleLayout(\.textCase, .some(value), context, animation)
  }
}

// The pointer's shape changes at once, never animated. Over what the pointer is on, it is
// re-resolved at the end of the frame, with no hit test.
extension HittableView {
  public func setPointerStyle(_ value: PointerStyle?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.pointerStyle else { return }
    self.pointerStyle = value
    if self.isHovered || self.isPressed {
      context.pointerStyleStale = true
    }
  }

  /// Read live by `hitTest`: nothing to invalidate.
  public func setContentShape(_ value: UIShape, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.hitShape = value
  }
}

extension VectorShape {
  public func setPointerStyle(_ value: PointerStyle?, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.pointerStyle else { return }
    self.pointerStyle = value
    if self.isHovered || self.isPressed {
      context.pointerStyleStale = true
    }
  }
}

extension UIElement {
  /// Changes what the pointer can reach, so the hit order is rebuilt; once, never animated.
  public func setAllowsHitTesting(_ value: Bool, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.allowsHitTesting else { return }
    self.allowsHitTesting = value
    context.invalidate(.treeOrder)
  }
}

// A new image snaps; its foreground color animates.
extension Image {
  public func setName(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.load(name: value)
    context.invalidate(.layout, animation: animation)
  }

  public func setNSImage(_ value: NSImage, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.load(nsImage: value)
    context.invalidate(.layout, animation: animation)
  }

  public func setSVG(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.load(svg: value)
    context.invalidate(.layout, animation: animation)
  }

  public func setForegroundColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .color, from: self.color, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Image.self).color = float4(packed: value)
      context.invalidate()
    }
  }
}

// Effects only change how things are drawn, never where they are laid out or hit.
extension EffectElement {
  public func setOpacity(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .opacity, from: self.opacity, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: EffectElement.self).opacity = value.x
      context.invalidate()
    }
  }

  public func setOffset(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .offset, from: self.offset, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: EffectElement.self).offset = float2(packed: value)
      context.invalidate()
    }
  }
}

extension ShadowElement {
  public func setColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .color, from: self.color, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: ShadowElement.self).color = float4(packed: value)
      context.invalidate()
    }
  }

  public func setRadius(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .radius, from: self.radius, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: ShadowElement.self).radius = value.x
      context.invalidate()
    }
  }

  public func setX(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .offsetX, from: self.x, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: ShadowElement.self).x = value.x
      context.invalidate()
    }
  }

  public func setY(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .offsetY, from: self.y, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: ShadowElement.self).y = value.x
      context.invalidate()
    }
  }
}

extension BlurElement {
  public func setRadius(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .radius, from: self.radius, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: BlurElement.self).radius = value.x
      context.invalidate()
    }
  }
}

extension GlassBackground {
  /// Snaps: a material has more to it than one animatable value holds.
  public func setMaterial(_ value: GlassMaterial, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    guard value != self.material else { return }
    self.material = value
    context.invalidate()
  }
}

// Vector shapes: only a `Path`'s outline ever re-bakes. Everything else changes the one item a
// shape draws as, so it only needs drawing again.
extension VectorShape {
  public func setColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .color, from: self.color, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: VectorShape.self).color = float4(packed: value)
      context.invalidate()
    }
  }

  public func setLineWidth(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .lineWidth, from: self.lineWidth, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: VectorShape.self).lineWidth = value.x
      context.invalidate()
    }
  }

  public func setTrimFrom(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .trimFrom, from: self.trim.x, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: VectorShape.self).trim.x = value.x
      context.invalidate()
    }
  }

  public func setTrimTo(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .trimTo, from: self.trim.y, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: VectorShape.self).trim.y = value.x
      context.invalidate()
    }
  }

  public func setRotation(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .rotation, from: self.rotation, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: VectorShape.self).rotation = value.x
      context.invalidate()
    }
  }

  public func setRotationAnchor(_ value: float2?, _ context: UIContext) -> Void {
    self.rotationAnchor = value
    context.invalidate()
  }

  public func setScale(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .scale, from: self.scale, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: VectorShape.self).scale = value.x
      context.invalidate()
    }
  }

  public func setScaleAnchor(_ value: float2?, _ context: UIContext) -> Void {
    self.scaleAnchor = value
    context.invalidate()
  }

  public func setOffset(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .offset, from: self.offset, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: VectorShape.self).offset = float2(packed: value)
      context.invalidate()
    }
  }

  public func setOpacity(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .opacity, from: self.opacity, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: VectorShape.self).opacity = value.x
      context.invalidate()
    }
  }
}

extension Circle {
  public func setCenter(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .center, from: self.center, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Circle.self).center = float2(packed: value)
      context.invalidate()
    }
  }

  public func setRadius(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .radius, from: self.radius, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Circle.self).radius = value.x
      context.invalidate()
    }
  }
}

extension Ellipse {
  public func setCenter(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .center, from: self.center, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Ellipse.self).center = float2(packed: value)
      context.invalidate()
    }
  }

  public func setRadii(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .radius, from: self.radii, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: Ellipse.self).radii = float2(packed: value)
      context.invalidate()
    }
  }
}

extension RoundedRectangle {
  public func setOrigin(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .origin, from: self.origin, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: RoundedRectangle.self).origin = float2(packed: value)
      context.invalidate()
    }
  }

  public func setSize(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .size, from: self.size, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: RoundedRectangle.self).size = float2(packed: value)
      context.invalidate()
    }
  }

  public func setCornerRadius(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .cornerRadius, from: self.cornerRadius, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: RoundedRectangle.self).cornerRadius = value.x
      context.invalidate()
    }
  }
}

// A path's outline is the one thing that re-bakes, once per frame at most, while it changes.
extension Path {
  /// Morphs to `value` with an animation when it has the same commands as what is shown.
  public func setD(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.morph(to: value, context, animation: animation)
  }

  public func setValue(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setValue(float4(value, 0, 0, 0), context, animation: animation)
  }

  public func setValue(_ value: float2, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setValue(float4(value.x, value.y, 0, 0), context, animation: animation)
  }

  public func setValue(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .pathValue, from: self.value, to: value, animation, context) { element, value, context in
      let path = unsafeDowncast(element, to: Path.self)
      path.value = value
      path.outlineChanged = true
      context.invalidate()
    }
  }
}

extension ScrollView {
  public func setAxes(_ value: Axis, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.axes = value
    context.invalidate(.layout, animation: animation)
  }

  public func setShowsIndicators(_ value: Bool, _ context: UIContext) -> Void {
    self.showsIndicators = value
    context.invalidate()
  }

  public func setIndicatorVisibility(_ value: ScrollIndicatorVisibility, _ context: UIContext) -> Void {
    self.indicatorVisibility = value
    context.invalidate()
  }

  /// Only the wheel reads it, so nothing needs redrawing.
  public func setScrollDisabled(_ value: Bool, _ context: UIContext) -> Void {
    self.isScrollDisabled = value
  }
}

// Shapes fitted to an element's bounds. Their corner radii animate; a change of kind —
// `.rect(cornerRadius: 8)` to `.capsule` — snaps, since the two resolve their radii differently.
// Only what is drawn changes, except where a clip's kind moves its bounds, which hit-testing uses.

extension ClipElement {
  public func setShape(_ value: UIShape, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let snapsKind = value.kind != self.shape.kind
    context.animator.set(self, .shape, from: self.shape.radii, to: value.radii, snapsKind ? nil : animation, context) { element, value, context in
      unsafeDowncast(element, to: ClipElement.self).shape.radii = value
      context.invalidate()
    }
    if snapsKind {
      self.shape = value
      context.invalidate([.render, .hitGrid])
    }
  }

  public func setCornerRadius(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.setShape(.rect(cornerRadius: value), context, animation: animation)
  }
}

extension Background {
  public func setShape(_ value: UIShape, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let snapsKind = value.kind != self.shape.kind
    context.animator.set(self, .shape, from: self.shape.radii, to: value.radii, snapsKind ? nil : animation, context) { element, value, context in
      unsafeDowncast(element, to: Background.self).shape.radii = value
      context.invalidate()
    }
    if snapsKind {
      self.shape = value
      context.invalidate()
    }
  }
}

extension BorderElement {
  public func setColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .color, from: self.color, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: BorderElement.self).color = float4(packed: value)
      context.invalidate()
    }
  }

  public func setLineWidth(_ value: Float, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    context.animator.set(self, .lineWidth, from: self.lineWidth, to: value, animation, context) { element, value, context in
      unsafeDowncast(element, to: BorderElement.self).lineWidth = value.x
      context.invalidate()
    }
  }

  public func setShape(_ value: UIShape, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let snapsKind = value.kind != self.shape.kind
    context.animator.set(self, .shape, from: self.shape.radii, to: value.radii, snapsKind ? nil : animation, context) { element, value, context in
      unsafeDowncast(element, to: BorderElement.self).shape.radii = value
      context.invalidate()
    }
    if snapsKind {
      self.shape = value
      context.invalidate()
    }
  }
}

extension DraggableElement {
  /// Invalidates nothing: the payload is never drawn, only handed to a destination on drop.
  public func setDragPayload(_ value: Any, _ context: UIContext) -> Void {
    self.payload = value
  }
}
