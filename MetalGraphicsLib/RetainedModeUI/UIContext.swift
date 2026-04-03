public class Counter {
  public var counter: Int = 0
  public func getId() -> Int {
    counter += 1
    return counter
  }
  
  public init() {}
}
@MainActor
public class UIContext {
  private var counter = Counter()
  
  private var leftMouseDownHandlers: [Int : () -> Void] = [:]
  private var rightMouseDownHandlers: [Int : () -> Void] = [:]
  
  private var leftMouseUpHandlers: [Int : () -> Void] = [:]
  private var rightMouseUpHandlers: [Int : () -> Void] = [:]
  
  private var mouseMoveHandlers: [Int : () -> Void] = [:]
  private var mouseDragHandlers: [Int : () -> Void] = [:]
  
  private var scrollWheelHandlers: [Int : () -> Void] = [:]
  
  private var keyHandlers: [Int : () -> Void] = [:]
  
  private var hittableViews: [UInt : HittableView] = [:]
  // 2d grid to store hittable views and handle hit tests against them
  
  public func registerHittableView(_ view: HittableView) -> Void {
    self.hittableViews[view.id] = view
  }
  public func unregisterHittableView(_ view: HittableView) -> Void {
    self.hittableViews.removeValue(forKey: view.id)
  }
  
  public func handleHitTest() -> Void {
    self.hittableViews.values.forEach { print("handleHitTest for \($0.id)") }
  }
  
  public init() {
    
  }
}
