import Foundation

public func iterateWithStep(from start: Float, to end: Float, step: Float, action: (Float) -> Void) {
  guard step != 0 else { return } // Step must not be zero to avoid infinite loop

  var current = start
  while current < end {
    action(current)
    current += step
  }

  action(end)
}

public func name<T>(of _: T.Type) -> String {
  String(describing: T.self)
}

public class Debouncer {
  private var workItem: DispatchWorkItem?
  private let queue: DispatchQueue
  
  public init(queue: DispatchQueue = .main) {
    self.queue = queue
  }
  
  public func debounce(delay: TimeInterval, action: @escaping () -> Void) {
    // Cancel the previous work item if it exists
    workItem?.cancel()
    
    // Create a new work item
    workItem = DispatchWorkItem(block: action)
    
    // Schedule the work item after the specified delay
    if let workItem = workItem {
      queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
  }
}
