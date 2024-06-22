///
/// Steps through the sequence includint start and end
///
public struct StepSequence: Sequence {
  public let from: Float
  public let to: Float
  public let step: Float

  public init(from: Float, to: Float, step: Float) {
    self.from = from
    self.to = to
    self.step = step
  }

  public func makeIterator() -> StepIterator {
    StepIterator(from: self.from, to: self.to, step: self.step)
  }
}

public struct StepIterator: IteratorProtocol {
  public let from: Float
  public let to: Float
  public let step: Float
  public var current: Float
  public var stop: Bool

  public init(from: Float, to: Float, step: Float) {
    self.from = from
    self.to = to
    self.step = step
    self.current = from
    self.stop = false
  }

  public mutating func next() -> Float? {
    guard self.step != 0, !self.stop else { return nil } // Step must not be zero to avoid infinite loop

    let nextValue = self.current
    self.current += self.step

    if nextValue >= self.to {
      self.stop = true
      return self.to
    }

    return nextValue
  }
}
