import simd

// SwiftUI's pointer modifiers. Each sets its part of the `HittableView` it is called on, when
// that is a plain one with the part free, and wraps anything else in one; a vector shape has
// its own, which set the shape itself. See `UIElementWrapping.hittable`.
extension UIElementWrapping where Self: UIElement {
  /// The pointer's shape over this element: `.pointerStyle(.link)`. Nil leaves it to what is
  /// around it.
  public func pointerStyle(_ style: PointerStyle?) -> HittableView {
    let view = self.hittable { $0.pointerStyle == nil }
    view.pointerStyle = style
    return view
  }

  /// Calls `action` with `.active(location)` when the pointer enters this element and whenever
  /// it moves over it, and with `.ended` when it leaves. `.local` locations are from the
  /// element's top left corner; `.global` from the window's.
  public func onContinuousHover(
    coordinateSpace: CoordinateSpace = .local, perform action: @escaping (HoverPhase) -> Void
  ) -> HittableView {
    let view = self.hittable { $0.onContinuousHover == nil }
    view.setContinuousHover(coordinateSpace, action)
    return view
  }

  /// Calls `action` when `count` clicks in a row end — the button coming up — over this
  /// element. Unlike `onTap`, which fires as the button goes down, a press that is dragged off
  /// the element before it comes up taps nothing.
  public func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> HittableView {
    let view = self.hittable { $0.tapAction == nil }
    view.setTapGesture(count, .local, HittableView.tapAction(action))
    return view
  }

  /// Calls `action` with where `count` clicks in a row ended over this element.
  public func onTapGesture(
    count: Int = 1, coordinateSpace: CoordinateSpace = .local, perform action: @escaping (float2) -> Void
  ) -> HittableView {
    let view = self.hittable { $0.tapAction == nil }
    view.setTapGesture(count, coordinateSpace, action)
    return view
  }

  /// Recognizes `gesture` on this element: a `DragGesture` or a `TapGesture`.
  public func gesture(_ gesture: some Gesture) -> HittableView {
    let view = self.hittable { $0.gesture == nil }
    view.gesture = gesture
    return view
  }

  /// Where this element is hit: inside `shape` resolved in its rect, rather than anywhere in
  /// the rect. The handlers set on the same view after it use it.
  public func contentShape(_ shape: UIShape) -> HittableView {
    let view = self.hittable { $0.hitShape == nil }
    view.hitShape = shape
    return view
  }
}
