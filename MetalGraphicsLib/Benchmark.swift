import Foundation

private var store = [String: (Int, Double)]()

public func benchmark(title: String, mean: Bool = false, operation: () -> Void) {
  let startTime = CFAbsoluteTimeGetCurrent()
  operation()
  let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 * 1000
  var result = Double()

  if mean {
    if var temp = store[title] {
      if temp.0 > (5 * 60) {
        result = timeElapsed
        store[title] = (1, timeElapsed)
      } else {
        temp.0 += 1
        temp.1 += timeElapsed

        result = temp.1 / Double(temp.0)
        store[title] = temp
      }
    } else {
      result = timeElapsed
      store[title] = (1, timeElapsed)
    }
  } else {
    result = timeElapsed
  }

  print("\(title): \(String(format: "%.3f", result)) us")
}
