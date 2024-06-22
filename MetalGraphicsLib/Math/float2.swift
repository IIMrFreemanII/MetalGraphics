public typealias float2 = SIMD2<Float>

public extension float2 {
  var width: Float {
    x
  }

  var height: Float {
    y
  }

  /// returns new float2 with greatest component and other components set to 0
  var greatestComponent: float2 {
    let condition = x > y
    return float2(x * Float(condition), y * Float(!condition))
  }

  var asInt2: int2 {
    int2(Int(x), Int(y))
  }
}
