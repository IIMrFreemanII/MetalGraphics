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
  
  private var renderableViews: [UInt : UIRenderableElement] = [:]
  
  public func registerRenderableView(_ view: UIRenderableElement) -> Void {
    self.renderableViews[view.id] = view
  }
  
  public func unregisterRenderableView(_ view: UIRenderableElement) -> Void {
    self.renderableViews.removeValue(forKey: view.id)
  }
  
  public func handleRenderableViews(_ renderer: Graphics2D) -> Void {
    let viewsToRender = self.renderableViews.values.sorted(by: { $0.depth < $1.depth })
    viewsToRender.forEach { $0.render(renderer) }
  }
  
  private var hittableViews: [UInt : HittableView] = [:]
  // 2d grid to store hittable views and handle hit tests against them
  
  public func registerHittableView(_ view: HittableView) -> Void {
    self.hittableViews[view.id] = view
  }
  
  public func unregisterHittableView(_ view: HittableView) -> Void {
    self.hittableViews.removeValue(forKey: view.id)
  }
  
  public func handleHitTest(_ grid: HittableGrid2D, _ input: Input, _ renderer: Graphics2D) -> Void {
    grid.reset()
    self.hittableViews.values.forEach { grid.mapViewToGrid($0, renderer) }
    grid.sortByDepth()
    grid.handleEvents(input)
  }
  
  public init() {
    
  }
}
