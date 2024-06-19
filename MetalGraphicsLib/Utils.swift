public func iterateWithStep(from start: Float, to end: Float, step: Float, action: (Float) -> Void) {
  guard step != 0 else { return }  // Step must not be zero to avoid infinite loop
  
  var current = start
  while current < end {
    action(current)
    current += step
  }
  
  action(end)
}
