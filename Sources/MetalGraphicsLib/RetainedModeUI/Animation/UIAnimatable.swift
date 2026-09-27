import simd

/// A value the animator can interpolate.
///
/// Every animatable value in the library fits in four floats, so the animator does all of its
/// arithmetic on `SIMD4<Float>` and never goes through a generic or an existential per frame.
/// A conformance only has to say how to pack itself and how to come back.
public protocol UIAnimatable: Equatable {
  init(packed: SIMD4<Float>)
  var packed: SIMD4<Float> { get }
}

extension Float: UIAnimatable {
  public init(packed: SIMD4<Float>) {
    self = packed.x
  }

  public var packed: SIMD4<Float> {
    SIMD4(self, 0, 0, 0)
  }
}

extension SIMD2: UIAnimatable where Scalar == Float {
  public init(packed: SIMD4<Float>) {
    self.init(packed.x, packed.y)
  }

  public var packed: SIMD4<Float> {
    SIMD4(self.x, self.y, 0, 0)
  }
}

extension SIMD4: UIAnimatable where Scalar == Float {
  public init(packed: SIMD4<Float>) {
    self = packed
  }

  public var packed: SIMD4<Float> {
    self
  }
}

extension Inset: UIAnimatable {
  public init(packed: SIMD4<Float>) {
    self.init(left: packed.x, top: packed.y, right: packed.z, bottom: packed.w)
  }

  public var packed: SIMD4<Float> {
    SIMD4(self.left, self.top, self.right, self.bottom)
  }
}
