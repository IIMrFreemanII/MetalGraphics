import simd
import Combine

@MainActor open class UIElement {
  public var mounted = false
  public var depth: Int = 0
  // Property bindings and builder content; subscribed on mount, cancelled on unmount.
  internal var reactions: [AnyReaction] = []
  private var contentReaction: Reaction<[UIElement]>?

  public init() {}
  
  open func mount(_ context: UIContext) -> Void {
//    print("mount: \(self)")
  }
  internal func handleMount(_ context: UIContext) -> Void {}
  
  open func unmount(_ context: UIContext) -> Void {
//    print("unmount: \(self)")
  }
  internal func handleUnmount(_ context: UIContext) -> Void {}
  
  // Iterates a snapshot: a reaction may add or drop reactions while it runs.
  internal func activateReactions(_ context: UIContext) -> Void {
    let reactions = self.reactions
    reactions.forEach { $0.activate(context) }
  }

  internal func deactivateReactions() -> Void {
    let reactions = self.reactions
    reactions.forEach { $0.deactivate() }
  }

  // Sets children from a builder closure; `if` / `if-else` / `if let` inside it
  // re-evaluate when the `State`s they read change.
  public func setContent(_ build: @escaping () -> [UIElementNode], _ context: UIContext? = nil) -> Void {
    self.clearContent()

    let reaction = DynamicContent.reaction(build) { [weak self] elements, context in
      self?.applyContent(elements, context)
    }
    self.contentReaction = reaction
    self.reactions.append(reaction)

    if self.mounted, let context {
      reaction.activate(context)
    } else {
      self.applyContent(reaction.value, nil)
    }
  }

  // Drops the builder closure; used when children are set imperatively instead.
  public func clearContent() -> Void {
    guard let reaction = self.contentReaction else { return }

    reaction.deactivate()
    self.reactions.removeAll { $0 === reaction }
    self.contentReaction = nil
  }

  // Applies the builder's result. `context` is nil while the element is unmounted.
  internal func applyContent(_ elements: [UIElement], _ context: UIContext?) -> Void {
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
