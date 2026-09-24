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
