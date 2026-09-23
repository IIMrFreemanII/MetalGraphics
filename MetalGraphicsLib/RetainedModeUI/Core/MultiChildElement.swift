import simd

open class MultiChildElement : UIElement {
  /// Laid out and drawn in this order.
  ///
  /// Includes children still playing their removal transition. Those are drawn, where they were
  /// last placed, but no longer laid out: the gap they leave closes at once, and with an
  /// animation the children after them slide into it. The indices `insertChild` and `remove(at:)` take are *logical* ones that skip those,
  /// which is what keeps a list's children index-for-index with its array while rows animate
  /// out.
  public var children: [UIElement] = []

  /// How many of `children` are leaving. Zero almost always, and then logical and physical
  /// indices are the same and no translation is done.
  private var leavingCount = 0

  /// The number of children that count, leaving ones excluded.
  public var liveChildrenCount: Int { self.children.count - self.leavingCount }

  public override func debugHierarchy(_ offset: String) {
    print(offset + "\(self)".split(separator: ".").last!)

    for child in children {
      child.debugHierarchy(offset + "  ")
    }
  }

  override func forEachChild(_ body: (UIElement) -> Void) {
    self.children.forEach(body)
  }

  override func applyContent(_ elements: [UIElement]) -> Void {
    self.children = elements
  }

  // Unmounts children that are gone and mounts new ones, keeping shared instances as is.
  //
  // Membership is tested through identity sets rather than the obvious `contains(where:)`,
  // which is quadratic. A list of n rows pays this on every shuffle and every branch swap.
  //
  // With an animation, a departing child that has a transition stays in place, after the
  // surviving child it followed, until its removal transition ends; arriving children with a
  // transition animate in.
  public func replaceChildren(_ elements: [UIElement], _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let old = self.children
    context.invalidate([.layout, .treeOrder], animation: animation)

    guard self.mounted else {
      self.children = elements
      return
    }

    let oldIdentities = Set(old.map { ObjectIdentifier($0) })
    let newIdentities = Set(elements.map { ObjectIdentifier($0) })

    guard animation != nil || self.leavingCount > 0 else {
      self.children = elements
      for child in old where !newIdentities.contains(ObjectIdentifier(child)) {
        child.handleUnmount(context)
      }
      for child in elements where !oldIdentities.contains(ObjectIdentifier(child)) {
        child.handleMount(context)
      }
      return
    }

    // Leaving children are anchored to the surviving child they followed (nil: the start).
    var leavingAfter: [ObjectIdentifier? : [UIElement]] = [:]
    var startLeaving: [(UIElement, TransitionElement)] = []
    var unmountNow: [UIElement] = []
    var lastKept: ObjectIdentifier? = nil

    for child in old {
      let id = ObjectIdentifier(child)
      if newIdentities.contains(id) {
        lastKept = id
      } else if child.isLeaving {
        leavingAfter[lastKept, default: []].append(child)
      } else if animation != nil, let transition = child.transitionOnSpine {
        leavingAfter[lastKept, default: []].append(child)
        startLeaving.append((child, transition))
      } else {
        unmountNow.append(child)
      }
    }

    var result = leavingAfter[nil] ?? []
    result.reserveCapacity(elements.count + self.leavingCount + startLeaving.count)
    for element in elements {
      result.append(element)
      if let following = leavingAfter[ObjectIdentifier(element)] {
        result.append(contentsOf: following)
      }
    }
    self.children = result

    for child in unmountNow {
      child.handleUnmount(context)
    }
    if let animation {
      for (child, transition) in startLeaving {
        self.beginLeaving(child, transition, animation, context)
      }
    }
    for element in elements {
      if element.isLeaving {
        self.revive(element, animation, context)
      } else if !oldIdentities.contains(ObjectIdentifier(element)) {
        self.mountArriving(element, animation, context)
      }
    }
  }

  func insertChild(_ element: UIElement, at index: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    self.children.insert(element, at: self.physicalIndex(forLogical: index))
    context.invalidate([.layout, .treeOrder], animation: animation)

    if self.mounted {
      self.mountArriving(element, animation, context)
    }
  }

  func remove(at index: Int, _ context: UIContext, animation: UIAnimation? = nil) -> Void {
    let physical = self.physicalIndex(forLogical: index)
    guard self.children.indices.contains(physical) else { return }
    let elem = self.children[physical]

    if self.mounted, let animation, let transition = elem.transitionOnSpine {
      // Stays in `children` to be drawn, but leaves layout: the rows after it slide up.
      context.invalidate([.layout, .treeOrder], animation: animation)
      self.beginLeaving(elem, transition, animation, context)
      return
    }

    self.children.remove(at: physical)

    if self.mounted {
      context.invalidate([.layout, .treeOrder], animation: animation)
      elem.handleUnmount(context)
    }
  }

  // MARK: - Transitions

  /// Where the `index`-th live child is in `children`, or the end when there is none.
  private func physicalIndex(forLogical index: Int) -> Int {
    guard self.leavingCount > 0 else {
      return index.clamped(to: 0 ... self.children.count)
    }

    var live = 0
    for (physical, child) in self.children.enumerated() where !child.isLeaving {
      if live >= index { return physical }
      live += 1
    }
    return self.children.count
  }

  private func mountArriving(_ element: UIElement, _ animation: UIAnimation?, _ context: UIContext) -> Void {
    element.handleMount(context)
    if let animation, let transition = element.transitionOnSpine {
      transition.animateIn(animation, context)
    }
  }

  private func beginLeaving(
    _ element: UIElement, _ transition: TransitionElement, _ animation: UIAnimation, _ context: UIContext
  ) -> Void {
    element.isLeaving = true
    self.leavingCount += 1
    transition.animateOut(animation, context) { [weak self] in
      self?.finishLeaving(element, context)
    }
  }

  /// Back before its removal transition ended: still mounted and in place, so it only turns
  /// round. Replacing the transition's animation also drops the pending `finishLeaving`.
  private func revive(_ element: UIElement, _ animation: UIAnimation?, _ context: UIContext) -> Void {
    element.isLeaving = false
    self.leavingCount -= 1
    element.transitionOnSpine?.animateBack(animation, context)
  }

  private func finishLeaving(_ element: UIElement, _ context: UIContext) -> Void {
    guard element.isLeaving, let index = self.children.firstIndex(where: { $0 === element }) else {
      return
    }
    self.children.remove(at: index)
    self.leavingCount -= 1
    element.isLeaving = false
    // Already out of layout since it started leaving; only what is drawn changes.
    context.invalidate(.treeOrder)
    element.handleUnmount(context)
  }

  /// Draws the leaving children where they were last placed within this container, so they
  /// move with it. Stacks call this at the end of `calcPosition`; leaving children are not laid
  /// out, so their size is the one they last had.
  func placeLeaving(in position: float2) -> Void {
    guard self.leavingCount > 0 else { return }
    for child in self.children where child.isLeaving {
      child.calcPosition(position + (child.placement ?? .zero))
    }
  }

  override func dropLeaving() -> Void {
    guard self.leavingCount > 0 else { return }
    self.children.removeAll { child in
      guard child.isLeaving else { return false }
      child.isLeaving = false
      return true
    }
    self.leavingCount = 0
  }
}
