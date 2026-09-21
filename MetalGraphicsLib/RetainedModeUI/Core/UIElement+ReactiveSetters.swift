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

extension Rectangle {
  public func setColor(_ value: float4, _ context: UIContext) -> Void {
    self.color = value
    context.invalidate()
  }
}

extension Background {
  public func setColor(_ value: float4, _ context: UIContext) -> Void {
    self.color = value
    context.invalidate()
  }
}

extension Frame {
  public func setSize(_ value: float2, _ context: UIContext) -> Void {
    self.size = value
    context.invalidate(layout: true)
  }

  public func setAlignment(_ value: Alignment, _ context: UIContext) -> Void {
    self.alignment = value
    context.invalidate(layout: true)
  }
}

extension Padding {
  public func setInset(_ value: Inset, _ context: UIContext) -> Void {
    self.inset = value
    context.invalidate(layout: true)
  }
}

extension VStack {
  public func setSpacing(_ value: Float, _ context: UIContext) -> Void {
    self.spacing = value
    context.invalidate(layout: true)
  }

  public func setAlignment(_ value: HorizontalAlignment, _ context: UIContext) -> Void {
    self.alignment = value
    context.invalidate(layout: true)
  }
}

extension HStack {
  public func setSpacing(_ value: Float, _ context: UIContext) -> Void {
    self.spacing = value
    context.invalidate(layout: true)
  }

  public func setAlignment(_ value: VerticalAlignment, _ context: UIContext) -> Void {
    self.alignment = value
    context.invalidate(layout: true)
  }
}

extension ExpandedFrame {
  public func setAxis(_ value: Axis, _ context: UIContext) -> Void {
    self.axis = value
    context.invalidate(layout: true)
  }

  public func setAlignment(_ value: Alignment, _ context: UIContext) -> Void {
    self.alignment = value
    context.invalidate(layout: true)
  }
}
