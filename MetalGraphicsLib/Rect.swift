public struct Rect {
  var position: float2
  var size: float2
  
  init(position: float2 = float2(), size: float2 = float2()) {
    self.position = position
    self.size = size
  }
  
  init(x: Float = 0, y: Float = 0, width: Float = 0, height: Float = 0) {
    self.position = float2(x, y)
    self.size = float2(width, height)
  }
  
  var center: float2 {
    position + size * 0.5
  }
  
  var width: Float {
    size.x
  }
  var height: Float {
    size.y
  }
  
  var minX: Float {
    position.x
  }
  var minY: Float {
    position.y
  }
  
  var maxX: Float {
    position.x + size.x
  }
  var maxY: Float {
    position.y + size.y
  }
  
  /// Returns a new rect that is smaller than the given rect by the amount of inset in the horizontal and vertical directions.
  func deflate(by inset: Inset) -> Rect {
    return Rect(
      position: self.position + inset.topLeft,
      size: inset.deflate(size: self.size)
    )
  }
  
  ///Returns a new rect that is bigger than the given rect by the amount of inset in the horizontal and vertical directions.
  func inflate(by inset: Inset) -> Rect {
    return Rect(
      position: self.position,
      size: inset.inflate(size: self.size)
    )
  }
}
