import simd

/// Something the pointer can hover, press and tap: a `HittableView`, which is hit anywhere in
/// its laid-out rect, or a `VectorCanvas` shape, which is hit only inside its own outline.
@MainActor public protocol Hittable: AnyObject {
  var mounted: Bool { get }
  /// Top left corner and size of the rect the hit grid files it under, in points, window top
  /// left origin, y down. Nothing outside it can hit.
  var hitPosition: float2 { get }
  var hitSize: float2 { get }

  var isHovered: Bool { get set }
  var isPressed: Bool { get set }

  var onTap: ((Input) -> Void)? { get }
  var onHover: ((Bool, Input) -> Void)? { get }
  var onPress: ((Bool, Input) -> Void)? { get }

  /// Whether `point` — window top left origin, y down, in points — hits it.
  func hitTest(_ point: float2) -> Bool
}

extension Hittable {
  var handlesEvents: Bool { self.onTap != nil || self.onHover != nil || self.onPress != nil }
}
