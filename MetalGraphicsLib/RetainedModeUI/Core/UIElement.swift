import simd

@MainActor open class UIElement {
  public var mounted = false
  public var depth: Int = 0

  public init() {}
  
  /// The element's own mount behaviour. Built-in elements override this to register themselves
  /// with the context; `@Component` generates it, which is why a component must not write one (F7).
  ///
  /// To run your own code on mount, override `onMount(_:)` instead.
  open func mount(_ context: UIContext) -> Void {}
  
  /// Called just after this element mounts, before its children do.
  ///
  /// The hook to override in your own elements and components. Unlike `mount(_:)` it is never
  /// generated and never owned by the macro, so overriding it can never collide with `@Component`.
  open func onMount(_ context: UIContext) -> Void {}
  
  internal func handleMount(_ context: UIContext) -> Void {}
  
  /// The element's own unmount behaviour. The mirror of `mount(_:)`, and macro-owned in the same
  /// way. To run your own code on unmount, override `onUnmount(_:)` instead.
  open func unmount(_ context: UIContext) -> Void {}

  /// Called just before this element unmounts, before its children do.
  open func onUnmount(_ context: UIContext) -> Void {}

  internal func handleUnmount(_ context: UIContext) -> Void {}
  
  // Sets children from a builder closure, once. Builder content used to be a reaction that
  // re-ran when a `State` it read changed; a `@Component`'s content is now generated straight
  // into its `__build`, so nothing here re-evaluates.
  public func setStaticContent(_ build: () -> [UIElementNode]) -> Void {
    self.applyContent(DynamicContent.elements(build()))
  }

  // Applies content at construction time, before the element is mounted.
  internal func applyContent(_ elements: [UIElement]) -> Void {
    assertionFailure("\(type(of: self)) does not accept content")
  }

  open func debugHierarchy(_ offset: String) -> Void {
    print(offset + "\(self)".split(separator: ".").last!)
  }
  
  open func calcSize(_ availableSize: float2) -> float2 {
    return .init()
  }
  
  open func getSize() -> float2 {
    return .init()
  }
  
  open func calcDepth(_ parentDepth: Int) -> Void {
    self.depth = parentDepth
  }
  open func calcPosition(_ position: float2) -> Void {}
//  open func render(_ renderer: Graphics2D) -> Void {}
  open func handleHitTest(_ input: Input) -> Bool {
    return false
  }
}
