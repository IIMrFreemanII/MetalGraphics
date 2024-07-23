public struct Inset {
  public var left: Float
  public var top: Float
  public var right: Float
  public var bottom: Float

  public var horizontal: Float {
    self.left + self.right
  }

  public var vertical: Float {
    self.top + self.bottom
  }

  public var topLeft: float2 {
    float2(self.left, self.top)
  }

  public init(left: Float = 0, top: Float = 0, right: Float = 0, bottom: Float = 0) {
    self.left = left
    self.top = top
    self.right = right
    self.bottom = bottom
  }

  public init(all: Float) {
    self.left = all
    self.top = all
    self.right = all
    self.bottom = all
  }

  public init(vertical: Float = 0, horizontal: Float = 0) {
    self.left = horizontal
    self.top = vertical
    self.right = horizontal
    self.bottom = vertical
  }

  /// Returns a new size that is bigger than the given size by the amount of inset in the horizontal and vertical directions.
  public func inflate(size: float2) -> float2 {
    size + float2(self.horizontal, self.vertical)
  }

  /// Returns a new size that is smaller than the given size by the amount of inset in the horizontal and vertical directions.
  public func deflate(size: float2) -> float2 {
    size - float2(self.horizontal, self.vertical)
  }
}
