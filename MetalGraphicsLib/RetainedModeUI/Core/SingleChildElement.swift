import simd

open class SingleChildElement : UIElement {
  open var child: UIElement?

  /// Previous children still playing their removal transition. They are drawn under `child`,
  /// where they were last laid out, and dropped when the transition ends — so an animated
  /// branch swap under a single-child element reads as a crossfade.
  private var leaving: [UIElement] = []

  open override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last!)
    child?.debugHierarchy(offset + "  ")
  }

  open override func getSize() -> float2 {
    return child?.getSize() ?? .init()
  }

  open override func calcSize(_ availableSize: float2) -> float2 {
    return child?.calcSize(availableSize) ?? .init()
  }

  open override func calcPosition(_ position: float2) {
    child?.calcPosition(position)
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    self.leaving.forEach(body)
    if let child = self.child {
      body(child)
    }
  }

  override func applyContent(_ elements: [UIElement]) -> Void {
    if elements.count > 1 {
      assertionFailure("\(type(of: self)) takes a single child, got \(elements.count)")
    }
    self.child = elements.first ?? EmptyElement()
  }

  // Unmounts the previous child (if different) and mounts the new one.
  //
  // With an animation, a child that has a transition plays it: the old one animates out before
  // it is unmounted, the new one animates in once mounted.
  public func setChild(_ element: UIElement, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let old = self.child
    guard old !== element else { return }
    self.child = element

    guard self.mounted else { return }
    context.invalidate([.layout, .treeOrder], animation: animation)

    if let old {
      if let animation, let transition = old.transitionOnSpine {
        old.isLeaving = true
        self.leaving.append(old)
        transition.animateOut(animation, context) { [weak self] in
          self?.finishLeaving(old, context)
        }
      } else {
        old.handleUnmount(context)
      }
    }

    if element.isLeaving, let index = self.leaving.firstIndex(where: { $0 === element }) {
      // Swapped back before it finished leaving: it is still mounted, so it only turns round.
      self.leaving.remove(at: index)
      element.isLeaving = false
      element.transitionOnSpine?.animateBack(animation, context)
    } else {
      element.handleMount(context)
      if let animation, let transition = element.transitionOnSpine {
        transition.animateIn(animation, context)
      }
    }
  }

  private func finishLeaving(_ element: UIElement, _ context: UIContext) -> Void {
    guard let index = self.leaving.firstIndex(where: { $0 === element }) else { return }
    self.leaving.remove(at: index)
    element.isLeaving = false
    // Never laid out while leaving; only what is drawn changes.
    context.invalidate(.treeOrder)
    element.handleUnmount(context)
  }

  override func dropLeaving() -> Void {
    guard !self.leaving.isEmpty else { return }
    self.leaving.forEach { $0.isLeaving = false }
    self.leaving.removeAll()
  }
}
