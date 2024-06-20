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
    return StepIterator(from: from, to: to, step: step)
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
    guard step != 0 && !stop else { return nil }  // Step must not be zero to avoid infinite loop
    
    let nextValue = current
    current += step
    
    if nextValue >= to {
      stop = true
      return to
    }
    
    return nextValue
  }
}
