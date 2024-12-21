public class Counter {
  public var counter: Int = 0
  public func getId() -> Int {
    counter += 1
    return counter
  }
  
  public init() {}
}

//public class Context {
//  private var counter = Counter()
//  
//  private var leftMouseDownHandlers: [Int : () -> Void] = [:]
//  private var rightMouseDownHandlers: [Int : () -> Void] = [:]
//  
//  private var leftMouseUpHandlers: [Int : () -> Void] = [:]
//  private var rightMouseUpHandlers: [Int : () -> Void] = [:]
//  
//  private var mouseMoveHandlers: [Int : () -> Void] = [:]
//  private var mouseDragHandlers: [Int : () -> Void] = [:]
//  
//  private var scrollWheelHandlers: [Int : () -> Void] = [:]
//  
//  private var keyHandlers: [Int : () -> Void] = [:]
//  
//  public init() {
//    
//  }
//}
