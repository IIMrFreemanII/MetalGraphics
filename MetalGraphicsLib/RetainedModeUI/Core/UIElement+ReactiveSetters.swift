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

  public func setAlignment(_ value: Alignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
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

  public func setAlignment(_ value: Alignment, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.alignment = value
    context.invalidate(.layout, animation: animation)
  }
}

// Color and size animate; a new face snaps. See `Text.restyle`.
extension Text {
  public func setText(_ value: String, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.text = value
    context.invalidate(.layout, animation: animation)
  }

  public func setFont(_ value: TextFont, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyle(context, animation) { $0.font = value }
  }

  public func setForegroundColor(_ value: float4, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.restyle(context, animation) { $0.color = value }
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
