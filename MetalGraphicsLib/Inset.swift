struct Inset {
  var left: Float
  var top: Float
  var right: Float
  var bottom: Float
  
  var horizontal: Float {
    left + right
  }
  
  var vertical: Float {
    top + bottom
  }
  
  var topLeft: float2 {
    float2(left, top)
  }
  
  init(left: Float = 0, top: Float = 0, right: Float = 0, bottom: Float = 0)
  {
    self.left = left
    self.top = top
    self.right = right
    self.bottom = bottom
  }
  
  init(all: Float) {
    self.left = all
    self.top = all
    self.right = all
    self.bottom = all
  }
  
  init(vertical: Float = 0, horizontal: Float = 0) {
    self.left = horizontal
    self.top = vertical
    self.right = horizontal
    self.bottom = vertical
  }
  
  ///Returns a new size that is bigger than the given size by the amount of inset in the horizontal and vertical directions.
  func inflate(size: float2) -> float2 {
    return size + float2(horizontal, vertical)
  }
  
  /// Returns a new size that is smaller than the given size by the amount of inset in the horizontal and vertical directions.
  func deflate(size: float2) -> float2 {
    return size - float2(horizontal, vertical)
  }
}
