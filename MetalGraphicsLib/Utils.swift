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

public func forEachGridCell(_ gridSize: int2, _ cellSize: Float, _ spacing: Float, _ cb: (float2) -> Void) -> Void {
  for y in 0..<gridSize.y {
    for x in 0..<gridSize.x {
      let coord = (float2(Float(x), Float(y)) * (cellSize + spacing)) - (float2(Float(gridSize.x), Float(gridSize.y)) * cellSize * 0.5) + float2(cellSize * 0.5, cellSize * 0.5)
      cb(coord)
    }
  }
}
